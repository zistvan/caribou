module ColToRow #(
	parameter COL_BITS = 2,
	parameter COL_COUNT = 3,
	parameter CNT_SKIP_WORDS = 0,
	parameter EQUAL_LENGTH_COMP = 1
	)
    (
	input wire         clk,
	input wire         rst,

	input  wire [511:0] input_data,
	input  wire         input_valid,
	input  wire			input_last,
	output wire          input_ready,

	output wire [COL_COUNT*32-1:0] output_data,
	output wire         output_valid,
	output wire			output_last,
	input  wire         output_ready
);





reg [512:0] buffer_input_data [COL_COUNT-1:0];
wire [COL_COUNT-1:0] buffer_input_hasdata;
wire [COL_COUNT-1:0] buffer_input_almfull;
wire [COL_COUNT-1:0] buffer_input_notfull;
reg [COL_COUNT-1:0] buffer_input_enable;	 

wire [512:0] buffer_output_data [COL_COUNT-1:0];
wire [COL_COUNT-1:0] buffer_output_valid;
wire  buffer_output_ready;

reg[3:0] assembled_pos;
wire [32*COL_COUNT-1:0] assembled_data;
wire assembled_last;
wire[COL_COUNT-1:0] assembled_last_pre;
wire assembled_valid;
wire assembled_ready;

reg [COL_BITS-1:0] current_buffer_engine;

reg buffer_inputbuffer_ok;
reg buffer_inputbuffer_pre;

assign input_ready = (buffer_inputbuffer_ok); 

reg rstBuf;

integer x;
reg first_word;

always @(posedge clk) begin
	rstBuf <= rst;	

	if (rst) begin
		current_buffer_engine <= 0;
		buffer_input_enable <= 0;		
		buffer_inputbuffer_ok <= 0;
		buffer_inputbuffer_pre <= 0;
		assembled_pos <= CNT_SKIP_WORDS;
		first_word <= 1;
	end
	else begin
		buffer_input_enable <= 0;			

		buffer_inputbuffer_pre <= (buffer_input_notfull == {COL_COUNT{1'b1}} ? 1 : 0) && (buffer_input_almfull == 0 ? 1 : 0);
		buffer_inputbuffer_ok <= buffer_inputbuffer_pre;
	

		if (input_ready==1 && input_valid==1) begin
			buffer_input_data[current_buffer_engine] <= {input_last, input_data};
			buffer_input_enable[current_buffer_engine] <= 1;
			if (input_last==1) begin
				if (current_buffer_engine==COL_COUNT-1) begin
					current_buffer_engine <= 0;
				end else begin
					current_buffer_engine <= current_buffer_engine +1;
				end
			end
		end


		if (assembled_valid==1 && assembled_ready==1) begin
			assembled_pos <= assembled_pos+1;
			first_word <= 0;

			if (assembled_last==1) begin
				assembled_pos <= CNT_SKIP_WORDS;
				first_word <= 1;
			end
		end

	end
end

wire [31:0] sum;



genvar X;
generate  

	if (EQUAL_LENGTH_COMP==1) begin
		assign sum=buffer_output_data[0][31:0]+buffer_output_data[1][31:0]+buffer_output_data[2][31:0];
	end

    for (X=0; X < COL_COUNT; X=X+1)  
	begin: generateloop		
			    
			nukv_fifogen #(
			    .DATA_SIZE(513),
			    .ADDR_BITS(9)
			)
			fifo_values (
			    .clk(clk),
			    .rst(rstBuf),
			    
			    .s_axis_tdata(buffer_input_data[X]),
			    .s_axis_tvalid(buffer_input_enable[X]),
			    .s_axis_tready(buffer_input_notfull[X]),
			    .s_axis_talmostfull(buffer_input_almfull[X]),
			    
			    .m_axis_tdata(buffer_output_data[X][512:0]),
			    .m_axis_tvalid(buffer_output_valid[X]),
			    .m_axis_tready(buffer_output_ready)
			);

			assign assembled_data[X*32 +: 32] = (assembled_pos==0 && first_word==1 && EQUAL_LENGTH_COMP==1) ? sum : buffer_output_data[X][assembled_pos*32 +: 32];			
			assign assembled_last_pre[X] = buffer_output_data[X][512];
	end  
endgenerate  

assign assembled_valid = (buffer_output_valid == {COL_COUNT{1'b1}}) ? 1 : 0;
assign buffer_output_ready = (assembled_pos==15) ? assembled_ready : 0;
assign assembled_last = (assembled_pos==15 && assembled_last_pre=={COL_COUNT{1'b1}}) ? 1 : 0; 


nukv_fifogen #(
			    .DATA_SIZE(COL_COUNT*32+1),
			    .ADDR_BITS(4)
			) fifo_output (
				 .clk(clk),
			    .rst(rstBuf),
			    
			    .s_axis_tdata({assembled_last,assembled_data}),
			    .s_axis_tvalid(assembled_valid),
			    .s_axis_tready(assembled_ready),
			    .s_axis_talmostfull(),
			    
			    .m_axis_tdata({output_last,output_data}),
			    .m_axis_tvalid(output_valid),
			    .m_axis_tready(output_ready)
			);
			


endmodule