module nukv_Rotation_Matrix_Buf
#(
    parameter MEMORY_WIDTH = 512,
    parameter COL_COUNT = 3,
    parameter COL_WIDTH = 64,
	parameter VALUE_SIZE_BYTES_NO = 2
)
(
    input wire clk,
    input wire rst,
    
    input wire [MEMORY_WIDTH-1:0] value_data,
	input wire value_valid,
	output reg value_ready,

    output wire [COL_COUNT*COL_COUNT*COL_WIDTH-1:0] matrix_data,
    output reg matrix_valid,
    output reg matrix_last
);

localparam MATRIX_BUF_SIZE = COL_COUNT*COL_COUNT*COL_WIDTH + MEMORY_WIDTH;

reg [MATRIX_BUF_SIZE-1:0] matrix_buf;
reg [$clog2(MATRIX_BUF_SIZE):0] matrix_buf_addr;

assign matrix_data = matrix_buf[COL_COUNT*COL_COUNT*COL_WIDTH-1:0];

always @(posedge clk) begin
	if (rst == 1) begin
	   matrix_buf <= 0;
	   matrix_last <= 0;
	   matrix_valid <= 1;
	   value_ready <= 1;
	   matrix_buf_addr <= 0;
	end else begin
	   if (value_valid == 1 && value_ready == 1) begin
	       if (matrix_buf_addr == 0) begin
	           matrix_buf[matrix_buf_addr +: MEMORY_WIDTH-8*VALUE_SIZE_BYTES_NO] <= value_data[8*VALUE_SIZE_BYTES_NO +: MEMORY_WIDTH-8*VALUE_SIZE_BYTES_NO];
	           if (matrix_buf_addr + MEMORY_WIDTH-8*VALUE_SIZE_BYTES_NO >= COL_COUNT*COL_COUNT*COL_WIDTH) begin
	               matrix_valid <= 1;
	               matrix_last <= 1;
	               matrix_buf_addr <= 0;
	           end else begin
	               matrix_valid <= 0;
	               matrix_buf_addr <= matrix_buf_addr + MEMORY_WIDTH-8*VALUE_SIZE_BYTES_NO;
	           end
	       end else begin
	           matrix_buf[matrix_buf_addr +: MEMORY_WIDTH] <= value_data;
	           if (matrix_buf_addr + MEMORY_WIDTH >= COL_COUNT*COL_COUNT*COL_WIDTH) begin
	               matrix_valid <= 1;
	               matrix_last <= 1;
	               matrix_buf_addr <= 0;
	           end else begin
	               matrix_valid <= 0;
	               matrix_buf_addr <= matrix_buf_addr + MEMORY_WIDTH;
	           end
	       end
	   end
	   
	   if (matrix_last == 1) begin
           matrix_last <= 0;
       end
	end
end

//localparam ROTATION_MATRIX_1 = {
//    64'h3FD3333333333333, //0.3
//    64'h3FD3333333333333, //0.3
//    64'h3FD3333333333333, //0.3
//    64'h3FC999999999999A, //0.2
//    64'h3FC999999999999A, //0.2
//    64'h3FC999999999999A, //0.2
//    64'h3FB999999999999A, //0.1
//    64'h3FB999999999999A, //0.1
//    64'h3FB999999999999A  //0.1
//};

//localparam ROTATION_MATRIX_2 = {
//    64'h4008000000000000, //3.0
//    64'h4000000000000000, //2.0
//    64'h3FF0000000000000, //1.0
//    64'h4008000000000000, //3.0
//    64'h4000000000000000, //2.0
//    64'h3FF0000000000000, //1.0
//    64'h4008000000000000, //3.0
//    64'h4000000000000000, //2.0
//    64'h3FF0000000000000  //1.0
//};

//assign matrix_valid = 1;
//assign matrix_data = ROTATION_MATRIX_1;

endmodule
