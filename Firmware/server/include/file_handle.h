#ifndef FILE_HANDLE_H
#define FILE_HANDLE_H

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <algorithm>
#include <dirent.h>

#define RESPONSE_FILE "response"
#define RESPONSE_DIR "../server/response/"
#define SIGNATURE_SIZEOF 4

bool is_response_zip(void);
std::vector<std::string> get_files(void);
std::vector<int*> process_files(std::vector<std::string> file_names);

#endif