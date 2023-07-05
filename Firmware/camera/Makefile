KDIR := /lib/modules/3.18.0/source
SRC := $(shell pwd)
ODIR := module
ARCH := arm
EXTRA_CFLAGS += -I$(PWD)/include/

obj-m += camera_driver.o

all:
	-cd $(SRC) && $(SRC)/deregister 
	make -C $(KDIR) M=$(SRC) ARCH=$(ARCH) modules
	cd $(SRC) && $(SRC)/register	

clean: 
	-cd $(SRC) && $(SRC)/deregister 
	make -C $(KDIR) M=$(SRC) ARCH=$(ARCH) clean