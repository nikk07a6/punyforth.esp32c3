#include <stdio.h>
#include "punyforth.h"
#include "forth_io.h"

void app_main(void) {
	init_event_queue();
  forth_start();
}
