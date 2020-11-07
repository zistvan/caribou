////------------------------------------------------------------------------------
////  (c) Copyright 2013 Xilinx, Inc. All rights reserved.
////
////  This file contains confidential and proprietary information
////  of Xilinx, Inc. and is protected under U.S. and
////  international copyright and other intellectual property
////  laws.
////
////  DISCLAIMER
////  This disclaimer is not a license and does not grant any
////  rights to the materials distributed herewith. Except as
////  otherwise provided in a valid license issued to you by
////  Xilinx, and to the maximum extent permitted by applicable
////  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
////  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
////  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
////  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
////  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
////  (2) Xilinx shall not be liable (whether in contract or tort,
////  including negligence, or under any other theory of
////  liability) for any loss or damage of any kind or nature
////  related to, arising under or in connection with these
////  materials, including for any direct, or any indirect,
////  special, incidental, or consequential loss or damage
////  (including loss of data, profits, goodwill, or any type of
////  loss or damage suffered as a result of any action brought
////  by a third party) even if such damage or loss was
////  reasonably foreseeable or Xilinx had been advised of the
////  possibility of the same.
////
////  CRITICAL APPLICATIONS
////  Xilinx products are not designed or intended to be fail-
////  safe, or for use in any application requiring fail-safe
////  performance, such as life-support or safety devices or
////  systems, Class III medical devices, nuclear facilities,
////  applications related to the deployment of airbags, or any
////  other applications that could lead to death, personal
////  injury, or severe property or environmental damage
////  (individually and collectively, "Critical
////  Applications"). Customer assumes the sole risk and
////  liability of any use of Xilinx products in Critical
////  Applications, subject only to applicable laws and
////  regulations governing limitations on product liability.
////
////  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
////  PART OF THIS FILE AT ALL TIMES.
////------------------------------------------------------------------------------


`timescale 1fs/1fs

//(* DowngradeIPIdentifiedWarnings="yes" *)
module vcu1525_top_multes
(
    input  wire [1-1:0] gt_rxp_in,
    input  wire [1-1:0] gt_rxn_in,
    output wire [1-1:0] gt_txp_out,
    output wire [1-1:0] gt_txn_out,
    //input wire  restart_tx_rx_0,
    //output wire rx_gt_locked_led_0,     // Indicates GT LOCK
    //output wire rx_block_lock_led_0,    // Indicates Core Block Lock
    //output wire [4:0] completion_status,

    //input             sys_reset,
    input             gt_refclk_p,
    input             gt_refclk_n,
    input             c300_p,
    input             c300_n,


    
    input wire c0_sys_clk_p,
    input wire c0_sys_clk_n,
    
    output wire [16 : 0] c0_ddr4_adr,
    output wire [1 : 0] c0_ddr4_ba,
    output wire [0 : 0] c0_ddr4_cke,
    output wire [0 : 0] c0_ddr4_cs_n,
    inout wire [71 : 0] c0_ddr4_dq,
    inout wire [17 : 0] c0_ddr4_dqs_c,
    inout wire [17 : 0] c0_ddr4_dqs_t,
    output wire [0 : 0] c0_ddr4_odt,
    output wire c0_ddr4_parity,
    output wire [1 : 0] c0_ddr4_bg,
    output wire c0_ddr4_reset_n,
    output wire c0_ddr4_act_n,
    output wire [0 : 0] c0_ddr4_ck_c,
    output wire [0 : 0] c0_ddr4_ck_t,
    
    
    input wire c1_sys_clk_p,
    input wire c1_sys_clk_n,
    
    output wire [16 : 0] c1_ddr4_adr,
    output wire [1 : 0] c1_ddr4_ba,
    output wire [0 : 0] c1_ddr4_cke,
    output wire [0 : 0] c1_ddr4_cs_n,
    inout wire [71 : 0] c1_ddr4_dq,
    inout wire [17 : 0] c1_ddr4_dqs_c,
    inout wire [17 : 0] c1_ddr4_dqs_t,
    output wire [0 : 0] c1_ddr4_odt,
    output wire c1_ddr4_parity,
    output wire [1 : 0] c1_ddr4_bg,
    output wire c1_ddr4_reset_n,
    output wire c1_ddr4_act_n,
    output wire [0 : 0] c1_ddr4_ck_c,
    output wire [0 : 0] c1_ddr4_ck_t
);

    wire sys_reset;
  wire clockdown_locked;
  
  
  assign sys_reset = ~clockdown_locked;

  wire [2:0] gt_loopback_in_0; 

//// For other GT loopback options please change the value appropriately
//// For example, for internal loopback gt_loopback_in[2:0] = 3'b010;
//// For more information and settings on loopback, refer GT Transceivers user guide
  wire dclk;  
  wire uclk;
  
  wire fclk; //300Mhz clock
  /*
       IBUFDS #(
  .DQS_BIAS("FALSE")  // (FALSE, TRUE)
)
clockdown (
  .O(uclk),   // 1-bit output: Buffer output
  .I(c300_p),   // 1-bit input: Diff_p buffer input (connect directly to top-level port)
  .IB(c300_n)  // 1-bit input: Diff_n buffer input (connect directly to top-level port)
);
  
  /**/
  
  clk_wiz_300_156 clockdown
     (
      // Clock out ports
      .clk_out1(dclk),     // output clk_out1
      .clk_out2(fclk),     // output clk_out1
      // Status and control signals
      .locked(clockdown_locked),       // output locked
     // Clock in ports
      .clk_in1_p(c300_p),    // input clk_in1_p
      .clk_in1_n(c300_n));
      
   /* */  

  assign gt_loopback_in_0 = 3'b000;
                                                
  wire  block_lock_led_0;
  
  wire rx_core_clk_0;
  wire rx_clk_out_0;
  wire tx_clk_out_0;
  //assign rx_core_clk_0 = tx_clk_out_0;
  assign rx_core_clk_0 = tx_clk_out_0;


//// RX_0 Signals
 wire rx_reset_0;
 wire user_rx_reset_0;
  wire rxrecclkout_0;


//// RX_0 User Interface Signals
  wire rx_axis_tvalid_cross;
  wire [63:0] rx_axis_tdata_cross;
  wire rx_axis_tlast_cross;
  wire rx_axis_tready_cross;
  wire [7:0] rx_axis_tkeep_cross;
  wire rx_axis_tuser_cross;
  wire [55:0] rx_preambleout_cross;

//// RX_0 User Interface Signals
wire rx_axis_tvalid_0;
wire [63:0] rx_axis_tdata_0;
wire rx_axis_tlast_0;
wire [7:0] rx_axis_tkeep_0;
wire rx_axis_tuser_0;
wire [55:0] rx_preambleout_0;

wire rx_axis_tvalid_oc;
wire [63:0] rx_axis_tdata_oc;
wire rx_axis_tlast_oc;
 wire rx_axis_tready_oc;
wire [7:0] rx_axis_tkeep_oc;
wire rx_axis_tuser_oc;
wire [55:0] rx_preambleout_oc;



//// RX_0 Control Signals
  wire ctl_rx_test_pattern_0;
  wire ctl_rx_test_pattern_enable_0;
  wire ctl_rx_data_pattern_select_0;
  wire ctl_rx_enable_0;
  wire ctl_rx_delete_fcs_0;
  wire ctl_rx_ignore_fcs_0;
  wire [14:0] ctl_rx_max_packet_len_0;
  wire [7:0] ctl_rx_min_packet_len_0;
  wire ctl_rx_custom_preamble_enable_0;
  wire ctl_rx_check_sfd_0;
  wire ctl_rx_check_preamble_0;
  wire ctl_rx_process_lfi_0;
  wire ctl_rx_force_resync_0;


//// RX_0 Stats Signals
  wire stat_rx_block_lock_0;
  wire stat_rx_framing_err_valid_0;
  wire stat_rx_framing_err_0;
  wire stat_rx_hi_ber_0;
  wire stat_rx_valid_ctrl_code_0;
  wire stat_rx_bad_code_0;
  wire [1:0] stat_rx_total_packets_0;
  wire stat_rx_total_good_packets_0;
  wire [3:0] stat_rx_total_bytes_0;
  wire [13:0] stat_rx_total_good_bytes_0;
  wire stat_rx_packet_small_0;
  wire stat_rx_jabber_0;
  wire stat_rx_packet_large_0;
  wire stat_rx_oversize_0;
  wire stat_rx_undersize_0;
  wire stat_rx_toolong_0;
  wire stat_rx_fragment_0;
  wire stat_rx_packet_64_bytes_0;
  wire stat_rx_packet_65_127_bytes_0;
  wire stat_rx_packet_128_255_bytes_0;
  wire stat_rx_packet_256_511_bytes_0;
  wire stat_rx_packet_512_1023_bytes_0;
  wire stat_rx_packet_1024_1518_bytes_0;
  wire stat_rx_packet_1519_1522_bytes_0;
  wire stat_rx_packet_1523_1548_bytes_0;
  wire [1:0] stat_rx_bad_fcs_0;
  wire stat_rx_packet_bad_fcs_0;
  wire [1:0] stat_rx_stomped_fcs_0;
  wire stat_rx_packet_1549_2047_bytes_0;
  wire stat_rx_packet_2048_4095_bytes_0;
  wire stat_rx_packet_4096_8191_bytes_0;
  wire stat_rx_packet_8192_9215_bytes_0;
  wire stat_rx_bad_preamble_0;
  wire stat_rx_bad_sfd_0;
  wire stat_rx_got_signal_os_0;
  wire stat_rx_test_pattern_mismatch_0;
  wire stat_rx_truncated_0;
  wire stat_rx_local_fault_0;
  wire stat_rx_remote_fault_0;
  wire stat_rx_internal_local_fault_0;
  wire stat_rx_received_local_fault_0;
   wire stat_rx_status_0;
//// TX_0 Signals
  wire tx_reset_0;
  wire user_tx_reset_0;

//// TX_0 User Interface Signals
  wire tx_axis_tready_0;
  wire tx_axis_tvalid_0;
  wire [63:0] tx_axis_tdata_0;
  wire tx_axis_tlast_0;
  wire [7:0] tx_axis_tkeep_0;
  reg tx_axis_tuser_0;
   wire tx_unfout_0;
  wire [55:0] tx_preamblein_0;

 wire tx_axis_tready_int;
  wire tx_axis_tvalid_int;
  wire [63:0] tx_axis_tdata_int;
  wire tx_axis_tlast_int;
  wire [7:0] tx_axis_tkeep_int;
  wire tx_axis_tuser_int;

  wire tx_axis_tready_oc;
  wire tx_axis_tvalid_oc;
  wire [63:0] tx_axis_tdata_oc;
  wire tx_axis_tlast_oc;
  wire [7:0] tx_axis_tkeep_oc;
  wire tx_axis_tuser_oc;
   wire tx_unfout_oc;
   wire [55:0] tx_preamblein_oc;

//// TX_0 Control Signals
  wire ctl_tx_test_pattern_0;
  wire ctl_tx_test_pattern_enable_0;
  wire ctl_tx_test_pattern_select_0;
  wire ctl_tx_data_pattern_select_0;
  wire [57:0] ctl_tx_test_pattern_seed_a_0;
  wire [57:0] ctl_tx_test_pattern_seed_b_0;
  wire ctl_tx_enable_0;
  wire ctl_tx_fcs_ins_enable_0;
  wire [3:0] ctl_tx_ipg_value_0;
  wire ctl_tx_send_lfi_0;
  wire ctl_tx_send_rfi_0;
  wire ctl_tx_send_idle_0;
  wire ctl_tx_custom_preamble_enable_0;
  wire ctl_tx_ignore_fcs_0;


//// TX_0 Stats Signals
  wire stat_tx_total_packets_0;
  wire [3:0] stat_tx_total_bytes_0;
  wire stat_tx_total_good_packets_0;
  wire [13:0] stat_tx_total_good_bytes_0;
  wire stat_tx_packet_64_bytes_0;
  wire stat_tx_packet_65_127_bytes_0;
  wire stat_tx_packet_128_255_bytes_0;
  wire stat_tx_packet_256_511_bytes_0;
  wire stat_tx_packet_512_1023_bytes_0;
  wire stat_tx_packet_1024_1518_bytes_0;
  wire stat_tx_packet_1519_1522_bytes_0;
  wire stat_tx_packet_1523_1548_bytes_0;
  wire stat_tx_packet_small_0;
  wire stat_tx_packet_large_0;
  wire stat_tx_packet_1549_2047_bytes_0;
  wire stat_tx_packet_2048_4095_bytes_0;
  wire stat_tx_packet_4096_8191_bytes_0;
  wire stat_tx_packet_8192_9215_bytes_0;
  wire stat_tx_bad_fcs_0;
  wire stat_tx_frame_error_0;
  wire stat_tx_local_fault_0;



  // assign completion_status = {stat_rx_total_packets_0, stat_rx_bad_code_0, stat_rx_framing_err_0, stat_rx_block_lock_0};


   wire gtwiz_reset_tx_datapath_0;
   wire gtwiz_reset_rx_datapath_0;
   assign gtwiz_reset_tx_datapath_0 = 1'b0; 
   assign gtwiz_reset_rx_datapath_0 = 1'b0; 
   wire gtpowergood_out_0;
   wire [2:0] txoutclksel_in_0;
   wire [2:0] rxoutclksel_in_0;

   assign txoutclksel_in_0 = 3'b101;    // this value should not be changed as per gtwizard 
   assign rxoutclksel_in_0 = 3'b101;    // this value should not be changed as per gtwizard
   
   

  wire  [4:0 ]completion_status_0;
  wire  gt_refclk_out;
  
  
  assign rx_reset_0 = sys_reset;
  assign ctl_rx_enable_0              = 1'b1;
  assign ctl_rx_check_preamble_0      = 1'b1;
  assign ctl_rx_check_sfd_0           = 1'b1;
  assign ctl_rx_force_resync_0        = 1'b0;
  assign ctl_rx_delete_fcs_0          = 1'b1;
  assign ctl_rx_ignore_fcs_0          = 1'b0;
  assign ctl_rx_process_lfi_0         = 1'b0;
  assign ctl_rx_test_pattern_0        = 1'b0;
  assign ctl_rx_test_pattern_enable_0 = 1'b0;
  assign ctl_rx_data_pattern_select_0 = 1'b0;
  assign ctl_rx_max_packet_len_0      = 15'd1536;
  assign ctl_rx_min_packet_len_0      = 15'd42;
  assign ctl_rx_custom_preamble_enable_0 = 1'b0;
  
   assign tx_reset_0                   = sys_reset;
 
   assign ctl_tx_enable_0              = 1'b1;
   assign ctl_tx_send_rfi_0            = 1'b0;
   assign ctl_tx_send_lfi_0            = 1'b0;
   assign ctl_tx_send_idle_0           = 1'b0;
   assign ctl_tx_fcs_ins_enable_0      = 1'b1;
   assign ctl_tx_ignore_fcs_0          = 1'b0;
   assign ctl_tx_test_pattern_0        = 1'b0;
   assign ctl_tx_test_pattern_enable_0 = 1'b0;
   assign ctl_tx_data_pattern_select_0 = 1'b0;
   assign ctl_tx_test_pattern_select_0 = 1'b0;
   assign ctl_tx_test_pattern_seed_a_0 = 58'h0;
   assign ctl_tx_test_pattern_seed_b_0 = 58'h0;
   assign ctl_tx_custom_preamble_enable_0 = 1'b0;
   assign ctl_tx_ipg_value_0           = 4'd12;


   //assign rx_block_lock_led_0 = gtpowergood_out_0;//block_lock_led_0 & stat_rx_status_0;
   //assign rx_gt_locked_led_0 = user_rx_reset_0 | user_tx_reset_0 | restart_tx_rx_0;


   always @(posedge tx_clk_out_0) begin 
     tx_axis_tuser_0 <= 1'b0;
   end
/*
ethernet_ip ethernet_ip_10g
(
    .gt_rxp_in (gt_rxp_in),
    .gt_rxn_in (gt_rxn_in),
    .gt_txp_out (gt_txp_out),
    .gt_txn_out (gt_txn_out),
    .tx_clk_out_0 (tx_clk_out_0),
    .rx_core_clk_0 (rx_core_clk_0),
    .rx_clk_out_0 (rx_clk_out_0),

    .gt_loopback_in_0 (gt_loopback_in_0),
    .rx_reset_0 (rx_reset_0),
    .user_rx_reset_0 (user_rx_reset_0),
    .rxrecclkout_0 (rxrecclkout_0),


//// RX User Interface Signals
    .rx_axis_tvalid_0 (rx_axis_tvalid_0),
    .rx_axis_tdata_0 (rx_axis_tdata_0),
    .rx_axis_tlast_0 (rx_axis_tlast_0),
    .rx_axis_tkeep_0 (rx_axis_tkeep_0),
    .rx_axis_tuser_0 (rx_axis_tuser_0),
    .rx_preambleout_0 (rx_preambleout_0),


//// RX Control Signals
    .ctl_rx_test_pattern_0 (ctl_rx_test_pattern_0),
    .ctl_rx_test_pattern_enable_0 (ctl_rx_test_pattern_enable_0),
    .ctl_rx_data_pattern_select_0 (ctl_rx_data_pattern_select_0),
    .ctl_rx_enable_0 (ctl_rx_enable_0),
    .ctl_rx_delete_fcs_0 (ctl_rx_delete_fcs_0),
    .ctl_rx_ignore_fcs_0 (ctl_rx_ignore_fcs_0),
    .ctl_rx_max_packet_len_0 (ctl_rx_max_packet_len_0),
    .ctl_rx_min_packet_len_0 (ctl_rx_min_packet_len_0),
    .ctl_rx_custom_preamble_enable_0 (ctl_rx_custom_preamble_enable_0),
    .ctl_rx_check_sfd_0 (ctl_rx_check_sfd_0),
    .ctl_rx_check_preamble_0 (ctl_rx_check_preamble_0),
    .ctl_rx_process_lfi_0 (ctl_rx_process_lfi_0),
    .ctl_rx_force_resync_0 (ctl_rx_force_resync_0),




//// RX Stats Signals
    .stat_rx_block_lock_0 (stat_rx_block_lock_0),
    .stat_rx_framing_err_valid_0 (stat_rx_framing_err_valid_0),
    .stat_rx_framing_err_0 (stat_rx_framing_err_0),
    .stat_rx_hi_ber_0 (stat_rx_hi_ber_0),
    .stat_rx_valid_ctrl_code_0 (stat_rx_valid_ctrl_code_0),
    .stat_rx_bad_code_0 (stat_rx_bad_code_0),
    .stat_rx_total_packets_0 (stat_rx_total_packets_0),
    .stat_rx_total_good_packets_0 (stat_rx_total_good_packets_0),
    .stat_rx_total_bytes_0 (stat_rx_total_bytes_0),
    .stat_rx_total_good_bytes_0 (stat_rx_total_good_bytes_0),
    .stat_rx_packet_small_0 (stat_rx_packet_small_0),
    .stat_rx_jabber_0 (stat_rx_jabber_0),
    .stat_rx_packet_large_0 (stat_rx_packet_large_0),
    .stat_rx_oversize_0 (stat_rx_oversize_0),
    .stat_rx_undersize_0 (stat_rx_undersize_0),
    .stat_rx_toolong_0 (stat_rx_toolong_0),
    .stat_rx_fragment_0 (stat_rx_fragment_0),
    .stat_rx_packet_64_bytes_0 (stat_rx_packet_64_bytes_0),
    .stat_rx_packet_65_127_bytes_0 (stat_rx_packet_65_127_bytes_0),
    .stat_rx_packet_128_255_bytes_0 (stat_rx_packet_128_255_bytes_0),
    .stat_rx_packet_256_511_bytes_0 (stat_rx_packet_256_511_bytes_0),
    .stat_rx_packet_512_1023_bytes_0 (stat_rx_packet_512_1023_bytes_0),
    .stat_rx_packet_1024_1518_bytes_0 (stat_rx_packet_1024_1518_bytes_0),
    .stat_rx_packet_1519_1522_bytes_0 (stat_rx_packet_1519_1522_bytes_0),
    .stat_rx_packet_1523_1548_bytes_0 (stat_rx_packet_1523_1548_bytes_0),
    .stat_rx_bad_fcs_0 (stat_rx_bad_fcs_0),
    .stat_rx_packet_bad_fcs_0 (stat_rx_packet_bad_fcs_0),
    .stat_rx_stomped_fcs_0 (stat_rx_stomped_fcs_0),
    .stat_rx_packet_1549_2047_bytes_0 (stat_rx_packet_1549_2047_bytes_0),
    .stat_rx_packet_2048_4095_bytes_0 (stat_rx_packet_2048_4095_bytes_0),
    .stat_rx_packet_4096_8191_bytes_0 (stat_rx_packet_4096_8191_bytes_0),
    .stat_rx_packet_8192_9215_bytes_0 (stat_rx_packet_8192_9215_bytes_0),
    .stat_rx_bad_preamble_0 (stat_rx_bad_preamble_0),
    .stat_rx_bad_sfd_0 (stat_rx_bad_sfd_0),
    .stat_rx_got_signal_os_0 (stat_rx_got_signal_os_0),
    .stat_rx_test_pattern_mismatch_0 (stat_rx_test_pattern_mismatch_0),
    .stat_rx_truncated_0 (stat_rx_truncated_0),
    .stat_rx_local_fault_0 (stat_rx_local_fault_0),
    .stat_rx_remote_fault_0 (stat_rx_remote_fault_0),
    .stat_rx_internal_local_fault_0 (stat_rx_internal_local_fault_0),
    .stat_rx_received_local_fault_0 (stat_rx_received_local_fault_0),
   .stat_rx_status_0 (stat_rx_status_0),


    .tx_reset_0 (tx_reset_0),
    .user_tx_reset_0 (user_tx_reset_0),
//// TX User Interface Signals
    .tx_axis_tready_0 (tx_axis_tready_0),
    .tx_axis_tvalid_0 (tx_axis_tvalid_0),
    .tx_axis_tdata_0 (tx_axis_tdata_0),
    .tx_axis_tlast_0 (tx_axis_tlast_0),
    .tx_axis_tkeep_0 (tx_axis_tkeep_0),
    .tx_axis_tuser_0 (tx_axis_tuser_0),
    .tx_unfout_0 (tx_unfout_0),
    .tx_preamblein_0 (0),//tx_preamblein_0),

//// TX Control Signals
    .ctl_tx_test_pattern_0 (ctl_tx_test_pattern_0),
    .ctl_tx_test_pattern_enable_0 (ctl_tx_test_pattern_enable_0),
    .ctl_tx_test_pattern_select_0 (ctl_tx_test_pattern_select_0),
    .ctl_tx_data_pattern_select_0 (ctl_tx_data_pattern_select_0),
    .ctl_tx_test_pattern_seed_a_0 (ctl_tx_test_pattern_seed_a_0),
    .ctl_tx_test_pattern_seed_b_0 (ctl_tx_test_pattern_seed_b_0),
    .ctl_tx_enable_0 (ctl_tx_enable_0),
    .ctl_tx_fcs_ins_enable_0 (ctl_tx_fcs_ins_enable_0),
    .ctl_tx_ipg_value_0 (ctl_tx_ipg_value_0),
    .ctl_tx_send_lfi_0 (ctl_tx_send_lfi_0),
    .ctl_tx_send_rfi_0 (ctl_tx_send_rfi_0),
    .ctl_tx_send_idle_0 (ctl_tx_send_idle_0),
    .ctl_tx_custom_preamble_enable_0 (ctl_tx_custom_preamble_enable_0),
    .ctl_tx_ignore_fcs_0 (ctl_tx_ignore_fcs_0),


//// TX Stats Signals
    .stat_tx_total_packets_0 (stat_tx_total_packets_0),
    .stat_tx_total_bytes_0 (stat_tx_total_bytes_0),
    .stat_tx_total_good_packets_0 (stat_tx_total_good_packets_0),
    .stat_tx_total_good_bytes_0 (stat_tx_total_good_bytes_0),
    .stat_tx_packet_64_bytes_0 (stat_tx_packet_64_bytes_0),
    .stat_tx_packet_65_127_bytes_0 (stat_tx_packet_65_127_bytes_0),
    .stat_tx_packet_128_255_bytes_0 (stat_tx_packet_128_255_bytes_0),
    .stat_tx_packet_256_511_bytes_0 (stat_tx_packet_256_511_bytes_0),
    .stat_tx_packet_512_1023_bytes_0 (stat_tx_packet_512_1023_bytes_0),
    .stat_tx_packet_1024_1518_bytes_0 (stat_tx_packet_1024_1518_bytes_0),
    .stat_tx_packet_1519_1522_bytes_0 (stat_tx_packet_1519_1522_bytes_0),
    .stat_tx_packet_1523_1548_bytes_0 (stat_tx_packet_1523_1548_bytes_0),
    .stat_tx_packet_small_0 (stat_tx_packet_small_0),
    .stat_tx_packet_large_0 (stat_tx_packet_large_0),
    .stat_tx_packet_1549_2047_bytes_0 (stat_tx_packet_1549_2047_bytes_0),
    .stat_tx_packet_2048_4095_bytes_0 (stat_tx_packet_2048_4095_bytes_0),
    .stat_tx_packet_4096_8191_bytes_0 (stat_tx_packet_4096_8191_bytes_0),
    .stat_tx_packet_8192_9215_bytes_0 (stat_tx_packet_8192_9215_bytes_0),
    .stat_tx_bad_fcs_0 (stat_tx_bad_fcs_0),
    .stat_tx_frame_error_0 (stat_tx_frame_error_0),
    .stat_tx_local_fault_0 (stat_tx_local_fault_0),



    .gtwiz_reset_tx_datapath_0 (gtwiz_reset_tx_datapath_0),
    .gtwiz_reset_rx_datapath_0 (gtwiz_reset_rx_datapath_0),
    .gtpowergood_out_0 (gtpowergood_out_0),
    .txoutclksel_in_0 (txoutclksel_in_0),
    .rxoutclksel_in_0 (rxoutclksel_in_0),
    .gt_refclk_p (gt_refclk_p),
    .gt_refclk_n (gt_refclk_n),
    .gt_refclk_out (gt_refclk_out),
    .sys_reset (sys_reset),
    .dclk (uclk)
);
*/



/*
 * RX Memory Signals
 */
 /*
// memory cmd streams
wire        axis_rxread_cmd_TVALID;
wire        axis_rxread_cmd_TREADY;
wire[71:0]  axis_rxread_cmd_TDATA;
wire        axis_rxwrite_cmd_TVALID;
wire        axis_rxwrite_cmd_TREADY;
wire[71:0]  axis_rxwrite_cmd_TDATA;
// memory sts streams
wire        axis_rxread_sts_TVALID;
wire        axis_rxread_sts_TREADY;
wire[7:0]   axis_rxread_sts_TDATA;
wire        axis_rxwrite_sts_TVALID;
wire        axis_rxwrite_sts_TREADY;
wire[31:0]  axis_rxwrite_sts_TDATA;
// memory data streams
wire        axis_rxread_data_TVALID;
wire        axis_rxread_data_TREADY;
wire[63:0]  axis_rxread_data_TDATA;
wire[7:0]   axis_rxread_data_TKEEP;
wire        axis_rxread_data_TLAST;

wire        axis_rxwrite_data_TVALID;
wire        axis_rxwrite_data_TREADY;
wire[63:0]  axis_rxwrite_data_TDATA;
wire[7:0]   axis_rxwrite_data_TKEEP;
wire        axis_rxwrite_data_TLAST;
*/

/*
 * TX Memory Signals
 */
// memory cmd streams
wire        axis_txread_cmd_TVALID;
wire        axis_txread_cmd_TREADY;
wire[71:0]  axis_txread_cmd_TDATA;
wire        axis_txwrite_cmd_TVALID;
wire        axis_txwrite_cmd_TREADY;
wire[71:0]  axis_txwrite_cmd_TDATA;
// memory sts streams
wire         axis_txread_sts_TVALID;
wire        axis_txread_sts_TREADY;
wire[7:0]   axis_txread_sts_TDATA;
wire         axis_txwrite_sts_TVALID;
wire        axis_txwrite_sts_TREADY;
wire[63:0]  axis_txwrite_sts_TDATA;
// memory data streams
wire         axis_txread_data_TVALID;
wire        axis_txread_data_TREADY;
wire[63:0]  axis_txread_data_TDATA;
wire[7:0]   axis_txread_data_TKEEP;
wire         axis_txread_data_TLAST;

wire        axis_txwrite_data_TVALID;
wire        axis_txwrite_data_TREADY;
wire[63:0]  axis_txwrite_data_TDATA;
wire[7:0]   axis_txwrite_data_TKEEP;
wire        axis_txwrite_data_TLAST;

/*
 * Application Signals
 */
 // listen&close port
  // open&close connection
wire        axis_listen_port_TVALID;
wire        axis_listen_port_TREADY;
wire[15:0]  axis_listen_port_TDATA;
wire        axis_listen_port_status_TVALID;
wire        axis_listen_port_status_TREADY;
wire[7:0]   axis_listen_port_status_TDATA;
//wire        axis_close_port_TVALID;
//wire        axis_close_port_TREADY;
//wire[15:0]  axis_close_port_TDATA;
 // notifications and pkg fetching
wire        axis_notifications_TVALID;
wire        axis_notifications_TREADY;
wire[87:0]  axis_notifications_TDATA;
wire        axis_read_package_TVALID;
wire        axis_read_package_TREADY;
wire[31:0]  axis_read_package_TDATA;
// open&close connection
wire        axis_open_connection_TVALID;
wire        axis_open_connection_TREADY;
wire[47:0]  axis_open_connection_TDATA;
wire        axis_open_status_TVALID;
wire        axis_open_status_TREADY;
wire[23:0]  axis_open_status_TDATA;
wire        axis_close_connection_TVALID;
wire        axis_close_connection_TREADY;
wire[15:0]  axis_close_connection_TDATA;
// rx data
wire        axis_rx_metadata_TVALID;
wire        axis_rx_metadata_TREADY;
wire[15:0]  axis_rx_metadata_TDATA;
wire        axis_rx_data_TVALID;
wire        axis_rx_data_TREADY;
 wire[63:0]  axis_rx_data_TDATA;
wire[7:0]   axis_rx_data_TKEEP;
wire        axis_rx_data_TLAST;
// tx data
wire        axis_tx_metadata_TVALID;
wire        axis_tx_metadata_TREADY;
wire[31:0]  axis_tx_metadata_TDATA;
wire        axis_tx_data_TVALID;
wire        axis_tx_data_TREADY;
wire[63:0]  axis_tx_data_TDATA;
wire[7:0]   axis_tx_data_TKEEP;
wire        axis_tx_data_TLAST;
wire        axis_tx_status_TVALID;
wire        axis_tx_status_TREADY;
wire[63:0]  axis_tx_status_TDATA;

/*
 * UDP APP Interface
 */
 // UDP port
 wire        axis_udp_open_port_tvalid;
 wire        axis_udp_open_port_tready;
 wire[15:0]  axis_udp_open_port_tdata;
 wire        axis_udp_open_port_status_tvalid;
 wire        axis_udp_open_port_status_tready;
 wire[7:0]   axis_udp_open_port_status_tdata; //actually only [0:0]
 
 // UDP RX
 wire        axis_udp_rx_data_tvalid;
 wire        axis_udp_rx_data_tready;
 wire[63:0]  axis_udp_rx_data_tdata;
 wire[7:0]   axis_udp_rx_data_tkeep;
 wire        axis_udp_rx_data_tlast;
 
 wire        axis_udp_rx_metadata_tvalid;
 wire        axis_udp_rx_metadata_tready;
 wire[95:0]  axis_udp_rx_metadata_tdata;
 
 // UDP TX
 wire        axis_udp_tx_data_tvalid;
 wire        axis_udp_tx_data_tready;
 wire[63:0]  axis_udp_tx_data_tdata;
 wire[7:0]   axis_udp_tx_data_tkeep;
 wire        axis_udp_tx_data_tlast;
 
 wire        axis_udp_tx_metadata_tvalid;
 wire        axis_udp_tx_metadata_tready;
 wire[95:0]  axis_udp_tx_metadata_tdata;
 
 wire        axis_udp_tx_length_tvalid;
 wire        axis_udp_tx_length_tready;
 wire[15:0]  axis_udp_tx_length_tdata;

reg runExperiment;
reg dualModeEn = 0;
reg[7:0] useConn = 8'h01;
reg[7:0] pkgWordCount = 8'h08;
reg[31:0] regIpAddress1 = 32'h00000000;
reg[15:0] numCons = 16'h0001;

wire[31:0] ip_address;
wire[15:0] regSessionCount_V;
wire regSessionCount_V_vld;

wire [161:0] debug_out;



reg ureset;
reg ureset1;
reg ureset2;





/*
////----------------------------------------------------------------------
//// The following process is used to pad outgoing packets to span at least
//// eight words. Weirdly, if I set a keep value less then 0x0F on the eigtht
//// word, the packet will be dropped by the switch.
////----------------------------------------------------------------------
reg waiting_first;
reg[9:0] words;
wire pad_next;
reg padding;

always @(posedge uclk) begin 
  if (ureset) begin
    waiting_first <= 1;
    words <= 1;  
    padding <= 0;
  end else begin
    if (padding==0 && tx_axis_tvalid_oc==1 & tx_axis_tready_oc==1) begin
      waiting_first <= 0;
      words <= words+1;
      if (tx_axis_tlast_oc==1 && words<8) begin
        padding <= 1;
      end
    end

    if (padding==1 & tx_axis_tready_int==1) begin
      words <= words+1;
      if (words==8) begin
        padding <= 0;
        words <= 1;
        waiting_first <= 1;
      end
    end
  end
end

assign pad_next = ~waiting_first & words<8 & tx_axis_tlast_oc & tx_axis_tvalid_oc & tx_axis_tready_oc;


assign tx_axis_tvalid_int = padding ? 1'b1 : tx_axis_tvalid_oc;
// below I set the keep of the eight word at least to 0x0F otherwise it will be dropped by the switch...
assign tx_axis_tkeep_int = (pad_next | padding) ? (words==8 ? 8'h0F : 8'hFF) : ((tx_axis_tlast_oc && tx_axis_tkeep_oc<8'h0F) ? 8'h0F : tx_axis_tkeep_oc);
assign tx_axis_tdata_int = padding ? 64'd0 : tx_axis_tdata_oc;
assign tx_axis_tlast_int = (pad_next | padding) ? (words==8 ? 1'b1 : 1'b0) : tx_axis_tlast_oc;
assign tx_axis_tready_oc = padding ? 1'b0 : tx_axis_tready_int;


  wire tx_axis_tready_after_tif;
  wire tx_axis_tvalid_after_tif;
  wire [63:0] tx_axis_tdata_after_tif;
  wire tx_axis_tlast_after_tif;
  wire [7:0] tx_axis_tkeep_after_tif;
  wire tx_axis_tuser_after_tif;

  tx_interface tx_inf
(
    .axi_str_tdata_to_xgmac(tx_axis_tdata_after_tif),
    .axi_str_tkeep_to_xgmac(tx_axis_tkeep_after_tif),
    .axi_str_tvalid_to_xgmac(tx_axis_tvalid_after_tif),
    .axi_str_tlast_to_xgmac(tx_axis_tlast_after_tif),
    .axi_str_tuser_to_xgmac(tx_axis_tuser_after_tif),
    .axi_str_tready_from_xgmac(tx_axis_tready_after_tif),
    
    .axi_str_tdata_from_fifo(tx_axis_tdata_int),   
    .axi_str_tkeep_from_fifo(tx_axis_tkeep_int),   
    .axi_str_tvalid_from_fifo(tx_axis_tvalid_int),
    .axi_str_tready_to_fifo(tx_axis_tready_int),
    .axi_str_tlast_from_fifo(tx_axis_tlast_int),

    .user_clk(uclk),
    .reset(ureset)

);

axis_data_fifo_0 tx_crossing (
  .s_axis_aresetn(~ureset),          // input wire s_axis_aresetn
  .m_axis_aresetn(~user_tx_reset_0),          // input wire m_axis_aresetn
  .s_axis_aclk(uclk),                // input wire s_axis_aclk
  .s_axis_tvalid(tx_axis_tvalid_after_tif),            // input wire s_axis_tvalid
  .s_axis_tready(tx_axis_tready_after_tif),            // output wire s_axis_tready
  .s_axis_tdata(tx_axis_tdata_after_tif),              // input wire [63 : 0] s_axis_tdata
  .s_axis_tkeep(tx_axis_tkeep_after_tif),              // input wire [7 : 0] s_axis_tkeep
  .s_axis_tlast(tx_axis_tlast_after_tif),              // input wire s_axis_tlast
  .m_axis_aclk(tx_clk_out_0),                // input wire m_axis_aclk
  .m_axis_tvalid(tx_axis_tvalid_0),            // output wire m_axis_tvalid
  .m_axis_tready(tx_axis_tready_0),            // input wire m_axis_tready
  .m_axis_tdata(tx_axis_tdata_0),              // output wire [63 : 0] m_axis_tdata
  .m_axis_tkeep(tx_axis_tkeep_0),              // output wire [7 : 0] m_axis_tkeep
  .m_axis_tlast(tx_axis_tlast_0),              // output wire m_axis_tlast
  .axis_data_count(),        // output wire [31 : 0] axis_data_count
  .axis_wr_data_count(),  // output wire [31 : 0] axis_wr_data_count
  .axis_rd_data_count()  // output wire [31 : 0] axis_rd_data_count
);

wire rx_axis_tready_0;

axis_data_fifo_0 rx_crossing (
  .s_axis_aresetn(~user_rx_reset_0),          // input wire s_axis_aresetn
  .m_axis_aresetn(~ureset),          // input wire m_axis_aresetn
  .s_axis_aclk(rx_core_clk_0),                // input wire s_axis_aclk
  .s_axis_tvalid(rx_axis_tvalid_0),            // input wire s_axis_tvalid
  .s_axis_tready(rx_axis_tready_0),            // output wire s_axis_tready
  .s_axis_tdata(rx_axis_tdata_0),              // input wire [63 : 0] s_axis_tdata
  .s_axis_tkeep(rx_axis_tkeep_0),              // input wire [7 : 0] s_axis_tkeep
  .s_axis_tlast(rx_axis_tlast_0),              // input wire s_axis_tlast
  .m_axis_aclk(uclk),                // input wire m_axis_aclk
  .m_axis_tvalid(rx_axis_tvalid_cross),            // output wire m_axis_tvalid
  .m_axis_tready(rx_axis_tready_cross),            // input wire m_axis_tready
  .m_axis_tdata(rx_axis_tdata_cross),              // output wire [63 : 0] m_axis_tdata
  .m_axis_tkeep(rx_axis_tkeep_cross),              // output wire [7 : 0] m_axis_tkeep
  .m_axis_tlast(rx_axis_tlast_cross),              // output wire m_axis_tlast
  .axis_data_count(),        // output wire [31 : 0] axis_data_count
  .axis_wr_data_count(),  // output wire [31 : 0] axis_wr_data_count
  .axis_rd_data_count()  // output wire [31 : 0] axis_rd_data_count
);

assign rx_axis_tready_cross = 1'b1; // the rx_interface does not assert backpressure!

rx_interface rx_if    
(
    .axi_str_tdata_from_xgmac(rx_axis_tdata_cross),
    .axi_str_tkeep_from_xgmac(rx_axis_tkeep_cross),
    .axi_str_tvalid_from_xgmac(rx_axis_tvalid_cross),
    .axi_str_tlast_from_xgmac(rx_axis_tlast_cross),
    .axi_str_tuser_from_xgmac(rx_axis_tuser_cross),

    .axi_str_tready_from_fifo(rx_axis_tready_oc),
    .axi_str_tdata_to_fifo(rx_axis_tdata_oc),   
    .axi_str_tkeep_to_fifo(rx_axis_tkeep_oc),   
    .axi_str_tvalid_to_fifo(rx_axis_tvalid_oc),
    .axi_str_tlast_to_fifo(rx_axis_tlast_oc),
    .rd_pkt_len(),
    .rx_fifo_overflow(),
    
    .rx_statistics_vector(),
    .rx_statistics_valid(),

    .rd_data_count(),

    .user_clk(uclk),
    .reset(ureset)

);*/



network_module network_module_inst
(
    .dclk (dclk),
    .net_clk(uclk),
    .sys_reset (sys_reset),
    .aresetn(~ureset),
    .network_init_done(),
    
    .gt_refclk_p(gt_refclk_p),
    .gt_refclk_n(gt_refclk_n),
    
    .gt_rxp_in(gt_rxp_in),
    .gt_rxn_in(gt_rxn_in),
    .gt_txp_out(gt_txp_out),
    .gt_txn_out(gt_txn_out),
    
    .user_rx_reset(user_rx_reset_0),
    .user_tx_reset(user_tx_reset_0),
    .gtpowergood_out(gtpowergood_out_0),
    
    //master 0
     .m_axis_0_tvalid(rx_axis_tvalid_oc),
     .m_axis_0_tready(rx_axis_tready_oc),
     .m_axis_0_tdata(rx_axis_tdata_oc),
     .m_axis_0_tkeep(rx_axis_tkeep_oc),
     .m_axis_0_tlast(rx_axis_tlast_oc),
         
     //slave 0
     .s_axis_0_tvalid(tx_axis_tvalid_oc),
     .s_axis_0_tready(tx_axis_tready_oc),
     .s_axis_0_tdata(tx_axis_tdata_oc),
     .s_axis_0_tkeep(tx_axis_tkeep_oc),
     .s_axis_0_tlast(tx_axis_tlast_oc)
    

);

wire[3:0] trig_boardnum;

vio_boardnumber vio_bnum (
	.clk(uclk),
	.probe_out0(trig_boardnum)
);



network_stack #(
    .MAC_ADDRESS    (48'hE59D02350A00), //bytes reversed
    //.IP_ADDRESS     (32'hd0d4010b),//(32'hD1D4010A), //reverse
    .IP_SUBNET_MASK     (32'h00FFFFFF), //reverse
    .IP_DEFAULT_GATEWAY   (32'h01d4010b)   //(32'h01D4010A), //reverse
)
tcp_ip_inst (
.aclk           (uclk),
//.reset           (reset),
.aresetn           (~ureset),
// network interface streams
.AXI_M_Stream_TVALID           (tx_axis_tvalid_oc),
.AXI_M_Stream_TREADY           (tx_axis_tready_oc),
.AXI_M_Stream_TDATA           (tx_axis_tdata_oc),
.AXI_M_Stream_TKEEP           (tx_axis_tkeep_oc),
.AXI_M_Stream_TLAST           (tx_axis_tlast_oc),

.AXI_S_Stream_TVALID           (rx_axis_tvalid_oc),
.AXI_S_Stream_TREADY          (rx_axis_tready_oc),
.AXI_S_Stream_TDATA           (rx_axis_tdata_oc),
.AXI_S_Stream_TKEEP           (rx_axis_tkeep_oc),
.AXI_S_Stream_TLAST           (rx_axis_tlast_oc),
/*
// memory rx cmd streams
.m_axis_rxread_cmd_TVALID           (axis_rxread_cmd_TVALID),
.m_axis_rxread_cmd_TREADY           (axis_rxread_cmd_TREADY),
.m_axis_rxread_cmd_TDATA           (axis_rxread_cmd_TDATA),
.m_axis_rxwrite_cmd_TVALID           (axis_rxwrite_cmd_TVALID),
.m_axis_rxwrite_cmd_TREADY           (axis_rxwrite_cmd_TREADY),
.m_axis_rxwrite_cmd_TDATA           (axis_rxwrite_cmd_TDATA),
// memory rx status streams
.s_axis_rxread_sts_TVALID           (axis_rxread_sts_TVALID),
.s_axis_rxread_sts_TREADY           (axis_rxread_sts_TREADY),
.s_axis_rxread_sts_TDATA           (axis_rxread_sts_TDATA),
.s_axis_rxwrite_sts_TVALID           (axis_rxwrite_sts_TVALID),
.s_axis_rxwrite_sts_TREADY           (axis_rxwrite_sts_TREADY),
.s_axis_rxwrite_sts_TDATA           (axis_rxwrite_sts_TDATA),
// memory rx data streams
.s_axis_rxread_data_TVALID           (axis_rxread_data_TVALID),
.s_axis_rxread_data_TREADY           (axis_rxread_data_TREADY),
.s_axis_rxread_data_TDATA           (axis_rxread_data_TDATA),
.s_axis_rxread_data_TKEEP           (axis_rxread_data_TKEEP),
.s_axis_rxread_data_TLAST           (axis_rxread_data_TLAST),
.m_axis_rxwrite_data_TVALID           (axis_rxwrite_data_TVALID),
.m_axis_rxwrite_data_TREADY           (axis_rxwrite_data_TREADY),
.m_axis_rxwrite_data_TDATA           (axis_rxwrite_data_TDATA),
.m_axis_rxwrite_data_TKEEP           (axis_rxwrite_data_TKEEP),
.m_axis_rxwrite_data_TLAST           (axis_rxwrite_data_TLAST),
*/
// memory tx cmd streams
.m_axis_txread_cmd_TVALID           (axis_txread_cmd_TVALID),
.m_axis_txread_cmd_TREADY           (axis_txread_cmd_TREADY),
.m_axis_txread_cmd_TDATA           (axis_txread_cmd_TDATA),
.m_axis_txwrite_cmd_TVALID           (axis_txwrite_cmd_TVALID),
.m_axis_txwrite_cmd_TREADY           (axis_txwrite_cmd_TREADY),
.m_axis_txwrite_cmd_TDATA           (axis_txwrite_cmd_TDATA),
// memory tx status streams
/*.s_axis_txread_sts_TVALID           (axis_txread_sts_TVALID),
.s_axis_txread_sts_TREADY           (axis_txread_sts_TREADY),
.s_axis_txread_sts_TDATA           (axis_txread_sts_TDATA),*/
.s_axis_txwrite_sts_TVALID           (axis_txwrite_sts_TVALID),
.s_axis_txwrite_sts_TREADY           (axis_txwrite_sts_TREADY),
.s_axis_txwrite_sts_TDATA           (axis_txwrite_sts_TDATA),
// memory tx data streams
.s_axis_txread_data_TVALID           (axis_txread_data_TVALID),
.s_axis_txread_data_TREADY           (axis_txread_data_TREADY),
.s_axis_txread_data_TDATA           (axis_txread_data_TDATA),
.s_axis_txread_data_TKEEP           (axis_txread_data_TKEEP),
.s_axis_txread_data_TLAST           (axis_txread_data_TLAST),
.m_axis_txwrite_data_TVALID           (axis_txwrite_data_TVALID),
.m_axis_txwrite_data_TREADY           (axis_txwrite_data_TREADY),
.m_axis_txwrite_data_TDATA           (axis_txwrite_data_TDATA),
.m_axis_txwrite_data_TKEEP           (axis_txwrite_data_TKEEP),
.m_axis_txwrite_data_TLAST           (axis_txwrite_data_TLAST),

//application interface streams
.m_axis_listen_port_status_TVALID       (axis_listen_port_status_TVALID),
.m_axis_listen_port_status_TREADY       (axis_listen_port_status_TREADY),
.m_axis_listen_port_status_TDATA        (axis_listen_port_status_TDATA),
.m_axis_notifications_TVALID            (axis_notifications_TVALID),
.m_axis_notifications_TREADY            (axis_notifications_TREADY),
.m_axis_notifications_TDATA             (axis_notifications_TDATA),
.m_axis_open_status_TVALID              (axis_open_status_TVALID),
.m_axis_open_status_TREADY              (axis_open_status_TREADY),
.m_axis_open_status_TDATA               (axis_open_status_TDATA),
.m_axis_rx_data_TVALID              (axis_rx_data_TVALID),
.m_axis_rx_data_TREADY              (axis_rx_data_TREADY), 
.m_axis_rx_data_TDATA               (axis_rx_data_TDATA),
.m_axis_rx_data_TKEEP               (axis_rx_data_TKEEP),
.m_axis_rx_data_TLAST               (axis_rx_data_TLAST),
.m_axis_rx_metadata_TVALID          (axis_rx_metadata_TVALID),
.m_axis_rx_metadata_TREADY          (axis_rx_metadata_TREADY),
.m_axis_rx_metadata_TDATA           (axis_rx_metadata_TDATA),
.m_axis_tx_status_TVALID            (axis_tx_status_TVALID),
.m_axis_tx_status_TREADY            (axis_tx_status_TREADY),
.m_axis_tx_status_TDATA             (axis_tx_status_TDATA),
.s_axis_listen_port_TVALID          (axis_listen_port_TVALID),
.s_axis_listen_port_TREADY          (axis_listen_port_TREADY),
.s_axis_listen_port_TDATA           (axis_listen_port_TDATA),

.s_axis_close_connection_TVALID           (axis_close_connection_TVALID),
.s_axis_close_connection_TREADY           (axis_close_connection_TREADY),
.s_axis_close_connection_TDATA           (axis_close_connection_TDATA),
.s_axis_open_connection_TVALID          (axis_open_connection_TVALID),
.s_axis_open_connection_TREADY          (axis_open_connection_TREADY),
.s_axis_open_connection_TDATA           (axis_open_connection_TDATA),
.s_axis_read_package_TVALID             (axis_read_package_TVALID),
.s_axis_read_package_TREADY             (axis_read_package_TREADY),
.s_axis_read_package_TDATA              (axis_read_package_TDATA),
.s_axis_tx_data_TVALID                  (axis_tx_data_TVALID),
.s_axis_tx_data_TREADY                  (axis_tx_data_TREADY),
.s_axis_tx_data_TDATA                   (axis_tx_data_TDATA),
.s_axis_tx_data_TKEEP                   (axis_tx_data_TKEEP),
.s_axis_tx_data_TLAST                   (axis_tx_data_TLAST),
.s_axis_tx_metadata_TVALID              (axis_tx_metadata_TVALID),
.s_axis_tx_metadata_TREADY              (axis_tx_metadata_TREADY),
.s_axis_tx_metadata_TDATA               (axis_tx_metadata_TDATA),
    
.ip_address_in(32'hd0d4010b),

.ip_address_out(ip_address),
.regSessionCount_V(regSessionCount_V),
.regSessionCount_V_ap_vld(regSessionCount_V_vld),

.board_number(trig_boardnum),
.subnet_number(2'b00)

);


////////////////////////////////////////////////////////////////
// disconnect the tcp from the memory
////////////////////////////////////////////////////////////////

/*
assign axis_txread_cmd_TREADY = 1;

assign axis_txread_sts_TDATA = 0;

always @(posedge uclk) begin
  axis_txread_sts_TVALID <= axis_txread_cmd_TVALID; 
  axis_txread_data_TVALID <= axis_txread_cmd_TVALID;
  axis_txread_data_TLAST <= axis_txread_cmd_TVALID;
  axis_txread_data_TKEEP <= 8'hff;
  
  axis_txread_data_TDATA <= 0;
  if (axis_txread_cmd_TVALID==1) begin
     axis_txread_data_TDATA <= axis_txread_cmd_TDATA;     
  end 
  
end


assign axis_txwrite_cmd_TREADY = 1;
assign axis_txwrite_data_TREADY = 1;

assign axis_txwrite_sts_TDATA = 32'hffffffff;

always @(posedge uclk) begin
  axis_txwrite_sts_TVALID <= axis_txwrite_cmd_TVALID;    
end

*/
/*
 * Application Module
 */
 
 
   wire [511:0] ht_dramRdData_data;
     wire          ht_dramRdData_empty;
     wire          ht_dramRdData_almost_empty;
    wire          ht_dramRdData_read;


    wire [63:0] ht_cmd_dramRdData_data;
    wire        ht_cmd_dramRdData_valid;
     wire        ht_cmd_dramRdData_stall;


    wire [511:0] ht_dramWrData_data;
    wire          ht_dramWrData_valid;
     wire          ht_dramWrData_stall;


    wire [63:0] ht_cmd_dramWrData_data;
    wire        ht_cmd_dramWrData_valid;
     wire        ht_cmd_dramWrData_stall;
     

     
   wire [511:0] upd_dramRdData_data;
   wire          upd_dramRdData_empty;
   wire          upd_dramRdData_almost_empty;
  wire          upd_dramRdData_read;

 
  wire [63:0] upd_cmd_dramRdData_data;
  wire        upd_cmd_dramRdData_valid;
   wire        upd_cmd_dramRdData_stall;

 
  wire [511:0] upd_dramWrData_data;
  wire          upd_dramWrData_valid;
   wire          upd_dramWrData_stall;

 
  wire [63:0] upd_cmd_dramWrData_data;
  wire        upd_cmd_dramWrData_valid;
   wire        upd_cmd_dramWrData_stall;    


  wire [63:0] ptr_rdcmd_data;
  wire         ptr_rdcmd_valid;
  wire         ptr_rdcmd_ready;

  wire [512-1:0]  ptr_rd_data;
  wire         ptr_rd_valid;
  wire         ptr_rd_ready; 

  wire [512-1:0] ptr_wr_data;
  wire         ptr_wr_valid;
  wire         ptr_wr_ready;

  wire [63:0] ptr_wrcmd_data;
  wire         ptr_wrcmd_valid;
  wire         ptr_wrcmd_ready;


  wire [63:0] bmap_rdcmd_data;
  wire         bmap_rdcmd_valid;
  wire         bmap_rdcmd_ready;

  wire [512-1:0]  bmap_rd_data;
  wire         bmap_rd_valid;
  wire         bmap_rd_ready; 

  wire [512-1:0] bmap_wr_data;
  wire         bmap_wr_valid;
  wire         bmap_wr_ready;

  wire [63:0] bmap_wrcmd_data;
  wire         bmap_wrcmd_valid;
  wire         bmap_wrcmd_ready;




//DRAM MEM interface



//wire clk233;
wire clk200, clk200_i;
wire c0_init_calib_complete;
wire c1_init_calib_complete;

//toe stream interface signals
wire           toeTX_s_axis_read_cmd_tvalid;
wire          toeTX_s_axis_read_cmd_tready;
wire[71:0]     toeTX_s_axis_read_cmd_tdata;
//read status
wire          toeTX_m_axis_read_sts_tvalid;
wire           toeTX_m_axis_read_sts_tready;
wire[7:0]     toeTX_m_axis_read_sts_tdata;
//read stream
wire[63:0]    toeTX_m_axis_read_tdata;
wire[7:0]     toeTX_m_axis_read_tkeep;
wire          toeTX_m_axis_read_tlast;
wire          toeTX_m_axis_read_tvalid;
wire           toeTX_m_axis_read_tready;

//write commands
wire           toeTX_s_axis_write_cmd_tvalid;
wire          toeTX_s_axis_write_cmd_tready;
wire[71:0]     toeTX_s_axis_write_cmd_tdata;
//write status
wire          toeTX_m_axis_write_sts_tvalid;
wire           toeTX_m_axis_write_sts_tready;
wire[31:0]     toeTX_m_axis_write_sts_tdata;
//write stream
wire[63:0]     toeTX_s_axis_write_tdata;
wire[7:0]      toeTX_s_axis_write_tkeep;
wire           toeTX_s_axis_write_tlast;
wire           toeTX_s_axis_write_tvalid;
wire          toeTX_s_axis_write_tready;

//upd stream interface signals
wire           upd_s_axis_read_cmd_tvalid;
wire          upd_s_axis_read_cmd_tready;
wire[71:0]     upd_s_axis_read_cmd_tdata;
//read status
wire          upd_m_axis_read_sts_tvalid;
wire           upd_m_axis_read_sts_tready;
wire[7:0]     upd_m_axis_read_sts_tdata;
//read stream
wire[511:0]    upd_m_axis_read_tdata;
wire[63:0]     upd_m_axis_read_tkeep;
wire          upd_m_axis_read_tlast;
wire          upd_m_axis_read_tvalid;
wire           upd_m_axis_read_tready;

//write commands
wire           upd_s_axis_write_cmd_tvalid;
wire          upd_s_axis_write_cmd_tready;
wire[71:0]     upd_s_axis_write_cmd_tdata;
//write status
wire          upd_m_axis_write_sts_tvalid;
wire           upd_m_axis_write_sts_tready;
wire[31:0]     upd_m_axis_write_sts_tdata;
//write stream
wire[511:0]     upd_s_axis_write_tdata;
wire[63:0]      upd_s_axis_write_tkeep;
wire           upd_s_axis_write_tlast;
wire           upd_s_axis_write_tvalid;
wire          upd_s_axis_write_tready;

wire[511:0]     upd_s_axis_write_tdata_x;
wire[63:0]      upd_s_axis_write_tkeep_x;
wire           upd_s_axis_write_tlast_x;
wire           upd_s_axis_write_tvalid_x;
wire          upd_s_axis_write_tready_x;


muu_TopWrapper_fclk multiuser_kvs_top  (
//zookeeper_tcp_top_parallel_nkv nkv_TopWrapper (
  .m_axis_open_connection_TVALID(axis_open_connection_TVALID),
  .m_axis_open_connection_TDATA(axis_open_connection_TDATA),
  .m_axis_open_connection_TREADY(axis_open_connection_TREADY),
  .m_axis_close_connection_TVALID(axis_close_connection_TVALID),
  .m_axis_close_connection_TDATA(axis_close_connection_TDATA),
  .m_axis_close_connection_TREADY(axis_close_connection_TREADY),
  .m_axis_listen_port_TVALID(axis_listen_port_TVALID),                // output wire m_axis_listen_port_TVALID
  .m_axis_listen_port_TREADY(axis_listen_port_TREADY),                // input wire m_axis_listen_port_TREADY
  .m_axis_listen_port_TDATA(axis_listen_port_TDATA),                  // output wire [15 : 0] m_axis_listen_port_TDATA
  .m_axis_read_package_TVALID(axis_read_package_TVALID),              // output wire m_axis_read_package_TVALID
  .m_axis_read_package_TREADY(axis_read_package_TREADY),              // input wire m_axis_read_package_TREADY
  .m_axis_read_package_TDATA(axis_read_package_TDATA),                // output wire [31 : 0] m_axis_read_package_TDATA
  .m_axis_tx_data_TVALID(axis_tx_data_TVALID),                        // output wire m_axis_tx_data_TVALID
  .m_axis_tx_data_TREADY(axis_tx_data_TREADY),                        // input wire m_axis_tx_data_TREADY
  .m_axis_tx_data_TDATA(axis_tx_data_TDATA),                          // output wire [63 : 0] m_axis_tx_data_TDATA
  .m_axis_tx_data_TKEEP(axis_tx_data_TKEEP),                          // output wire [7 : 0] m_axis_tx_data_TKEEP
  .m_axis_tx_data_TLAST(axis_tx_data_TLAST),                          // output wire [0 : 0] m_axis_tx_data_TLAST
  .m_axis_tx_metadata_TVALID(axis_tx_metadata_TVALID),                // output wire m_axis_tx_metadata_TVALID
  .m_axis_tx_metadata_TREADY(axis_tx_metadata_TREADY),                // input wire m_axis_tx_metadata_TREADY
  .m_axis_tx_metadata_TDATA(axis_tx_metadata_TDATA),                  // output wire [15 : 0] m_axis_tx_metadata_TDATA
  .s_axis_listen_port_status_TVALID(axis_listen_port_status_TVALID),  // input wire s_axis_listen_port_status_TVALID
  .s_axis_listen_port_status_TREADY(axis_listen_port_status_TREADY),  // output wire s_axis_listen_port_status_TREADY
  .s_axis_listen_port_status_TDATA(axis_listen_port_status_TDATA),    // input wire [7 : 0] s_axis_listen_port_status_TDATA
  .s_axis_open_status_TVALID(axis_open_status_TVALID),
  .s_axis_open_status_TDATA(axis_open_status_TDATA),
  .s_axis_open_status_TREADY(axis_open_status_TREADY),
  .s_axis_notifications_TVALID(axis_notifications_TVALID),            // input wire s_axis_notifications_TVALID
  .s_axis_notifications_TREADY(axis_notifications_TREADY),            // output wire s_axis_notifications_TREADY
  .s_axis_notifications_TDATA(axis_notifications_TDATA),              // input wire [87 : 0] s_axis_notifications_TDATA
  .s_axis_rx_data_TVALID(axis_rx_data_TVALID),                        // input wire s_axis_rx_data_TVALID
  .s_axis_rx_data_TREADY(axis_rx_data_TREADY),                        // output wire s_axis_rx_data_TREADY
  .s_axis_rx_data_TDATA(axis_rx_data_TDATA),                          // input wire [63 : 0] s_axis_rx_data_TDATA
  .s_axis_rx_data_TKEEP(axis_rx_data_TKEEP),                          // input wire [7 : 0] s_axis_rx_data_TKEEP
  .s_axis_rx_data_TLAST(axis_rx_data_TLAST),                          // input wire [0 : 0] s_axis_rx_data_TLAST
  .s_axis_rx_metadata_TVALID(axis_rx_metadata_TVALID),                // input wire s_axis_rx_metadata_TVALID
  .s_axis_rx_metadata_TREADY(axis_rx_metadata_TREADY),                // output wire s_axis_rx_metadata_TREADY
  .s_axis_rx_metadata_TDATA(axis_rx_metadata_TDATA),                  // input wire [15 : 0] s_axis_rx_metadata_TDATA
  .s_axis_tx_status_TVALID(axis_tx_status_TVALID),                    // input wire s_axis_tx_status_TVALID
  .s_axis_tx_status_TREADY(axis_tx_status_TREADY),                    // output wire s_axis_tx_status_TREADY
  .s_axis_tx_status_TDATA(axis_tx_status_TDATA),                      // input wire [23 : 0] s_axis_tx_status_TDATA


  
  .ht_dramRdData_data(ht_dramRdData_data),
  .ht_dramRdData_empty(ht_dramRdData_empty),
  .ht_dramRdData_almost_empty(ht_dramRdData_almost_empty),
  .ht_dramRdData_read(ht_dramRdData_read),
  
  .ht_cmd_dramRdData_data(ht_cmd_dramRdData_data),
  .ht_cmd_dramRdData_valid(ht_cmd_dramRdData_valid),
  .ht_cmd_dramRdData_stall(ht_cmd_dramRdData_stall),

  .ht_dramWrData_data(ht_dramWrData_data),
  .ht_dramWrData_valid(ht_dramWrData_valid),
  .ht_dramWrData_stall(ht_dramWrData_stall),
  
  .ht_cmd_dramWrData_data(ht_cmd_dramWrData_data),
  .ht_cmd_dramWrData_valid(ht_cmd_dramWrData_valid),
  .ht_cmd_dramWrData_stall(ht_cmd_dramWrData_stall),  
  
  // Update DRAM Connection  
  .upd_dramRdData_data(upd_dramRdData_data),
  .upd_dramRdData_empty(upd_dramRdData_empty),
  .upd_dramRdData_almost_empty(upd_dramRdData_almost_empty),
  .upd_dramRdData_read(upd_dramRdData_read),
  
  .upd_cmd_dramRdData_data(upd_cmd_dramRdData_data),
  .upd_cmd_dramRdData_valid(upd_cmd_dramRdData_valid),
  .upd_cmd_dramRdData_stall(upd_cmd_dramRdData_stall),
  
  .upd_dramWrData_data(upd_dramWrData_data),
  .upd_dramWrData_valid(upd_dramWrData_valid),
  .upd_dramWrData_stall(upd_dramWrData_stall),

  .upd_cmd_dramWrData_data(upd_cmd_dramWrData_data),
  .upd_cmd_dramWrData_valid(upd_cmd_dramWrData_valid),
  .upd_cmd_dramWrData_stall(upd_cmd_dramWrData_stall),  

  .ptr_rdcmd_data(ptr_rdcmd_data),
  .ptr_rdcmd_valid(ptr_rdcmd_valid),
  .ptr_rdcmd_ready(ptr_rdcmd_ready),

  .ptr_rd_data(ptr_rd_data),
  .ptr_rd_valid(ptr_rd_valid),
  .ptr_rd_ready(ptr_rd_ready),  

  .ptr_wr_data(ptr_wr_data),
  .ptr_wr_valid(ptr_wr_valid),
  .ptr_wr_ready(ptr_wr_ready),

  .ptr_wrcmd_data(ptr_wrcmd_data),
  .ptr_wrcmd_valid(ptr_wrcmd_valid),
  .ptr_wrcmd_ready(ptr_wrcmd_ready),


  .bmap_rdcmd_data(bmap_rdcmd_data),
  .bmap_rdcmd_valid(bmap_rdcmd_valid),
  .bmap_rdcmd_ready(bmap_rdcmd_ready),

  .bmap_rd_data(bmap_rd_data),
  .bmap_rd_valid(bmap_rd_valid),
  .bmap_rd_ready(bmap_rd_ready),  

  .bmap_wr_data(bmap_wr_data),
  .bmap_wr_valid(bmap_wr_valid),
  .bmap_wr_ready(bmap_wr_ready),

  .bmap_wrcmd_data(bmap_wrcmd_data),
  .bmap_wrcmd_valid(bmap_wrcmd_valid),
  .bmap_wrcmd_ready(bmap_wrcmd_ready), 
  
  .fclk(fclk),
  
  .aclk(uclk),                                                          // input wire aclk
  .aresetn(~ureset)                                                    // input wire aresetn
);



wire ddr3_calib_complete, init_calib_complete;
wire toeTX_compare_error, ht_compare_error, upd_compare_error;

//registers for crossing clock domains (from 233MHz to 156.25MHz)
reg c0_init_calib_complete_r1, c0_init_calib_complete_r2;
reg c1_init_calib_complete_r1, c1_init_calib_complete_r2;


//-

always @(posedge uclk) 
begin
    /*if (~ureset == 0) begin
        c0_init_calib_complete_r1 <= 1'b0;
        c0_init_calib_complete_r2 <= 1'b0;
        c1_init_calib_complete_r1 <= 1'b0;
        c1_init_calib_complete_r2 <= 1'b0;
    end
    else begin*/
        c0_init_calib_complete_r1 <= c0_init_calib_complete;
        c0_init_calib_complete_r2 <= c0_init_calib_complete_r1;
        c1_init_calib_complete_r1 <= c1_init_calib_complete;
        c1_init_calib_complete_r2 <= c1_init_calib_complete_r1;
    //end
end

assign ddr3_calib_complete = c0_init_calib_complete_r2 & c1_init_calib_complete_r2;
assign init_calib_complete = ddr3_calib_complete;
/*
 * TX Memory Signals
 */
// memory cmd streams
assign toeTX_s_axis_read_cmd_tvalid = axis_txread_cmd_TVALID;
assign axis_txread_cmd_TREADY = toeTX_s_axis_read_cmd_tready;
assign toeTX_s_axis_read_cmd_tdata = axis_txread_cmd_TDATA;
assign toeTX_s_axis_write_cmd_tvalid = axis_txwrite_cmd_TVALID;
assign axis_txwrite_cmd_TREADY = toeTX_s_axis_write_cmd_tready;
assign toeTX_s_axis_write_cmd_tdata = axis_txwrite_cmd_TDATA;
// memory sts streams
assign axis_txread_sts_TVALID         = toeTX_m_axis_read_sts_tvalid;
assign toeTX_m_axis_read_sts_tready = 1; //axis_txread_sts_TREADY;
assign axis_txread_sts_TDATA          = toeTX_m_axis_read_sts_tdata;
assign axis_txwrite_sts_TVALID        = toeTX_m_axis_write_sts_tvalid;
assign toeTX_m_axis_write_sts_tready    = axis_txwrite_sts_TREADY;
assign axis_txwrite_sts_TDATA         = toeTX_m_axis_write_sts_tdata;
// memory data streams
assign axis_txread_data_TVALID = toeTX_m_axis_read_tvalid;
assign toeTX_m_axis_read_tready = axis_txread_data_TREADY;
assign axis_txread_data_TDATA = toeTX_m_axis_read_tdata;
assign axis_txread_data_TKEEP = toeTX_m_axis_read_tkeep;
assign axis_txread_data_TLAST = toeTX_m_axis_read_tlast;

assign toeTX_s_axis_write_tvalid = axis_txwrite_data_TVALID;
assign axis_txwrite_data_TREADY = toeTX_s_axis_write_tready;
assign toeTX_s_axis_write_tdata = axis_txwrite_data_TDATA;
assign toeTX_s_axis_write_tkeep = axis_txwrite_data_TKEEP;
assign toeTX_s_axis_write_tlast = axis_txwrite_data_TLAST;

wire           toeRX_s_axis_read_cmd_tvalid;
wire          toeRX_s_axis_read_cmd_tready;
wire[71:0]     toeRX_s_axis_read_cmd_tdata;
//read status
wire          toeRX_m_axis_read_sts_tvalid;
wire           toeRX_m_axis_read_sts_tready;
wire[7:0]     toeRX_m_axis_read_sts_tdata;
//read stream
wire[63:0]    toeRX_m_axis_read_tdata;
wire[7:0]     toeRX_m_axis_read_tkeep;
wire          toeRX_m_axis_read_tlast;
wire          toeRX_m_axis_read_tvalid;
wire           toeRX_m_axis_read_tready;

//write commands
wire           toeRX_s_axis_write_cmd_tvalid;
wire          toeRX_s_axis_write_cmd_tready;
wire[71:0]     toeRX_s_axis_write_cmd_tdata;
//write status
wire          toeRX_m_axis_write_sts_tvalid;
wire           toeRX_m_axis_write_sts_tready;
wire[31:0]     toeRX_m_axis_write_sts_tdata;
//write stream
wire[63:0]     toeRX_s_axis_write_tdata;
wire[7:0]      toeRX_s_axis_write_tkeep;
wire           toeRX_s_axis_write_tlast;
wire           toeRX_s_axis_write_tvalid;
wire          toeRX_s_axis_write_tready;

/*
 * RX Memory Signals
 */
 /*
// memory cmd streams
assign toeRX_s_axis_read_cmd_tvalid = axis_rxread_cmd_TVALID;
assign axis_rxread_cmd_TREADY = toeRX_s_axis_read_cmd_tready;
assign toeRX_s_axis_read_cmd_tdata = axis_rxread_cmd_TDATA;
assign toeRX_s_axis_write_cmd_tvalid = axis_rxwrite_cmd_TVALID;
assign axis_rxwrite_cmd_TREADY = toeRX_s_axis_write_cmd_tready;
assign toeRX_s_axis_write_cmd_tdata = axis_rxwrite_cmd_TDATA;
// memory sts streams
assign axis_rxread_sts_TVALID = 1'b0; //toeRX_m_axis_read_sts_tvalid;
assign toeRX_m_axis_read_sts_tready = axis_rxread_sts_TREADY;
assign axis_rxread_sts_TDATA = toeRX_m_axis_read_sts_tdata;
assign axis_rxwrite_sts_TVALID = 1'b0; //toeRX_m_axis_write_sts_tvalid;
assign toeRX_m_axis_write_sts_tready = axis_rxwrite_sts_TREADY;
assign axis_rxwrite_sts_TDATA = toeRX_m_axis_write_sts_tdata;
// memory data streams
assign axis_rxread_data_TVALID = toeRX_m_axis_read_tvalid;
assign toeRX_m_axis_read_tready = axis_rxread_data_TREADY;
assign axis_rxread_data_TDATA = toeRX_m_axis_read_tdata;
assign axis_rxread_data_TKEEP = toeRX_m_axis_read_tkeep;
assign axis_rxread_data_TLAST = toeRX_m_axis_read_tlast;

assign toeRX_s_axis_write_tvalid = axis_rxwrite_data_TVALID;
assign axis_rxwrite_data_TREADY = toeRX_s_axis_write_tready;
assign toeRX_s_axis_write_tdata = axis_rxwrite_data_TDATA;
assign toeRX_s_axis_write_tkeep = axis_rxwrite_data_TKEEP;
assign toeRX_s_axis_write_tlast = axis_rxwrite_data_TLAST;
*/




assign upd_m_axis_read_sts_tready = 1'b1;
assign upd_m_axis_write_sts_tready = 1'b1;


/*
 * TCP DDR Memory Interface
 */
nkv_ddr4_mem_inf  mem_inf_inst
(
.sys_rst(sys_reset),

.clk156_25(uclk),
.reset156_25_n(~ureset),

.c0_init_calib_complete(c0_init_calib_complete),
.c0_sys_clk_p(c0_sys_clk_p),
.c0_sys_clk_n(c0_sys_clk_n),

.c0_ddr4_adr(c0_ddr4_adr),
.c0_ddr4_ba(c0_ddr4_ba),
.c0_ddr4_cke(c0_ddr4_cke),
.c0_ddr4_cs_n(c0_ddr4_cs_n),
.c0_ddr4_dq(c0_ddr4_dq),
.c0_ddr4_dqs_c(c0_ddr4_dqs_c),
.c0_ddr4_dqs_t(c0_ddr4_dqs_t),
.c0_ddr4_odt(c0_ddr4_odt),
.c0_ddr4_parity(c0_ddr4_parity),
.c0_ddr4_bg(c0_ddr4_bg),
.c0_ddr4_reset_n(c0_ddr4_reset_n),
.c0_ddr4_act_n(c0_ddr4_act_n),
.c0_ddr4_ck_c(c0_ddr4_ck_c),
.c0_ddr4_ck_t(c0_ddr4_ck_t),


.c1_init_calib_complete(c1_init_calib_complete),
.c1_sys_clk_p(c1_sys_clk_p),
.c1_sys_clk_n(c1_sys_clk_n),

.c1_ddr4_adr(c1_ddr4_adr),
.c1_ddr4_ba(c1_ddr4_ba),
.c1_ddr4_cke(c1_ddr4_cke),
.c1_ddr4_cs_n(c1_ddr4_cs_n),
.c1_ddr4_dq(c1_ddr4_dq),
.c1_ddr4_dqs_c(c1_ddr4_dqs_c),
.c1_ddr4_dqs_t(c1_ddr4_dqs_t),
.c1_ddr4_odt(c1_ddr4_odt),
.c1_ddr4_parity(c1_ddr4_parity),
.c1_ddr4_bg(c1_ddr4_bg),
.c1_ddr4_reset_n(c1_ddr4_reset_n),
.c1_ddr4_act_n(c1_ddr4_act_n),
.c1_ddr4_ck_c(c1_ddr4_ck_c),
.c1_ddr4_ck_t(c1_ddr4_ck_t),

//toe stream interface signals
.toeTX_s_axis_read_cmd_tvalid(toeTX_s_axis_read_cmd_tvalid),
.toeTX_s_axis_read_cmd_tready(toeTX_s_axis_read_cmd_tready),
.toeTX_s_axis_read_cmd_tdata(toeTX_s_axis_read_cmd_tdata),
//read status
.toeTX_m_axis_read_sts_tvalid(toeTX_m_axis_read_sts_tvalid),
.toeTX_m_axis_read_sts_tready(toeTX_m_axis_read_sts_tready),
.toeTX_m_axis_read_sts_tdata(toeTX_m_axis_read_sts_tdata),
//read stream
.toeTX_m_axis_read_tdata(toeTX_m_axis_read_tdata),
.toeTX_m_axis_read_tkeep(toeTX_m_axis_read_tkeep),
.toeTX_m_axis_read_tlast(toeTX_m_axis_read_tlast),
.toeTX_m_axis_read_tvalid(toeTX_m_axis_read_tvalid),
.toeTX_m_axis_read_tready(toeTX_m_axis_read_tready),

//write commands
.toeTX_s_axis_write_cmd_tvalid(toeTX_s_axis_write_cmd_tvalid),
.toeTX_s_axis_write_cmd_tready(toeTX_s_axis_write_cmd_tready),
.toeTX_s_axis_write_cmd_tdata(toeTX_s_axis_write_cmd_tdata),
//write status
.toeTX_m_axis_write_sts_tvalid(toeTX_m_axis_write_sts_tvalid),
.toeTX_m_axis_write_sts_tready(toeTX_m_axis_write_sts_tready),
.toeTX_m_axis_write_sts_tdata(toeTX_m_axis_write_sts_tdata),
//write stream
.toeTX_s_axis_write_tdata(toeTX_s_axis_write_tdata),
.toeTX_s_axis_write_tkeep(toeTX_s_axis_write_tkeep),
.toeTX_s_axis_write_tlast(toeTX_s_axis_write_tlast),
.toeTX_s_axis_write_tvalid(toeTX_s_axis_write_tvalid),
.toeTX_s_axis_write_tready(toeTX_s_axis_write_tready),

  // HashTable DRAM Connection

  .ht_dramRdData_data(ht_dramRdData_data),
  .ht_dramRdData_empty(ht_dramRdData_empty),
  .ht_dramRdData_almost_empty(ht_dramRdData_almost_empty),
  .ht_dramRdData_read(ht_dramRdData_read),
  
  .ht_cmd_dramRdData_data(ht_cmd_dramRdData_data),
  .ht_cmd_dramRdData_valid(ht_cmd_dramRdData_valid),
  .ht_cmd_dramRdData_stall(ht_cmd_dramRdData_stall),

  .ht_dramWrData_data(ht_dramWrData_data),
  .ht_dramWrData_valid(ht_dramWrData_valid),
  .ht_dramWrData_stall(ht_dramWrData_stall),
  
  .ht_cmd_dramWrData_data(ht_cmd_dramWrData_data),
  .ht_cmd_dramWrData_valid(ht_cmd_dramWrData_valid),
  .ht_cmd_dramWrData_stall(ht_cmd_dramWrData_stall),
  
  .upd_dramRdData_data(upd_dramRdData_data),
  .upd_dramRdData_empty(upd_dramRdData_empty),
  .upd_dramRdData_almost_empty(upd_dramRdData_almost_empty),
  .upd_dramRdData_read(upd_dramRdData_read),
  
  .upd_cmd_dramRdData_data(upd_cmd_dramRdData_data),
  .upd_cmd_dramRdData_valid(upd_cmd_dramRdData_valid),
  .upd_cmd_dramRdData_stall(upd_cmd_dramRdData_stall),
  
  .upd_dramWrData_data(upd_dramWrData_data),
  .upd_dramWrData_valid(upd_dramWrData_valid),
  .upd_dramWrData_stall(upd_dramWrData_stall),

  .upd_cmd_dramWrData_data(upd_cmd_dramWrData_data),
  .upd_cmd_dramWrData_valid(upd_cmd_dramWrData_valid),
  .upd_cmd_dramWrData_stall(upd_cmd_dramWrData_stall), 
  
   .ptr_rdcmd_data(ptr_rdcmd_data),
   .ptr_rdcmd_valid(ptr_rdcmd_valid),
   .ptr_rdcmd_ready(ptr_rdcmd_ready),
 
   .ptr_rd_data(ptr_rd_data),
   .ptr_rd_valid(ptr_rd_valid),
   .ptr_rd_ready(ptr_rd_ready),  
 
   .ptr_wr_data(ptr_wr_data),
   .ptr_wr_valid(ptr_wr_valid),
   .ptr_wr_ready(ptr_wr_ready),
 
   .ptr_wrcmd_data(ptr_wrcmd_data),
   .ptr_wrcmd_valid(ptr_wrcmd_valid),
   .ptr_wrcmd_ready(ptr_wrcmd_ready),
 
 
   .bmap_rdcmd_data(bmap_rdcmd_data),
   .bmap_rdcmd_valid(bmap_rdcmd_valid),
   .bmap_rdcmd_ready(bmap_rdcmd_ready),
 
   .bmap_rd_data(bmap_rd_data),
   .bmap_rd_valid(bmap_rd_valid),
   .bmap_rd_ready(bmap_rd_ready),  
 
   .bmap_wr_data(bmap_wr_data),
   .bmap_wr_valid(bmap_wr_valid),
   .bmap_wr_ready(bmap_wr_ready),
 
   .bmap_wrcmd_data(bmap_wrcmd_data),
   .bmap_wrcmd_valid(bmap_wrcmd_valid),
   .bmap_wrcmd_ready(bmap_wrcmd_ready)





);

always @(posedge uclk) begin 
  ureset2 <= sys_reset | ~init_calib_complete;
  ureset1 <= ureset2;
  ureset <= ureset1;
end

endmodule
