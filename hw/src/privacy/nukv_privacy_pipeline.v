//---------------------------------------------------------------------------
//--  Copyright 2015 - 2017 Systems Group, ETH Zurich
//-- 
//--  This hardware module is free software: you can redistribute it and/or
//--  modify it under the terms of the GNU General Public License as published
//--  by the Free Software Foundation, either version 3 of the License, or
//--  (at your option) any later version.
//-- 
//--  This program is distributed in the hope that it will be useful,
//--  but WITHOUT ANY WARRANTY; without even the implied warranty of
//--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//--  GNU General Public License for more details.
//-- 
//--  You should have received a copy of the GNU General Public License
//--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//---------------------------------------------------------------------------


module nukv_Privacy_Pipeline
#(
	parameter MEMORY_WIDTH = 512,
	parameter COL_COUNT = 3,
    parameter COL_WIDTH = 64,
    parameter VALUE_SIZE_BYTES_NO = 2
)
(
	input wire clk,
	input wire rst,

	(* mark_debug = "true" *)input wire [MEMORY_WIDTH-1:0] pred_data,
	(* mark_debug = "true" *)input wire pred_valid,
	(* mark_debug = "true" *)output wire pred_ready,

	(* mark_debug = "true" *)input wire [MEMORY_WIDTH-1:0] value_data,
	(* mark_debug = "true" *)input wire value_valid,
	(* mark_debug = "true" *)input wire value_last,
	(* mark_debug = "true" *)output wire value_ready,

	(* mark_debug = "true" *)output wire [MEMORY_WIDTH-1:0] output_data,
	(* mark_debug = "true" *)output wire output_valid,
	(* mark_debug = "true" *)output wire output_last,
	(* mark_debug = "true" *)input wire output_ready

);

    (* mark_debug = "true" *)reg [63:0] cnt_valid_priv;
    (* mark_debug = "true" *)reg [63:0] cnt_last_priv;
    
    always @(posedge clk) begin
        if (rst == 1) begin
            cnt_valid_priv <= 0;
            cnt_last_priv <= 0;
        end else begin
            if (output_valid == 1 && output_ready == 1) begin
                cnt_valid_priv <= cnt_valid_priv + 1;
                if (output_last == 1) begin
                    cnt_last_priv <= cnt_last_priv + 1;
                end
            end
        end
    end

    wire [MEMORY_WIDTH-1:0] seg_data;
    wire seg_valid;
    wire seg_last;
    wire seg_ready;

    wire ic_data;
    wire ic_valid;
    wire ic_valid_masked;
    wire ic_ready;
    wire ic_ready_fifo;

    wire oc_data;
    wire oc_valid;
    wire oc_ready;

    wire [MEMORY_WIDTH-1:0] imed_data [1:0];
    wire [1:0] imed_valid;
    wire [1:0] imed_last;
    wire [1:0] imed_ready;

    wire [MEMORY_WIDTH-1:0] omed_data [1:0];
    wire [1:0] omed_valid;
    wire [1:0] omed_last;
    wire [1:0] omed_ready;
    
    wire [COL_COUNT*COL_COUNT*COL_WIDTH-1:0] matrix_data;
    wire matrix_valid;
    wire matrix_last;
    
    wire is_get_cond_valid;
    wire is_get_cond_ready;
    
    wire buffering_matrix;
    reg matrix_buf_flag;
    
    wire matrix_buf_valid;
    wire matrix_buf_ready;
    
    wire segmenter_valid;
    wire segmenter_ready;
    
    assign buffering_matrix = ((matrix_buf_flag == 1 && matrix_last == 0) || (pred_valid == 1 && pred_data[8*VALUE_SIZE_BYTES_NO +: 8] == 8'hFE)) ? 1 : 0;
    
    assign segmenter_valid = /*(buffering_matrix == 1) ? 0 : */value_valid;
    assign matrix_buf_valid = (buffering_matrix == 1) ? value_valid : 0;
    assign value_ready = (buffering_matrix == 1) ? (matrix_buf_ready & segmenter_ready) : segmenter_ready;
    
    assign is_get_cond_valid = /*(buffering_matrix == 1) ? 0 : */pred_valid;
    assign pred_ready = /*(buffering_matrix == 1) ? 1 : */is_get_cond_ready;
    
    always @(posedge clk) begin
        if (rst == 1) begin
            matrix_buf_flag <= 0;
        end else begin
            if (matrix_buf_flag == 0 && buffering_matrix == 1) begin
                matrix_buf_flag <= 1;
            end
            if (matrix_buf_flag == 1 && matrix_last == 1) begin
                matrix_buf_flag <= 0;
            end
        end
    end

    nukv_fifogen #(
    .DATA_SIZE(8),
    .ADDR_BITS(5)
    ) fifo_input_choice (
        .clk(clk),
        .rst(rst),
        
        .s_axis_tdata(pred_data[8*VALUE_SIZE_BYTES_NO +: 1]),
        .s_axis_tvalid(is_get_cond_valid),
        .s_axis_tready(is_get_cond_ready),
        .s_axis_talmostfull(),
        
        .m_axis_tdata(ic_data),
        .m_axis_tvalid(ic_valid),
        .m_axis_tready(ic_ready)
    );

    assign ic_ready = ic_ready_fifo & seg_valid & seg_last & seg_ready;
    assign ic_valid_masked = ic_valid & ic_ready;
    
    assign seg_data = value_data;
    assign seg_valid = segmenter_valid;
    assign seg_last = value_last;
    assign segmenter_ready = seg_ready;

//    nukv_Value_Segmenter segmenter (
//        .clk(clk),
//        .rst(rst),
//        .value_data(value_data),
//        .value_valid(segmenter_valid),
//        .value_ready(segmenter_ready),

//        .output_data(seg_data),
//        .output_last(seg_last),
//        .output_valid(seg_valid),
//        .output_ready(seg_ready)
//    );

    assign imed_data[0] = seg_data;
    assign imed_last[0] = seg_last;    
    assign imed_data[1] = seg_data;
    assign imed_last[1] = seg_last;
    assign seg_ready = ic_valid==1 ? imed_ready[ic_data] : 0;
    assign imed_valid[0] = ic_valid==1 && ic_data==0 ? seg_valid : 0;
    assign imed_valid[1] = ic_valid==1 && ic_data==1 ? seg_valid : 0;


    nukv_fifogen #(
    .DATA_SIZE(MEMORY_WIDTH+1),
    .ADDR_BITS(10)
    ) fifo_bypass (
        .clk(clk),
        .rst(rst),
        
        .s_axis_tdata({imed_last[0],imed_data[0]}),
        .s_axis_tvalid(imed_valid[0]),
        .s_axis_tready(imed_ready[0]),
        .s_axis_talmostfull(),
        
        .m_axis_tdata({omed_last[0],omed_data[0]}),
        .m_axis_tvalid(omed_valid[0]),
        .m_axis_tready(omed_ready[0])
    );
    
    nukv_Rotation_Matrix_Buf #(
        .MEMORY_WIDTH(MEMORY_WIDTH),
        .COL_COUNT(COL_COUNT),
   	    .COL_WIDTH(COL_WIDTH),
   	    .VALUE_SIZE_BYTES_NO(VALUE_SIZE_BYTES_NO)
    ) rotation_matrix_buf (
        .clk(clk),
        .rst(rst),
        
        .value_data(value_data),
        .value_valid(matrix_buf_valid),
        .value_ready(matrix_buf_ready),
        
        .matrix_data(matrix_data),
        .matrix_valid(matrix_valid),
        .matrix_last(matrix_last)
    );

   nukv_Rotation_Module #(
        .MEMORY_WIDTH(MEMORY_WIDTH),
        .COL_COUNT(COL_COUNT),
   	    .COL_WIDTH(COL_WIDTH),
   	    .VALUE_SIZE_BYTES_NO(VALUE_SIZE_BYTES_NO)
    ) rotation_perturb (
        .clk(clk),
        .rst(rst),
        
        .matrix_data(matrix_data),
        .matrix_valid(matrix_valid),
        
        .input_data(imed_data[1]),
        .input_valid(imed_valid[1]),
        .input_ready(imed_ready[1]),
        .input_last(imed_last[1]),
        
        .output_data(omed_data[1]),
        .output_valid(omed_valid[1]),
        .output_ready(omed_ready[1]),
        .output_last(omed_last[1])
    );


    nukv_fifogen #(
    .DATA_SIZE(8),
    .ADDR_BITS(5)
    ) fifo_output_choice (
        .clk(clk),
        .rst(rst),
        
        .s_axis_tdata(ic_data),
        .s_axis_tvalid(ic_valid_masked),
        .s_axis_tready(ic_ready_fifo),
        .s_axis_talmostfull(),
        
        .m_axis_tdata(oc_data),
        .m_axis_tvalid(oc_valid),
        .m_axis_tready(oc_ready)
    );

    assign oc_ready = oc_valid & omed_valid[oc_data] & omed_last[oc_data] & output_ready;

    assign output_data = oc_valid==1 ? omed_data[oc_data] : 0;
    assign output_last = oc_valid==1 ? omed_last[oc_data] : 0;
    assign output_valid = oc_valid==1 ? omed_valid[oc_data] : 0;
    assign omed_ready[0] = oc_valid==1 && oc_data==0 ? output_ready : 0;
    assign omed_ready[1] = oc_valid==1 && oc_data==1 ? output_ready : 0;

endmodule
