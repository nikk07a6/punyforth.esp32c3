set (srcs
    "main.c"
    "forth_io.c"
    "forth_net.c"
    "forth_bt.c"
    "forth_1wire.c"
    "forth_adc.c"
    "punyforth.S")
idf_component_register(SRCS ${srcs}
    INCLUDE_DIRS "."
    PRIV_REQUIRES bt nvs_flash vfs fatfs esp_timer esp_driver_gpio esp_adc
                  esp_wifi esp_event esp_netif lwip led_strip onewire_bus)
idf_build_get_property(project_ver PROJECT_VER)
target_compile_definitions(${COMPONENT_LIB} PRIVATE
    PUNYFORTH_VERSION="${project_ver}")
