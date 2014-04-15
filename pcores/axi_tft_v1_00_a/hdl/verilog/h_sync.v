// --------------------------------------------------------------------
// -- (c) Copyright 1984 - 2012 Xilinx, Inc. All rights reserved.	 --
// --		                                						 --
// -- This file contains confidential and proprietary information	 --
// -- of Xilinx, Inc. and is protected under U.S. and	        	 --
// -- international copyright and other intellectual property    	 --
// -- laws.							                                 --
// --								                                 --
// -- DISCLAIMER							                         --
// -- This disclaimer is not a license and does not grant any	     --
// -- rights to the materials distributed herewith. Except as	     --
// -- otherwise provided in a valid license issued to you by	     --
// -- Xilinx, and to the maximum extent permitted by applicable	     --
// -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND	     --
// -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES	 --
// -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING	     --
// -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-	     --
// -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and	     --
// -- (2) Xilinx shall not be liable (whether in contract or tort,	 --
// -- including negligence, or under any other theory of		     --
// -- liability) for any loss or damage of any kind or nature	     --
// -- related to, arising under or in connection with these	         --
// -- materials, including for any direct, or any indirect,	         --
// -- special, incidental, or consequential loss or damage		     --
// -- (including loss of data, profits, goodwill, or any type of	 --
// -- loss or damage suffered as a result of any action brought	     --
// -- by a third party) even if such damage or loss was		         --
// -- reasonably foreseeable or Xilinx had been advised of the	     --
// -- possibility of the same.					                     --
// --								                                 --
// -- CRITICAL APPLICATIONS					                         --
// -- Xilinx products are not designed or intended to be fail-	     --
// -- safe, or for use in any application requiring fail-safe	     --
// -- performance, such as life-support or safety devices or	     --
// -- systems, Class III medical devices, nuclear facilities,	     --
// -- applications related to the deployment of airbags, or any	     --
// -- other applications that could lead to death, personal	         --
// -- injury, or severe property or environmental damage		     --
// -- (individually and collectively, "Critical			             --
// -- Applications"). Customer assumes the sole risk and		     --
// -- liability of any use of Xilinx products in Critical		     --
// -- Applications, subject only to applicable laws and	  	         --
// -- regulations governing limitations on product liability.	     --
// --								                                 --
// -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS	     --
// -- PART OF THIS FILE AT ALL TIMES. 				                 --
// --------------------------------------------------------------------
//-----------------------------------------------------------------------------
// h_sync.v   
//-----------------------------------------------------------------------------
// Filename:        h_sync.v
// Version:         v2.01a
// Description:     This is the HSYNC signal generator.  It generates the 
//                  appropriate HSYNC signal for the target TFT display.  
//                  The core of this module is a state machine that controls 
//                  4 counters and the HSYNC and H_DE signals.  
//
//                                   
// Verilog-Standard: Verilog'2001
//-----------------------------------------------------------------------------
// Structure:   
//                  axi_tft.vhd
//                     -- axi_master_burst.vhd               
//                     -- axi_lite_ipif.vhd
//                     -- tft_controller.v
//                            -- line_buffer.v
//                            -- v_sync.v
//                            -- h_sync.v
//                            -- slave_register.v
//                            -- tft_interface.v
//                                -- iic_init.v
//-----------------------------------------------------------------------------
// Author:          PVK
// History:
//   PVK           06/10/08    First Version
// ^^^^^^
//        
//    -- Input clock is SYS_TFT_Clk
//    -- H_DE is anded with V_DE to generate DE signal for the TFT display.    
//    -- H_bp_cnt_tc, H_bp_cnt_tc2, H_pix_cnt_tc, H_pix_cnt_tc2 are used to 
//    -- generate read and output enable signals for the tft side of the BRAM.
// ~~~~~~~~
//-----------------------------------------------------------------------------
// Naming Conventions:
//      active low signals:                     "*_n"
//      clock signals:                          "clk", "clk_div#", "clk_#x" 
//      reset signals:                          "rst", "rst_n" 
//      parameters:                             "C_*" 
//      user defined types:                     "*_TYPE" 
//      state machine next state:               "*_ns" 
//      state machine current state:            "*_cs" 
//      combinatorial signals:                  "*_com" 
//      pipelined or register delay signals:    "*_d#" 
//      counter signals:                        "*cnt*"
//      clock enable signals:                   "*_ce" 
//      internal version of output port         "*_i"
//      device pins:                            "*_pin" 
//      ports:                                  - Names begin with Uppercase 
//      component instantiations:               "<MODULE>I_<#|FUNC>
//-----------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
module h_sync(
    Clk,                    // Clock      
    Rst,                    // Reset
    HSYNC,                  // Horizontal Sync
    H_DE,                   // Horizontal Data enable
    VSYNC_Rst,              // Vsync reset
    H_bp_cnt_tc,            // Horizontal back porch terminal count delayed
    H_bp_cnt_tc2,           // Horizontal back porch terminal count 
    H_pix_cnt_tc,           // Horizontal pixel data terminal count delayed
    H_pix_cnt_tc2           // Horizontal pixel data terminal count
);
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
    input         Clk;
    input         Rst;
    output        VSYNC_Rst;
    output        HSYNC;
    output        H_DE;
    output        H_bp_cnt_tc;
    output        H_bp_cnt_tc2;
    output        H_pix_cnt_tc;
    output        H_pix_cnt_tc2; 

///////////////////////////////////////////////////////////////////////////////
// Signal Declaration
///////////////////////////////////////////////////////////////////////////////
    reg           VSYNC_Rst;
    reg           HSYNC;
    reg           H_DE;
    reg [0:6]     h_p_cnt;    // 7-bit  counter (96 clocks for pulse time)
    reg [0:5]     h_bp_cnt;   // 6-bit  counter (48 clocks for back porch time)
    reg [0:10]    h_pix_cnt;  // 11-bit counter (640 clocks for pixel time)
    reg [0:3]     h_fp_cnt;  // 4-bit  counter (16 clocks fof front porch time)
    reg           h_p_cnt_clr;
    reg           h_bp_cnt_clr;
    reg           h_pix_cnt_clr;
    reg           h_fp_cnt_clr;
    reg           h_p_cnt_tc;
    reg           H_bp_cnt_tc;
    reg           H_bp_cnt_tc2;
    reg           H_pix_cnt_tc;
    reg           H_pix_cnt_tc2;
    reg           h_fp_cnt_tc;

///////////////////////////////////////////////////////////////////////////////
// HSYNC State Machine - State Declaration
///////////////////////////////////////////////////////////////////////////////

    parameter [0:4] SET_COUNTERS = 5'b00001;
    parameter [0:4] PULSE        = 5'b00010;
    parameter [0:4] BACK_PORCH   = 5'b00100;
    parameter [0:4] PIXEL        = 5'b01000;
    parameter [0:4] FRONT_PORCH  = 5'b10000;

    reg [0:4]       HSYNC_cs;
    reg [0:4]       HSYNC_ns;
    
    // set the initial value for reset 
    initial  VSYNC_Rst = 1'b1;
 
///////////////////////////////////////////////////////////////////////////////
// HSYNC State Machine - Sequential Block
///////////////////////////////////////////////////////////////////////////////
    always @(posedge Clk) 
    begin : HSYNC_REG_STATE
      if (Rst) 
        begin
          HSYNC_cs  = SET_COUNTERS;
          VSYNC_Rst = 1;
        end
      else 
        begin
          HSYNC_cs  = HSYNC_ns;
          VSYNC_Rst = 0;
        end
    end

///////////////////////////////////////////////////////////////////////////////
// HSYNC State Machine - Combinatorial Block 
///////////////////////////////////////////////////////////////////////////////
    always @(HSYNC_cs or h_p_cnt_tc or H_bp_cnt_tc or H_pix_cnt_tc 
             or h_fp_cnt_tc) 
    begin : HSYNC_SM_CMB
       case (HSYNC_cs)
         //////////////////////////////////////////////////////////////
         //      SET COUNTERS STATE
         //////////////////////////////////////////////////////////////
         SET_COUNTERS: begin
           h_p_cnt_clr   = 1;
           h_bp_cnt_clr  = 1;
           h_pix_cnt_clr = 1;
           h_fp_cnt_clr  = 1;
           HSYNC         = 1;
           H_DE          = 0;
           HSYNC_ns      = PULSE;
         end
         //////////////////////////////////////////////////////////////
         //      PULSE STATE
         // -- Enable pulse counter
         // -- De-enable others
         //////////////////////////////////////////////////////////////
         PULSE: begin
           h_p_cnt_clr   = 0;
           h_bp_cnt_clr  = 1;
           h_pix_cnt_clr = 1;
           h_fp_cnt_clr  = 1;
           HSYNC         = 0;
           H_DE          = 0;
           
           if (h_p_cnt_tc == 0) 
             HSYNC_ns = PULSE;                     
           else 
             HSYNC_ns = BACK_PORCH;
         end
         //////////////////////////////////////////////////////////////
         //      BACK PORCH STATE
         // -- Enable back porch counter
         // -- De-enable others
         //////////////////////////////////////////////////////////////
         BACK_PORCH: begin
           h_p_cnt_clr   = 1;
           h_bp_cnt_clr  = 0;
           h_pix_cnt_clr = 1;
           h_fp_cnt_clr  = 1;
           HSYNC         = 1;
           H_DE          = 0;
           
           if (H_bp_cnt_tc == 0) 
             HSYNC_ns = BACK_PORCH;                                            
           else 
             HSYNC_ns = PIXEL;
         end
         //////////////////////////////////////////////////////////////
         //      PIXEL STATE
         // -- Enable pixel counter
         // -- De-enable others
         //////////////////////////////////////////////////////////////
         PIXEL: begin
           h_p_cnt_clr   = 1;
           h_bp_cnt_clr  = 1;
           h_pix_cnt_clr = 0;
           h_fp_cnt_clr  = 1;
           HSYNC         = 1;
           H_DE          = 1;
           
           if (H_pix_cnt_tc == 0) 
             HSYNC_ns = PIXEL;                                                
           else 
             HSYNC_ns = FRONT_PORCH;
         end
         //////////////////////////////////////////////////////////////
         //      FRONT PORCH STATE
         // -- Enable front porch counter
         // -- De-enable others
         // -- Wraps to PULSE state
         //////////////////////////////////////////////////////////////
         FRONT_PORCH: begin
           h_p_cnt_clr   = 1;
           h_bp_cnt_clr  = 1;
           h_pix_cnt_clr = 1;
           h_fp_cnt_clr  = 0;
           HSYNC         = 1;      
           H_DE          = 0;
           
           if (h_fp_cnt_tc == 0) 
             HSYNC_ns = FRONT_PORCH;                                           
           else 
             HSYNC_ns = PULSE;
         end
         //////////////////////////////////////////////////////////////
         //      DEFAULT STATE
         //////////////////////////////////////////////////////////////
         // added coverage off to disable the coverage for default state
         // as state machine will never enter in defualt state while doing
         // verification. 
         // coverage off
         default: begin
           h_p_cnt_clr   = 1;
           h_bp_cnt_clr  = 1;
           h_pix_cnt_clr = 1;
           h_fp_cnt_clr  = 0;
           HSYNC         = 1;      
           H_DE          = 0;
           HSYNC_ns      = SET_COUNTERS;
         end
         // coverage on 
           
       endcase
    end

///////////////////////////////////////////////////////////////////////////////
//      Horizontal Pulse Counter - Counts 96 clocks for pulse time                                                                                                                              
///////////////////////////////////////////////////////////////////////////////
    always @(posedge Clk)
    begin : HSYNC_PULSE_CNT
      if (Rst || h_p_cnt_clr) 
        begin
          h_p_cnt = 7'b0;
          h_p_cnt_tc = 0;
        end
      else 
        begin
          if (h_p_cnt == 94) 
            begin
              h_p_cnt = h_p_cnt + 1;
              h_p_cnt_tc = 1;
            end
          else 
            begin
              h_p_cnt = h_p_cnt + 1;
              h_p_cnt_tc = 0;
            end
        end
    end
///////////////////////////////////////////////////////////////////////////////
//      Horizontal Back Porch Counter - Counts 48 clocks for back porch time                                                                    
///////////////////////////////////////////////////////////////////////////////                 
    always @(posedge Clk )
    begin : HSYNC_BP_CNTR
      if (Rst || h_bp_cnt_clr) 
        begin
          h_bp_cnt = 6'b0;
          H_bp_cnt_tc = 0;
          H_bp_cnt_tc2 = 0;
        end
      else 
        begin
          if (h_bp_cnt == 45) 
            begin
              h_bp_cnt = h_bp_cnt + 1;
              H_bp_cnt_tc2 = 1;
              H_bp_cnt_tc = 0;
            end
          else if (h_bp_cnt == 46) 
            begin
              h_bp_cnt = h_bp_cnt + 1;
              H_bp_cnt_tc = 1;
              H_bp_cnt_tc2 = 0;
            end
          else 
            begin
              h_bp_cnt = h_bp_cnt + 1;
              H_bp_cnt_tc = 0;
              H_bp_cnt_tc2 = 0;
            end
        end
    end

///////////////////////////////////////////////////////////////////////////////
//      Horizontal Pixel Counter - Counts 640 clocks for pixel time                                                                                                                     
///////////////////////////////////////////////////////////////////////////////                 
    always @(posedge Clk)
    begin : HSYNC_PIX_CNTR
        if (Rst || h_pix_cnt_clr) 
          begin
            h_pix_cnt = 11'b0;
            H_pix_cnt_tc = 0;
            H_pix_cnt_tc2 = 0;
          end
        else 
          begin
            if (h_pix_cnt == 637) 
              begin
                h_pix_cnt = h_pix_cnt + 1;
                H_pix_cnt_tc2 = 1;
              end
            else if (h_pix_cnt == 638) 
              begin
                h_pix_cnt = h_pix_cnt + 1;
                H_pix_cnt_tc = 1;
              end
            else 
              begin
                h_pix_cnt = h_pix_cnt + 1;
                H_pix_cnt_tc = 0;
                H_pix_cnt_tc2 = 0;
              end
            end
    end

///////////////////////////////////////////////////////////////////////////////
//      Horizontal Front Porch Counter - Counts 16 clocks for front porch time
///////////////////////////////////////////////////////////////////////////////                 
    always @(posedge Clk)
    begin : HSYNC_FP_CNTR
        if (Rst || h_fp_cnt_clr) 
            begin
            h_fp_cnt = 5'b0;
            h_fp_cnt_tc = 0;
            end
        else 
            begin
                if (h_fp_cnt == 14) 
                    begin
                    h_fp_cnt = h_fp_cnt + 1;
                    h_fp_cnt_tc = 1;
                    end
                else 
                    begin
                    h_fp_cnt = h_fp_cnt + 1;
                    h_fp_cnt_tc = 0;
                    end
            end
    end
endmodule
