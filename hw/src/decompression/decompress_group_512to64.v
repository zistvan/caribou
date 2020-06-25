`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/06/2019 03:27:27 PM
// Design Name: 
// Module Name: decompress_group_512to64
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module decompress_group_512to64
#(
    parameter META_WIDTH = 96,
    parameter MEMORY_WIDTH = 512,
    parameter DECOMPRESS_MODE_SIZE = 8,
    parameter DECOMPRESS_ENGINES_NO = 16,
    parameter VALUE_SIZE_BYTES_NO = 2,
    localparam WORD_SIZE = 512,
    localparam DECOMPRESS_WORD_SIZE = 64
)
(
    input wire clk,
    input wire rst,
    
    input wire [WORD_SIZE-1:0] in_data,
    input wire in_valid,
    output reg in_ready,
    
    input wire [1+META_WIDTH+MEMORY_WIDTH-1:0] in_predconf_data,
    input wire in_predconf_valid,
    output reg in_predconf_ready,
    
    output reg [WORD_SIZE-1:0] out_data,
    output reg out_valid,
    output reg out_last,
    input wire out_ready,
    
    output reg [1+META_WIDTH+MEMORY_WIDTH-1:0] out_predconf_data,
    output reg out_predconf_valid,
    input wire out_predconf_ready
);

reg [DECOMPRESS_MODE_SIZE-1:0] mode_data_buf;

reg [DECOMPRESS_ENGINES_NO-1:0] mode_valids;
wire [DECOMPRESS_ENGINES_NO-1:0] mode_readys;
wire [DECOMPRESS_ENGINES_NO-1:0] mode_fifo_almost_full;

wire [DECOMPRESS_MODE_SIZE-1:0] mode_datas_interm[0:DECOMPRESS_ENGINES_NO-1];
wire [DECOMPRESS_ENGINES_NO-1:0] mode_valids_interm;
wire [DECOMPRESS_ENGINES_NO-1:0] mode_readys_interm;

reg [WORD_SIZE-1:0] in_data_buf;
reg [$clog2(WORD_SIZE)-1:0] in_data_buf_addr;
reg [DECOMPRESS_WORD_SIZE-1:0] in_data_decompress;

reg [DECOMPRESS_ENGINES_NO-1:0] in_valids;
wire [DECOMPRESS_ENGINES_NO-1:0] in_readys;
wire [DECOMPRESS_ENGINES_NO-1:0] in_fifo_almost_full;

wire [DECOMPRESS_WORD_SIZE-1:0] in_datas_interm[0:DECOMPRESS_ENGINES_NO-1];
wire [DECOMPRESS_ENGINES_NO-1:0] in_valids_interm;
wire [DECOMPRESS_ENGINES_NO-1:0] in_readys_interm;

wire [DECOMPRESS_WORD_SIZE-1:0] out_datas_interm[0:DECOMPRESS_ENGINES_NO-1];
wire [DECOMPRESS_ENGINES_NO-1:0] out_valids_interm;
wire [DECOMPRESS_ENGINES_NO-1:0] out_lasts_interm;
wire [DECOMPRESS_ENGINES_NO-1:0] out_readys_interm;

wire [DECOMPRESS_WORD_SIZE-1:0] out_datas[0:DECOMPRESS_ENGINES_NO-1];
wire [DECOMPRESS_ENGINES_NO-1:0] out_valids;
reg [DECOMPRESS_ENGINES_NO-1:0] out_readys;
wire [DECOMPRESS_ENGINES_NO-1:0] out_lasts;
wire [DECOMPRESS_ENGINES_NO-1:0] out_fifo_almost_full;

reg [$clog2(WORD_SIZE)-1:0] out_data_addr;

reg in_last;

reg first_word_flag = 1;
reg [8*VALUE_SIZE_BYTES_NO-1:0] value_bytes_counter;

reg [$clog2(DECOMPRESS_ENGINES_NO)-1:0] cur_in_engine_addr = 0;
reg [$clog2(DECOMPRESS_ENGINES_NO)-1:0] cur_out_engine_addr = 0;

genvar i;
generate
    for (i = 0; i < DECOMPRESS_ENGINES_NO; i = i + 1) begin
        nukv_fifogen #(
            .ADDR_BITS(8),
            .DATA_SIZE(DECOMPRESS_MODE_SIZE)
        ) fifo_mode (
            .clk(clk),
            .rst(rst),
            
            .s_axis_tdata(mode_data_buf),
            .s_axis_tvalid(mode_valids[i]),
            .s_axis_tready(mode_readys[i]),
            .s_axis_talmostfull(mode_fifo_almost_full[i]),
            
            .m_axis_tdata(mode_datas_interm[i]),
            .m_axis_tvalid(mode_valids_interm[i]),
            .m_axis_tready(mode_readys_interm[i])
        );
        
        nukv_fifogen #(
            .ADDR_BITS(8),
            .DATA_SIZE(DECOMPRESS_WORD_SIZE)
        ) fifo_in (
            .clk(clk),
            .rst(rst),
            
            .s_axis_tdata(in_data_decompress),
            .s_axis_tvalid(in_valids[i]),
            .s_axis_tready(in_readys[i]),
            .s_axis_talmostfull(in_fifo_almost_full[i]),
            
            .m_axis_tdata(in_datas_interm[i]),
            .m_axis_tvalid(in_valids_interm[i]),
            .m_axis_tready(in_readys_interm[i])
        );
        
        decompress_engine #(
            .WORD_SIZE(DECOMPRESS_WORD_SIZE),
            .VALUE_SIZE_BYTES_NO(VALUE_SIZE_BYTES_NO)
        ) decompress (
            .clk(clk),
            .rst(rst),
            
            .in_data(in_datas_interm[i]),
            .in_valid(in_valids_interm[i]),
            .in_ready(in_readys_interm[i]),
            
            .mode_data(mode_datas_interm[i]),
            .mode_valid(mode_valids_interm[i]),
            .mode_ready(mode_readys_interm[i]),
            
            .out_data(out_datas_interm[i]),
            .out_valid(out_valids_interm[i]),
            .out_last(out_lasts_interm[i]),
            .out_ready(out_readys_interm[i])
        );
        
        nukv_fifogen #(
            .ADDR_BITS(8),
            .DATA_SIZE(DECOMPRESS_WORD_SIZE+1)
        ) fifo_out (
            .clk(clk),
            .rst(rst),
            
            .s_axis_tdata({out_datas_interm[i],out_lasts_interm[i]}),
            .s_axis_tvalid(out_valids_interm[i]),
            .s_axis_tready(out_readys_interm[i]),
            .s_axis_talmostfull(out_fifo_almost_full[i]),
            
            .m_axis_tdata({out_datas[i],out_lasts[i]}),
            .m_axis_tvalid(out_valids[i]),
            .m_axis_tready(out_readys[i])
        );
    end
endgenerate

always @(posedge clk) begin
    if (rst == 1) begin
        first_word_flag <= 1;
        value_bytes_counter <= 0;
        in_last <= 0;
        in_ready <= 1;
        in_predconf_ready <= 1;
        out_predconf_valid <= 0;
        out_valid <= 0;
        out_last <= 0;
        out_data <= 0;
        
        mode_valids <= 0;
        in_valids <= 0;
        out_readys <= 0;
        
        cur_in_engine_addr <= 0;
        cur_out_engine_addr <= 0;
        
        out_data_addr <= 0;
        in_data_buf <= 0;
        in_data_buf_addr <= 0;
        in_data_decompress <= 0;
    end else begin
        // mode data round-robin logic
        if (in_predconf_valid == 1 && in_predconf_ready == 1) begin
            if (in_predconf_data[1+META_WIDTH +: 8*VALUE_SIZE_BYTES_NO] == 0 || in_predconf_data[1+META_WIDTH +: 8*VALUE_SIZE_BYTES_NO] == 2) begin
                mode_data_buf <= 0;
                out_predconf_data[1+META_WIDTH +: MEMORY_WIDTH] <= in_predconf_data[1+META_WIDTH +: MEMORY_WIDTH];
            end else begin
                mode_data_buf <= in_predconf_data[1+META_WIDTH+8*VALUE_SIZE_BYTES_NO +: DECOMPRESS_MODE_SIZE];
                out_predconf_data[1+META_WIDTH +: 8*VALUE_SIZE_BYTES_NO] <= in_predconf_data[1+META_WIDTH +: 8*VALUE_SIZE_BYTES_NO] - 1;
                out_predconf_data[1+META_WIDTH+8*VALUE_SIZE_BYTES_NO +: MEMORY_WIDTH-8*VALUE_SIZE_BYTES_NO] <= // shift
                    in_predconf_data[1+META_WIDTH+8*VALUE_SIZE_BYTES_NO+DECOMPRESS_MODE_SIZE +: MEMORY_WIDTH-8*VALUE_SIZE_BYTES_NO-DECOMPRESS_MODE_SIZE];
            end
            in_predconf_ready <= 0;
            mode_valids[cur_in_engine_addr] <= 1;
            out_predconf_data[0 +: 1+META_WIDTH] <= in_predconf_data[0 +: 1+META_WIDTH];
            out_predconf_valid <= 1;
        end else begin
            if (mode_readys[cur_in_engine_addr] == 1) begin
                mode_valids <= 0;
            end
            if (out_predconf_valid == 1 && out_predconf_ready == 1) begin
                out_predconf_valid <= 0;
            end
        end
        
        // input data round-robin logic
        if (in_valid == 1 && in_ready == 1) begin
            in_data_buf <= in_data;
            in_ready <= 0;
            in_data_decompress <= in_data[0 +: DECOMPRESS_WORD_SIZE];
            in_valids[cur_in_engine_addr] <= 1;
            in_data_buf_addr <= DECOMPRESS_WORD_SIZE;
            
            if (first_word_flag == 1) begin
                if (in_data[0 +: 8*VALUE_SIZE_BYTES_NO] <= DECOMPRESS_WORD_SIZE/8) begin
                    in_last <= 1;
                end else begin
                    in_last <= 0;
                    first_word_flag <= 0;
                    value_bytes_counter <= in_data[0 +: 8*VALUE_SIZE_BYTES_NO] - DECOMPRESS_WORD_SIZE/8;
                end
            end else begin
                if (value_bytes_counter <= DECOMPRESS_WORD_SIZE/8) begin
                    in_last <= 1;
                    first_word_flag <= 1;
                    in_data_buf_addr <= 0;
                end else begin
                    in_last <= 0;
                    first_word_flag <= 0;
                    value_bytes_counter <= value_bytes_counter - DECOMPRESS_WORD_SIZE/8;
                end
            end
        end else begin
            if (in_readys[cur_in_engine_addr] == 1) begin
                if (in_data_buf_addr != 0 && in_last != 1) begin
                    in_data_decompress <= in_data_buf[in_data_buf_addr +: DECOMPRESS_WORD_SIZE];
                    in_valids[cur_in_engine_addr] <= 1;
                    in_data_buf_addr <= in_data_buf_addr + DECOMPRESS_WORD_SIZE;
                    
                    if (value_bytes_counter <= DECOMPRESS_WORD_SIZE/8) begin
                        in_last <= 1;
                        first_word_flag <= 1;
                        in_data_buf_addr <= 0;
                    end else begin
                        in_last <= 0;
                        first_word_flag <= 0;
                        value_bytes_counter <= value_bytes_counter - DECOMPRESS_WORD_SIZE/8;
                    end
                end else begin
                    in_ready <= 1;
                    in_valids <= 0;
                    if (in_last == 1) begin
                        in_last <= 0;
                        in_predconf_ready <= 1;
                        if (cur_in_engine_addr == DECOMPRESS_ENGINES_NO-1) begin
                            cur_in_engine_addr <= 0;
                        end else begin
                            cur_in_engine_addr <= cur_in_engine_addr + 1;
                        end
                    end
                end
            end
        end
        
        // output round-robin logic
        if (out_valid == 0) begin
            out_readys[cur_out_engine_addr] <= 1;
            if (out_valids[cur_out_engine_addr] == 1 && out_readys[cur_out_engine_addr] == 1) begin
                out_data[out_data_addr +: DECOMPRESS_WORD_SIZE] <= out_datas[cur_out_engine_addr];
                out_data_addr <= out_data_addr + DECOMPRESS_WORD_SIZE;
                if (out_data_addr == WORD_SIZE-DECOMPRESS_WORD_SIZE || out_lasts[cur_out_engine_addr] == 1) begin
                    out_valid <= 1;
                    out_readys <= 0;
                    out_last <= out_lasts[cur_out_engine_addr];
                    out_data_addr <= 0;
                end
            end
        end else begin
            if (out_ready == 1) begin
                out_valid <= 0;
                out_data <= 0;
                if (out_last == 1) begin
                    out_last <= 0;
                    if (cur_out_engine_addr == DECOMPRESS_ENGINES_NO-1) begin
                        cur_out_engine_addr <= 0;
                    end else begin
                        cur_out_engine_addr <= cur_out_engine_addr + 1;
                    end
                end
            end else begin
                out_readys <= 0;
            end
        end
    end
end

endmodule