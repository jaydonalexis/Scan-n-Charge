// `timescale 1ns / 1ps

module frame_sync_tb;

reg clk = 0;
reg reset = 1;
reg stream_endofpacket = 0;

wire stream_ready;
wire video_stream_reset;

frame_sync dut(
    .clk(clk),
    .reset(reset),
    .stream_endofpacket(stream_endofpacket),
    .stream_ready(stream_ready),
    .video_stream_reset(video_stream_reset)
);

always begin
    clk = 1'b0;
    #5;
    clk = 1'b1;
    #5;
end

initial
begin
    reset = 1'b0;
    #10;
    reset = 1'b1;
    #10;
    reset = 1'b0;
    
    // Test 1: No end-of-packet signal
    repeat(10) #10;
    
    // Test 2: End-of-packet signal
    stream_endofpacket = 1;
    #10;
    stream_endofpacket = 0;
    repeat(16) #10;
    stream_endofpacket = 0;
    repeat(10) #10;
    
    // Test 3: Two consecutive end-of-packet signals
    // stream_endofpacket = 1;
    // repeat(16) #10;
    // stream_endofpacket = 0;
    // repeat(10) #10;
    // stream_endofpacket = 1;
    // repeat(16) #10;
    // stream_endofpacket = 0;
    // repeat(10) #10;
end

endmodule