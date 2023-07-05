#include "accel_utils.h"
using namespace std;

int network_init(const string& file_name) {
  ifstream init_file(file_name, ios::binary);

  if(!init_file) {
    cerr << "Failed to open binary" << endl;
    return -1;
  }

  init_file.seekg(0, ios::end);
  streampos file_size = init_file.tellg();
  init_file.seekg(0, ios::beg);
  int num_elems = file_size / sizeof(int);
  int* init = new int[num_elems];
  init_file.read(reinterpret_cast<char*>(init), file_size);
  init_file.close();

  if(!init) {
    cerr << "Failed to load binary into neural network" << endl;
    return -1;
  }

  int err = nn_init(init, IN_SIZE, L1_SIZE, L2_SIZE, L3_SIZE);
  delete[] init;

  if(err != 0) {
    cerr << "Failed to initialize neural network" << endl;
    return -1;
  }

  return 0;
}

string network_run(vector<int*> bin_data) {
  string result = "";
  int predicted_index;
  int size = bin_data.size();
  vector<char> character_map = {'0','1','2','3','4','5',
                                '6','7','8','9','A','B',
                                'C','D','E','F','G','H',
                                'I','J','K','L','M','N',
                                'O','P','Q','R','S','T',
                                'U','V','W','X','Y','Z'};

  for(int i = 0; i < size; i++) {
    predicted_index = nn_run(bin_data[i]);
    result += character_map[predicted_index];
  }

  return result;
}