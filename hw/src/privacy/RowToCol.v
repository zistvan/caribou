module RowToCol #(
	parameter COL_BITS = 2,
	parameter COL_COUNT = 3
	)
    (
	input wire         clk,
	input wire         rst,

	input wire [COL_COUNT*32-1:0] input_data,
	input wire         input_valid,
	input wire			input_last,
	output  wire         input_ready,

	output  wire [511:0] output_data,
	output  wire         output_valid,
	output  wire			output_last,
	input wire          output_ready
);





reg [512:0] buffer_input_data [COL_COUNT-1:0];
wire [COL_COUNT-1:0] buffer_input_almfull;
wire [COL_COUNT-1:0] buffer_input_notfull;
reg [COL_COUNT-1:0] buffer_input_enable;	 
reg [7:0] buffer_input_words;

wire [512:0] buffer_output_data [COL_COUNT-1:0];
wire [COL_COUNT-1:0] buffer_output_valid;
wire [COL_COUNT-1:0] buffer_output_ready;
reg [COL_COUNT-1:0] buffer_output_sel;

wire input_valid_masked;

assign input_ready = (buffer_input_notfull=={COL_COUNT{1'b1}} && buffer_input_almfull=={COL_COUNT{1'b0}}) ? 1 : 0;
assign input_valid_masked = input_valid & input_ready;

integer x;
always @(posedge clk) begin 
	if(rst) begin
		for (x=0; x<COL_COUNT; x=x+1) begin
			buffer_input_data[x] <= 0;
			buffer_input_enable[x] <= 0;
		end
		buffer_input_words <= 0;		
	end else begin
		buffer_input_enable <= 0;

		if (input_valid_masked==1) begin

			for (x=0; x<COL_COUNT; x=x+1) begin
				buffer_input_data[x][buffer_input_words*32 +: 32] <= input_data[x*32 +: 32];
				buffer_input_data[x][512] <= input_last;
			end
			buffer_input_words <= buffer_input_words+1;

			if (buffer_input_words==15 || input_last==1) begin
				buffer_input_words <= 0;
				buffer_input_enable <= {COL_COUNT{1'b1}};
			end
			
		end
	end
end




genvar X;
generate  

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
			    .m_axis_tready(buffer_output_ready[X])
			);

			assign buffer_output_ready[X] = buffer_output_sel==X ? output_ready : 0;
	end  
endgenerate  

assign output_data = buffer_output_data[buffer_output_sel][511:0];
assign output_last = buffer_output_data[buffer_output_sel][512:0];
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