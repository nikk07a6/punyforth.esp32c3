DEFPRIMITIVE REGULAR,utype,5,"_type"  // ( a -- )
    DPOP     a0           // string
    call     forth_type
    NEXT

DEFPRIMITIVE REGULAR,readchar_wait,13,"readchar-wait" // ( -- char )
    lw       a0, input_file
    beqz     a0, 1f
    call     fgetc
    bgez     a0, 2f
    lw       a0, input_file
    call     fclose
    sw       zero, input_file, a0
    li       a0, 10
    j        2f
1:  call     forth_getchar
2:  DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,readchar_nowait,15,"readchar-nowait" // ( -- char | -1 )
    call     forth_getchar_nowait
    DPUSH    a0
    NEXT
// -----------------------------------------------
DEFPRIMITIVE REGULAR,mount_fat_spiflash,18,"mount-fat-spiflash" // ( path -- rc )
    READTOS1 a0
    call     forth_mount_fat_spiflash
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,fopen,5,"fopen" // ( name mode -- file )
    DPOP     a1
    READTOS1 a0
    call     fopen
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,fopen_rb,8,"fopen-rb" // ( name -- file )
    READTOS1 a0
    la       a1, RB_MODE
    call     fopen
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,fopen_wb,8,"fopen-wb" // ( name -- file )
    READTOS1 a0
    la       a1, WB_MODE
    call     fopen
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,fclose,6,"fclose" // ( file -- )
    DPOP     a0
    call     fclose
    NEXT

DEFPRIMITIVE REGULAR,fputs,5,"fputs" // ( str file -- rc )
    DPOP     a1
    READTOS1 a0
    call     fputs
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,fgets,5,"fgets" // ( str n file -- str | 0 )
    DPOP     a2
    DPOP     a1
    READTOS1 a0
    call     fgets
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,fgetc,5,"fgetc" // ( file -- chr )
    READTOS1 a0
    call     fgetc
    WRTETOS1 a0
    NEXT


DEFPRIMITIVE REGULAR,fwrite,6,"fwrite" // ( buf n file -- n )
    DPOP     a3
    DPOP     a2
    li       a1,1
    READTOS1 a0
    call     fwrite
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,fread,5,"fread" // ( buf n file -- n )
    DPOP     a3
    DPOP     a2
    li       a1,1
    READTOS1 a0
    call     fread
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,opendir,7,"opendir" // ( path -- dirp )
    READTOS1 a0
    call     opendir
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,closedir,8,"closedir" // ( dirp -- )
    DPOP     a0
    call     closedir
    NEXT

DEFPRIMITIVE REGULAR,readdir,7,"readdir" // ( dirp -- dirint )
    READTOS1 a0
    call     readdir
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,rmdir,5,"rmdir" // ( name -- rc )
    READTOS1 a0
    call     rmdir
    WRTETOS1 a0
    NEXT
// -----------------------------------------------
DEFPRIMITIVE REGULAR,add_event,9,"add-event" // ( buf --  )
    DPOP     a0
    call     forth_add_event
    NEXT

DEFPRIMITIVE REGULAR,wait_event,10,"wait-event" // ( buf timeout -- rc )
    DPOP     a0
    READTOS1 a1
    call     forth_wait_event
    WRTETOS1 a0
    NEXT
// -----------------------------------------------
DEFPRIMITIVE REGULAR,gpio_reset_pin,14,"gpio-reset-pin" // ( pin -- )
    DPOP     a0
    call     gpio_reset_pin
    DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,gpio_mode,9,"gpio-mode" // ( pin mode -- )
    DPOP     a1
    DPOP     a0
    call     forth_gpio_mode
    NEXT

DEFPRIMITIVE REGULAR,gpio_pull_mode,14,"gpio-pull-mode" // ( pin mode -- )
    DPOP     a1
    DPOP     a0
    call     forth_gpio_pull_mode
    NEXT

DEFPRIMITIVE REGULAR,gpio_set_interrupt,18,"gpio-set-interrupt" // ( pin intr_type -- )
    DPOP     a1
    DPOP     a0
    call     forth_gpio_set_interrupt
    NEXT

DEFPRIMITIVE REGULAR,gpio_read,9,"gpio-read" // ( pin -- level )
    READTOS1 a0
    call     gpio_get_level
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,gpio_write,10,"gpio-write" // ( pin level -- )
    DPOP     a1
    DPOP     a0
    call     gpio_set_level
    NEXT

DEFPRIMITIVE REGULAR,btn_init,8,"btn-init" // ( pin -- rc )
    READTOS1 a0
    call     forth_btn_init
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,rotary_init,11,"rotary-init" // ( pinA pinB -- )
    DPOP     a1
    DPOP     a0
    call     forth_rotary_init
    NEXT
// -----------------------------------------------
DEFPRIMITIVE REGULAR,wifi_set_sta_config,19,"wifi-set-sta-config"
    DPOP     a0                            // ssid
    READTOS1 a1                            // password
    call     forth_wifi_set_sta_config
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,wifi_set_ap_config,18,"wifi-set-ap-config"
    DPOP     a0                           // ssid
    DPOP     a1                           // password
    DPOP     a2                           // auth_mode
    DPOP     a3                           // hidden
    DPOP     a4                           // channel
    READTOS1 a5                           // max_cannection
    call     forth_wifi_set_ap_config
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,wifi_sta_connect,16,"wifi-sta-connect" // ( -- rc )
    call     esp_wifi_connect
    DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,wifi_sta_disconnect,19,"wifi-sta-disconnect" // ( -- rc )
    call     esp_wifi_disconnect
    DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,wifi_set_mode,13,"wifi-set-mode" // ( mode -- rc )
    READTOS1 a0
    call     esp_wifi_set_mode
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,wifi_start,10,"wifi-start" // ( -- rc )
    call     esp_wifi_start
    DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,wifi_stop,9,"wifi-stop"
    call     esp_wifi_stop
    DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,wifi_init,9,"wifi-init" // ( -- rc )
    call     forth_wifi_init
    DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,wifi_ip,7,"wifi-ip" // ( i -- ipv4 )
    READTOS1 a0                    // interface 0 = sta, 1 = ap
    call     forth_wifi_get_ip
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,2ipv4,5,">ipv4" // ( a b c d -- ipv4 )
    DPOP     a0
    slli     a0, a0, 8
    DPOP     t0
    andi     t0, t0, 0xff
    or       a0, a0, t0
    slli     a0, a0, 8
    DPOP     t0
    andi     t0, t0, 0xff
    or       a0, a0, t0
    slli     a0, a0, 8
    READTOS1 t0
    andi     t0, t0, 0xff
    or       a0, a0, t0
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,get_host_by_name,16,"get-host-by-name" // ( name -- ipv4 | 0 )
    READTOS1 a0
    call     forth_gethostbyname
    beqz     a0, 1f
    lw       a0, 0(a0)
1:  WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,get_errno,9,"get-errno" // ( -- n )
    call     forth_get_errno
    DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,socket_new,10,"socket-new" // ( type -- socket | rc <=0 )
    READTOS1 a0                                 //  type: 1 = UDP, 2 = TCP
    call     forth_socket_new
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,socket_nonblock,15,"socket-nonblock" // ( socket -- rc )
    DPOP     a0
    call     forth_socket_nonblock
    DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,socket_close,12,"socket-close" // ( socket -- )
    DPOP     a0
    call     forth_socket_close
    NEXT

DEFPRIMITIVE REGULAR,socket_bind,11,"socket-bind" // ( port host socket -- rc )
    DPOP     a0
    DPOP     a1
    READTOS1 a2
    call     forth_socket_bind
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,socket_listen,13,"socket-listen" // ( socket -- rc )
    READTOS1 a0
    call     forth_socket_listen
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,socket_accept,13,"socket-accept" // ( listen_socket -- socket | rc <=0 )
    READTOS1 a0
    call     forth_socket_accept
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,socket_peer_ip,18,"socket-peer-ip-raw" // ( socket ip_addr -- rc )
    DPOP     a1
    READTOS1 a0
    call     forth_socket_peer_ip
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,socket_connect,14,"socket-connect" // ( port host socket -- rc )
    DPOP     a0
    DPOP     a1
    READTOS1 a2
    call     forth_socket_connect
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,socket_send,11,"socket-send" // ( socket buf len -- len | rc )
    DPOP     a2
    DPOP     a1
    READTOS1 a0
    call     forth_socket_send
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,socket_recv,11,"socket-recv" // ( socket maxlen buf -- len | rc)
    DPOP     a1
    DPOP     a2
    READTOS1 a0
    call     forth_socket_recv
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,ping,4,"ping" // ( timeout interval count host -- )
    DPOP     a0
    DPOP     a1
    DPOP     a2
    DPOP     a3
    call     forth_ping
    NEXT
// -----------------------------------------------
DEFPRIMITIVE REGULAR,bt_init,7,"bt-init" // ( -- rc )
    call     forth_bt_init
    DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,bt_set_name,11,"bt-set-name" // ( name -- rc )
    READTOS1 a0
    call     forth_bt_set_name
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,bt_advertise,12,"bt-advertise" // ( -- rc )
    call     forth_bt_advertise
    DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,bt_stop_advertise,17,"bt-stop-advertise" // ( -- rc )
    call     forth_bt_stop_advertise
    DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,bt_connected,12,"bt-connected" // ( -- 0|1 )
    call     forth_bt_connected
    DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,bt_available,12,"bt-available" // ( -- n )
    call     forth_bt_available
    DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,bt_read,7,"bt-read" // ( buf maxlen -- n )
    DPOP     a1
    READTOS1 a0
    call     forth_bt_read
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,bt_write,8,"bt-write" // ( buf len -- n | rc )
    DPOP     a1
    READTOS1 a0
    call     forth_bt_write
    WRTETOS1 a0
    NEXT
// -----------------------------------------------
DEFPRIMITIVE REGULAR,led_strip_init,14,"led-strip-init" // ( pin n -- strip | 0 )
    DPOP     a1
    READTOS1 a0
    call     forth_led_strip_init
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,led_strip_clear,15,"led-strip-clear" // ( strip -- )
    DPOP     a0
    call     forth_led_strip_clear
    NEXT

DEFPRIMITIVE REGULAR,led_strip_set_pixel,19,"led-strip-set-pixel" // ( strip i rgb -- )
    DPOP     a2
    DPOP     a1
    DPOP     a0
    call     forth_led_strip_set_pixel
    NEXT

DEFPRIMITIVE REGULAR,led_strip_del,13,"led-strip-del" // ( strip -- )
    DPOP     a0
    call     forth_led_strip_del
    NEXT
// -----------------------------------------------
DEFPRIMITIVE REGULAR,1w_init,7,"1w-init" // ( pin -- bus | 0 )
    READTOS1 a0
    call     forth_1w_init
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,1w_del,6,"1w-del" // ( bus -- rc )
    READTOS1 a0
    call     forth_1w_del
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,1w_reset,8,"1w-reset" // ( bus -- rc )
    READTOS1 a0
    call     forth_1w_reset
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,1w_write,8,"1w-write" // ( bus buf len -- rc )
    DPOP     a2
    DPOP     a1
    READTOS1 a0
    call     forth_1w_write
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,1w_read,7,"1w-read" // ( bus buf len -- rc )
    DPOP     a2
    DPOP     a1
    READTOS1 a0
    call     forth_1w_read
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,1w_search_begin,15,"1w-search-begin" // ( bus -- iter | 0 )
    READTOS1 a0
    call     forth_1w_search_begin
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,1w_search_next,14,"1w-search-next" // ( iter rom8 -- 0|1|<0 )
    DPOP     a1
    READTOS1 a0
    call     forth_1w_search_next
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,1w_search_end,13,"1w-search-end" // ( iter -- rc )
    READTOS1 a0
    call     forth_1w_search_end
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,1w_crc8,7,"1w-crc8" // ( buf len -- crc )
    DPOP     a1
    READTOS1 a0
    call     forth_1w_crc8
    WRTETOS1 a0
    NEXT
// -----------------------------------------------
DEFPRIMITIVE REGULAR,adc_init,8,"adc-init" // ( unit -- handle | 0 )
    READTOS1 a0
    call     forth_adc_init
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,adc_config,10,"adc-config" // ( handle channel atten -- rc )
    DPOP     a2
    DPOP     a1
    READTOS1 a0
    call     forth_adc_config
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,adc_read,8,"adc-read" // ( handle channel -- raw | <0 )
    DPOP     a1
    READTOS1 a0
    call     forth_adc_read
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,adc_del,7,"adc-del" // ( handle -- rc )
    READTOS1 a0
    call     forth_adc_del
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,adc_cali_init,13,"adc-cali-init" // ( unit channel atten -- cali | 0 )
    DPOP     a2
    DPOP     a1
    READTOS1 a0
    call     forth_adc_cali_init
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,adc_raw_mv,10,"adc-raw>mv" // ( cali raw -- mv | <0 )
    DPOP     a1
    READTOS1 a0
    call     forth_adc_raw_to_mv
    WRTETOS1 a0
    NEXT

DEFPRIMITIVE REGULAR,adc_cali_del,12,"adc-cali-del" // ( cali -- rc )
    READTOS1 a0
    call     forth_adc_cali_del
    WRTETOS1 a0
    NEXT
// -----------------------------------------------
DEFPRIMITIVE REGULAR,uemit,5,"_emit"
    DPOP     a0
    call     forth_putchar
    NEXT

DEFPRIMITIVE REGULAR,ms,2,"ms"
    DPOP     a0                 // millis to wait
    call     forth_delay_ms
    NEXT

DEFPRIMITIVE REGULAR,msat,3,"ms@"
    call     forth_time_ms
    DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,usat,3,"us@"
    call     forth_time_us
    DPUSH    a0
    NEXT

DEFPRIMITIVE REGULAR,abort,5,"abort"
    call     forth_abort
    NEXT

#define LAST_API name_abort
