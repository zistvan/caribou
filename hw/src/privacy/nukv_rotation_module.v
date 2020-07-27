module nukv_Rotation_Module
#(
    parameter MEMORY_WIDTH = 512,
    parameter COL_COUNT = 3,
    parameter COL_WIDTH = 64,
    parameter VALUE_SIZE_BYTES_NO = 2
)
(
	input wire         clk,
	input wire         rst,
	
	(* mark_debug = "true" *)input wire [COL_COUNT*COL_COUNT*COL_WIDTH-1:0] matrix_data,
    (* mark_debug = "true" *)input wire matrix_valid,

	(* mark_debug = "true" *)input  wire [MEMORY_WIDTH-1:0] input_data,
	(* mark_debug = "true" *)input  wire         input_valid,
	(* mark_debug = "true" *)input  wire			input_last,
	(* mark_debug = "true" *)output wire         input_ready,

	(* mark_debug = "true" *)output wire [MEMORY_WIDTH-1:0] output_data,
	(* mark_debug = "true" *)output wire         output_valid,
	(* mark_debug = "true" *)output wire			output_last,
	(* mark_debug = "true" *)input  wire         output_ready
);


    reg[2:0] state;
    
    (* mark_debug = "true" *)wire [8*VALUE_SIZE_BYTES_NO-1:0] ctr_value_size_data;
    (* mark_debug = "true" *)wire [COL_COUNT*COL_WIDTH-1:0] ctr_data;
    (* mark_debug = "true" *)wire ctr_valid;
    (* mark_debug = "true" *)wire ctr_ready;
    (* mark_debug = "true" *)wire ctr_last;
    
    (* mark_debug = "true" *)wire[COL_COUNT*COL_WIDTH-1:0] rot_data;
    (* mark_debug = "true" *)wire rot_valid;
    (* mark_debug = "true" *)wire rot_ready;
    (* mark_debug = "true" *)wire rot_last;

    (* mark_debug = "true" *)wire [8*VALUE_SIZE_BYTES_NO-1:0] rtc_value_size_data;
    (* mark_debug = "true" *)wire [MEMORY_WIDTH-1:0] rtc_data;
    (* mark_debug = "true" *)wire rtc_valid;
    (* mark_debug = "true" *)wire rtc_ready;
    (* mark_debug = "true" *)wire rtc_last;
    
    wire mult_valid;
    
    assign mult_valid = matrix_valid && ctr_valid;

   	ColToRow #(
   	    .MEMORY_WIDTH(MEMORY_WIDTH),
   	    .COL_COUNT(COL_COUNT),
   	    .COL_WIDTH(COL_WIDTH),
   	    .VALUE_SIZE_BYTES_NO(VALUE_SIZE_BYTES_NO)
   	) col_to_row (
        .clk(clk),
        .rst(rst),
        
        .input_data(input_data),
        .input_valid(input_valid),
        .input_ready(input_ready),
        .input_last(input_last),
        
        .value_size_data(ctr_value_size_data),
        .output_data(ctr_data),
        .output_valid(ctr_valid),
        .output_ready(ctr_ready),
        .output_last(ctr_last)
    );

    MatrixVectorMultiplicationGroup #(
        .VECTOR_SIZE(COL_COUNT),
        .ENTRY_SIZE(COL_WIDTH),
        .VALUE_SIZE_BYTES_NO(VALUE_SIZE_BYTES_NO)
    ) matrix_vector_multiplication_group (
        .clk(clk),
        .rst(rst),
        
        .matrix_data(matrix_data),
        .in_value_size_data(ctr_value_size_data),
        .vector_data(ctr_data),
        .in_valid(mult_valid),
        .in_last(ctr_last),
        .in_ready(ctr_ready),
        
        .out_value_size_data(rtc_value_size_data),
        .out_data(rot_data),
        .out_valid(rot_valid),
        .out_last(rot_last),
        .out_ready(rot_ready)
    );

    RowToCol #(
        .MEMORY_WIDTH(MEMORY_WIDTH),
        .COL_COUNT(COL_COUNT),
   	    .COL_WIDTH(COL_WIDTH),
   	    .VALUE_SIZE_BYTES_NO(VALUE_SIZE_BYTES_NO)
    ) row_to_col (
        .clk(clk),
        .rst(rst),
        
        .value_size_data(rtc_value_size_data),
        .input_data(rot_data),
        .input_valid(rot_valid),
        .input_ready(rot_ready),
        .input_last(rot_last),
        
        .output_data(rtc_data),
        .output_valid(rtc_valid),
        .output_ready(rtc_ready),
        .output_last(rtc_last)
    );


    reg [MEMORY_WIDTH-1:0] alt_data;
    reg alt_valid;
    reg alt_last;

    assign output_valid = state==0 ? rtc_valid : alt_valid;
    assign output_data = state==0 ? rtc_data : alt_data;
    assign output_last = state==0 ? rtc_last : alt_last;
    assign rtc_ready = state==0 ? output_ready : 0;

    always @(posedge clk) begin 
    	if(rst) begin
    		 alt_data <= {504'b0, 8'h08};
    		 alt_last <= 1;
    		 alt_valid <= 1;

    		 state <= 0;
    	end else begin

    		/*case (state)
    			0:  begin
    				if (ctr_valid==1 && output_ready==1 && ctr_last==1) begin
    					state <= state+1;
    				end
    			end
    			1: begin
    				if (alt_valid==1 && output_ready==1 && alt_last==1) begin
    					state <= state+1;
    				end
    			end    			
    			2: begin
    				if (alt_valid==1 && output_ready==1 && alt_last==1) begin
    					state <= 0;
    				end
    			end
    		endcase

            */
    	end
    end


endmodule
