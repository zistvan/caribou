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


module muu_Dedup_Hashers
(
	input clk,
	input rst,	

	input [511:0] input_data,
	input 		  input_valid,
	input 		  input_last,
	output		  input_ready,
	
	output [63:0] hash_data,
	output 		  hash_valid,
	input		  hash_ready
);

parameter HASH_COUNT_BITS = 4;
parameter MAX_HASH_ENGINES = 16;

wire [512:0] hash_input_data [MAX_HASH_ENGINES-1:0];
reg [512:0] hash_input_prebuf [MAX_HASH_ENGINES-1:0];
wire [MAX_HASH_ENGINES-1:0] hash_input_hasdata;
wire [MAX_HASH_ENGINES-1:0] hash_input_almfull;
wire [MAX_HASH_ENGINES-1:0] hash_input_notfull;
wire [MAX_HASH_ENGINES-1:0] hash_input_ready;
reg [MAX_HASH_ENGINES-1:0] hash_input_enable;	 
reg [MAX_HASH_ENGINES-1:0] hash_input_type;	

reg softReset; 
reg softResetInt; 

wire [MAX_HASH_ENGINES-1:0] hash_output_valid;
wire [511:0] hash_output_data [MAX_HASH_ENGINES-1:0];

wire [MAX_HASH_ENGINES-1:0] outfifo_valid;
wire [MAX_HASH_ENGINES-1:0] outfifo_ready;
wire [63:0]  outfifo_data [MAX_HASH_ENGINES-1:0];

reg [HASH_COUNT_BITS-1:0] outfifo_pos;

reg [HASH_COUNT_BITS-1:0] current_hash_engine;
reg [HASH_COUNT_BITS-1:0] output_hash_engine;

reg hash_inputbuffer_ok;
reg hash_inputbuffer_pre;

assign input_ready = (hash_inputbuffer_ok); 

reg rstBuf;

integer x;

always @(posedge clk) begin
	rstBuf <= rst;	

	if (rst) begin
		current_hash_engine <= 0;		
		hash_input_enable <= 0;		
		output_hash_engine <= 0;
		hash_inputbuffer_ok <= 0;
		hash_inputbuffer_pre <= 0;
	end
	else begin
	   
	    
	   
		hash_input_enable <= 0;			

		hash_inputbuffer_pre <= (hash_input_notfull == {MAX_HASH_ENGINES{1'b1}} ? 1 : 0) && (hash_input_almfull == 0 ? 1 : 0);
		hash_inputbuffer_ok <= hash_inputbuffer_pre;

		
		if (input_ready==1 && input_valid==1) begin

			hash_input_prebuf[current_hash_engine] <= {input_last,input_data};
			hash_input_enable[current_hash_engine] <= 1;
			hash_input_type[current_hash_engine] <= 0;
			if (input_last==1) begin
				if (current_hash_engine==MAX_HASH_ENGINES-1) begin
					current_hash_engine <= 0;
				end else begin
					current_hash_engine <= current_hash_engine +1;
				end
			end
		end

		if (hash_valid==1 && hash_ready==1) begin
			if (output_hash_engine==MAX_HASH_ENGINES-1) begin
				output_hash_engine <= 0;
			end else begin
				output_hash_engine <= output_hash_engine+1;
			end
		end

	end
end

assign hash_valid = outfifo_valid[output_hash_engine];
assign hash_data = outfifo_data[output_hash_engine];


genvar X;
generate  
    for (X=0; X < MAX_HASH_ENGINES; X=X+1)  
	begin: generateloop		
			    
			nukv_fifogen #(
			    .DATA_SIZE(513),
			    .ADDR_BITS(6)
			) 			
			fifo_values (
			    .clk(clk),
    			.rst(rst),
			    
			    .s_axis_tdata(hash_input_prebuf[X]),
			    .s_axis_tvalid(hash_input_enable[X]),
			    .s_axis_tready(hash_input_notfull[X]),
			    .s_axis_talmostfull(hash_input_almfull[X]),
			    
			    .m_axis_tdata(hash_input_data[X][512:0]),
			    .m_axis_tvalid(hash_input_hasdata[X]),
			    .m_axis_tready(hash_input_ready[X])
			);

			sha256_stream sha_inst
			(
			    .clk(clk),
			    .rst(rst),
			    .mode(1),
			    .s_tdata_i(hash_input_data[X][511:0]),
			    .s_tlast_i(hash_input_data[X][512]),
			    .s_tvalid_i(hash_input_hasdata[X]),
			    .s_tready_o(hash_input_ready[X]),
			    .digest_o(hash_output_data[X]),
			    .digest_valid_o(hash_output_valid[X])
			);
		


			nukv_fifogen #(
			    .DATA_SIZE(64),
			    .ADDR_BITS(4)
			) 			
			fifo_values2 (
			    .clk(clk),
    			.rst(rst),
				    
				    .s_axis_tdata(hash_output_data[X]),
				    .s_axis_tvalid(hash_output_valid[X]),
				    .s_axis_tready(),
				    
				    .m_axis_tdata(outfifo_data[X]),
				    .m_axis_tvalid(outfifo_valid[X]),
				    .m_axis_tready(outfifo_ready[X])

				);


	 	assign outfifo_ready[X] = output_hash_engine==X ? hash_ready : 0;
	end  
	endgenerate  


endmodule