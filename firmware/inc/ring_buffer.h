#pragma once

#include <stddef.h>
#include <stdint.h>

#define RING_BUFFER_MAX 2

typedef struct {
    size_t s_elem;
    size_t n_elem;
    void *buffer;
} rb_attr_t;

/* ring buffer descriptor */
typedef unsigned int rbd_t;

struct ring_buffer {
    size_t s_elem;
    size_t n_elem;
    uint8_t *buf;
    volatile size_t head;
    volatile size_t tail;
};

int ring_buffer_init(rbd_t *rbd, rb_attr_t *attr);
int ring_buffer_put(rbd_t rbd, const void *data);
int ring_buffer_get(rbd_t rbd, void *data);