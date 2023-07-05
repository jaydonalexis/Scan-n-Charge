module dot(input logic clk, input logic rst_n,
           output logic slave_waitrequest,
           input logic [3:0] slave_address,
           input logic slave_read, output logic [31:0] slave_readdata,
           input logic slave_write, input logic [31:0] slave_writedata,
           input logic master_waitrequest,
           output logic [31:0] master_address,
           output logic master_read, input logic [31:0] master_readdata, input logic master_readdatavalid,
           output logic master_write, output logic [31:0] master_writedata);

    enum{GETPARAM, READ1, READ2, DONE, WAITR1, WAITR2, RESULT1_FIRST, RESULT2_FIRST, REQUEST1_FIRST, REQUEST2_FIRST} state;
    logic signed[63:0] temp;
    logic signed[31:0] num1, start, num2;
    logic[31:0] weight_addr, activation_addr, length, i, weight_addr_copy, activation_addr_copy;
    logic w;

    assign slave_waitrequest = rst_n ? w : 1'b1;
    assign master_write = 1'b0;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            state <= GETPARAM;
            w <= 1'b0;
            master_read <= 1'b0;
            i <= 1'b0;
        end
        else
            case (state)
                GETPARAM: begin
                    if(slave_address == 4'd0 && slave_write == 1'b1) begin
                        state <= READ1;
                        w <= 1'b1;
                        start <= 0;
                        activation_addr_copy <= activation_addr;
                        weight_addr_copy <= weight_addr;
                    end
                    else if(slave_address == 2) begin
                        if(slave_read) begin
                            slave_readdata <= weight_addr;
                            w <= 1'b0;
                        end
                        else if(slave_write) begin
                            weight_addr <= slave_writedata;
                            w <= 1'b0;
                        end
                    end
                    else if(slave_address == 3) begin
                        if(slave_read) begin
                            slave_readdata <= activation_addr;
                            w <= 1'b0;
                        end
                        else if(slave_write) begin
                            activation_addr <= slave_writedata;
                            w <= 1'b0;
                        end
                    end
                    else if(slave_address == 5) begin
                        if(slave_read) begin
                            slave_readdata <= length;
                            w <= 1'b0;
                        end
                        else if(slave_write) begin
                            length <= slave_writedata;
                            w <= 1'b0;
                        end
                    end
                    else if (slave_address == 0 && slave_read == 1'b1) begin
                        slave_readdata <= start;
                        w <= 1'b0;
                    end
                end

                READ1: begin
                    master_read <= 1'b1;
                    master_address <= weight_addr_copy;
                    state <= WAITR1;
                    weight_addr_copy <= weight_addr_copy + 4'd4;
                end

                WAITR1: begin
                    if(!master_waitrequest && master_readdatavalid) begin
                        master_read <= 1'b0;
                        state <= READ2;
                        num1 <= master_readdata;
                    end
                    else if(master_readdatavalid) begin
                        num1 <= master_readdata;
                        state <= RESULT1_FIRST;
                    end
                    else if(!master_waitrequest) begin
                        master_read <= 1'b0;
                        state <= REQUEST1_FIRST;
                    end
                end

                REQUEST1_FIRST: begin
                    if(master_readdatavalid) begin
                        num1 <= master_readdata;
                        state <= READ2;
                    end
                end

                RESULT1_FIRST: begin
                    if(!master_waitrequest) begin
                        master_read <= 1'b0;
                        state <= READ2;
                    end
                end

                READ2: begin
                    master_read <= 1'b1;
                    master_address <= activation_addr_copy;
                    state <= WAITR2;
                    activation_addr_copy <= activation_addr_copy + 4'd4;
                    i <= i + 1'd1;
                end

                WAITR2: begin
                    if(!master_waitrequest && master_readdatavalid) begin
                        temp = (num1 * $signed(master_readdata));
                        start = start + (temp >>> 16);
                        master_read <= 1'b0;
                        state <= READ1;
                    end
                    else if(master_readdatavalid) begin
                        num2 <= master_readdata;
                        state <= RESULT2_FIRST;
                    end
                    else if(!master_waitrequest) begin
                        master_read <= 1'b0;
                        state <= REQUEST2_FIRST;
                    end
                end

                RESULT2_FIRST: begin
                    if(!master_waitrequest) begin
                        temp = num1 * num2;
                        start = start + (temp >>> 16);
                        master_read <= 1'b0;
                        if(i == length)
                            state <= DONE;
                        else
                            state <= READ1;
                    end
                end

                REQUEST2_FIRST: begin
                    if(master_readdatavalid) begin
                        state <= READ1;
                        temp = (num1 * $signed(master_readdata));
                        start = start + (temp >>> 16);
                        if(i == length)
                            state <= DONE;
                        else
                            state <= READ1;
                    end
                end
                
                default: begin
                    i <= 1'b0;
                    state <= GETPARAM;
                end
            endcase
        end
endmodule: dot
