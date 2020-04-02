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


module nukv_Privacy_Pipeline #(
	parameter MEMORY_WIDTH = 512	
	)
    (
	// Clock
	input wire         clk,
	input wire         rst,

	input wire pred_data,
	input wire pred_valid,
	output wire pred_ready,

	input  wire [MEMORY_WIDTH-1:0] value_data,
	input  wire         value_valid,
	output wire         value_ready,

	output wire [MEMORY_WIDTH-1:0] output_data,
	output wire         output_valid,
	output wire			output_last,
	input  wire         output_ready

);

    wire[MEMORY_WIDTH-1:0] seg_data;
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

    wire[MEMORY_WIDTH-1:0] imed_data [1:0];
    wire[1:0] imed_valid;
    wire[1:0] imed_last;
    wire[1:0] imed_ready;

    wire[MEMORY_WIDTH-1:0] omed_data [1:0];
    wire[1:0] omed_valid;
    wire[1:0] omed_last;
    wire[1:0] omed_ready;


    assign pred_ready = 1;

    nukv_fifogen #(
    .DATA_SIZE(8),
    .ADDR_BITS(5) 
    ) fifo_input_choice (
        .clk(clk),
        .rst(rst),
        
        .s_axis_tdata(pred_data),
        .s_axis_tvalid(pred_valid),
        .s_axis_tready(pred_rady),
        .s_axis_talmostfull(),
        
        .m_axis_tdata(ic_data),
        .m_axis_tvalid(ic_valid),
        .m_axis_tready(ic_ready)
    );

    assign ic_ready = ic_ready_fifo & seg_valid & seg_last & seg_ready;
    assign ic_valid_masked = ic_valid & ic_ready;

    nukv_Value_Segmenter segmenter (
        .clk(clk),
        .rst(rst),
        .value_data(value_data),
        .value_valid(value_valid),
        .value_ready(value_ready),

        .output_data(seg_data),
        .output_last(seg_last),
        .output_valid(seg_valid),
        .output_ready(seg_ready)
    );

    assign imed_data[0] = seg_data;
    assign imed_last[0] = seg_last;    
    assign imed_data[1] = seg_data;
    assign imed_last[1] = seg_last;
    assign seg_ready = ic_valid==1 ? imed_ready[ic_data] : 0;
    assign imed_valid[0] = ic_valid==1 && ic_data==0 ? seg_valid : 0;
    assign imed_valid[1] = ic_valid==1 && ic_data==1 ? seg_valid : 0;


    nukv_fifogen #(
    .DATA_SIZE(513),
    .ADDR_BITS(8) 
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

   nukv_Rotation_Module rotation_perturb (
        .clk(clk),
        .rst(rst),
        
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