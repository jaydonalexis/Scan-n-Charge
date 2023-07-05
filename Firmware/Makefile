# Compiler options
CC = gcc
CXX = g++
CFLAGS = -Wall -Wextra -std=c99
CXXFLAGS = -Wall -Wextra -std=c++0x

# Directories	
ACCEL_DIR = accel
SERVER_DIR = server
BUILD_DIR = build

# Include directories
ACCEL_INCLUDE = $(ACCEL_DIR)/include
SERVER_INCLUDE = $(SERVER_DIR)/include

# Source files
ACCEL_SRCS = $(wildcard $(ACCEL_DIR)/*.c) $(wildcard $(ACCEL_DIR)/*.cpp)
SERVER_SRCS = $(wildcard $(SERVER_DIR)/*.c) $(wildcard $(SERVER_DIR)/*.cpp)

# Object files
ACCEL_OBJS = $(patsubst $(ACCEL_DIR)/%.c,$(BUILD_DIR)/%.o,$(patsubst $(ACCEL_DIR)/%.cpp,$(BUILD_DIR)/%.o,$(ACCEL_SRCS)))
SERVER_OBJS = $(patsubst $(SERVER_DIR)/%.c,$(BUILD_DIR)/%.o,$(patsubst $(SERVER_DIR)/%.cpp,$(BUILD_DIR)/%.o,$(SERVER_SRCS)))

# Target
TARGET = $(BUILD_DIR)/scanapp

all: $(TARGET)

$(TARGET): $(ACCEL_OBJS) $(SERVER_OBJS)
	$(CXX) $(CXXFLAGS) -I$(ACCEL_INCLUDE) -I$(SERVER_INCLUDE) $(ACCEL_OBJS) $(SERVER_OBJS) -o $(TARGET)

$(BUILD_DIR)/%.o: $(ACCEL_DIR)/%.c
	$(CC) $(CFLAGS) -c -I$(ACCEL_INCLUDE) -I$(SERVER_INCLUDE) $< -o $@

$(BUILD_DIR)/%.o: $(ACCEL_DIR)/%.cpp
	$(CXX) $(CXXFLAGS) -c -I$(ACCEL_INCLUDE) -I$(SERVER_INCLUDE) $< -o $@

$(BUILD_DIR)/%.o: $(SERVER_DIR)/%.c
	$(CC) $(CFLAGS) -c -I$(ACCEL_INCLUDE) -I$(SERVER_INCLUDE) $< -o $@

$(BUILD_DIR)/%.o: $(SERVER_DIR)/%.cpp
	$(CXX) $(CXXFLAGS) -c -I$(ACCEL_INCLUDE) -I$(SERVER_INCLUDE) $< -o $@
	
clean:
	rm -rfv build && mkdir build