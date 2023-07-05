#ifndef ACCEL_UTILS_H
#define ACCEL_UTILS_H

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include "neural_net.h"

int network_init(const std::string& file_name);
std::string network_run(std::vector<int*> bin_data);

#endif