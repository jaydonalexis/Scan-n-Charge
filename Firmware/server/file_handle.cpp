#include "file_handle.h"
using namespace std;

bool is_response_zip(void) {
  string file_name = RESPONSE_FILE;
  string dir = RESPONSE_DIR;
  string path = dir + file_name;
  ifstream response(path.c_str(), ios::binary);

  if(!response.is_open()) {
    std::cerr << "Error opening file." << std::endl;
    return false;
  }

  char signature[SIGNATURE_SIZEOF];
  response.read(signature, SIGNATURE_SIZEOF);
  response.close();

  // The zip file signature is 0x50 0x4B 0x03 0x04
  return (signature[0] == 0x50 && signature[1] == 0x4B &&
          signature[2] == 0x03 && signature[3] == 0x04);
}

vector<string> get_files(void) {
  vector<string> file_names;
  DIR* dir;
  struct dirent* entry;

  if((dir = opendir(RESPONSE_DIR)) != NULL) {
    while((entry = readdir(dir)) != NULL) {
      string file_name = entry->d_name;
      if(file_name.find(".bin") != string::npos) {
        file_names.push_back(file_name);
      }
    }

    closedir(dir);
  }
  else {
    cerr << "Failed to open directory." << endl;
  }

  return file_names;
}

vector<int*> process_files(vector<string> file_names) {
  vector<int*> bin_data;
  
  for(const string& file_name : file_names) {
    string dir = RESPONSE_DIR;
    string path = dir + file_name;
    ifstream file(path.c_str(), ios::binary);
    
    if(!file) {
      cerr << "Failed to open " << path << endl;
      return bin_data;
    }

    file.seekg(0, ios::end);
    streampos file_size = file.tellg();
    file.seekg(0, ios::beg);
    char* data = new char[file_size * sizeof(int)];
    file.read(reinterpret_cast<char*>(data), file_size * sizeof(int));
    bin_data.push_back(reinterpret_cast<int*>(data));
  }

  return bin_data;
}
