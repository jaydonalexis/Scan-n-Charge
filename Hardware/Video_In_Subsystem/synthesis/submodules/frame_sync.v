module frame_sync(
    // Inputs
    clk,
    reset,

    stream_endofpacket,
    
    // Outputs
    stream_ready,
    video_stream_reset
);

input clk;
input reset;
input stream_endofpacket;

output reg stream_ready;
output reg video_stream_reset;

reg [2:0] state;
reg [2:0] count;

localparam IDLE = 3'b000;
localparam WAIT = 3'b001;
localparam ACTIVE = 3'b010;

always @(posedge clk)
begin
    if(reset)
    begin
        state <= IDLE;
        count <= 0;
        stream_ready <= 1;
        video_stream_reset <= 1;
    end
    else 
    begin
        case(state)
            IDLE:
                if(stream_endofpacket)
                begin
                    state <= WAIT;
                    count <= 0;
                    stream_ready <= 0;
                    video_stream_reset <= 1;
                end
                else
                begin
                    state <= IDLE;
                    count <= 0;
                    stream_ready <= 1;
                    video_stream_reset <= 1;
                end
            WAIT:
                if(count == 3'b110)
                begin
                    state <= ACTIVE;
                    count <= 0;
                    stream_ready <= 0;
                    video_stream_reset <= 0;
                end
                else
                begin
                    state <= WAIT;
                    count <= count + 1;
                    stream_ready <= 0;
                    video_stream_reset <= 1;
                end
            ACTIVE:
                if(count == 3'b101)
                begin
                    state <= IDLE;
                    count <= 0;
                    stream_ready <= 1;
                    video_stream_reset <= 1;
                end
                else
                begin
                    state <= ACTIVE;
                    count <= count + 1;
                    stream_ready <= 0;
                    video_stream_reset <= 1;
                end
        endcase
    end
end

endmodule