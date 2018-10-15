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


module nukv_fifogen #(
    parameter ADDR_BITS=5,      // number of bits of address bus
    parameter DATA_SIZE=16     // number of bits of data bus
) 
(
  // Clock
  input wire         clk,
  input wire         rst,

  input  wire [DATA_SIZE-1:0] s_axis_tdata,
  input  wire         s_axis_tvalid,
  output wire         s_axis_tready,
  output wire         s_axis_talmostfull,


  output wire [DATA_SIZE-1:0] m_axis_tdata,
  output wire        m_axis_tvalid,
  input  wire         m_axis_tready
);

wire[(DATA_SIZE+72):0] in_data;
assign in_data[DATA_SIZE-1:0] = {72'b0, s_axis_tdata[DATA_SIZE-1:0]};

reg [1:0] waiter = 0;
wire rd_ok;
assign rd_ok = waiter == 2 ? 1 : 0;

always @(posedge clk) begin 
  if(rst) begin
     waiter <= 0;
  end else begin
    if (waiter<2) begin
      waiter <= waiter+1;
    end
  end
end

genvar x;
generate 
  if (ADDR_BITS<=9) begin

    wire[(DATA_SIZE+71)/72-1:0] in_full;
    wire[(DATA_SIZE+71)/72-1:0] in_almost_full;

    wire[(DATA_SIZE+71)/72-1:0] out_empty;
    wire[(DATA_SIZE+71)/72-1:0] out_almost_empty;
    wire[(DATA_SIZE+71):0] out_data;
    assign m_axis_tdata[DATA_SIZE-1:0] = out_data[DATA_SIZE-1:0];

    assign s_axis_tready = ~rst & (in_almost_full!=0 ? 0 :1);
    assign s_axis_talmostfull = in_almost_full==0 ? 0 :1;

    assign m_axis_tvalid = out_empty==0 ? 1 : 0;


    for (x=0; x<(DATA_SIZE+71)/72; x=x+1) begin
         FIFO_DUALCLOCK_MACRO  #(
          .ALMOST_EMPTY_OFFSET(13'h0080),    // Sets the almost empty threshold
          .ALMOST_FULL_OFFSET(13'h0 + (2**ADDR_BITS-7)),     // Sets almost full threshold
          .DATA_WIDTH(72),                    // Sets data width to 4-72
          .DEVICE("7SERIES"),  // Target device: "7SERIES" 
          .FIFO_SIZE ("36Kb"), // Target BRAM: "18Kb" or "36Kb" 
          .FIRST_WORD_FALL_THROUGH ("TRUE") // Sets the FIFO FWFT to "TRUE" or "FALSE" 
       ) FIFO_DUALCLOCK_MACRO_inst (
          .ALMOSTEMPTY(out_almost_empty[x]),     // 1-bit output: Almost empty flag
          .ALMOSTFULL(in_almost_full[x]),       // 1-bit output: Almost full flag
          .DO(out_data[x*72 +: 72]),                   // Output data, width defined by DATA_WIDTH parameter
          .EMPTY(out_empty[x]),                 // 1-bit output: Empty flag
          .FULL(in_full[x]),                   // 1-bit output: Full flag
          .RDCOUNT(),         // Output read count, width determined by FIFO depth
          .RDERR(),             // 1-bit output read error
          .WRCOUNT(),         // Output write count, width determined by FIFO depth
          .WRERR(),             // 1-bit output write error
          .DI(in_data[x*72 +: 72]),                   // Input data, width defined by DATA_WIDTH parameter
          .RDCLK(clk),             // 1-bit input read clock
          .RDEN(m_axis_tready & rd_ok),               // 1-bit input read enable
          .RST(rst),                 // 1-bit input reset
          .WRCLK(clk),             // 1-bit input write clock
          .WREN(s_axis_tvalid & rd_ok & ~in_almost_full[x])                // 1-bit input write enable
       );
        
         
    end


 end else if (ADDR_BITS<=10) begin


    wire[(DATA_SIZE+35)/36-1:0] in_full;
    wire[(DATA_SIZE+35)/36-1:0] in_almost_full;

    wire[(DATA_SIZE+35)/36-1:0] out_empty;
    wire[(DATA_SIZE+35)/36-1:0] out_almost_empty;
    wire[(DATA_SIZE+35):0] out_data;
    assign m_axis_tdata[DATA_SIZE-1:0] = out_data[DATA_SIZE-1:0];

    assign s_axis_tready = ~rst & (in_almost_full!=0 ? 0 : 1);
    assign s_axis_talmostfull = in_almost_full==0 ? 0 :1;

    assign m_axis_tvalid = out_empty==0 ? 1 : 0;

    for (x=0; x<(DATA_SIZE+35)/36; x=x+1) begin
    
        FIFO_DUALCLOCK_MACRO  #(
              .ALMOST_EMPTY_OFFSET(13'h0080),    // Sets the almost empty threshold
              .ALMOST_FULL_OFFSET(13'h0 + (2**ADDR_BITS-7)),     // Sets almost full threshold
              .DATA_WIDTH(36),                    // Sets data width to 4-72
              .DEVICE("7SERIES"),  // Target device: "7SERIES" 
              .FIFO_SIZE ("36Kb"), // Target BRAM: "18Kb" or "36Kb" 
              .FIRST_WORD_FALL_THROUGH ("TRUE") // Sets the FIFO FWFT to "TRUE" or "FALSE" 
           ) FIFO_DUALCLOCK_MACRO_inst (
              .ALMOSTEMPTY(out_almost_empty[x]),     // 1-bit output: Almost empty flag
              .ALMOSTFULL(in_almost_full[x]),       // 1-bit output: Almost full flag
              .DO(out_data[x*36 +: 36]),                   // Output data, width defined by DATA_WIDTH parameter
              .EMPTY(out_empty[x]),                 // 1-bit output: Empty flag
              .FULL(in_full[x]),                   // 1-bit output: Full flag
              .RDCOUNT(),         // Output read count, width determined by FIFO depth
              .RDERR(),             // 1-bit output read error
              .WRCOUNT(),         // Output write count, width determined by FIFO depth
              .WRERR(),             // 1-bit output write error
              .DI(in_data[x*36 +: 36]),                   // Input data, width defined by DATA_WIDTH parameter
              .RDCLK(clk),             // 1-bit input read clock
              .RDEN(m_axis_tready & rd_ok),               // 1-bit input read enable
              .RST(rst),                 // 1-bit input reset
              .WRCLK(clk),             // 1-bit input write clock
              .WREN(s_axis_tvalid & rd_ok & ~in_almost_full[x])                // 1-bit input write enable
           );

        
    end


 end else if (ADDR_BITS<=11) begin


    wire[(DATA_SIZE+17)/18-1:0] in_full;
    wire[(DATA_SIZE+17)/18-1:0] in_almost_full;

    wire[(DATA_SIZE+17)/18-1:0] out_empty;
    wire[(DATA_SIZE+17)/18-1:0] out_almost_empty;
    wire[(DATA_SIZE+17):0] out_data;
    assign m_axis_tdata[DATA_SIZE-1:0] = out_data[DATA_SIZE-1:0];

    assign s_axis_tready = ~rst & (in_almost_full!=0 ? 0 : 1);
    assign s_axis_talmostfull = in_almost_full==0 ? 0 :1;

    assign m_axis_tvalid = out_empty==0 ? 1 : 0;

    for (x=0; x<(DATA_SIZE+17)/18; x=x+1) begin

        FIFO_DUALCLOCK_MACRO  #(
              .ALMOST_EMPTY_OFFSET(13'h0080),    // Sets the almost empty threshold
              .ALMOST_FULL_OFFSET(13'h0 + (2**ADDR_BITS-7)),     // Sets almost full threshold
              .DATA_WIDTH(18),                    // Sets data width to 4-72
              .DEVICE("7SERIES"),  // Target device: "7SERIES" 
              .FIFO_SIZE ("36Kb"), // Target BRAM: "18Kb" or "36Kb" 
              .FIRST_WORD_FALL_THROUGH ("TRUE") // Sets the FIFO FWFT to "TRUE" or "FALSE" 
           ) FIFO_DUALCLOCK_MACRO_inst (
              .ALMOSTEMPTY(out_almost_empty[x]),     // 1-bit output: Almost empty flag
              .ALMOSTFULL(in_almost_full[x]),       // 1-bit output: Almost full flag
              .DO(out_data[x*18 +: 18]),                   // Output data, width defined by DATA_WIDTH parameter
              .EMPTY(out_empty[x]),                 // 1-bit output: Empty flag
              .FULL(in_full[x]),                   // 1-bit output: Full flag
              .RDCOUNT(),         // Output read count, width determined by FIFO depth
              .RDERR(),             // 1-bit output read error
              .WRCOUNT(),         // Output write count, width determined by FIFO depth
              .WRERR(),             // 1-bit output write error
              .DI(in_data[x*18 +: 18]),                   // Input data, width defined by DATA_WIDTH parameter
              .RDCLK(clk),             // 1-bit input read clock
              .RDEN(m_axis_tready & rd_ok),               // 1-bit input read enable
              .RST(rst),                 // 1-bit input reset
              .WRCLK(clk),             // 1-bit input write clock
              .WREN(s_axis_tvalid & rd_ok & ~in_almost_full[x])                // 1-bit input write enable
           );
    end



 end
endgenerate

endmodule


