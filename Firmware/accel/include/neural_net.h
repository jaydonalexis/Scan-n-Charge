#ifndef NEURAL_NET_H
#define NEURAL_NET_H

#include <string.h>
#include "memory_map.h"

#define DOT_BASE 0x80
#define WRITE_OFF 0x0
#define READ_OFF 0x0
#define WEIGHT_OFF 0x2
#define INPUT_OFF 0x3
#define LENGTH 0x5
#define MEM_BASE 0xC0001000 
#define FPGA_MEM_BASE MEM_BASE - 0xC0000000
#define MEM_SIZE 1024 * 1024 * 20
#define DOT 0xFF202000
#define DOT_SIZE 0x4 * 0xF
#define FPGA_SRAM0 0x8000000
#define HPS_SRAM0 0xC0000000 + FPGA_SRAM0
#define SRAM_SIZE 0x1000
#define FPGA_SRAM1 FPGA_SRAM0 + SRAM_SIZE
#define HPS_SRAM1 0xC0000000 + FPGA_SRAM1
#define IN_SIZE 784
#define L1_SIZE 1000
#define L2_SIZE 750
#define L3_SIZE 36
#define NETWORK_INIT_FILENAME "../models/model.bin"

#ifdef __cplusplus
extern "C" {
#endif

int nn_init(int *nn_in, int in_size, int l1_size, int l2_size, int l3_size);
int nn_run(int *in);
int nn_destroy(void);

#ifdef __cplusplus
}
#endif

#endif