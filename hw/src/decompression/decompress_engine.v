`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/16/2019 03:40:57 PM
// Design Name: 
// Module Name: decompress_engine
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

`define LITERAL_TAG 2'b00
`define MATCH_1_TAG 2'b01
`define MATCH_2_TAG 2'b10

module decompress_engine
#(
    parameter DECOMPRESS_MODE_SIZE = 8,
    parameter WORD_SIZE = 512,
    parameter VALUE_SIZE_BYTES_NO = 2
)
(
    input wire clk,
    input wire rst,

    input wire [WORD_SIZE-1:0] in_data,
    input wire in_valid,
    output reg in_ready,
    
    input wire [DECOMPRESS_MODE_SIZE-1:0] mode_data,
    input wire mode_valid,
    output reg mode_ready,

    output reg [WORD_SIZE-1:0] out_data,
    output reg out_valid,
    output reg out_last,
    input wire out_ready
);

// decompression modes
localparam [DECOMPRESS_MODE_SIZE-1:0]
    NO_DECOMPRESS = 0,
    SNAPPY_DECOMPRESS = 1;

reg [DECOMPRESS_MODE_SIZE-1:0] cur_mode;

reg [8*VALUE_SIZE_BYTES_NO-1:0] value_bytes_counter;

// snappy states
localparam [3:0]
    WAIT_WORD = 4'b0000,
    GET_UNCOMPRESSED_BLOCK_SIZE = 4'b0001,
    GET_BOUNDARY_BYTE = 4'b0011,
    GET_LITERAL_SIZE = 4'b0010,
    GET_LITERAL = 4'b0110,
    GET_MATCH_1_OFFSET = 4'b0111,
    GET_MATCH_2_OFFSET_1 = 4'b1011,
    OUTPUT_WORD = 4'b0100,
    COPY_BYTE = 4'b0101,
    GET_MATCH_2_OFFSET_2 = 4'b1001;

reg [3:0] prev_state;
reg [3:0] state;

reg [WORD_SIZE-1:0] cur_word;
reg [$clog2(WORD_SIZE)-1:0] cur_byte_addr;

reg [34:0] uncompressed_block_size;
reg [4:0] uncompressed_block_size_addr;

reg [31:0] size_reg;
reg [4:0] size_reg_addr;
reg [1:0] size_reg_bytes_no;
reg [15:0] offset_reg;

(* ram_style = "block" *)reg [7:0] window[0:65535];
reg [15:0] window_addr;
reg [15:0] window_read_addr;
reg [7:0] window_read_byte;

reg [$clog2(WORD_SIZE)-1:0] out_data_addr;

reg first_out_byte_flag = 1; // must be set every time I wait for a new BLOCK
reg read_delay_flag;

always @(posedge clk) begin
    window_read_byte <= window[window_read_addr];
end

always @(posedge clk) begin
    if (rst == 1) begin
        in_ready <= 0;
        out_valid <= 0;
        first_out_byte_flag <= 1;
        mode_ready <= 1;
        state <= WAIT_WORD;
    end else begin
        if (mode_ready == 1) begin
            if (mode_valid == 1) begin
                cur_mode <= mode_data;
                mode_ready <= 0;
                in_ready <= 1;
            end
        end else begin
            case (cur_mode)
                NO_DECOMPRESS: begin
                    // pass through the input data and generate the out_last signal
                    if (in_ready == 1 && in_valid == 1) begin
                        if (out_ready == 0) begin
                            in_ready <= 0;
                        end
                        out_data <= in_data;
                        out_valid <= 1;
                        if (first_out_byte_flag == 1) begin
                            if (in_data[0 +: 8*VALUE_SIZE_BYTES_NO] <= WORD_SIZE/8) begin
                                out_last <= 1;
                                in_ready <= 0;
                            end else begin
                                out_last <= 0;
                                first_out_byte_flag <= 0;
                                value_bytes_counter <= in_data[0 +: 8*VALUE_SIZE_BYTES_NO] - WORD_SIZE/8;
                            end
                        end else begin
                            if (value_bytes_counter <= WORD_SIZE/8) begin
                                out_last <= 1;
                                in_ready <= 0;
                                first_out_byte_flag <= 1;
                            end else begin
                                out_last <= 0;
                                first_out_byte_flag <= 0;
                                value_bytes_counter <= value_bytes_counter - WORD_SIZE/8;
                            end
                        end
                    end else begin
                        if (out_valid == 1 && out_ready == 1) begin
                            out_valid <= 0;
                            if (out_last == 1) begin
                                out_last <= 0;
                                mode_ready <= 1;
                            end else begin
                                in_ready <= 1;
                            end
                        end
                    end
                end
                SNAPPY_DECOMPRESS: begin
                    case (state)
                        WAIT_WORD: begin // assumes that in_ready was set in the previous clk cycle
                            out_valid <= 0;
                            if (first_out_byte_flag == 1) begin
                                in_ready <= 1;
                                out_data <= 0;
                                out_last <= 0;
                                
                                window_addr <= 0;
                                out_data_addr <= 0;
                                
                                if (in_valid == 1) begin
                                    in_ready <= 0;
                                    cur_word <= in_data;
                                    cur_byte_addr <= 8*VALUE_SIZE_BYTES_NO;
                                    
                                    uncompressed_block_size <= 0;
                                    uncompressed_block_size_addr <= 0;
                                    prev_state <= WAIT_WORD;
                                    state <= GET_UNCOMPRESSED_BLOCK_SIZE;
                                end
                            end else begin
                                if (in_valid == 1) begin
                                    in_ready <= 0;
                                    cur_word <= in_data;
                                    cur_byte_addr <= 0;
                                    
                                    state <= prev_state;
                                    prev_state <= WAIT_WORD;
                                end
                            end
                        end
                        GET_UNCOMPRESSED_BLOCK_SIZE: begin
                            out_valid <= 0;
                            in_ready <= 0;
                            
                            prev_state <= GET_UNCOMPRESSED_BLOCK_SIZE;
                            if (cur_word[cur_byte_addr+7] == 1) begin
                                uncompressed_block_size[uncompressed_block_size_addr +: 7] <= cur_word[cur_byte_addr +: 7];
                                uncompressed_block_size_addr <= uncompressed_block_size_addr + 7;
                                out_data[out_data_addr +: 7] <= cur_word[cur_byte_addr +: 7];
                                out_data_addr <= out_data_addr + 7;
                                cur_byte_addr <= cur_byte_addr + 8;
                            end else begin
                                uncompressed_block_size[uncompressed_block_size_addr +: 7] <= cur_word[cur_byte_addr +: 7];
                                out_data[out_data_addr +: 7] <= cur_word[cur_byte_addr +: 7];
                                out_data_addr <= 32;
                                cur_byte_addr <= cur_byte_addr + 8;
                                state <= GET_BOUNDARY_BYTE;
                            end
                        end
                        GET_BOUNDARY_BYTE: begin
                            out_valid <= 0;
                            
                            if (cur_byte_addr == 0 && prev_state != WAIT_WORD) begin
                                in_ready <= 1;
                                prev_state <= GET_BOUNDARY_BYTE;
                                state <= WAIT_WORD;
                            end else begin
                                in_ready <= 0;
                                prev_state <= GET_BOUNDARY_BYTE;
                                case (cur_word[cur_byte_addr +: 2])
                                    `LITERAL_TAG: begin
                                        if (cur_word[(cur_byte_addr+2) +: 6] < 60) begin
                                            size_reg <= cur_word[(cur_byte_addr+2) +: 6];
                                            state <= GET_LITERAL;
                                        end else if (cur_word[(cur_byte_addr+2) +: 6] == 60) begin
                                            size_reg <= 0;
                                            size_reg_addr <= 0;
                                            size_reg_bytes_no <= 0;
                                            state <= GET_LITERAL_SIZE;
                                        end else if (cur_word[(cur_byte_addr+2) +: 6] == 61) begin
                                            size_reg <= 0;
                                            size_reg_addr <= 0;
                                            size_reg_bytes_no <= 1;
                                            state <= GET_LITERAL_SIZE;
                                        end else if (cur_word[(cur_byte_addr+2) +: 6] == 62) begin
                                            size_reg <= 0;
                                            size_reg_addr <= 0;
                                            size_reg_bytes_no <= 2;
                                            state <= GET_LITERAL_SIZE;
                                        end else if (cur_word[(cur_byte_addr+2) +: 6] == 63) begin
                                            size_reg <= 0;
                                            size_reg_addr <= 0;
                                            size_reg_bytes_no <= 3;
                                            state <= GET_LITERAL_SIZE;
                                        end
                                    end
                                    `MATCH_1_TAG: begin
                                        size_reg <= cur_word[(cur_byte_addr+2) +: 3] + 3;
                                        offset_reg[15:8] <= cur_word[(cur_byte_addr+5) +: 3];
                                        state <= GET_MATCH_1_OFFSET;
                                    end
                                    `MATCH_2_TAG: begin
                                        size_reg <= cur_word[(cur_byte_addr+2) +: 6];
                                        state <= GET_MATCH_2_OFFSET_1;
                                    end
                                    default: begin in_ready <= 0; out_valid <= 0; first_out_byte_flag <= 1; mode_ready <= 1; state <= WAIT_WORD; end
                                endcase
                                cur_byte_addr <= cur_byte_addr + 8;
                            end
                        end
                        GET_LITERAL_SIZE: begin
                            out_valid <= 0;
                            
                            if (cur_byte_addr == 0 && prev_state != WAIT_WORD) begin
                                in_ready <= 1;
                                prev_state <= GET_LITERAL_SIZE;
                                state <= WAIT_WORD;
                            end else begin
                                in_ready <= 0;
                                prev_state <= GET_LITERAL_SIZE;
                                if (size_reg_bytes_no == 0) begin
                                    size_reg[size_reg_addr +: 8] <= cur_word[cur_byte_addr +: 8];
                                    cur_byte_addr <= cur_byte_addr + 8;
                                    state <= GET_LITERAL;
                                end else begin
                                    size_reg[size_reg_addr +: 8] <= cur_word[cur_byte_addr +: 8];
                                    cur_byte_addr <= cur_byte_addr + 8;
                                    size_reg_addr <= size_reg_addr + 8;
                                    size_reg_bytes_no <= size_reg_bytes_no - 1;
                                end
                            end
                        end
                        GET_LITERAL: begin
                            out_valid <= 0;
                            
                            if (cur_byte_addr == 0 && prev_state != WAIT_WORD && prev_state != OUTPUT_WORD) begin
                                in_ready <= 1;
                                prev_state <= GET_LITERAL;
                                state <= WAIT_WORD;
                            end else begin
                                in_ready <= 0;
                                if (out_data_addr == 0 && prev_state != OUTPUT_WORD && first_out_byte_flag == 0) begin
                                    out_valid <= 1;
                                    prev_state <= GET_LITERAL;
                                    state <= OUTPUT_WORD;
                                end else begin
                                    first_out_byte_flag <= 0;
                                    window[window_addr] <= cur_word[cur_byte_addr +: 8];
                                    out_data[out_data_addr +: 8] <= cur_word[cur_byte_addr +: 8];
                                    window_addr <= window_addr + 1;
                                    out_data_addr <= out_data_addr + 8;
                                    cur_byte_addr <= cur_byte_addr + 8;
                                    size_reg <= size_reg - 1;
                                    uncompressed_block_size <= uncompressed_block_size - 1;
                                    prev_state <= GET_LITERAL;
                                    if (size_reg == 0) begin
                                        if (uncompressed_block_size == 1) begin
                                            out_valid <= 1;
                                            out_last <= 1;
                                            state <= OUTPUT_WORD;
                                        end else begin
                                            state <= GET_BOUNDARY_BYTE;
                                        end
                                    end
                                end
                            end
                        end
                        OUTPUT_WORD: begin // assumes that out_valid was set in the previous clk cycle
                            in_ready <= 0;
                            
                            if (out_ready == 1) begin
                                out_valid <= 0;
                                out_data <= 0;
                                if (out_last == 0) begin
                                    state <= prev_state;
                                    prev_state <= OUTPUT_WORD;
                                end else begin
                                    prev_state <= OUTPUT_WORD;
                                    out_last <= 0;
                                    in_ready <= 0;
                                    first_out_byte_flag <= 1;
                                    mode_ready <= 1;
                                    state <= WAIT_WORD;
                                end
                            end
                        end
                        GET_MATCH_1_OFFSET: begin
                            out_valid <= 0;
                            
                            if (cur_byte_addr == 0 && prev_state != WAIT_WORD) begin
                                in_ready <= 1;
                                prev_state <= GET_MATCH_1_OFFSET;
                                state <= WAIT_WORD;
                            end else begin
                                in_ready <= 0;
                                offset_reg[7:0] <= cur_word[cur_byte_addr +: 8];
                                cur_byte_addr <= cur_byte_addr + 8;
                                window_read_addr <= window_addr - {offset_reg[10:8],cur_word[cur_byte_addr +: 8]};
                                read_delay_flag <= 1;
                                prev_state <= GET_MATCH_1_OFFSET;
                                state <= COPY_BYTE;
                            end
                        end
                        COPY_BYTE: begin
                            if (read_delay_flag == 1) begin
                                read_delay_flag <= 0;
                            end else begin
                                out_valid <= 0;
                                in_ready <= 0;
                                
                                if (out_data_addr == 0 && prev_state != OUTPUT_WORD) begin
                                    out_valid <= 1;
                                    prev_state <= COPY_BYTE;
                                    state <= OUTPUT_WORD;
                                end else begin
                                    window[window_addr] <= window_read_byte;
                                    out_data[out_data_addr +: 8] <= window_read_byte;
                                    window_addr <= window_addr + 1;
                                    window_read_addr <= window_read_addr + 1;
                                    read_delay_flag <= 1;
                                    out_data_addr <= out_data_addr + 8;
                                    size_reg <= size_reg - 1;
                                    uncompressed_block_size <= uncompressed_block_size - 1;
                                    prev_state <= COPY_BYTE;
                                    if (size_reg == 0) begin
                                        if (uncompressed_block_size == 1) begin
                                            out_valid <= 1;
                                            out_last <= 1;
                                            state <= OUTPUT_WORD;
                                        end else begin
                                            state <= GET_BOUNDARY_BYTE;
                                        end
                                    end
                                end
                            end
                        end
                        GET_MATCH_2_OFFSET_1: begin
                            out_valid <= 0;
                            
                            if (cur_byte_addr == 0 && prev_state != WAIT_WORD) begin
                                in_ready <= 1;
                                prev_state <= GET_MATCH_2_OFFSET_1;
                                state <= WAIT_WORD;
                            end else begin
                                in_ready <= 0;
                                offset_reg[7:0] <= cur_word[cur_byte_addr +: 8];
                                cur_byte_addr <= cur_byte_addr + 8;
                                prev_state <= GET_MATCH_2_OFFSET_1;
                                state <= GET_MATCH_2_OFFSET_2;
                            end
                        end
                        GET_MATCH_2_OFFSET_2: begin
                            out_valid <= 0;
                            
                            if (cur_byte_addr == 0 && prev_state != WAIT_WORD) begin
                                in_ready <= 1;
                                prev_state <= GET_MATCH_2_OFFSET_2;
                                state <= WAIT_WORD;
                            end else begin
                                in_ready <= 0;
                                offset_reg[15:8] <= cur_word[cur_byte_addr +: 8];
                                cur_byte_addr <= cur_byte_addr + 8;
                                window_read_addr <= window_addr - {cur_word[cur_byte_addr +: 8],offset_reg[7:0]};
                                read_delay_flag <= 1;
                                prev_state <= GET_MATCH_2_OFFSET_2;
                                state <= COPY_BYTE;
                            end
                        end
                        default: begin in_ready <= 0; out_valid <= 0; first_out_byte_flag <= 1; mode_ready <= 1; state <= WAIT_WORD; end
                    endcase
                end
            endcase
        end
    end
end

endmodule