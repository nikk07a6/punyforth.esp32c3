#ifndef __FORTH_IO_H__
#define __FORTH_IO_H__

#define EVT_GPIO   100
#define EVT_BTN    110
#define EVT_ROTARY 120
#define EVT_PING   130
#define EVT_BT_CONNECT    140
#define EVT_BT_DISCONNECT 141
#define EVT_BT_RX         142

struct forth_event {
	int event_type;
	int event_time_ms;
	int event_time_us;
	int event_payload;
};

void init_event_queue();
void forth_add_event(struct forth_event *event);
int forth_wait_event(int timeout_ms, void* event);

#endif
