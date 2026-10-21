#include <string.h>
#include "esp_wifi.h"
#include "esp_event.h"
#include "nvs_flash.h"
#include "esp_log.h"
#include "esp_netif.h"
#include "lwip/err.h"
#include "lwip/sockets.h"
#include "lwip/sys.h"
#include <lwip/netdb.h>
#include "forth_io.h"
#include "ping/ping_sock.h"

static const char *TAG = "forth_net";

static esp_netif_t* netif[2];
static int forth_errno = 0;

static void forth_wifi_event_handler(void *arg, esp_event_base_t event_base,
                                     int32_t event_id, void *event_data) {
	if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
		esp_wifi_connect();
	} else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
		wifi_event_sta_disconnected_t *e = (wifi_event_sta_disconnected_t *)event_data;
		ESP_LOGW(TAG, "STA disconnected, reason=%d", e->reason);
	}
}
int enable = 1;
int keepIdle = 5;
int keepInterval = 5;
int keepCount = 3;

int forth_wifi_init() {
	esp_err_t ret = nvs_flash_init();
	if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
		ESP_ERROR_CHECK(nvs_flash_erase());
		ret = nvs_flash_init();
	}
	ESP_ERROR_CHECK(ret);

	ESP_ERROR_CHECK(esp_netif_init());
	ESP_ERROR_CHECK(esp_event_loop_create_default());
	netif[0] = esp_netif_create_default_wifi_sta();
	netif[1] = esp_netif_create_default_wifi_ap();
	wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
	esp_err_t err = esp_wifi_init(&cfg);
	if (err != ESP_OK) {
		return err;
	}
	esp_event_handler_instance_register(WIFI_EVENT, ESP_EVENT_ANY_ID,
	                                    forth_wifi_event_handler, NULL, NULL);
	return ESP_OK;
}

int forth_wifi_set_sta_config(char* ssid, char* pass) {
	wifi_config_t config;
	memset(&config, 0, sizeof(config));
	memcpy(config.sta.ssid, ssid, MIN(32, strlen(ssid)));
	memcpy(config.sta.password, pass, MIN(64, strlen(pass)));
	config.sta.threshold.authmode = WIFI_AUTH_WPA2_PSK;
	config.sta.pmf_cfg.capable = true;
	config.sta.pmf_cfg.required = false;
	config.sta.sae_pwe_h2e = WPA3_SAE_PWE_BOTH;
	return esp_wifi_set_config(WIFI_IF_STA, &config);
}

int forth_wifi_set_ap_config(char* ssid, char* pass, wifi_auth_mode_t auth_mode,
                                 int hidden, int channel, int max_connection ) {
	wifi_config_t config;
	memset(&config, 0, sizeof(config));
	memcpy(config.ap.ssid, ssid, MIN(32, strlen(ssid)));
  memcpy(config.ap.password, pass, MIN(64, strlen(pass)));
  config.ap.ssid_len = (uint8_t)(strlen(ssid) & 0xff);
  config.ap.ssid_hidden = (uint8_t)(hidden & 0xff);
  config.ap.channel = (uint8_t)(channel & 0xff);
  config.ap.authmode = auth_mode;
  config.ap.max_connection = (uint8_t)(max_connection & 0xff);
  config.ap.beacon_interval = 100;
  return esp_wifi_set_config(WIFI_IF_AP, &config);
}
// -----------------------------------------------
esp_ip4_addr_t forth_wifi_get_ip(int interface) {
	esp_netif_ip_info_t ip_info;
	ESP_ERROR_CHECK(esp_netif_get_ip_info(netif[interface], &ip_info));
  return ip_info.ip;
}

int forth_get_errno() { return forth_errno; }

int forth_socket_new(int type) {
	int sock = 0;
	if (type == 1) sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
  else if (type == 2)	sock = socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
  if (sock < 0) forth_errno = errno;
  return sock;
}

int forth_socket_nonblock(int sock) {
	int flags = fcntl(sock, F_GETFL, 0);
	if (flags < 0) {
		forth_errno = errno;
		return -1;
	}
	if (fcntl(sock, F_SETFL, flags | O_NONBLOCK) < 0) {
		forth_errno = errno;
		return -1;
	}
	return 0;
}

void forth_socket_close(int sock) {
  shutdown(sock, 0);
  close(sock);
}

int forth_socket_bind(int sock, int host, int port) {
	struct sockaddr_in source_addr;
  source_addr.sin_addr.s_addr = host;
  source_addr.sin_family = AF_INET;
  source_addr.sin_port = htons(port);
  int rc = bind(sock, (struct sockaddr *)&source_addr, sizeof(struct sockaddr_in));
  if (rc < 0) forth_errno = errno;
  return rc;
}

int forth_socket_listen(int sock) {
  setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &enable, sizeof(enable));
	int rc = listen(sock, 1);
  if (rc < 0) forth_errno = errno;
  return rc;
}

int forth_socket_accept(int listen_sock) {
	struct sockaddr_in source_addr;
	socklen_t addr_len = sizeof(source_addr);
	int sock = accept(listen_sock, (struct sockaddr *)&source_addr, &addr_len);
	if (sock < 0) forth_errno = errno;
	else {
    setsockopt(sock, SOL_SOCKET, SO_KEEPALIVE, &enable, sizeof(int));
    setsockopt(sock, IPPROTO_TCP, TCP_KEEPIDLE, &keepIdle, sizeof(int));
    setsockopt(sock, IPPROTO_TCP, TCP_KEEPINTVL, &keepInterval, sizeof(int));
    setsockopt(sock, IPPROTO_TCP, TCP_KEEPCNT, &keepCount, sizeof(int));
  }
	return sock;
}

int forth_socket_peer_ip(int sock, uint32_t *ip) {
  struct sockaddr_in peer_addr;
  socklen_t addr_len = sizeof(peer_addr);
  int rc = getpeername(sock, (struct sockaddr *)&peer_addr, &addr_len);
  if (rc < 0) {
    forth_errno = errno;
    return rc;
  }
  *ip = peer_addr.sin_addr.s_addr;
  return 0;
}

int forth_socket_connect(int sock, int host, int port) {
  struct sockaddr_in dest_addr;
  dest_addr.sin_addr.s_addr = host;
  dest_addr.sin_family = AF_INET;
  dest_addr.sin_port = htons(port);
  int rc = connect(sock, (struct sockaddr *)&dest_addr, sizeof(struct sockaddr_in));
  if (rc < 0) forth_errno = errno;
  return rc;
}

char* forth_gethostbyname(char* name) {
	struct hostent *res = gethostbyname(name);
	if (res) return res->h_addr_list[0];
	else return 0;
}

int forth_socket_send(int sock, char* buf, int len) {
	int rc = send(sock, buf, len, 0);
  if (rc < 0) forth_errno = errno;
  return rc;
}

int forth_socket_recv(int sock, char* buf, int len) {
	int rc = recv(sock, buf, len, 0);
  if (rc < 0) forth_errno = errno;
  return rc;
}
// -----------------------------------------------
static void forth_ping_success(esp_ping_handle_t hdl, void* args) {
	uint16_t seqno;
	uint32_t elapsed_time;
  esp_ping_get_profile(hdl, ESP_PING_PROF_SEQNO, &seqno, sizeof(seqno));
  esp_ping_get_profile(hdl, ESP_PING_PROF_TIMEGAP, &elapsed_time, sizeof(elapsed_time));
	struct forth_event event = {
		.event_type    = EVT_PING,
		.event_time_ms = elapsed_time,
		.event_time_us = seqno,
		.event_payload = 0,
	};
	forth_add_event(&event);
}

static void forth_ping_timeout(esp_ping_handle_t hdl, void* args) {
	uint16_t seqno;
  esp_ping_get_profile(hdl, ESP_PING_PROF_SEQNO, &seqno, sizeof(seqno));
	struct forth_event event = {
		.event_type    = EVT_PING,
		.event_time_ms = -1,
		.event_time_us = seqno,
		.event_payload = 0,
	};
	forth_add_event(&event);
}

static void forth_ping_end(esp_ping_handle_t hdl, void* args) {
	uint32_t total_time, transmitted, received;
  esp_ping_get_profile(hdl, ESP_PING_PROF_DURATION, &total_time, sizeof(total_time));
  esp_ping_get_profile(hdl, ESP_PING_PROF_REQUEST, &transmitted, sizeof(transmitted));
  esp_ping_get_profile(hdl, ESP_PING_PROF_REPLY, &received, sizeof(received));
	struct forth_event event = {
		.event_type    = EVT_PING,
		.event_time_ms = total_time,
		.event_time_us = received,
		.event_payload = transmitted,
	};
	forth_add_event(&event);
	esp_ping_delete_session(hdl);
}

void forth_ping(ip4_addr_t host, int count, int interval, int timeout) {
	esp_ping_config_t config = ESP_PING_DEFAULT_CONFIG();
	if (timeout >0) config.timeout_ms = timeout * 1000;
	if (interval >0) config.interval_ms = interval * 1000;
	if (count >0) config.count = count;
  ip_addr_t target_addr;
  memset(&target_addr, 0, sizeof(target_addr));
  target_addr.u_addr.ip4 = host;
  config.target_addr = target_addr;

  esp_ping_callbacks_t cbs = {
		.on_ping_success = forth_ping_success,
		.on_ping_timeout = forth_ping_timeout,
		.on_ping_end = forth_ping_end,
		.cb_args = NULL
  };
  esp_ping_handle_t ping;
  esp_ping_new_session(&config, &cbs, &ping);
  esp_ping_start(ping);
}
