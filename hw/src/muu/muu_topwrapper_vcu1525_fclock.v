//---------------------------------------------------------------------------
//--  Copyright 2015 - 2017 Systems Group, ETH Zurich
//--  Copyright 2018 - 2019 IMDEA Software Institute, Madrid
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


module muu_TopWrapper_fclk #(
      parameter IS_SIM = 0,
      parameter USER_BITS = 3
      )
      (

			  input 	    aclk,
			  input 	    aresetn,

        input       fclk, //faster clock, to drive the KVS


			  output 	    m_axis_open_connection_TVALID,
			  input 	    m_axis_open_connection_TREADY,
			  output [47:0]     m_axis_open_connection_TDATA,

			  input 	    s_axis_open_status_TVALID,
			  output 	    s_axis_open_status_TREADY,
			  input [23:0] 	    s_axis_open_status_TDATA,

			  output 	    m_axis_close_connection_TVALID,
			  input 	    m_axis_close_connection_TREADY,
			  output [15:0]     m_axis_close_connection_TDATA,

			  output 	    m_axis_listen_port_TVALID,
			  input 	    m_axis_listen_port_TREADY,
			  output [15:0]     m_axis_listen_port_TDATA,

			  input 	    s_axis_listen_port_status_TVALID,
			  output 	    s_axis_listen_port_status_TREADY,
			  input [7:0] 	    s_axis_listen_port_status_TDATA,

			  input 	    s_axis_notifications_TVALID,
			  output 	    s_axis_notifications_TREADY,
			  input [87:0] 	    s_axis_notifications_TDATA,

			  output 	    m_axis_read_package_TVALID,
			  input 	    m_axis_read_package_TREADY,
			  output [31:0]     m_axis_read_package_TDATA,

			  output 	    m_axis_tx_data_TVALID,
			  input 	    m_axis_tx_data_TREADY,
			  output [63:0]     m_axis_tx_data_TDATA,
			  output [7:0] 	    m_axis_tx_data_TKEEP,
			  output [0:0] 	    m_axis_tx_data_TLAST,

			  output  	    m_axis_tx_metadata_TVALID,
			  input 	    m_axis_tx_metadata_TREADY,
			  output  [31:0] m_axis_tx_metadata_TDATA,

			  input 	    s_axis_tx_status_TVALID,
			  output 	    s_axis_tx_status_TREADY,
			  input [63:0] 	    s_axis_tx_status_TDATA,

			  input 	    s_axis_rx_data_TVALID,
			  output 	    s_axis_rx_data_TREADY,
			  input [63:0] 	    s_axis_rx_data_TDATA,
			  input [7:0] 	    s_axis_rx_data_TKEEP,
			  input [0:0] 	    s_axis_rx_data_TLAST,

			  input 	    s_axis_rx_metadata_TVALID,
			  output 	    s_axis_rx_metadata_TREADY,
			  input [15:0] 	    s_axis_rx_metadata_TDATA,
			  
			  
			  
			  input [511:0] ht_dramRdData_data,
              input          ht_dramRdData_empty,
              input         ht_dramRdData_almost_empty,
              output          ht_dramRdData_read,
        
        
              output [63:0] ht_cmd_dramRdData_data,
              output        ht_cmd_dramRdData_valid,
              input        ht_cmd_dramRdData_stall,
        
        
              output [511:0] ht_dramWrData_data,
              output          ht_dramWrData_valid,
              input          ht_dramWrData_stall,
        
        
              output [63:0] ht_cmd_dramWrData_data,
              output        ht_cmd_dramWrData_valid,
              input        ht_cmd_dramWrData_stall,

			  input [511:0] upd_dramRdData_data,
              input          upd_dramRdData_empty,
              input         upd_dramRdData_almost_empty,
              output         upd_dramRdData_read,
        
        
              output [63:0] upd_cmd_dramRdData_data,
              output        upd_cmd_dramRdData_valid,
              input        upd_cmd_dramRdData_stall,
        
        
              output [511:0] upd_dramWrData_data,
              output          upd_dramWrData_valid,
              input          upd_dramWrData_stall,
        
        
              output [63:0] upd_cmd_dramWrData_data,
              output        upd_cmd_dramWrData_valid,
              input        upd_cmd_dramWrData_stall,


              output [63:0] ptr_rdcmd_data,
              output          ptr_rdcmd_valid,
              input           ptr_rdcmd_ready,

              input  [512-1:0]  ptr_rd_data,
              input          ptr_rd_valid,
              output           ptr_rd_ready, 

              output  [512-1:0] ptr_wr_data,
              output          ptr_wr_valid,
              input           ptr_wr_ready,

              output  [63:0] ptr_wrcmd_data,
              output          ptr_wrcmd_valid,
              input           ptr_wrcmd_ready,


              output  [63:0] bmap_rdcmd_data,
              output          bmap_rdcmd_valid,
              input           bmap_rdcmd_ready,

              input  [512-1:0]  bmap_rd_data,
              input          bmap_rd_valid,
              output           bmap_rd_ready, 

              output  [512-1:0] bmap_wr_data,
              output          bmap_wr_valid,
              input           bmap_wr_ready,

              output  [63:0] bmap_wrcmd_data,
              output          bmap_wrcmd_valid,
              input           bmap_wrcmd_ready         

			  );

   assign m_axis_close_connection_TVALID = 0;
   assign s_axis_listen_port_status_TREADY = 1;
   assign s_axis_rx_metadata_TREADY = 1;
   assign s_axis_tx_status_TREADY = 1;      
   


   reg 					    port_opened;
   reg 					    axis_listen_port_valid;
   reg [15:0] 				    axis_listen_port_data;
   reg 					    reset;
   wire [63:0] 				    meta_output;

   wire 				    s_axis_rx_data_TFULL;

   wire 				    packbufEmpty;
   wire 				    packbufValid;
   wire [511+1:0] 				    packbufData;
   wire 				    packbufRead;

   wire 				    sesspackValid;
   wire 				    sesspackReady;
   wire 				    sesspackLast;
   wire [511:0] 				    sesspackData;
   wire [63:0] 				    sesspackMeta;
   wire [USER_BITS-1:0]       sesspackUser;

   wire 				    cmdInReady;
   wire 				    cmdInValid;
   wire [127:0] 			    cmdInData;
   wire 				    cmdInBufReady;
   wire 				    cmdInBufValid;
   wire [127:0] 			    cmdInBufData;

   wire 				    cmdOutReady;
   wire 				    cmdOutValid;
   wire [127:0] 			    cmdOutData;

   wire 				    cmdOutBufdReady;
   wire 				    cmdOutBufdValid;
   wire [127:0] 			    cmdOutBufdData;

   wire 				    payloadValid;
   wire 				    payloadReady;
   wire 				    payloadLast;
   wire [511:0] 			    payloadData;
   
   wire 				    payloadValid_b;
   wire                     payloadReady_b;
   wire                     payloadLast_b;
   wire [511:0]                 payloadData_b;   

   wire 				    bypassValid;
   wire 				    bypassReady;
   wire 				    bypassLast;
   wire [63:0] 				    bypassData;
   wire [63:0] 				    bypassMeta;

   wire 				    bypassBufdValid;
   wire 				    bypassBufdReady;
   wire 				    bypassBufdLast;
   wire [127:0] 			    bypassBufdData;


   wire 				    toAppValid;
   wire 				    toAppReady;
   wire 				    toAppLast;
   wire [63:0] 				    toAppData;
   wire [63:0] 				    toAppMeta;

   wire 				    toNetValid;
   wire 				    toNetReady;
   wire 				    toNetLast;
   wire [63:0] 				    toNetData;
   wire [63:0] 				    toNetMeta;
   
   wire 				    toNetBufdValid;
   wire                     toNetBufdReady;
   wire                     toNetBufdLast;
   wire [127:0]                     toNetBufdData;
      

   wire 				    toPifValid;
   wire 				    toPifReady;
   wire 				    toPifLast;
   wire [63:0] 				    toPifData;
   wire [63:0] 				    toPifMeta;

   
   wire                     para_valid;
   wire                     para_ready;
   wire                     para_last;
   wire [63:0]              para_data;   


   wire 				    toKvsValid;
   wire 				    toKvsReady;
   wire 				    toKvsLast;
   wire [127:0] 			    toKvsData;
   wire [USER_BITS-1:0]       toKvsUserId;
   
   wire 				    fromKvsValid;
   wire                     fromKvsReady;
   wire                     fromKvsLast;
   wire [511+64:0]             fromKvsData;
   wire [USER_BITS-1:0]             fromKvsUser;

      wire            fromKvsValid_f;
   wire                     fromKvsReady_f;
   wire                     fromKvsLast_f;
   wire [511+64:0]             fromKvsData_f;
   wire [USER_BITS-1:0]             fromKvsUser_f;

   wire 				    finalOutValid;
   wire 				    finalOutReady;
   wire 				    finalOutLast;
   wire [512+64-1:0] 			    finalOutData;

   wire 				    log_addreq_valid;
   wire [31:0] 				    log_addreq_size;
   wire [31:0] 				    log_addreq_zxid;

   wire 				    log_addresp_valid;
   wire [31:0] 				    log_addresp_size;
   wire [31:0] 				    log_addresp_pos;

   wire 				    log_findreq_valid;
   wire 				    log_findreq_since;
   wire [31:0] 				    log_findreq_zxid;

   wire 				    log_findresp_valid;
   wire [31:0] 				    log_findresp_size;
   wire [31:0] 				    log_findresp_pos;

   wire 				    errorValid;
   wire [7:0] 				    errorOpcode;

   wire 				    mem_readcmd_valid;
   wire 				    mem_readcmd_stall;
   wire [63:0] 				    mem_readcmd_data;

   wire 				    mem_writecmd_valid;
   wire 				    mem_writecmd_stall;
   wire [63:0] 				    mem_writecmd_data;

   wire 				    mem_read_empty;
   wire 				    mem_read_read;
   wire [511:0] 			    mem_read_data;

   wire 				    mem_write_valid;
   wire 				    mem_write_stall;
   wire [511:0] 			    mem_write_data;


   wire 				    splitPreValid;
   wire 				    splitPreLast;
   wire 				    splitPreReady;
   wire [3+512+64:0] 			    splitPreDataMerged;

   wire 				    splitInValid;
   wire 				    splitInLast;
   wire 				    splitInReady;
   wire [511:0] 				    splitInData;
   wire [63:0] 				    splitInMeta;
   wire [512+64+USER_BITS:0] 			    splitInDataMerged;
   wire [USER_BITS-1:0]       splitInUser;


   wire [35:0] 				    control0, control1;
   wire [255:0] 			    data;
   reg [255:0] 				    debug_r;
   reg [255:0] 				    debug_r2;
   wire [63:0] 				    vio_cmd;
   reg [63:0] 				    vio_cmd_r;

   reg 					    dbg_capture;
   reg 					    dbg_capture_valid;
   reg [80:0] 				    dbg_capture_data;
   reg [15:0] 				    dbg_capture_count;
   reg [15:0] 				    dbg_capture_pos;
   reg [15:0] 				    dbg_replay_pos;
   reg [15:0] 				    dbg_replay_left;
   wire [80:0] 				    dbg_replay_data;  
   reg 					    dbg_replay;
   reg 					    dbg_replay_valid;
   reg 					    dbg_replay_prevalid;
   wire 				    dbg_replay_ready;
   reg 					    replay_mode;
				    

   reg          is_first_output_cycle;
   
   reg [31:0] myClock;


   assign m_axis_listen_port_TDATA = axis_listen_port_data;
   assign m_axis_listen_port_TVALID = axis_listen_port_valid;

   reg [15:0] min_port;
   reg [15:0] max_port;
   //open up server port (2888)
   always @(posedge aclk) 
     begin
	reset <= !aresetn;
	
	if (aresetn == 0) begin
           port_opened <= 1'b0;
           axis_listen_port_valid <= 1'b0;
           myClock <= 0;       
           
           min_port <= 16'h0B40; //first assigned port will be 2880, last one 2887
           max_port <= 16'h0B48;
	end
	else begin
           axis_listen_port_valid <= 1'b0;
           
           if (axis_listen_port_valid==0 && m_axis_listen_port_TREADY==1 && min_port<max_port) begin
              axis_listen_port_valid <= 1'b1;
              axis_listen_port_data <= min_port;
              min_port <= min_port+1; 
              port_opened <= 1;
           end
           
           
           myClock <= myClock+1;
	end
     end

  reg freset_0, freset;
  always @(posedge fclk) begin
    freset_0 <= reset;
    freset <= freset_0;
  end


      wire [511:0] s_axis_wide_data;
      assign s_axis_wide_data[63:0] = s_axis_rx_data_TDATA;


        nukv_fifogen #(
            .DATA_SIZE(513),
            .ADDR_BITS(8)
        ) input_firstword_fifo_inst (
                .clk(aclk),
                .rst(reset),
                .s_axis_tvalid(s_axis_rx_data_TVALID),
                .s_axis_tready(s_axis_rx_data_TREADY),
                .s_axis_tdata({s_axis_rx_data_TLAST[0], s_axis_wide_data}),  
                .m_axis_tvalid(packbufValid),
                .m_axis_tready(packbufRead),
                .m_axis_tdata(packbufData)
                ); 
						 
    assign para_valid = 0;
    assign para_last = 0;
    assign para_data = 0;


    
    wire[127:0] debug_sess;
   muu_session_Top512  #(
                        .USER_BITS(USER_BITS)
   ) muuSessionMngr (
					    .clk(aclk),
					    .rst(reset),
					    .rstn(aresetn),

					    .stop(1'b0),
      
					    .event_valid(s_axis_notifications_TVALID),
					    .event_ready(s_axis_notifications_TREADY),
					    .event_data(s_axis_notifications_TDATA),
      
					    .readreq_valid(m_axis_read_package_TVALID),
					    .readreq_ready(m_axis_read_package_TREADY),
					    .readreq_data(m_axis_read_package_TDATA),
      
					    .packet_valid(packbufValid),
					    .packet_ready(packbufRead),
					    .packet_data({packbufData[511:0]}),    
					    //.packet_keep(8'b11111111),
					    .packet_last(packbufData[512]),
      
					    .out_valid(sesspackValid),
					    .out_ready(sesspackReady),
					    .out_last(sesspackLast),
					    .out_data(sesspackData),
					    .out_meta(sesspackMeta),
              .out_userid(sesspackUser),             
      
					    .debug_out(debug_sess)
					    );

    assign splitPreValid = sesspackValid;
    assign sesspackReady = splitPreReady;
    assign splitPreDataMerged[USER_BITS+64+511:0] = {sesspackUser, sesspackMeta, sesspackData};
    assign splitPreDataMerged[512+64+USER_BITS] = sesspackLast;
       
   nukv_fifogen_async #(
            .DATA_SIZE(512+64+1+USER_BITS),
            .ADDR_BITS(6)
        ) fifo_splitprepare (
						    .s_axis_clk(aclk),
						    .s_axis_rst(reset),
                .m_axis_clk(fclk),
						    .s_axis_tvalid(splitPreValid),
						    .s_axis_tready(splitPreReady),
						    .s_axis_tdata(splitPreDataMerged),	
						    .m_axis_tvalid(splitInValid),
						    .m_axis_tready(splitInReady),
						    .m_axis_tdata(splitInDataMerged)
						    ); 
   

   assign splitInData = splitInDataMerged[511:0];
   assign splitInMeta = splitInDataMerged[511+64:512];
   assign splitInUser = splitInDataMerged[512+64 +: USER_BITS];
   assign splitInLast = splitInDataMerged[512+64+USER_BITS];
 
					  
  assign toPifReady = 1;					  

  
					  
		

   wire kvs_is_stuck;          
   
   
   
  
  wire [511:0] ht_dramRdData_data_f;
  wire          ht_dramRdData_valid_f;
  wire          ht_dramRdData_ready_f;

  wire [63:0] ht_cmd_dramRdData_data_f;
  wire          ht_cmd_dramRdData_valid_f;
  wire          ht_cmd_dramRdData_ready_f;

  wire [511:0] ht_dramWrData_data_f;
  wire          ht_dramWrData_valid_f;
  wire          ht_dramWrData_ready_f;

  wire [63:0] ht_cmd_dramWrData_data_f;
  wire          ht_cmd_dramWrData_valid_f;
  wire          ht_cmd_dramWrData_ready_f;

  wire [511:0] upd_dramRdData_data_f;
  wire          upd_dramRdData_valid_f;
  wire          upd_dramRdData_ready_f;

  wire [63:0] upd_cmd_dramRdData_data_f;
  wire          upd_cmd_dramRdData_valid_f;
  wire          upd_cmd_dramRdData_ready_f;

  wire [511:0] upd_dramWrData_data_f;
  wire          upd_dramWrData_valid_f;
  wire          upd_dramWrData_ready_f;

  wire [63:0] upd_cmd_dramWrData_data_f;
  wire          upd_cmd_dramWrData_valid_f;
  wire          upd_cmd_dramWrData_ready_f;


  wire [63:0] ptr_rdcmd_data_f;
  wire         ptr_rdcmd_valid_f;
  wire         ptr_rdcmd_ready_f;

  wire [63:0]  ptr_wrcmd_data_f;
  wire         ptr_wrcmd_valid_f;
  wire         ptr_wrcmd_ready_f;

  wire [511:0] ptr_rd_data_f;
  wire         ptr_rd_valid_f;
  wire         ptr_rd_ready_f;

  wire [511:0] ptr_wr_data_f;
  wire         ptr_wr_valid_f;
  wire         ptr_wr_ready_f;
 

   wire [63:0] bmap_rdcmd_data_f;
  wire         bmap_rdcmd_valid_f;
  wire         bmap_rdcmd_ready_f;

  wire [63:0]  bmap_wrcmd_data_f;
  wire         bmap_wrcmd_valid_f;
  wire         bmap_wrcmd_ready_f;

  wire [511:0] bmap_rd_data_f;
  wire         bmap_rd_valid_f;
  wire         bmap_rd_ready_f;

  wire [511:0] bmap_wr_data_f;
  wire         bmap_wr_valid_f;
  wire         bmap_wr_ready_f;


  wire [47:0]  m_axis_open_connection_TDATA_f;
  wire         m_axis_open_connection_TVALID_f;
  wire         m_axis_open_connection_TREADY_f;


  wire [23:0]  s_axis_open_status_TDATA_f;
  wire         s_axis_open_status_TVALID_f;
  wire         s_axis_open_status_TREADY_f;
 
  
	reg injectValid;
  reg[127:0] injectWord;		


   muu_Top_Module_LMem512
   #(   
            .IS_SIM(IS_SIM),
            .USER_BITS(USER_BITS),
            .HASHTABLE_MEM_SIZE(25), //the total size is this +USER_BITS!!!
            .VALUESTORE_MEM_SIZE(27)    
   ) muukvs_instance (
        .clk(fclk),
        .rst(freset),
        .s_axis_tvalid(splitInValid),
        .s_axis_tready(splitInReady),
        .s_axis_tuserid(splitInUser),
        .s_axis_tdata({splitInMeta,splitInData}),
        .s_axis_tlast(splitInLast),

        .m_axis_tvalid(fromKvsValid_f),
        .m_axis_tready(fromKvsReady_f),
        .m_axis_tdata(fromKvsData_f),
        .m_axis_tuserid(fromKvsUser_f),
        .m_axis_tlast(fromKvsLast_f),
        
          .ht_rd_data(ht_dramRdData_data_f),
          .ht_rd_empty(~ht_dramRdData_valid_f),
          .ht_rd_almost_empty(),
          .ht_rd_read(ht_dramRdData_ready_f),
          
          .ht_rd_cmd_data(ht_cmd_dramRdData_data_f),
          .ht_rd_cmd_valid(ht_cmd_dramRdData_valid_f),
          .ht_rd_cmd_stall(~ht_cmd_dramRdData_ready_f),
        
          .ht_wr_data(ht_dramWrData_data_f),
          .ht_wr_valid(ht_dramWrData_valid_f),
          .ht_wr_stall(~ht_dramWrData_ready_f),
          
          .ht_wr_cmd_data(ht_cmd_dramWrData_data_f),
          .ht_wr_cmd_valid(ht_cmd_dramWrData_valid_f),
          .ht_wr_cmd_stall(~ht_cmd_dramWrData_ready_f),
        
          // Update DRAM Connection  
          .upd_rd_data(upd_dramRdData_data_f),
          .upd_rd_empty(~upd_dramRdData_valid_f),
          .upd_rd_almost_empty(),
          .upd_rd_read(upd_dramRdData_ready_f),
          
          .upd_rd_cmd_data(upd_cmd_dramRdData_data_f),
          .upd_rd_cmd_valid(upd_cmd_dramRdData_valid_f),
          .upd_rd_cmd_stall(~upd_cmd_dramRdData_ready_f),
          
          .upd_wr_data(upd_dramWrData_data_f),
          .upd_wr_valid(upd_dramWrData_valid_f),
          .upd_wr_stall(~upd_dramWrData_ready_f),
        
          .upd_wr_cmd_data(upd_cmd_dramWrData_data_f),
          .upd_wr_cmd_valid(upd_cmd_dramWrData_valid_f),
          .upd_wr_cmd_stall(~upd_cmd_dramWrData_ready_f),

          .p_rdcmd_data(ptr_rdcmd_data_f),
          .p_rdcmd_valid(ptr_rdcmd_valid_f),
          .p_rdcmd_ready(ptr_rdcmd_ready_f),

          .p_rd_data(ptr_rd_data_f),
          .p_rd_valid(ptr_rd_valid_f),
          .p_rd_ready(ptr_rd_ready_f),  

          .p_wr_data(ptr_wr_data_f),
          .p_wr_valid(ptr_wr_valid_f),
          .p_wr_ready(ptr_wr_ready_f),

          .p_wrcmd_data(ptr_wrcmd_data_f),
          .p_wrcmd_valid(ptr_wrcmd_valid_f),
          .p_wrcmd_ready(ptr_wrcmd_ready_f),


          .b_rdcmd_data(bmap_rdcmd_data_f),
          .b_rdcmd_valid(bmap_rdcmd_valid_f),
          .b_rdcmd_ready(bmap_rdcmd_ready_f),

          .b_rd_data(bmap_rd_data_f),
          .b_rd_valid(bmap_rd_valid_f),
          .b_rd_ready(bmap_rd_ready_f),  

          .b_wr_data(bmap_wr_data_f),
          .b_wr_valid(bmap_wr_valid_f),
          .b_wr_ready(bmap_wr_ready_f),

          .b_wrcmd_data(bmap_wrcmd_data_f),
          .b_wrcmd_valid(bmap_wrcmd_valid_f),
          .b_wrcmd_ready(bmap_wrcmd_ready_f),

          .m_axis_open_connection_TVALID(m_axis_open_connection_TVALID_f),
          .m_axis_open_connection_TREADY(m_axis_open_connection_TREADY_f),
          .m_axis_open_connection_TDATA(m_axis_open_connection_TDATA_f),

          .s_axis_open_status_TVALID(s_axis_open_status_TVALID_f),
          .s_axis_open_status_TREADY(s_axis_open_status_TREADY_f),
          .s_axis_open_status_TDATA(s_axis_open_status_TDATA_f),
          
          .debug(kvs_is_stuck)
   );

// .S00_AXIS_TDATA({fromKvsData[63:0],fromKvsData[127:64]}),
  
   wire[512+64+USER_BITS:0] fromKvsMerged;
   nukv_fifogen_async #(
            .DATA_SIZE(512+64+1+USER_BITS),
            .ADDR_BITS(6)
        ) fifo_f_fromkvs (
                .s_axis_clk(fclk),
                .s_axis_rst(freset),
                .m_axis_clk(aclk),
                .s_axis_tvalid(fromKvsValid_f),
                .s_axis_tready(fromKvsReady_f),
                .s_axis_tdata({fromKvsData_f,fromKvsUser_f,fromKvsLast_f}),  
                .m_axis_tvalid(fromKvsValid),
                .m_axis_tready(fromKvsReady),
                .m_axis_tdata(fromKvsMerged)
                ); 
   assign fromKvsData = fromKvsMerged[USER_BITS+1+512+63:USER_BITS+1];
   assign fromKvsLast = fromKvsMerged[0];
   assign fromKvsUser = fromKvsMerged[USER_BITS:1];

   nukv_fifogen_async #(
            .DATA_SIZE(512),
            .ADDR_BITS(6)
        ) fifo_f_dramrddata (
                .s_axis_clk(aclk),
                .s_axis_rst(reset),
                .m_axis_clk(fclk),
                .s_axis_tvalid(~ht_dramRdData_empty),
                .s_axis_tready(ht_dramRdData_read),
                .s_axis_tdata(ht_dramRdData_data),  
                .m_axis_tvalid(ht_dramRdData_valid_f),
                .m_axis_tready(ht_dramRdData_ready_f),
                .m_axis_tdata(ht_dramRdData_data_f)
                ); 

   nukv_fifogen_async #(
            .DATA_SIZE(64),
            .ADDR_BITS(6)
        ) fifo_f_dramrdcmd (
                .s_axis_clk(fclk),
                .s_axis_rst(freset),
                .m_axis_clk(aclk),
                .s_axis_tvalid(ht_cmd_dramRdData_valid_f),
                .s_axis_tready(ht_cmd_dramRdData_ready_f),
                .s_axis_tdata(ht_cmd_dramRdData_data_f),  
                .m_axis_tvalid(ht_cmd_dramRdData_valid),
                .m_axis_tready(~ht_cmd_dramRdData_stall),
                .m_axis_tdata(ht_cmd_dramRdData_data)
                );         

   nukv_fifogen_async #(
            .DATA_SIZE(512),
            .ADDR_BITS(6)
        ) fifo_f_dramwrdata (
                .s_axis_clk(fclk),
                .s_axis_rst(freset),
                .m_axis_clk(aclk),
                .s_axis_tvalid(ht_dramWrData_valid_f),
                .s_axis_tready(ht_dramWrData_ready_f),
                .s_axis_tdata(ht_dramRdData_data_f),  
                .m_axis_tvalid(ht_dramWrData_valid),
                .m_axis_tready(~ht_dramWrData_stall),
                .m_axis_tdata(ht_dramWrData_data)
                ); 

   nukv_fifogen_async #(
            .DATA_SIZE(64),
            .ADDR_BITS(6)
        ) fifo_f_dramwrcmd (
                .s_axis_clk(fclk),
                .s_axis_rst(freset),
                .m_axis_clk(aclk),
                .s_axis_tvalid(ht_cmd_dramWrData_valid_f),
                .s_axis_tready(ht_cmd_dramWrData_ready_f),
                .s_axis_tdata(ht_cmd_dramWrData_data_f),  
                .m_axis_tvalid(ht_cmd_dramWrData_valid),
                .m_axis_tready(~ht_cmd_dramWrData_stall),
                .m_axis_tdata(ht_cmd_dramWrData_data)
                );   


nukv_fifogen_async #(
            .DATA_SIZE(512),
            .ADDR_BITS(6)
        ) fifo_f_dramrddata2 (
                .s_axis_clk(aclk),
                .s_axis_rst(reset),
                .m_axis_clk(fclk),
                .s_axis_tvalid(~upd_dramRdData_empty),
                .s_axis_tready(upd_dramRdData_read),
                .s_axis_tdata(upd_dramRdData_data),  
                .m_axis_tvalid(upd_dramRdData_valid_f),
                .m_axis_tready(upd_dramRdData_ready_f),
                .m_axis_tdata(upd_dramRdData_data_f)
                ); 

   nukv_fifogen_async #(
            .DATA_SIZE(64),
            .ADDR_BITS(6)
        ) fifo_f_dramrdcmd2 (
                .s_axis_clk(fclk),
                .s_axis_rst(freset),
                .m_axis_clk(aclk),
                .s_axis_tvalid(upd_cmd_dramRdData_valid_f),
                .s_axis_tready(upd_cmd_dramRdData_ready_f),
                .s_axis_tdata(upd_cmd_dramRdData_data_f),  
                .m_axis_tvalid(upd_cmd_dramRdData_valid),
                .m_axis_tready(~upd_cmd_dramRdData_stall),
                .m_axis_tdata(upd_cmd_dramRdData_data)
                );         

   nukv_fifogen_async #(
            .DATA_SIZE(512),
            .ADDR_BITS(6)
        ) fifo_f_dramwrdata2 (
                .s_axis_clk(fclk),
                .s_axis_rst(freset),
                .m_axis_clk(aclk),
                .s_axis_tvalid(upd_dramWrData_valid_f),
                .s_axis_tready(upd_dramWrData_ready_f),
                .s_axis_tdata(upd_dramRdData_data_f),  
                .m_axis_tvalid(upd_dramWrData_valid),
                .m_axis_tready(~upd_dramWrData_stall),
                .m_axis_tdata(upd_dramWrData_data)
                ); 

   nukv_fifogen_async #(
            .DATA_SIZE(64),
            .ADDR_BITS(6)
        ) fifo_f_dramwrcmd2 (
                .s_axis_clk(fclk),
                .s_axis_rst(freset),
                .m_axis_clk(aclk),
                .s_axis_tvalid(upd_cmd_dramWrData_valid_f),
                .s_axis_tready(upd_cmd_dramWrData_ready_f),
                .s_axis_tdata(upd_cmd_dramWrData_data_f),  
                .m_axis_tvalid(upd_cmd_dramWrData_valid),
                .m_axis_tready(~upd_cmd_dramWrData_stall),
                .m_axis_tdata(upd_cmd_dramWrData_data)
                );           

    

nukv_fifogen_async #(
            .DATA_SIZE(512),
            .ADDR_BITS(6)
        ) fifo_f_dramrddata3 (
                .s_axis_clk(aclk),
                .s_axis_rst(reset),
                .m_axis_clk(fclk),
                .s_axis_tvalid(ptr_rd_valid),
                .s_axis_tready(ptr_rd_ready),
                .s_axis_tdata(ptr_rd_data),  
                .m_axis_tvalid(ptr_rd_valid_f),
                .m_axis_tready(ptr_rd_ready_f),
                .m_axis_tdata(ptr_rd_data_f)
                ); 

   nukv_fifogen_async #(
            .DATA_SIZE(64),
            .ADDR_BITS(6)
        ) fifo_f_dramrdcmd3 (
                .s_axis_clk(fclk),
                .s_axis_rst(freset),
                .m_axis_clk(aclk),
                .s_axis_tvalid(ptr_rdcmd_valid_f),
                .s_axis_tready(ptr_rdcmd_ready_f),
                .s_axis_tdata(ptr_rdcmd_data_f),  
                .m_axis_tvalid(ptr_rdcmd_valid),
                .m_axis_tready(~ptr_rdcmd_ready),
                .m_axis_tdata(ptr_rdcmd_data)
                );         

   nukv_fifogen_async #(
            .DATA_SIZE(512),
            .ADDR_BITS(6)
        ) fifo_f_dramwrdata3 (
                .s_axis_clk(fclk),
                .s_axis_rst(freset),
                .m_axis_clk(aclk),
                .s_axis_tvalid(ptr_wr_valid_f),
                .s_axis_tready(ptr_wr_ready_f),
                .s_axis_tdata(uptr_wr_data_f),  
                .m_axis_tvalid(ptr_wr_valid),
                .m_axis_tready(ptr_wr_ready),
                .m_axis_tdata(ptr_wr_data)
                ); 

   nukv_fifogen_async #(
            .DATA_SIZE(64),
            .ADDR_BITS(6)
        ) fifo_f_dramwrcmd3 (
                .s_axis_clk(fclk),
                .s_axis_rst(freset),
                .m_axis_clk(aclk),
                .s_axis_tvalid(ptr_wrcmd_valid_f),
                .s_axis_tready(ptr_wrcmd_ready_f),
                .s_axis_tdata(ptr_wrcmd_data_f),  
                .m_axis_tvalid(ptr_wrcmd_valid),
                .m_axis_tready(ptr_wrcmd_ready),
                .m_axis_tdata(ptr_wrcmd_data)
                );           

    

nukv_fifogen_async #(
            .DATA_SIZE(512),
            .ADDR_BITS(6)
        ) fifo_f_dramrddata4 (
                .s_axis_clk(aclk),
                .s_axis_rst(reset),
                .m_axis_clk(fclk),
                .s_axis_tvalid(bmap_rd_valid),
                .s_axis_tready(bmap_rd_ready),
                .s_axis_tdata(bmap_rd_data),  
                .m_axis_tvalid(bmap_rd_valid_f),
                .m_axis_tready(bmap_rd_ready_f),
                .m_axis_tdata(bmap_rd_data_f)
                ); 

   nukv_fifogen_async #(
            .DATA_SIZE(64),
            .ADDR_BITS(6)
        ) fifo_f_dramrdcmd4 (
                .s_axis_clk(fclk),
                .s_axis_rst(freset),
                .m_axis_clk(aclk),
                .s_axis_tvalid(bmap_rdcmd_valid_f),
                .s_axis_tready(bmap_rdcmd_ready_f),
                .s_axis_tdata(bmap_rdcmd_data_f),  
                .m_axis_tvalid(bmap_rdcmd_valid),
                .m_axis_tready(~bmap_rdcmd_ready),
                .m_axis_tdata(bmap_rdcmd_data)
                );         

   nukv_fifogen_async #(
            .DATA_SIZE(512),
            .ADDR_BITS(6)
        ) fifo_f_dramwrdata4 (
                .s_axis_clk(fclk),
                .s_axis_rst(freset),
                .m_axis_clk(aclk),
                .s_axis_tvalid(bmap_wr_valid_f),
                .s_axis_tready(bmap_wr_ready_f),
                .s_axis_tdata(ubmap_wr_data_f),  
                .m_axis_tvalid(bmap_wr_valid),
                .m_axis_tready(bmap_wr_ready),
                .m_axis_tdata(bmap_wr_data)
                ); 

   nukv_fifogen_async #(
            .DATA_SIZE(64),
            .ADDR_BITS(6)
        ) fifo_f_dramwrcmd4 (
                .s_axis_clk(fclk),
                .s_axis_rst(freset),
                .m_axis_clk(aclk),
                .s_axis_tvalid(bmap_wrcmd_valid_f),
                .s_axis_tready(bmap_wrcmd_ready_f),
                .s_axis_tdata(ubmap_wrcmd_data_f),  
                .m_axis_tvalid(bmap_wrcmd_valid),
                .m_axis_tready(bmap_wrcmd_ready),
                .m_axis_tdata(bmap_wrcmd_data)
                );           

   nukv_fifogen_async #(
            .DATA_SIZE(48),
            .ADDR_BITS(6)
        ) fifo_f_openreq (
                .s_axis_clk(fclk),
                .s_axis_rst(freset),
                .m_axis_clk(aclk),
                .s_axis_tvalid(m_axis_open_connection_TVALID_f),
                .s_axis_tready(m_axis_open_connection_TREADY_f),
                .s_axis_tdata(m_axis_open_connection_TDATA_f),  
                .m_axis_tvalid(m_axis_open_connection_TVALID),
                .m_axis_tready(m_axis_open_connection_TREADY),
                .m_axis_tdata(m_axis_open_connection_TDATA)
                );  

   nukv_fifogen_async #(
            .DATA_SIZE(24),
            .ADDR_BITS(6)
        ) fifo_f_openstat (
                .s_axis_clk(aclk),
                .s_axis_rst(reset),
                .m_axis_clk(fclk),
                .s_axis_tvalid(s_axis_open_status_TVALID),
                .s_axis_tready(s_axis_open_status_TREADY),
                .s_axis_tdata(s_axis_open_status_TDATA),  
                .m_axis_tvalid(s_axis_open_status_TVALID_f),
                .m_axis_tready(s_axis_open_status_TREADY_f),
                .m_axis_tdata(s_axis_open_status_TDATA_f)
                );  


  reg derMetaValid;
  wire derMetaReady;
  reg[15:0] derMetaData;
  reg[15:0] derMetaLen;

    always @(posedge aclk) begin  
      if(reset) begin
         injectValid <= 0;
      end else begin
        if ((injectValid==1 && fromKvsReady==1) || fromKvsValid==1) begin
          injectValid <= 0;
        end
        if (injectValid==0 && fromKvsValid==1 && fromKvsReady==1 && fromKvsLast==1) begin
          //injectValid <= 1;
          injectWord <= {fromKvsData[511+64:64],512'd0};
        end
      end
    end
    
    wire derOutValid;
    wire derOutReady;
    wire[512+64-1:0] derOutData;
    wire derOutLast;
    
    assign derOutValid = fromKvsValid | injectValid;
    assign fromKvsReady = derOutReady; 
    assign derOutData = (injectValid==1 && fromKvsValid==0) ? {1'b1,injectWord} : {fromKvsLast,fromKvsData};
    assign derOutLast = (injectValid==1 && fromKvsValid==0) ? 1 : fromKvsLast;

    //axis_data_saf_kvs
        nukv_fifogen #(
            .DATA_SIZE(512+64+1),
            .ADDR_BITS(11)
        ) fifo_lastdata (
                .clk(aclk),//.s_axis_aclk(aclk),
                .rst(reset),//.s_axis_aresetn(~reset),
                .s_axis_tvalid(derOutValid),
                .s_axis_tready(derOutReady),
                .s_axis_tdata(derOutData),
                //.s_axis_tdata(fromKvsData),
                //.s_axis_tlast(fromKvsLast),  
                .m_axis_tvalid(finalOutValid),
                .m_axis_tready(finalOutReady),                
                .m_axis_tdata({finalOutLast,finalOutData})
                //.m_axis_tdata(finalOutData),
                //.m_axis_tlast(finalOutLast)
                );
                
         nukv_fifogen #(
                    .DATA_SIZE(32),
                    .ADDR_BITS(4)
                ) fifo_lastmeta (
                        .clk(aclk),
                        .rst(reset),
                        .s_axis_tvalid(derMetaValid),
                        .s_axis_tready(derMetaReady),
                        .s_axis_tdata({derMetaLen,derMetaData}),  
                        .m_axis_tvalid(m_axis_tx_metadata_TVALID),
                        .m_axis_tready(m_axis_tx_metadata_TREADY),
                        .m_axis_tdata(m_axis_tx_metadata_TDATA)
                        );              
   
   
   assign   m_axis_tx_data_TVALID =  finalOutValid ;
   assign   m_axis_tx_data_TDATA = finalOutData[511:0];
   assign   m_axis_tx_data_TKEEP = 8'b11111111;
   assign   m_axis_tx_data_TLAST = finalOutLast;
   assign   finalOutReady =  m_axis_tx_data_TREADY ;
   
/*   assign   m_axis_tx_data_TVALID = (is_first_output_cycle==0) ? finalOutValid : (finalOutValid && m_axis_tx_metadata_TREADY);
   assign   m_axis_tx_data_TDATA = finalOutData[63:0];
   assign   m_axis_tx_data_TKEEP = 8'b11111111;
   assign   m_axis_tx_data_TLAST = finalOutLast;
   assign   finalOutReady = (is_first_output_cycle==0) ? m_axis_tx_data_TREADY : (m_axis_tx_data_TREADY && m_axis_tx_metadata_TREADY);
   
*/
   //assign timerReady = is_first_output_cycle & finalOutValid & finalOutReady;
    
   always @(posedge aclk) 
     begin
	if (aresetn == 0) begin
	   is_first_output_cycle <= 1;
	   derMetaValid <= 0;     
     derMetaLen <= 0;  
	end
	else begin
	   if (derMetaValid==1 && derMetaReady==1) begin
	       derMetaValid <= 0;
	   end

     if (derOutValid==1 && derOutReady==1 ) begin
      derMetaLen <= derMetaLen+8;
     end
	
	   if (derOutValid==1 && derOutReady==1 && is_first_output_cycle==1) begin	      
	      derMetaData <= derOutData[512 +: 16];
	      is_first_output_cycle <= 0;	  
          derMetaLen <= 8;
	   end	  

	   if (derOutReady==1 && derOutValid==1 && derOutLast==1) begin
	       derMetaValid <= 1;
	       is_first_output_cycle <= 1;
	   end
	end
     end   
   
  /* always @(posedge aclk) 
     begin
	if (aresetn == 0) begin
	   is_first_output_cycle <= 1;
	   m_axis_tx_metadata_TVALID <= 0;       
	end
	else begin
	   if (finalOutValid==1 && finalOutReady==1 && is_first_output_cycle==1) begin
	      m_axis_tx_metadata_TVALID <= 1;
	      m_axis_tx_metadata_TDATA <= finalOutData[64 +: 16];
	      is_first_output_cycle <= 0;	  
	   end

	   if (m_axis_tx_metadata_TVALID==1 && m_axis_tx_metadata_TREADY==1) begin
	      m_axis_tx_metadata_TVALID <= 0;	  
	   end

	   if (finalOutValid==1 && finalOutReady==1 && finalOutLast==1) begin
	      is_first_output_cycle <= 1;
	   end
	end
     end*/


/*
   reg[31:0] clock_reg;

   reg [31:0] sent_count;
   reg [31:0] recv_count;
   
   reg [31:0] position_consumed;   

   always @(posedge aclk) 
     begin
	if (aresetn == 0) begin
           dbg_capture_count <= 0;
           dbg_replay_left <= 0;
	   replay_mode <= 0;
           dbg_replay_valid <= 0;
           dbg_replay_prevalid <= 0;
           dbg_capture_valid <= 0;
           
	end
	else 
	  begin

             vio_cmd_r <= vio_cmd;
	     
	     dbg_capture <= vio_cmd_r[0];
	     dbg_replay <= vio_cmd_r[1];
 	     dbg_capture_valid <= 0;
	     
	     
	     if (vio_cmd_r[0]==1 && dbg_capture==0) 
	       begin
		  dbg_capture_count <= 0;
	       end
	     
	     if (vio_cmd_r[1]==1 && dbg_replay==0) 
	       begin
		  replay_mode <= 0;
		  dbg_replay_pos <= 0;
		  dbg_capture_pos <= 0;	
		  dbg_replay_left <= vio_cmd_r[2+15:2];
		  clock_reg <= 0;
		  sent_count <= 0;
		  recv_count <= 0;
		  
		  dbg_replay_prevalid <= 0;
		  dbg_replay_valid <= 0;
	       end
	     
	     if (dbg_capture==0 && dbg_capture==1 && sesspackValid==1 && sesspackReady==1 && dbg_capture_count<vio_cmd_r[2+15:2])
	       begin
		  dbg_capture_pos <= dbg_capture_count;
		  dbg_capture_valid <= 1;
		  dbg_capture_data <= {sesspackLast ,16'h8001, sesspackData};
		  dbg_capture_count <= dbg_capture_count+1;
	       end
	     
	     if (toPifValid==1 && toPifLast==1) 
	       begin
		  recv_count <= recv_count+1;
	       end
	     
	     if (sent_count!=recv_count) begin
		clock_reg<= clock_reg+1;
	     end 
	     
	     if (dbg_replay==0 && dbg_replay==1 && dbg_replay_left>0) 
	       begin
		  
		  clock_reg<= clock_reg+1;
		  
		  replay_mode <= 1;	
		  dbg_replay_valid <= dbg_replay_prevalid;	  
		  
//		  if (clock_reg[0]==0) 
//		    begin
    		  dbg_replay_prevalid <= 1;
//		    end						

		  if (dbg_replay_ready==1 && dbg_replay_valid==1) 
		    begin
                       dbg_replay_valid <= 0;
 //                     dbg_replay_prevalid <= 0;
   
		       dbg_replay_pos <= dbg_replay_pos+1;
		       
		       if (dbg_replay_valid==1 && dbg_replay_data[15:0]==16'hffff) 
			 begin
			    sent_count <= sent_count+1;
			 end
		    end
		  
		  
		  if (dbg_replay_pos+1==dbg_capture_count && dbg_replay_ready==1 && dbg_replay_valid==1)
		    begin
		       dbg_replay_pos <= 0;
		       dbg_replay_left <= dbg_replay_left-1;
		       
		       if (dbg_replay_left==1) 
			 begin
			    replay_mode <= 0;					
			 end
		    end
		  
	       end
             
	  end
	
     end


    reg[15:0] diff_front;
    reg[15:0] diff_sm;
    reg[15:0] diff_kvs;
    reg[15:0] diff_smkvs;
    
    reg[63:0] delayed_input_data;
    reg[63:0] delayed_memread_data;

*/
endmodule
