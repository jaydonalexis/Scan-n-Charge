//`timescale 1ns / 1ps

module avalon_image_writer_tb;

  // Parameters
  parameter COMPONENT_SIZE = 8;
  parameter NUMBER_COMPONENTS = 4;
  parameter PIX_WR = 4;
  
  // Inputs
  reg clk;
  reg reset_n;
  reg stream_reset_n;
  reg [15:0] img_width;
  reg [15:0] img_height;
  reg [NUMBER_COMPONENTS*COMPONENT_SIZE-1:0] input_data;
  reg data_valid;
  reg [3:0] S_address;
  reg [31:0] S_writedata;
  reg S_write;
  reg S_read;
  // Outputs
  wire [31:0] S_readdata;
  wire [31:0] M_address;
  wire M_write;
  wire [PIX_WR*NUMBER_COMPONENTS*COMPONENT_SIZE/8-1:0] M_byteenable;
  wire [PIX_WR*NUMBER_COMPONENTS*COMPONENT_SIZE-1:0] M_writedata;
  wire M_waitrequest;
  wire [6:0] M_burstcount;
  
  // Instantiate the unit under test (UUT)
  avalon_image_writer uut (
    .clk(clk),
    .reset_n(reset_n),
    .stream_reset_n(stream_reset_n),
    .img_width(img_width),
    .img_height(img_height),
    .input_data(input_data),
    .data_valid(data_valid),
    .S_address(S_address),
    .S_writedata(S_writedata),
    .S_readdata(S_readdata),
    .S_write(S_write),
    .S_read(S_read),
    .M_address(M_address),
    .M_write(M_write),
    .M_byteenable(M_byteenable),
    .M_writedata(M_writedata),
    .M_waitrequest(M_waitrequest),
    .M_burstcount(M_burstcount)
  );
  
  // Clock generator
  always begin
    clk = 1'b0;
    #5;
    clk = 1'b1;
    #5;
  end
  
  // Configuration
  initial begin
    reset_n = 1'b1;
    #10;
    reset_n = 1'b0;
    #10;
    reset_n = 1'b1;
    // Set the image size to 640x480
    img_width = 640;
    img_height = 480;
    #10;
    S_address = 0;
    S_writedata = 1;
    S_write = 1'b1;
    #10;
    S_address = 1;
    S_writedata = 8'hFF;
    S_write = 1'b1;
    #10;
    S_address = 2;
    S_writedata = 8'hFF;
    S_write = 1;
    #10;
    S_address = 4;
    S_writedata = 0;
    S_write = 1;
    #10;
    S_address = 3;
    S_writedata = 1;
    S_write = 1;
    #10;
    S_address = 8;
    S_writedata = 1;
    S_write = 1;
    #10;
    S_address = 5;
    S_writedata = 0;
    S_write = 1;
    #10;
    S_write = 0;
    #10;

    // Configure the component to write one pixel per write
    S_address = 5;
    S_writedata = 1;
    S_write = 1'b1;
    #10;
    S_write = 1'b0;
    #10;
    
    // Write a pixel to the input
    input_data = 32'hAABBCCDD;
    data_valid = 1'b1;
    #10;
    
    input_data = 32'hDDCCBBAA;
    data_valid = 1'b1;
    #10;

    input_data = 32'hBBAADDCC;
    data_valid = 1'b1;
    #10;

    input_data = 32'hDDCCBBAA;
    data_valid = 1'b1;
    #10;
    
    data_valid = 1'b0;
    
    // Wait for the write to complete
    repeat (10) begin
      #10;
    end
    
    stream_reset_n = 1'b1;
    #10;
    stream_reset_n = 1'b0;
    #10;
    stream_reset_n = 1'b1;
    #10;

    // Write a pixel to the input
    input_data = 32'hAABBCCDD;
    data_valid = 1'b1;
    #10;
    
    input_data = 32'hDDCCBBAA;
    data_valid = 1'b1;
    #10;

    input_data = 32'hBBAADDCC;
    data_valid = 1'b1;
    #10;

    input_data = 32'hDDCCBBAA;
    data_valid = 1'b1;
    #10;

    input_data = 32'hAACCDDBB;
    data_valid = 1'b1;
    #10;

    input_data = 32'hDDBBAACC;
    data_valid = 1'b1;
    #10;

    input_data = 32'hDDAACCBB;
    data_valid = 1'b1;
    #10;

    data_valid = 1'b0;
    
    // Wait for the write to complete
    repeat (10) begin
      #10;
    end
  end
  
endmodule