#ifndef __FORTH_BT_H__
#define __FORTH_BT_H__

int forth_bt_init(void);
int forth_bt_set_name(const char *name);
int forth_bt_advertise(void);
int forth_bt_stop_advertise(void);
int forth_bt_connected(void);
int forth_bt_available(void);
int forth_bt_read(char *buf, int maxlen);
int forth_bt_write(const char *buf, int len);

#endif
