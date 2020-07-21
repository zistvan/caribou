module MatrixVectorMultiplicationGroup
#(
    parameter VECTOR_SIZE = 3,
    parameter ENTRY_SIZE = 64, // double-precision floating-point format
    parameter MULTIPLICATION_ENGINES_NO = 6,
	parameter VALUE_SIZE_BYTES_NO = 2
)
(
    input wire clk,
    input wire rst,
    
	input wire [VECTOR_SIZE*VECTOR_SIZE*ENTRY_SIZE-1:0] matrix_data,
	input wire [8*VALUE_SIZE_BYTES_NO-1:0] in_value_size_data,
    input wire [VECTOR_SIZE*ENTRY_SIZE-1:0] vector_data,
    input wire in_valid,
    input wire in_last,
    output wire in_ready,
    
    output reg [8*VALUE_SIZE_BYTES_NO-1:0] out_value_size_data,
    output wire [VECTOR_SIZE*ENTRY_SIZE-1:0] out_data,
    output wire out_valid,
    output reg out_last,
    input wire out_ready
);

wire rst_n;

wire [VECTOR_SIZE*VECTOR_SIZE*ENTRY_SIZE-1:0] matrix_datas[0:MULTIPLICATION_ENGINES_NO-1];
wire [VECTOR_SIZE*ENTRY_SIZE-1:0] vector_datas[0:MULTIPLICATION_ENGINES_NO-1];
wire [MULTIPLICATION_ENGINES_NO-1:0] in_valids;
wire [MULTIPLICATION_ENGINES_NO-1:0] in_readys;

wire [VECTOR_SIZE*ENTRY_SIZE-1:0] res_datas[0:MULTIPLICATION_ENGINES_NO-1];
wire [MULTIPLICATION_ENGINES_NO-1:0] res_valids;
wire [MULTIPLICATION_ENGINES_NO-1:0] res_readys;

reg [$clog2(MULTIPLICATION_ENGINES_NO)-1:0] cur_in_engine_addr = 0;
reg [$clog2(MULTIPLICATION_ENGINES_NO)-1:0] cur_out_engine_addr = 0;

reg first_word_flag;

reg [8*VALUE_SIZE_BYTES_NO-1:0] in_value_size_data_buf;
reg in_value_size_data_buf_valid;
wire in_value_size_data_buf_ready;

wire [8*VALUE_SIZE_BYTES_NO-1:0] out_value_size_data_buf;
wire out_value_size_data_buf_valid;
reg out_value_size_data_buf_ready;

reg [8*VALUE_SIZE_BYTES_NO-1:0] value_size;

integer idx;

genvar i;
generate
    for (i = 0; i < MULTIPLICATION_ENGINES_NO; i = i + 1) begin
        MatrixVectorMultiplication_0 matvecmul (
            .ap_clk(clk),
            .ap_rst_n(rst_n),
            
            .in_r_TDATA({vector_datas[i], matrix_datas[i]}),
            .in_r_TVALID(in_valids[i]),
            .in_r_TREADY(in_readys[i]),
            
            .out_res_vals_TDATA(res_datas[i]),
            .out_res_vals_TVALID(res_valids[i]),
            .out_res_vals_TREADY(res_readys[i])
        );
    end
endgenerate

assign rst_n = ~rst;

for (i = 0; i < MULTIPLICATION_ENGINES_NO; i = i + 1) begin
    assign matrix_datas[i] = (cur_in_engine_addr == i) ? matrix_data : 0;
    assign vector_datas[i] = (cur_in_engine_addr == i) ? vector_data : 0;
    assign in_valids[i] = (cur_in_engine_addr == i) ? in_valid : 0;
    
    assign res_readys[i] = (cur_out_engine_addr == i) ? out_ready : 0;
end

assign in_ready = in_readys[cur_in_engine_addr];

assign out_data = res_datas[cur_out_engine_addr];
assign out_valid = res_valids[cur_out_engine_addr];

nukv_fifogen #(
    .DATA_SIZE(8*VALUE_SIZE_BYTES_NO),
    .ADDR_BITS(5)
) fifo_output (
    .clk(clk),
    .rst(rst),
    
    .s_axis_tdata(in_value_size_data_buf),
    .s_axis_tvalid(in_value_size_data_buf_valid),
    .s_axis_tready(in_value_size_data_buf_ready),
    .s_axis_talmostfull(),
    
    .m_axis_tdata(out_value_size_data_buf),
    .m_axis_tvalid(out_value_size_data_buf_valid),
    .m_axis_tready(out_value_size_data_buf_ready)
);

always @(posedge clk) begin
    if (rst == 1) begin
        cur_in_engine_addr <= 0;
        cur_out_engine_addr <= 0;
        out_last <= 0;
        first_word_flag <= 1;
        in_value_size_data_buf_valid <= 0;
        out_value_size_data_buf_ready <= 1;
        value_size <= 0;
    end else begin
        if (in_valid == 1) begin
            if (first_word_flag == 1) begin
                in_value_size_data_buf <= in_value_size_data;
                in_value_size_data_buf_valid <= 1;
                first_word_flag <= 0;
            end
            
            if (in_ready == 1) begin
                if (cur_in_engine_addr == MULTIPLICATION_ENGINES_NO - 1) begin
                    cur_in_engine_addr <= 0;
                end else begin
                    cur_in_engine_addr <= cur_in_engine_addr + 1;
                end
                
                if (in_last == 1) begin
                    first_word_flag <= 1;
                end
            end
        end
        
        if (out_valid == 1 && out_ready == 1) begin
            if (cur_out_engine_addr == MULTIPLICATION_ENGINES_NO - 1) begin
                cur_out_engine_addr <= 0;
            end else begin
                cur_out_engine_addr <= cur_out_engine_addr + 1;
            end
            
            if (out_last == 1) begin
                out_last <= 0;
                out_value_size_data_buf_ready <= 1;
            end else begin
                value_size <= value_size - ENTRY_SIZE / 8;
                if (value_size - ENTRY_SIZE / 8 == ENTRY_SIZE / 8) begin
                    out_last <= 1;
                end
            end
        end
        
        if (in_value_size_data_buf_valid == 1 && in_value_size_data_buf_ready == 1) begin
            in_value_size_data_buf_valid <= 0;
        end
        
        if (out_value_size_data_buf_valid == 1 && out_value_size_data_buf_ready == 1) begin
            out_value_size_data_buf_ready <= 0;
            out_value_size_data <= out_value_size_data_buf;
            value_size <= out_value_size_data_buf - VALUE_SIZE_BYTES_NO;
            if (out_value_size_data_buf - VALUE_SIZE_BYTES_NO < 2 * ENTRY_SIZE / 8) begin
                out_last <= 1;
            end
        end
    end
end

endmodule
