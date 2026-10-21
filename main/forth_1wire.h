#ifndef __FORTH_1WIRE_H__
#define __FORTH_1WIRE_H__

#include <stdint.h>

/* Thin Forth-side wrappers around espressif/onewire_bus.
 * Handles (bus / iterator) are exposed as opaque pointers cast to int. */

void *forth_1w_init(int pin);                            /* returns handle or NULL  */
int   forth_1w_del(void *bus);                           /* 0 on success            */
int   forth_1w_reset(void *bus);                         /* 0 if a device responds  */
int   forth_1w_write(void *bus, const void *buf, int n); /* 0 on success            */
int   forth_1w_read(void *bus, void *buf, int n);        /* 0 on success            */

void *forth_1w_search_begin(void *bus);                  /* returns iter or NULL    */
int   forth_1w_search_next(void *iter, void *rom8);      /* 1 found / 0 done / <0   */
int   forth_1w_search_end(void *iter);                   /* 0 on success            */

int   forth_1w_crc8(const void *buf, int n);             /* 8-bit CRC               */

#endif
