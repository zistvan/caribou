module nukv_Rotation_Module 
    (
	input wire         clk,
	input wire         rst,

	input  wire [511:0] input_data,
	input  wire         input_valid,
	input  wire			input_last,
	output wire          input_ready,

	output wire [511:0] output_data,
	output wire         output_valid,
	output wire			output_last,
	input  wire         output_ready
);


    reg[2:0] state;

    wire[511:0] ctr_data;
    wire ctr_valid;
    wire ctr_ready;
    wire ctr_last;

    reg[511:0] alt_data;
    reg alt_valid;
    reg alt_last;

   	ColToRow #(
    	.EQUAL_LENGTH_COMP(1)
    ) rotation_perturb (
        .clk(clk),
        .rst(rst),
        
        .input_data(input_data),
        .input_valid(input_valid),
        .input_ready(input_ready),
        .input_last(input_last),
        
        .output_data(ctr_data),
        .output_valid(ctr_valid),
        .output_ready(ctr_ready),
        .output_last(ctr_last)
    );

    assign output_valid = state==0 ? ctr_valid : alt_valid;
    assign output_data = state==0 ? ctr_data : alt_data;
    assign output_last = state==0 ? ctr_last : alt_last;
    assign ctr_ready = state==0 ? output_ready : 0;

    always @(posedge clk) begin 
    	if(rst) begin
    		 alt_data <= {504'b0, 8'h08};
    		 alt_last <= 1;
    		 alt_valid <= 1;

    		 state <= 0;
    	end else begin

    		case (state)
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
    			default : /* default */;
    		endcase
    	end
    end


endmodule;