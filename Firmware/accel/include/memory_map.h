#ifndef MAPPING_H
#define MAPPING_H

#include <fcntl.h>
#include <sys/mman.h>
#include <stddef.h>
#include <stdio.h>
#include <unistd.h>

int open_physical (int fd);
void close_physical (int fd);
void* map_physical(int fd, unsigned int base, unsigned int span);
int unmap_physical(void * virtual_base, unsigned int span);

#endif