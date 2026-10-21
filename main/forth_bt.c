#include <string.h>
#include "esp_log.h"
#include "nvs_flash.h"
#include "freertos/FreeRTOS.h"
#include "forth_io.h"
#include "forth_bt.h"
#include "os/os_mbuf.h"

#ifdef CONFIG_BT_ENABLED
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "host/ble_hs.h"
#include "host/ble_uuid.h"
#include "host/ble_gatt.h"
#include "host/util/util.h"
#include "services/gap/ble_svc_gap.h"
#include "services/gatt/ble_svc_gatt.h"
#include "store/config/ble_store_config.h"

#define BT_RX_BUF_SIZE 1024
#define BT_DEVICE_NAME_DEFAULT "PunyForth"
#define BT_DEVICE_NAME_MAX 29

static const char *TAG = "forth_bt";

/* Nordic UART Service (NUS) */
static const ble_uuid128_t nus_svc_uuid =
    BLE_UUID128_INIT(0x9e, 0xca, 0xdc, 0x24, 0x0e, 0xe5, 0xa9, 0xe0,
                     0x93, 0xf3, 0xa3, 0xb5, 0x01, 0x00, 0x40, 0x6e);
static const ble_uuid128_t nus_rx_chr_uuid =
    BLE_UUID128_INIT(0x9e, 0xca, 0xdc, 0x24, 0x0e, 0xe5, 0xa9, 0xe0,
                     0x93, 0xf3, 0xa3, 0xb5, 0x02, 0x00, 0x40, 0x6e);
static const ble_uuid128_t nus_tx_chr_uuid =
    BLE_UUID128_INIT(0x9e, 0xca, 0xdc, 0x24, 0x0e, 0xe5, 0xa9, 0xe0,
                     0x93, 0xf3, 0xa3, 0xb5, 0x03, 0x00, 0x40, 0x6e);

static uint8_t bt_rx_buf[BT_RX_BUF_SIZE];
static size_t bt_rx_head;
static size_t bt_rx_tail;
static portMUX_TYPE bt_rx_mux = portMUX_INITIALIZER_UNLOCKED;

static uint16_t conn_handle = BLE_HS_CONN_HANDLE_NONE;
static uint16_t nus_tx_val_handle;
static bool tx_notify_enabled;
static bool stack_synced;
static bool advertise_on_sync;
static bool advertising;
static char device_name[BT_DEVICE_NAME_MAX + 1] = BT_DEVICE_NAME_DEFAULT;

static uint8_t own_addr_type;

static int start_advertising(void);

static void bt_rx_put(const uint8_t *data, int len)
{
    portENTER_CRITICAL(&bt_rx_mux);
    for (int i = 0; i < len; i++) {
        size_t next = (bt_rx_head + 1) % BT_RX_BUF_SIZE;
        if (next == bt_rx_tail) {
            break;
        }
        bt_rx_buf[bt_rx_head] = data[i];
        bt_rx_head = next;
    }
    portEXIT_CRITICAL(&bt_rx_mux);
}

static int bt_rx_count(void)
{
    portENTER_CRITICAL(&bt_rx_mux);
    int n = (int)((bt_rx_head + BT_RX_BUF_SIZE - bt_rx_tail) % BT_RX_BUF_SIZE);
    portEXIT_CRITICAL(&bt_rx_mux);
    return n;
}

static int bt_rx_get(char *buf, int maxlen)
{
    int n = 0;
    portENTER_CRITICAL(&bt_rx_mux);
    while (n < maxlen && bt_rx_tail != bt_rx_head) {
        buf[n++] = (char)bt_rx_buf[bt_rx_tail];
        bt_rx_tail = (bt_rx_tail + 1) % BT_RX_BUF_SIZE;
    }
    portEXIT_CRITICAL(&bt_rx_mux);
    return n;
}

static void bt_post_event(int type, int payload)
{
    struct forth_event event = {
        .event_type = type,
        .event_time_ms = xTaskGetTickCount() * portTICK_PERIOD_MS,
        .event_time_us = 0,
        .event_payload = payload,
    };
    forth_add_event(&event);
}

static int nus_rx_access(uint16_t conn_hdl, uint16_t attr_hdl,
                         struct ble_gatt_access_ctxt *ctxt, void *arg)
{
    (void)conn_hdl;
    (void)attr_hdl;
    (void)arg;

    if (ctxt->op != BLE_GATT_ACCESS_OP_WRITE_CHR) {
        return BLE_ATT_ERR_UNLIKELY;
    }
    uint8_t chunk[256];
    uint16_t len = sizeof(chunk);
    int rc = ble_hs_mbuf_to_flat(ctxt->om, chunk, sizeof(chunk), &len);
    if (rc != 0 || len <= 0) {
        return 0;
    }
    bt_rx_put(chunk, len);
    bt_post_event(EVT_BT_RX, len);
    return 0;
}

static int nus_tx_access(uint16_t conn_hdl, uint16_t attr_hdl,
                         struct ble_gatt_access_ctxt *ctxt, void *arg)
{
    (void)conn_hdl;
    (void)attr_hdl;
    (void)ctxt;
    (void)arg;
    return BLE_ATT_ERR_UNLIKELY;
}

static const struct ble_gatt_svc_def gatt_svcs[] = {
    {
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = &nus_svc_uuid.u,
        .characteristics = (struct ble_gatt_chr_def[]){
            {
                .uuid = &nus_rx_chr_uuid.u,
                .access_cb = nus_rx_access,
                .flags = BLE_GATT_CHR_F_WRITE | BLE_GATT_CHR_F_WRITE_NO_RSP,
            },
            {
                .uuid = &nus_tx_chr_uuid.u,
                .access_cb = nus_tx_access,
                .flags = BLE_GATT_CHR_F_NOTIFY,
                .val_handle = &nus_tx_val_handle,
            },
            {0},
        },
    },
    {0},
};

static int gap_event(struct ble_gap_event *event, void *arg)
{
    (void)arg;

    switch (event->type) {
    case BLE_GAP_EVENT_CONNECT:
        if (event->connect.status == 0) {
            conn_handle = event->connect.conn_handle;
            tx_notify_enabled = false;
            bt_post_event(EVT_BT_CONNECT, (int)conn_handle);
            ESP_LOGI(TAG, "connected, handle=%d", conn_handle);
        } else {
            ESP_LOGW(TAG, "connect failed, status=%d", event->connect.status);
            if (advertise_on_sync) {
                start_advertising();
            }
        }
        return 0;

    case BLE_GAP_EVENT_DISCONNECT:
        ESP_LOGI(TAG, "disconnected, reason=%d", event->disconnect.reason);
        bt_post_event(EVT_BT_DISCONNECT, (int)event->disconnect.reason);
        conn_handle = BLE_HS_CONN_HANDLE_NONE;
        tx_notify_enabled = false;
        if (advertise_on_sync) {
            start_advertising();
        }
        return 0;

    case BLE_GAP_EVENT_SUBSCRIBE:
        if (event->subscribe.attr_handle == nus_tx_val_handle) {
            tx_notify_enabled = event->subscribe.cur_notify;
        }
        return 0;

    case BLE_GAP_EVENT_ADV_COMPLETE:
        advertising = false;
        if (advertise_on_sync && conn_handle == BLE_HS_CONN_HANDLE_NONE) {
            start_advertising();
        }
        return 0;

    default:
        return 0;
    }
}

static int start_advertising(void)
{
    struct ble_hs_adv_fields fields = {0};
    struct ble_gap_adv_params params = {0};
    int rc;

    if (!stack_synced) {
        advertise_on_sync = true;
        return 0;
    }

    fields.flags = BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP;
    fields.name = (uint8_t *)device_name;
    fields.name_len = strlen(device_name);
    fields.name_is_complete = 1;

    rc = ble_gap_adv_set_fields(&fields);
    if (rc != 0) {
        return rc;
    }

    params.conn_mode = BLE_GAP_CONN_MODE_UND;
    params.disc_mode = BLE_GAP_DISC_MODE_GEN;

    rc = ble_gap_adv_start(own_addr_type, NULL, BLE_HS_FOREVER,
                           &params, gap_event, NULL);
    if (rc == 0) {
        advertising = true;
        ESP_LOGI(TAG, "advertising as \"%s\"", device_name);
    }
    return rc;
}

static void on_stack_reset(int reason)
{
    ESP_LOGW(TAG, "nimble reset, reason=%d", reason);
    stack_synced = false;
    conn_handle = BLE_HS_CONN_HANDLE_NONE;
    advertising = false;
}

static void on_stack_sync(void)
{
    int rc;

    rc = ble_hs_util_ensure_addr(0);
    if (rc != 0) {
        ESP_LOGE(TAG, "no BT address");
        return;
    }

    rc = ble_hs_id_infer_auto(0, &own_addr_type);
    if (rc != 0) {
        ESP_LOGE(TAG, "infer addr type failed: %d", rc);
        return;
    }

    stack_synced = true;
    if (advertise_on_sync) {
        start_advertising();
    }
}

static void ble_host_task(void *param)
{
    (void)param;
    nimble_port_run();
    nimble_port_freertos_deinit();
}

static bool bt_inited;

static esp_err_t init_nvs(void)
{
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    return ret;
}

int forth_bt_init(void)
{
    int rc;

    if (bt_inited) {
        return 0;
    }

    esp_log_level_set("NimBLE", ESP_LOG_WARN);

    esp_err_t ret = init_nvs();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "nvs_flash_init: %s", esp_err_to_name(ret));
        return (int)ret;
    }

    ret = nimble_port_init();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "nimble_port_init: %s", esp_err_to_name(ret));
        return (int)ret;
    }

    ble_hs_cfg.reset_cb = on_stack_reset;
    ble_hs_cfg.sync_cb = on_stack_sync;
    ble_hs_cfg.store_status_cb = ble_store_util_status_rr;
    ble_hs_cfg.store_read_cb = ble_store_config_read;
    ble_hs_cfg.store_write_cb = ble_store_config_write;
    ble_hs_cfg.store_delete_cb = ble_store_config_delete;

    rc = ble_svc_gap_device_name_set(device_name);
    if (rc != 0) {
        ESP_LOGE(TAG, "ble_svc_gap_device_name_set: %d", rc);
        return rc;
    }
    ble_svc_gap_init();
    ble_svc_gatt_init();

    rc = ble_gatts_count_cfg(gatt_svcs);
    if (rc != 0) {
        ESP_LOGE(TAG, "ble_gatts_count_cfg: %d", rc);
        return rc;
    }
    rc = ble_gatts_add_svcs(gatt_svcs);
    if (rc != 0) {
        ESP_LOGE(TAG, "ble_gatts_add_svcs: %d", rc);
        return rc;
    }

    nimble_port_freertos_init(ble_host_task);
    bt_inited = true;
    return 0;
}

int forth_bt_set_name(const char *name)
{
    if (!name) {
        return -1;
    }
    strncpy(device_name, name, BT_DEVICE_NAME_MAX);
    device_name[BT_DEVICE_NAME_MAX] = '\0';
    if (bt_inited && stack_synced) {
        return ble_svc_gap_device_name_set(device_name);
    }
    return 0;
}

int forth_bt_advertise(void)
{
    advertise_on_sync = true;
    if (!bt_inited) {
        return -1;
    }
    return start_advertising();
}

int forth_bt_stop_advertise(void)
{
    int rc = 0;
    advertise_on_sync = false;
    if (advertising) {
        rc = ble_gap_adv_stop();
        advertising = false;
    }
    return rc;
}

int forth_bt_connected(void)
{
    return (conn_handle != BLE_HS_CONN_HANDLE_NONE) ? 1 : 0;
}

int forth_bt_available(void)
{
    return bt_rx_count();
}

int forth_bt_read(char *buf, int maxlen)
{
    return bt_rx_get(buf, maxlen);
}

int forth_bt_write(const char *buf, int len)
{
    struct os_mbuf *om;
    int rc;

    if (conn_handle == BLE_HS_CONN_HANDLE_NONE || !tx_notify_enabled) {
        return -1;
    }
    if (len <= 0) {
        return 0;
    }

    om = ble_hs_mbuf_from_flat(buf, len);
    if (!om) {
        return -1;
    }
    rc = ble_gatts_notify_custom(conn_handle, nus_tx_val_handle, om);
    if (rc != 0) {
        os_mbuf_free_chain(om);
    }
    return (rc == 0) ? len : -rc;
}

#else /* !CONFIG_BT_ENABLED */

int forth_bt_init(void) { return -1; }
int forth_bt_set_name(const char *name) { (void)name; return -1; }
int forth_bt_advertise(void) { return -1; }
int forth_bt_stop_advertise(void) { return -1; }
int forth_bt_connected(void) { return 0; }
int forth_bt_available(void) { return 0; }
int forth_bt_read(char *buf, int maxlen) { (void)buf; (void)maxlen; return -1; }
int forth_bt_write(const char *buf, int len) { (void)buf; (void)len; return -1; }

#endif
