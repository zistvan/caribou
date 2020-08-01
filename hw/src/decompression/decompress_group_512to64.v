`timescale 1ns / 1ps

module decompress_group_512to64
#(
    parameter DECOMPRESS_MODE_SIZE = 8,
    parameter DECOMPRESS_ENGINES_NO = 36,
    parameter VALUE_SIZE_BYTES_NO = 2,
    localparam WORD_SIZE = 512,
    localparam DECOMPRESS_WORD_SIZE = 64
)
(
    input wire clk,
    input wire rst,
    
    (* mark_debug = "true" *)input wire [WORD_SIZE-1:0] in_data,
    (* mark_debug = "true" *)input wire in_valid,
    (* mark_debug = "true" *)output reg in_ready,
    
    (* mark_debug = "true" *)input wire [WORD_SIZE-1:0] in_pred_data,
    (* mark_debug = "true" *)input wire in_pred_valid,
    (* mark_debug = "true" *)output reg in_pred_ready,
    
    (* mark_debug = "true" *)output reg [WORD_SIZE-1:0] out_data,
    (* mark_debug = "true" *)output reg out_valid,
    (* mark_debug = "true" *)output reg out_last,
    (* mark_debug = "true" *)input wire out_ready,
    
    (* mark_debug = "true" *)output wire [WORD_SIZE-1:0] out_pred_data,
    (* mark_debug = "true" *)output wire out_pred_valid,
    (* mark_debug = "true" *)input wire out_pred_ready
);

(* mark_debug = "true" *)reg [63:0] cnt_valid_deco;
(* mark_debug = "true" *)reg [63:0] cnt_last_deco;

always @(posedge clk) begin
    if (rst == 1) begin
        cnt_valid_deco <= 0;
        cnt_last_deco <= 0;
    end else begin
        if (out_valid == 1 && out_ready == 1) begin
            cnt_valid_deco <= cnt_valid_deco + 1;
            if (out_last == 1) begin
                cnt_last_deco <= cnt_last_deco + 1;
            end
        end
    end
end

reg [$clog2(DECOMPRESS_ENGINES_NO)-1:0] prev_in_engine_addr;
reg [$clog2(DECOMPRESS_ENGINES_NO)-1:0] cur_in_engine_addr;
reg [$clog2(DECOMPRESS_ENGINES_NO)-1:0] cur_out_engine_addr;

reg in_last;
reg first_word_flag;

reg [8*VALUE_SIZE_BYTES_NO-1:0] value_bytes_counter;

reg [WORD_SIZE-1:0] in_data_buf;
reg [$clog2(WORD_SIZE)-1:0] in_data_buf_addr;
reg [DECOMPRESS_WORD_SIZE-1:0] in_data_decompress;
reg [0:DECOMPRESS_ENGINES_NO-1] in_valids;
wire [0:DECOMPRESS_ENGINES_NO-1] in_readys;
wire [0:DECOMPRESS_ENGINES_NO-1] in_almostfulls;

wire [DECOMPRESS_WORD_SIZE-1:0] out_datas[0:DECOMPRESS_ENGINES_NO-1];
wire [0:DECOMPRESS_ENGINES_NO-1] out_valids;
reg [0:DECOMPRESS_ENGINES_NO-1] out_readys;
wire [0:DECOMPRESS_ENGINES_NO-1] out_lasts;

reg [$clog2(WORD_SIZE)-1:0] out_data_addr;

reg [DECOMPRESS_MODE_SIZE-1:0] mode_data_buf;
reg [0:DECOMPRESS_ENGINES_NO-1] mode_valids;
wire [0:DECOMPRESS_ENGINES_NO-1] mode_readys;

wire [DECOMPRESS_MODE_SIZE-1:0] mode_datas_interm[0:DECOMPRESS_ENGINES_NO-1];
wire [0:DECOMPRESS_ENGINES_NO-1] mode_valids_interm;
wire [0:DECOMPRESS_ENGINES_NO-1] mode_readys_interm;

reg [WORD_SIZE-1:0] out_pred_data_interm;
reg out_pred_valid_interm;
wire out_pred_ready_interm;

reg waiting_for_out_pred_clearance_flag;

wire [DECOMPRESS_WORD_SIZE-1:0] in_datas_interm[0:DECOMPRESS_ENGINES_NO-1];
wire [0:DECOMPRESS_ENGINES_NO-1] in_valids_interm;
wire [0:DECOMPRESS_ENGINES_NO-1] in_readys_interm;

wire [DECOMPRESS_WORD_SIZE-1:0] out_datas_interm[0:DECOMPRESS_ENGINES_NO-1];
wire [0:DECOMPRESS_ENGINES_NO-1] out_valids_interm;
wire [0:DECOMPRESS_ENGINES_NO-1] out_lasts_interm;
wire [0:DECOMPRESS_ENGINES_NO-1] out_readys_interm;

always @(posedge clk) begin
    if (rst == 1) begin
        prev_in_engine_addr <= DECOMPRESS_ENGINES_NO-1;
        cur_in_engine_addr <= 0;
        cur_out_engine_addr <= 0;
        
        in_pred_ready <= 1;
        in_ready <= 0;
        first_word_flag <= 1;
        
        value_bytes_counter <= 0;
        in_last <= 0;
        out_pred_valid_interm <= 0;
        out_valid <= 0;
        out_last <= 0;
        out_data <= 0;
        waiting_for_out_pred_clearance_flag <= 0;
        
        mode_valids <= 0;
        in_valids <= 0;
        out_readys <= 0;
        
        out_data_addr <= 0;
        in_data_buf <= 0;
        in_data_buf_addr <= 0;
        in_data_decompress <= 0;
    end else begin
        if (mode_valids[cur_in_engine_addr] == 1 && mode_readys[cur_in_engine_addr] == 1) begin
            mode_valids <= 0;
        end
        if (out_pred_valid_interm == 1 && out_pred_ready_interm == 1) begin
            out_pred_valid_interm <= 0;
        end
        if (in_valids[prev_in_engine_addr] == 1 && in_readys[prev_in_engine_addr] == 1) begin
            in_valids[prev_in_engine_addr] <= 0;
        end
        
        // mode data round-robin logic
        if (in_pred_ready == 1) begin
            if (in_pred_valid == 1) begin
                in_pred_ready <= 0;
                in_ready <= 1;
                if (in_pred_data[0 +: 8*VALUE_SIZE_BYTES_NO] <= 2) begin
                    mode_data_buf <= 0;
                    out_pred_data_interm <= in_pred_data;
                end else begin
                    mode_data_buf <= in_pred_data[8*VALUE_SIZE_BYTES_NO +: DECOMPRESS_MODE_SIZE];
                    out_pred_data_interm[0 +: 8*VALUE_SIZE_BYTES_NO] <= in_pred_data[0 +: 8*VALUE_SIZE_BYTES_NO] - DECOMPRESS_MODE_SIZE/8;
                    out_pred_data_interm[8*VALUE_SIZE_BYTES_NO +: WORD_SIZE-8*VALUE_SIZE_BYTES_NO] <= // shift
                        in_pred_data[8*VALUE_SIZE_BYTES_NO+DECOMPRESS_MODE_SIZE +: WORD_SIZE-8*VALUE_SIZE_BYTES_NO-DECOMPRESS_MODE_SIZE];
                end
                mode_valids[cur_in_engine_addr] <= 1;
                out_pred_valid_interm <= 1;
            end
        end else begin
            // input data round-robin logic
            if (in_valid == 1 && in_ready == 1) begin
                in_ready <= 0;
                in_data_buf <= in_data;
                in_data_decompress <= in_data[0 +: DECOMPRESS_WORD_SIZE];
                in_valids[cur_in_engine_addr] <= 1;
                in_data_buf_addr <= DECOMPRESS_WORD_SIZE;
                in_last <= 0;
                if (first_word_flag == 1) begin
                    if (in_data[0 +: 8*VALUE_SIZE_BYTES_NO] <= DECOMPRESS_WORD_SIZE/8) begin
                        in_last <= 1;
                        in_data_buf_addr <= 0;
                        if (in_almostfulls[cur_in_engine_addr] == 0 && mode_valids == 0 && out_pred_valid_interm == 0) begin
                            in_pred_ready <= 1;
                            if (cur_in_engine_addr == DECOMPRESS_ENGINES_NO-1) begin
                                cur_in_engine_addr <= 0;
                                prev_in_engine_addr <= DECOMPRESS_ENGINES_NO-1;
                            end else begin
                                cur_in_engine_addr <= cur_in_engine_addr + 1;
                                if (prev_in_engine_addr == DECOMPRESS_ENGINES_NO-1) begin
                                    prev_in_engine_addr <= 0;
                                end else begin
                                    prev_in_engine_addr <= prev_in_engine_addr + 1;
                                end
                            end
                        end
                    end else begin
                        first_word_flag <= 0;
                        value_bytes_counter <= in_data[0 +: 8*VALUE_SIZE_BYTES_NO] - DECOMPRESS_WORD_SIZE/8;
                    end
                end else begin
                    if (value_bytes_counter <= DECOMPRESS_WORD_SIZE/8) begin
                        in_last <= 1;
                        in_data_buf_addr <= 0;
                        first_word_flag <= 1;
                        if (in_almostfulls[cur_in_engine_addr] == 0 && mode_valids == 0 && out_pred_valid_interm == 0) begin
                            in_pred_ready <= 1;
                            if (cur_in_engine_addr == DECOMPRESS_ENGINES_NO-1) begin
                                cur_in_engine_addr <= 0;
                                prev_in_engine_addr <= DECOMPRESS_ENGINES_NO-1;
                            end else begin
                                cur_in_engine_addr <= cur_in_engine_addr + 1;
                                if (prev_in_engine_addr == DECOMPRESS_ENGINES_NO-1) begin
                                    prev_in_engine_addr <= 0;
                                end else begin
                                    prev_in_engine_addr <= prev_in_engine_addr + 1;
                                end
                            end
                        end
                    end else begin
                        value_bytes_counter <= value_bytes_counter - DECOMPRESS_WORD_SIZE/8;
                    end
                end
            end else begin
                if (in_valids[cur_in_engine_addr] == 1 && in_readys[cur_in_engine_addr] == 1) begin
                    in_valids <= 0;
                    if (in_last == 1) begin
                        in_last <= 0;
                        if (cur_in_engine_addr == DECOMPRESS_ENGINES_NO-1) begin
                            cur_in_engine_addr <= 0;
                            prev_in_engine_addr <= DECOMPRESS_ENGINES_NO-1;
                        end else begin
                            cur_in_engine_addr <= cur_in_engine_addr + 1;
                            if (prev_in_engine_addr == DECOMPRESS_ENGINES_NO-1) begin
                                prev_in_engine_addr <= 0;
                            end else begin
                                prev_in_engine_addr <= prev_in_engine_addr + 1;
                            end
                        end
                        if (mode_valids == 0 && out_pred_valid_interm == 0) begin
                            in_pred_ready <= 1;
                        end else begin
                            waiting_for_out_pred_clearance_flag <= 1;
                        end
                    end else begin
                        if (in_data_buf_addr == 0) begin
                            in_ready <= 1;
                        end else begin
                            in_data_decompress <= in_data_buf[in_data_buf_addr +: DECOMPRESS_WORD_SIZE];
                            in_valids[cur_in_engine_addr] <= 1;
                            in_data_buf_addr <= in_data_buf_addr + DECOMPRESS_WORD_SIZE;
                            if (value_bytes_counter <= DECOMPRESS_WORD_SIZE/8) begin
                                in_last <= 1;
                                in_data_buf_addr <= 0;
                                first_word_flag <= 1;
                                if (in_almostfulls[cur_in_engine_addr] == 0 && mode_valids == 0 && out_pred_valid_interm == 0) begin
                                    in_pred_ready <= 1;
                                    if (cur_in_engine_addr == DECOMPRESS_ENGINES_NO-1) begin
                                        cur_in_engine_addr <= 0;
                                        prev_in_engine_addr <= DECOMPRESS_ENGINES_NO-1;
                                    end else begin
                                        cur_in_engine_addr <= cur_in_engine_addr + 1;
                                        if (prev_in_engine_addr == DECOMPRESS_ENGINES_NO-1) begin
                                            prev_in_engine_addr <= 0;
                                        end else begin
                                            prev_in_engine_addr <= prev_in_engine_addr + 1;
                                        end
                                    end
                                end
                            end else begin
                                value_bytes_counter <= value_bytes_counter - DECOMPRESS_WORD_SIZE/8;
                                if (in_data_buf_addr == WORD_SIZE - DECOMPRESS_WORD_SIZE) begin
                                    in_data_buf_addr <= 0;
                                    if (in_almostfulls[cur_in_engine_addr] == 0) begin
                                        in_ready <= 1;
                                    end
                                end
                            end
                        end
                    end
                end
                if (waiting_for_out_pred_clearance_flag == 1 && mode_valids == 0 && out_pred_valid_interm == 0) begin
                    waiting_for_out_pred_clearance_flag <= 0;
                    in_pred_ready <= 1;
                end
            end
        end
        
        // output round-robin logic
        if (out_valid == 0) begin
            out_readys[cur_out_engine_addr] <= 1;
        end else begin
            if (out_ready == 1) begin
                out_valid <= 0;
                out_data <= 0;
                if (out_last == 1) begin
                    out_last <= 0;
                    if (out_readys == 0) begin
                        if (cur_out_engine_addr == DECOMPRESS_ENGINES_NO-1) begin
                            cur_out_engine_addr <= 0;
                        end else begin
                            cur_out_engine_addr <= cur_out_engine_addr + 1;
                        end
                    end
                end
            end
        end
        if (out_valids[cur_out_engine_addr] == 1 && out_readys[cur_out_engine_addr] == 1) begin
            out_data[out_data_addr +: DECOMPRESS_WORD_SIZE] <= out_datas[cur_out_engine_addr];
            out_data_addr <= out_data_addr + DECOMPRESS_WORD_SIZE;
            if (out_lasts[cur_out_engine_addr] == 1) begin
                out_last <= 1;
                out_valid <= 1;
                out_data_addr <= 0;
                if (out_ready == 1) begin
                    out_readys[cur_out_engine_addr] <= 0;
                    if (cur_out_engine_addr == DECOMPRESS_ENGINES_NO-1) begin
                        cur_out_engine_addr <= 0;
                        out_readys[0] <= 1;
                    end else begin
                        cur_out_engine_addr <= cur_out_engine_addr + 1;
                        out_readys[cur_out_engine_addr + 1] <= 1;
                    end
                end else begin
                    out_readys <= 0;
                end
            end else begin
                if (out_data_addr == WORD_SIZE - DECOMPRESS_WORD_SIZE) begin
                    out_valid <= 1;
                    out_data_addr <= 0;
                    if (out_ready == 0) begin
                        out_readys <= 0;
                    end
                end
            end
        end
    end
end

genvar i;
generate
    for (i = 0; i < DECOMPRESS_ENGINES_NO; i = i + 1) begin
        nukv_fifogen #(
            .ADDR_BITS(9),
            .DATA_SIZE(DECOMPRESS_MODE_SIZE)
        ) fifo_mode (
            .clk(clk),
            .rst(rst),
            
            .s_axis_tdata(mode_data_buf),
            .s_axis_tvalid(mode_valids[i]),
            .s_axis_tready(mode_readys[i]),
            
            .m_axis_tdata(mode_datas_interm[i]),
            .m_axis_tvalid(mode_valids_interm[i]),
            .m_axis_tready(mode_readys_interm[i])
        );
        
        nukv_fifogen #(
            .ADDR_BITS(9),
            .DATA_SIZE(DECOMPRESS_WORD_SIZE)
        ) fifo_in (
            .clk(clk),
            .rst(rst),
            
            .s_axis_tdata(in_data_decompress),
            .s_axis_tvalid(in_valids[i]),
            .s_axis_tready(in_readys[i]),
            .s_axis_talmostfull(in_almostfulls[i]),
            
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
            .ADDR_BITS(9),
            .DATA_SIZE(DECOMPRESS_WORD_SIZE+1)
        ) fifo_out (
            .clk(clk),
            .rst(rst),
            
            .s_axis_tdata({out_lasts_interm[i], out_datas_interm[i]}),
            .s_axis_tvalid(out_valids_interm[i]),
            .s_axis_tready(out_readys_interm[i]),
            
            .m_axis_tdata({out_lasts[i], out_datas[i]}),
            .m_axis_tvalid(out_valids[i]),
            .m_axis_tready(out_readys[i])
        );
    end
endgenerate

nukv_fifogen #(
    .ADDR_BITS(9),
    .DATA_SIZE(WORD_SIZE)
) fifo_mode (
    .clk(clk),
    .rst(rst),
    
    .s_axis_tdata(out_pred_data_interm),
    .s_axis_tvalid(out_pred_valid_interm),
    .s_axis_tready(out_pred_ready_interm),
    
    .m_axis_tdata(out_pred_data),
    .m_axis_tvalid(out_pred_valid),
    .m_axis_tready(out_pred_ready)
);

endmodule
