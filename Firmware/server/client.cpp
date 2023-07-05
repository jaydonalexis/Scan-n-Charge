#include "client.h"
using namespace std;

int main(void) {
  uint32_t image_size = IMAGE_HEIGHT * IMAGE_WIDTH * PIXEL_NO;
  uint8_t skipped_frames = 0;
  string command;
  string response_file = RESPONSE_FILE;
  string response_dir = RESPONSE_DIR;
  string response_path = response_dir + response_file;
  string result(image_size, '\0');
  ifstream camera;
  ofstream stream_out;
  camera.open("/dev/ntsc_video_camera", ios::binary);
  int initialized = network_init(NETWORK_INIT_FILENAME);

  if(initialized != 0) {
    return -1;
  }

  this_thread::sleep_for(chrono::seconds(DELAY_TIME));

  while(true) {
    result.clear();
    camera.read(&result[0], image_size);
    skipped_frames++;

    if(skipped_frames > FRAMES_TO_SKIP) {
      stream_out.open("image");
      stream_out << result;
      stream_out.close();
      skipped_frames = 0;
      command = "curl -L -F 'file=@image' http://ec2-3-20-235-97.us-east-2.compute.amazonaws.com:8080/preprocess > " + response_path + " 2> /dev/null";
      system(command.c_str());
    }

    if(is_response_zip()) {
      command = "unzip -o " + response_path + " -d " + response_dir + " > /dev/null";
      system(command.c_str());
      vector<string> file_names = get_files();

      if(file_names.size() != IMAGE_NUMBER) {
        cerr << "Error: Found " << file_names.size() << " files." << endl;
        return -1;
      }

      sort(file_names.begin(), file_names.end());
      vector<int*> bin_data = process_files(file_names);

      if(bin_data.size() != IMAGE_NUMBER) {
        cerr << "Error: Extracted data for " << bin_data.size() << " files." << endl;
        return -1;
      }

      string result = network_run(bin_data);
      command = "curl -X POST -d \"" + result + "\" http://ec2-3-20-235-97.us-east-2.compute.amazonaws.com:8080/postprocess 2> /dev/null";
      system(command.c_str());
    }
  }

  return 0;
}