module RowToCol
#(
    parameter MEMORY_WIDTH = 512,
	parameter COL_COUNT = 3,
	parameter COL_WIDTH = 64,
	parameter VALUE_SIZE_BYTES_NO = 2
)
(
	input wire         clk,
	input wire         rst,

    input wire [8*VALUE_SIZE_BYTES_NO-1:0] value_size_data,
	input wire [COL_COUNT*COL_WIDTH-1:0] input_data,
	input wire input_valid,
	input wire input_last,
	output reg input_ready,

	output wire [MEMORY_WIDTH-1:0] output_data,
	output wire output_valid,
	output wire output_last,
	input wire output_ready
);

localparam WORD_OFFSET = (MEMORY_WIDTH/8-VALUE_SIZE_BYTES_NO) % (COL_WIDTH/8);

reg rstBuf;

reg [MEMORY_WIDTH:0] buffer_input_data [COL_COUNT-1:0];
wire [COL_COUNT-1:0] buffer_input_almfull;
wire [COL_COUNT-1:0] buffer_input_ready;
reg [COL_COUNT-1:0] buffer_input_valid;

reg [$clog2(MEMORY_WIDTH)-1:0] buffer_input_addr;

wire [MEMORY_WIDTH:0] buffer_output_data [COL_COUNT-1:0];
wire [COL_COUNT-1:0] buffer_output_valid;
wire [COL_COUNT-1:0] buffer_output_ready;
reg [COL_COUNT-1:0] buffer_output_sel;

reg [COL_COUNT*COL_WIDTH-1:0] in_buf;
reg [8*VALUE_SIZE_BYTES_NO-1:0] value_size_buf;
reg in_last_buf;

reg first_word_flag;

integer idx, byte;
always @(posedge clk) begin
    rstBuf <= rst;
    
	if(rst) begin
		for (idx = 0; idx < COL_COUNT; idx = idx + 1) begin
			buffer_input_data[idx] <= 0;
			buffer_input_valid[idx] <= 0;
		end
		input_ready <= 1;
		first_word_flag <= 1;
		buffer_input_addr <= 0;
	end else begin
        if (input_valid == 1 && input_ready == 1) begin
            input_ready <= 0;
            in_buf <= input_data;
            if (first_word_flag == 1) begin
                value_size_buf <= value_size_data;
            end
            in_last_buf <= input_last;
        end
        
        if (input_ready == 0 && buffer_input_valid == 0) begin
            if (first_word_flag == 1) begin
                first_word_flag <= 0;
                for (idx = 0; idx < COL_COUNT; idx = idx + 1) begin
                    buffer_input_data[idx][0 +: 8*VALUE_SIZE_BYTES_NO] <= value_size_buf;
                end
                buffer_input_addr <= VALUE_SIZE_BYTES_NO;
            end else begin
                if (buffer_input_addr == 0) begin
                    for (idx = 0; idx < COL_COUNT; idx = idx + 1) begin
                        for (byte = 0; byte < (COL_WIDTH/8-WORD_OFFSET); byte = byte + 1) begin
                            buffer_input_data[idx][buffer_input_addr*8 + byte*8 +: 8] <= in_buf[idx * COL_WIDTH + WORD_OFFSET*8 + byte*8 +: 8];
                        end
                    end
                    buffer_input_addr <= buffer_input_addr + (COL_WIDTH/8-WORD_OFFSET);
                    input_ready <= 1;
                    if (buffer_input_addr + (COL_WIDTH/8-WORD_OFFSET) >= MEMORY_WIDTH/8 || in_last_buf == 1) begin
                        for (idx = 0; idx < COL_COUNT; idx = idx + 1) begin
                            buffer_input_data[idx][MEMORY_WIDTH] <= in_last_buf;
                            buffer_input_valid[idx] <= 1;
                        end
                        buffer_input_addr <= 0;
                        if (in_last_buf == 1) begin
                            first_word_flag <= 1;
                        end
                    end
                end else begin
                    if (buffer_input_addr <= MEMORY_WIDTH/8 - COL_WIDTH/8) begin
                        for (idx = 0; idx < COL_COUNT; idx = idx + 1) begin
                            for (byte = 0; byte < COL_WIDTH/8; byte = byte + 1) begin
                                buffer_input_data[idx][buffer_input_addr*8 + byte*8 +: 8] <= in_buf[idx * COL_WIDTH + byte*8 +: 8];
                            end
                        end
                        buffer_input_addr <= buffer_input_addr + COL_WIDTH/8;
                        input_ready <= 1;
                        if (buffer_input_addr + COL_WIDTH/8 == MEMORY_WIDTH/8 || in_last_buf == 1) begin
                            for (idx = 0; idx < COL_COUNT; idx = idx + 1) begin
                                buffer_input_data[idx][MEMORY_WIDTH] <= in_last_buf;
                                buffer_input_valid[idx] <= 1;
                            end
                            buffer_input_addr <= 0;
                            if (in_last_buf == 1) begin
                                first_word_flag <= 1;
                            end
                        end
                    end else begin
                        if (buffer_input_addr >= MEMORY_WIDTH/8) begin
                            for (idx = 0; idx < COL_COUNT; idx = idx + 1) begin
                                buffer_input_data[idx][MEMORY_WIDTH] <= in_last_buf;
                                buffer_input_valid[idx] <= 1;
                            end
                            buffer_input_addr <= 0;
                            if (in_last_buf == 1) begin
                                first_word_flag <= 1;
                            end
                        end else begin
                            for (idx = 0; idx < COL_COUNT; idx = idx + 1) begin
                                for (byte = 0; byte < WORD_OFFSET; byte = byte + 1) begin
                                    buffer_input_data[idx][buffer_input_addr*8 + byte*8 +: 8] <= in_buf[idx * COL_WIDTH + byte*8 +: 8];
                                end
                                buffer_input_valid[idx] <= 1;
                                buffer_input_addr <= 0;
                            end
                        end
                    end
                end
            end
        end
        
        for (idx = 0; idx < COL_COUNT; idx = idx + 1) begin
            if (buffer_input_valid[idx] == 1 && buffer_input_ready[idx] == 1) begin
                buffer_input_valid[idx] <= 0;
                buffer_input_data[idx] <= 0;
            end
        end
	end
end

genvar X;
generate
    for (X=0; X < COL_COUNT; X=X+1)
	begin: generateloop
			nukv_fifogen #(
			    .DATA_SIZE(MEMORY_WIDTH+1),
			    .ADDR_BITS(9)
			)
			fifo_values (
			    .clk(clk),
			    .rst(rstBuf),
			    
			    .s_axis_tdata(buffer_input_data[X]),
			    .s_axis_tvalid(buffer_input_valid[X]),
			    .s_axis_tready(buffer_input_ready[X]),
			    .s_axis_talmostfull(buffer_input_almfull[X]),
			    
			    .m_axis_tdata(buffer_output_data[X][MEMORY_WIDTH:0]),
			    .m_axis_tvalid(buffer_output_valid[X]),
			    .m_axis_tready(buffer_output_ready[X])
			);

			assign buffer_output_ready[X] = buffer_output_sel==X ? output_ready : 0;
	end
endgenerate

assign output_data = buffer_output_data[buffer_output_sel][MEMORY_WIDTH-1:0];
assign output_last = buffer_output_data[buffer_output_sel][MEMORY_WIDTH];
assign output_valid = buffer_output_valid[buffer_output_sel];

always @(posedge clk) begin 
	if(rst) begin
		buffer_output_sel <= 0;
	end else begin
		if (output_ready==1 && output_valid==1 && output_last==1) begin
			buffer_output_sel <= buffer_output_sel+1;

			if (buffer_output_sel==COL_COUNT-1) begin
				buffer_output_sel <= 0;
			end
		end
	end
end

endmodule
