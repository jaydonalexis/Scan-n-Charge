#include <asm/io.h>
#include <asm/types.h>
#include <asm/uaccess.h>
#include <linux/device.h>
#include <linux/dma-mapping.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/kobject.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/miscdevice.h>
#include <linux/mman.h>
#include <linux/io.h>
#include "camera_driver.h"

// Module information
MODULE_AUTHOR("Jaydon Alexis");
MODULE_DESCRIPTION("Camera Driver");
MODULE_LICENSE("GPL");
MODULE_VERSION("0.1");

// Device driver variables
static int major_number;
static int minor_number;
static struct class *device_class = NULL;
static struct device *ntsc_device = NULL;

// Frame writer variables
static void *frame_writer;
static int channel_open;
static void *virtual_buffer0;
static dma_addr_t physical_buffer0;
static void *virtual_buffer1;
static dma_addr_t physical_buffer1;
static size_t frame_memory_size;
static int32_t frame_count;

// Function prototypes
static int camera_open(struct inode *, struct file *);
static int camera_release(struct inode *, struct file *);
static ssize_t camera_read(struct file *, char *, size_t, loff_t *);
int camera_capture(char *user_buffer);

static struct file_operations fops = {
  // Kernel backend calls
  .open = camera_open,
  .read = camera_read,
  .release = camera_release,
};

static int frame_height = DEFAULT_FRAME_HEIGHT;
static int frame_width = DEFAULT_FRAME_WIDTH;
static int frame_writer_mode = CONTINUOUS;
static struct kobject *ntsc_camera_kobj;

//------INIT AND EXIT FUNCTIONS-----//
static int __init camera_driver_init(void) {
  void *SDRAMC_virtual_address;

  printk(KERN_INFO DRIVER_NAME ": Init\n");

  minor_number = 0;

  // Register character device driver
  major_number = register_chrdev(0, DRIVER_NAME, &fops);

  if(major_number < 0) {
    printk(KERN_ALERT DRIVER_NAME ": Failed to register a major number\n");
    return 1;
  }

  // Register the device class
  device_class = class_create(THIS_MODULE, CLASS_NAME);

  if(IS_ERR(device_class)) {
    printk(KERN_ALERT DRIVER_NAME ": Failed to register device class\n");
    goto class_create_error;
  }

  // Register the NTSC device
  ntsc_device = device_create(device_class, NULL, MKDEV(major_number, minor_number), NULL, DEVICE_NAME);

  if(IS_ERR(ntsc_device)) {
    printk(KERN_ALERT DRIVER_NAME ": Failed to create the device NTSC video camera\n");
    goto ntsc_create_error;
  }

  // kernel_kobj points to /sys/kernel
  ntsc_camera_kobj = kobject_create_and_add(DRIVER_NAME, kernel_kobj->parent);

  if(!ntsc_camera_kobj) {
    printk(KERN_INFO DRIVER_NAME ": Failed to create kobject mapping\n");
    goto kobj_create_error;
  }

  // Reset the variables that flag if a device is already open
  channel_open = 0;

  // Remove FPGA-to-SDRAMC ports from reset so FPGA can access SDRAM from them
  SDRAMC_virtual_address = ioremap(SDRAMC_REGS, SDRAMC_REGS_SPAN);

  if(SDRAMC_virtual_address == NULL) {
    printk(KERN_INFO "DMA LKM: error doing SDRAMC ioremap\n");
    goto kobj_create_error;
  }
  
  *((unsigned int *)(SDRAMC_virtual_address + FPGAPORTRST)) = 0xFFFF;

  return 0;

  // Backtrack in the case of module initialization error
  kobj_create_error:
    device_destroy(device_class, MKDEV(major_number, minor_number));
  ntsc_create_error:
    class_unregister(device_class);
    class_destroy(device_class);
  class_create_error:
    unregister_chrdev(major_number, DRIVER_NAME);
    return -1;
}

static void __exit camera_driver_exit(void) {
  device_destroy(device_class, MKDEV(major_number, minor_number));
  class_unregister(device_class);
  class_destroy(device_class);
  unregister_chrdev(major_number, DRIVER_NAME);
  kobject_put(ntsc_camera_kobj);
  printk(KERN_INFO DRIVER_NAME ": Exit\n");
}

int camera_get_frame(int n, char *user_buffer, size_t size) {
  int error;
  int last_buffer;
  void *address_virtual_buffer;

  while(ioread32(frame_writer + CAPTURE_FRAME_COUNTER) == frame_count) {
  };

  frame_count = ioread32(frame_writer + CAPTURE_FRAME_COUNTER);

  // Capture already started so just check where the last frame was saved
  last_buffer = ioread32(frame_writer + LAST_BUFFER_CAPTURED);

  if(last_buffer == 0) {
    address_virtual_buffer = virtual_buffer0;
  }
  else {
    address_virtual_buffer = virtual_buffer1;
  }

  // Copy the frame from buffer camera buffer to user buffer
  error = copy_to_user(user_buffer, address_virtual_buffer, size);

  if(error != 0) {
    printk(KERN_INFO DRIVER_NAME ": Failed to send %d characters to the user in read function\n", error);
    return -EFAULT; // Failed -- return a bad address message (i.e. -14)
  }

  return 0;
}

//-----CHAR DEVICE DRIVER SPECIFIC FUNCTIONS-----//
static int camera_open(struct inode *inodep, struct file *filep) {
  int frame_writer_base;
  int frame_writer_span;
  int pixel_size;
  int counter;

  // Findout which device is being open using the minor numbers
  int device_number = iminor(filep->f_path.dentry->d_inode);

  // Establish frame_writer and pixel_size based on frame_type
  if(device_number == minor_number) {
    printk(KERN_INFO DRIVER_NAME ": Open NTSC video camera\n");
    frame_writer_base = AVALON_FRAME_WRITER_BASE;
    frame_writer_span = AVALON_FRAME_WRITER_SPAN;
    pixel_size = sizeof(u8) * 4;
  } else {
    printk(KERN_INFO DRIVER_NAME ": Error encountered with the minor numbers\n");
    return -1;
  }

  if(channel_open == 1) {
    printk(KERN_INFO DRIVER_NAME ": This device is already open!\n");
    return -1;
  }

  // ioremap the slave port of the frame writer in the FPGA so we can access from the kernel space
  frame_writer = ioremap(HPS_FPGA_BRIDGE_BASE + frame_writer_base, frame_writer_span);

  if(frame_writer == NULL) {
    printk(KERN_INFO DRIVER_NAME ": Error performing FPGA ioremap\n");
    return -1;
  }

  // Calculate required memory to store a frame
  frame_memory_size = frame_width * frame_height * pixel_size;

  virtual_buffer0 = dma_alloc_coherent(NULL, frame_memory_size, &(physical_buffer0), GFP_KERNEL);

  if(virtual_buffer0 == NULL) {
    printk(KERN_INFO DRIVER_NAME ": Allocation of non-cached buffer 0 failed\n");
    return -1;
  }

  virtual_buffer1 = dma_alloc_coherent(NULL, frame_memory_size, &(physical_buffer1), GFP_KERNEL);

  if(virtual_buffer1 == NULL) {
    printk(KERN_INFO DRIVER_NAME ": Allocation of non-cached buffer 1 failed\n");
    return -1;
  }

  iowrite32(frame_writer_mode, frame_writer + CAPTURE_MODE);
  iowrite32(physical_buffer0, frame_writer + CAPTURE_BUFFER0);
  iowrite32(physical_buffer1, frame_writer + CAPTURE_BUFFER1);
  iowrite32(0, frame_writer + BUFFER_SELECT);
  iowrite32(1, frame_writer + DOUBLE_BUFFER);
  iowrite32(1, frame_writer + CAPTURE_DOWNSAMPLING);
  iowrite32(0, frame_writer + START_CAPTURE);
  counter = TIMEOUT;

  while((!(ioread32(frame_writer + CAPTURE_STANDBY))) && (counter > 0)) {
    counter--;
  }
  
  if(counter == 0) {
    printk(KERN_INFO DRIVER_NAME ": No camera reply\n");
    return COMMUNICATION_ERROR;
  }

  // Start the capture
  iowrite32(1, frame_writer + START_CAPTURE);
  channel_open = 1;
  frame_count = 0;

  return 0;
}

static ssize_t camera_read(struct file *filep, char *buffer, size_t size, loff_t *offset) {
  int error;
  int device_number = iminor(filep->f_path.dentry->d_inode);

  if(channel_open == 0) {
    printk(KERN_INFO DRIVER_NAME ": This device is not open!\n");
    return -1;
  }

  error = camera_get_frame(device_number, buffer, size);

  if(error != 0) {
    printk(KERN_INFO DRIVER_NAME ": Read failure!\n");
    return -1;
  }

  return frame_memory_size;
}

static int camera_release(struct inode *inodep, struct file *filep) {
  int device_number = iminor(filep->f_path.dentry->d_inode);

  if(device_number == minor_number) {
    printk(KERN_INFO DRIVER_NAME ": Release NTSC video camera\n");
  }

  if(channel_open == 0) {
    printk(KERN_INFO DRIVER_NAME ": Error releasing: This device is not open!\n");
    return -1;
  }

  // Set start to 0
  iowrite32(0, frame_writer + START_CAPTURE);
  dma_free_coherent(NULL, frame_memory_size, virtual_buffer0, physical_buffer0);
  dma_free_coherent(NULL, frame_memory_size, virtual_buffer1, physical_buffer1);
  iounmap(frame_writer);
  channel_open = 0;

  return 0;
}

module_init(camera_driver_init);
module_exit(camera_driver_exit);