module feed_forward (
    // Inputs
    clk,
    reset,

    stream_data,
    stream_startofpacket,
    stream_endofpacket,
    stream_empty,
    stream_valid,

    // Outputs
    stream_ready,

    out_data,
    out_data_valid
);

parameter           IDW = 23;
parameter           ODW = 31;
parameter           EW = 1;

input               clk;
input               reset;

input [IDW:0]       stream_data;
input               stream_startofpacket;
input               stream_endofpacket;
input [EW:0]        stream_empty;
input               stream_valid;

output              stream_ready;
output reg [ODW:0]  out_data;
output reg          out_data_valid;

wire [7:0]          r;
wire [7:0]          g;
wire [7:0]          b;
wire [7:0]          a;

wire [ODW:0]        converted_data;

// Output Registers
always @(posedge clk)
begin
    if(reset)
    begin
        out_data <= 'b0;
        out_data_valid <= 1'b0;
    end
    else
    begin
        out_data <= converted_data;
        out_data_valid <= stream_valid;
    end
end

// Combination Logic
assign r = stream_data[23:16];
assign g = stream_data[15:8];
assign b = stream_data[7:0];
assign a = 8'b0;

assign converted_data = {a, b, g, r};

endmodule