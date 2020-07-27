module ColToRow
#(
    parameter MEMORY_WIDTH = 512, // constraint: 8 * (VALUE_SIZE_BYTES_NO + VALUE_HEADER_BYTES_NO) <= MEMORY_WIDTH
	parameter COL_COUNT = 3,
	parameter COL_WIDTH = 64,
	parameter VALUE_SIZE_BYTES_NO = 2
)
(
	input wire clk,
	input wire rst,

	input  wire [MEMORY_WIDTH-1:0] input_data,
	input  wire input_valid,
	input  wire input_last,
	output wire input_ready,

    output reg [8*VALUE_SIZE_BYTES_NO-1:0] value_size_data,
	output wire [COL_COUNT*COL_WIDTH-1:0] output_data,
	output wire output_valid,
	output wire output_last,
	input  wire output_ready
);

reg [$clog2(COL_COUNT)-1:0] current_buffer_engine;

wire [MEMORY_WIDTH:0] buffer_input_data [COL_COUNT-1:0];
wire [COL_COUNT-1:0] buffer_input_valid;
wire [COL_COUNT-1:0] buffer_input_ready;

wire [MEMORY_WIDTH:0] buffer_output_data [COL_COUNT-1:0];
wire [COL_COUNT-1:0] buffer_output_valid;
reg [COL_COUNT-1:0] buffer_output_ready;

reg [MEMORY_WIDTH-1:0] colword_buf [COL_COUNT-1:0];
reg [COL_COUNT-1:0] colword_last;
reg [$clog2(MEMORY_WIDTH)-1:0] colword_addr [COL_COUNT-1:0];

reg [COL_COUNT-1:0] first_word_flag;

reg [8*VALUE_SIZE_BYTES_NO-1:0] value_bytes_counter [COL_COUNT-1:0];

reg [COL_WIDTH*COL_COUNT-1:0] assembled_data;
reg [COL_COUNT-1:0] assembled_valid_pre;
wire assembled_valid;
wire assembled_last;
wire assembled_ready;

reg [$clog2(COL_WIDTH/8)-1:0] offset [COL_COUNT-1:0];

integer idx, byte;

genvar i;
generate  
    for (i=0; i < COL_COUNT; i = i + 1)  
	begin: generateloop
			nukv_fifogen #(
			    .DATA_SIZE(MEMORY_WIDTH+1),
			    .ADDR_BITS(9)
			) fifo_values (
			    .clk(clk),
			    .rst(rst),
			    
			    .s_axis_tdata(buffer_input_data[i]),
			    .s_axis_tvalid(buffer_input_valid[i]),
			    .s_axis_tready(buffer_input_ready[i]),
			    .s_axis_talmostfull(),
			    
			    .m_axis_tdata(buffer_output_data[i]),
			    .m_axis_tvalid(buffer_output_valid[i]),
			    .m_axis_tready(buffer_output_ready[i])
			);
	end  
endgenerate

nukv_fifogen #(
    .DATA_SIZE(COL_COUNT*COL_WIDTH+1),
    .ADDR_BITS(4)
) fifo_output (
    .clk(clk),
    .rst(rst),
    
    .s_axis_tdata({assembled_last,assembled_data}),
    .s_axis_tvalid(assembled_valid),
    .s_axis_tready(assembled_ready),
    .s_axis_talmostfull(),
    
    .m_axis_tdata({output_last,output_data}),
    .m_axis_tvalid(output_valid),
    .m_axis_tready(output_ready)
);

for (i = 0; i < COL_COUNT; i = i + 1) begin
    assign buffer_input_data[i] = (current_buffer_engine == i) ? input_data : 0;
    assign buffer_input_valid[i] = (current_buffer_engine == i) ? input_valid : 0;
end

assign input_ready = buffer_input_ready[current_buffer_engine];

assign assembled_valid = (assembled_valid_pre == {COL_COUNT{1'b1}}) ? 1 : 0;
assign assembled_last = assembled_valid == 1 && value_bytes_counter[0] == 0;

always @(posedge clk) begin
	if (rst == 1) begin
		current_buffer_engine <= 0;
		
		for (idx = 0; idx < COL_COUNT; idx = idx + 1) begin
            first_word_flag[idx] <= 1;
            buffer_output_ready[idx] <= 1;
            assembled_valid_pre[idx] <= 0;
        end
	end else begin
        if (input_valid == 1 && input_ready == 1 && input_last == 1) begin
            if (current_buffer_engine == COL_COUNT - 1) begin
                current_buffer_engine <= 0;
            end else begin
                current_buffer_engine <= current_buffer_engine + 1;
            end
        end
        
        for (idx = 0; idx < COL_COUNT; idx = idx + 1) begin
            if (buffer_output_valid[idx] == 1 && buffer_output_ready[idx] == 1) begin
                buffer_output_ready[idx] <= 0;
                
                colword_buf[idx] <= buffer_output_data[idx][MEMORY_WIDTH-1:0];
                colword_last[idx] <= buffer_output_data[idx][MEMORY_WIDTH];
            end
            
            if (buffer_output_ready[idx] == 0 && assembled_valid_pre[idx] == 0) begin
                if (first_word_flag[idx] == 1) begin
                    // HACK: there are some unwanted bytes in the beginning of the page
                    if (colword_buf[idx][8*VALUE_SIZE_BYTES_NO +: 8] == 8'h02) begin
                        value_bytes_counter[idx] <= colword_buf[idx][0 +: 8*VALUE_SIZE_BYTES_NO] - VALUE_SIZE_BYTES_NO - 6;
                        colword_addr[idx] <= 8 * (VALUE_SIZE_BYTES_NO + 6);
                        first_word_flag[idx] <= 0;
                        if (idx == 0) begin
                            value_size_data <= colword_buf[idx][0 +: 8*VALUE_SIZE_BYTES_NO] - 6;
                        end
                        offset[idx] <= (MEMORY_WIDTH/8-(VALUE_SIZE_BYTES_NO + 6)) % (COL_WIDTH/8);
                    end else begin
                        if (colword_buf[idx][8*VALUE_SIZE_BYTES_NO +: 8] == 8'h03) begin
                            value_bytes_counter[idx] <= colword_buf[idx][0 +: 8*VALUE_SIZE_BYTES_NO] - VALUE_SIZE_BYTES_NO - 7;
                            colword_addr[idx] <= 8 * (VALUE_SIZE_BYTES_NO + 7);
                            first_word_flag[idx] <= 0;
                            if (idx == 0) begin
                                value_size_data <= colword_buf[idx][0 +: 8*VALUE_SIZE_BYTES_NO] - 7;
                            end
                            offset[idx] <= (MEMORY_WIDTH/8-(VALUE_SIZE_BYTES_NO + 7)) % (COL_WIDTH/8);
                        end
                    end
                end else begin
                    if (colword_addr[idx] == 0) begin
                        for (byte = 0; byte < (COL_WIDTH/8-offset[idx]); byte = byte + 1) begin
                            assembled_data[idx * COL_WIDTH + offset[idx]*8 + byte*8 +: 8] <= colword_buf[idx][colword_addr[idx] + byte*8 +: 8];
                        end
                        assembled_valid_pre[idx] <= 1;
                        colword_addr[idx] <= colword_addr[idx] + (COL_WIDTH-offset[idx]*8);
                        value_bytes_counter[idx] <= value_bytes_counter[idx] - COL_WIDTH / 8;
                        if (colword_addr[idx] + (COL_WIDTH-offset[idx]*8) >= MEMORY_WIDTH) begin
                            colword_addr[idx] <= 0;
                            buffer_output_ready[idx] <= 1;
                        end
                        if (value_bytes_counter[idx] - COL_WIDTH / 8 == 0) begin
                            colword_addr[idx] <= 0;
                            buffer_output_ready[idx] <= 1;
                            first_word_flag[idx] <= 1;
                        end
                    end else begin
                        if (colword_addr[idx] <= MEMORY_WIDTH - COL_WIDTH) begin
                            for (byte = 0; byte < COL_WIDTH/8; byte = byte + 1) begin
                                assembled_data[idx * COL_WIDTH + byte*8 +: 8] <= colword_buf[idx][colword_addr[idx] + byte*8 +: 8];
                            end
                            assembled_valid_pre[idx] <= 1;
                            colword_addr[idx] <= colword_addr[idx] + COL_WIDTH;
                            value_bytes_counter[idx] <= value_bytes_counter[idx] - COL_WIDTH / 8;
                            if (colword_addr[idx] + COL_WIDTH == MEMORY_WIDTH) begin
                                colword_addr[idx] <= 0;
                                buffer_output_ready[idx] <= 1;
                            end
                            if (value_bytes_counter[idx] - COL_WIDTH / 8 == 0) begin
                                colword_addr[idx] <= 0;
                                buffer_output_ready[idx] <= 1;
                                first_word_flag[idx] <= 1;
                            end
                        end else begin
                            if (colword_addr[idx] >= MEMORY_WIDTH) begin
                                colword_addr[idx] <= 0;
                                buffer_output_ready[idx] <= 1;
                            end else begin
                                for (byte = 0; byte < offset[idx]; byte = byte + 1) begin
                                    assembled_data[idx * COL_WIDTH + byte*8 +: 8] <= colword_buf[idx][colword_addr[idx] + byte*8 +: 8];
                                end
                                colword_addr[idx] <= 0;
                                buffer_output_ready[idx] <= 1;
                            end
                        end
                    end
                end
            end
        end
        
        if (assembled_valid == 1 && assembled_ready == 1) begin
            assembled_valid_pre <= 0;
        end
	end
end

endmodule
