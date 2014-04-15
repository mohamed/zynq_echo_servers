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
// tft_interface.v   
//-----------------------------------------------------------------------------
// Filename:        tft_interface.vhd
// Version:         v1.00a
// Description:     This module provides external interface(VGA/DVI) to TFT 
//                  Display
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
//  PVK             08/05/09    v2.00.a
// ^^^^^^^
//  Changed the DDR alignment for ODDR2 for Spartan6 DVI mode.
// ~~~~~~~~~
//  PVK             09/15/09    v2.01.a
// ^^^^^^^
//  Reverted back DDR alignment for ODDR2 for Spartan6 DVI mode. Added 
//  flexibilty for Chrontel Chip configuration through register interface.
// ~~~~~~~~~
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
module tft_interface (
    TFT_Clk,                // TFT Clock
    TFT_Rst,                // TFT Reset
    Bus2IP_Clk,             // Slave Clock
    Bus2IP_Rst,             // Slave Reset
    HSYNC,                  // Hsync input
    VSYNC,                  // Vsync input
    DE,                     // Data Enable
    RED,                    // RED pixel data 
    GREEN,                  // Green pixel data
    BLUE,                   // Blue pixel data
    TFT_HSYNC,              // TFT Hsync
    TFT_VSYNC,              // TFT Vsync
    TFT_DE,                 // TFT data enable
    TFT_VGA_CLK,            // TFT VGA clock
    TFT_VGA_R,              // TFT VGA Red pixel data 
    TFT_VGA_G,              // TFT VGA Green pixel data
    TFT_VGA_B,              // TFT VGA Blue pixel data
    TFT_DVI_CLK_P,          // TFT DVI differential clock
    TFT_DVI_CLK_N,          // TFT DVI differential clock
    TFT_DVI_DATA,           // TFT DVI pixel data
    
    //IIC init state machine for Chrontel CH7301C
    I2C_done,               // I2C configuration done
    TFT_IIC_SCL_I,          // I2C Clock input 
    TFT_IIC_SCL_O,          // I2C Clock output
    TFT_IIC_SCL_T,          // I2C Clock control
    TFT_IIC_SDA_I,          // I2C data input
    TFT_IIC_SDA_O,          // I2C data output 
    TFT_IIC_SDA_T,          // I2C data control
    IIC_xfer_done,          // IIC configuration done
    TFT_iic_xfer,           // IIC configuration request
    TFT_iic_reg_addr,       // IIC register address 
    TFT_iic_reg_data        // IIC register data
);

///////////////////////////////////////////////////////////////////////////////
// Parameter Declarations
///////////////////////////////////////////////////////////////////////////////
    parameter         C_FAMILY         = "virtex5";
    parameter         C_I2C_SLAVE_ADDR = "1110110";
    parameter integer C_TFT_INTERFACE  = 1;
    parameter integer C_IOREG_STYLE    = 1;

///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////

// Inputs Ports
    input             TFT_Clk;
    input             TFT_Rst;
    input             Bus2IP_Rst;
    input             Bus2IP_Clk;
    input             HSYNC;                          
    input             VSYNC;                          
    input             DE;     
    input    [5:0]    RED;
    input    [5:0]    GREEN;
    input    [5:0]    BLUE;
    
// Output Ports    
    output            TFT_HSYNC;
    output            TFT_VSYNC;
    output            TFT_DE;
    output            TFT_VGA_CLK;
    output   [5:0]    TFT_VGA_R;
    output   [5:0]    TFT_VGA_G;
    output   [5:0]    TFT_VGA_B;
    output            TFT_DVI_CLK_P;
    output            TFT_DVI_CLK_N;
    output   [11:0]   TFT_DVI_DATA;

// I2C Ports
    output            I2C_done;
    input             TFT_IIC_SCL_I;
    output            TFT_IIC_SCL_O;
    output            TFT_IIC_SCL_T;
    input             TFT_IIC_SDA_I;
    output            TFT_IIC_SDA_O;
    output            TFT_IIC_SDA_T;
    output            IIC_xfer_done;
    input             TFT_iic_xfer;
    input  [0:7]      TFT_iic_reg_addr;
    input  [0:7]      TFT_iic_reg_data;


///////////////////////////////////////////////////////////////////////////////
// Implementation
///////////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    // FDS/FDR COMPONENT INSTANTIATION FOR IOB OUTPUT REGISTERS
    // -- All output to TFT are registered
    ///////////////////////////////////////////////////////////////////////////
    
    // Generate TFT HSYNC
    FDS FDS_HSYNC (.Q(TFT_HSYNC), 
                   .C(~TFT_Clk), 
                   .S(TFT_Rst), 
                   .D(HSYNC)); 


    // Generate TFT VSYNC
    FDS FDS_VSYNC (.Q(TFT_VSYNC), 
                   .C(~TFT_Clk), 
                   .S(TFT_Rst), 
                   .D(VSYNC));
                     
    // Generate TFT DE
    FDR FDR_DE    (.Q(TFT_DE),    
                   .C(~TFT_Clk), 
                   .R(TFT_Rst), 
                   .D(DE));

    
      
    generate
      if (C_TFT_INTERFACE == 1) // Selects DVI interface
        begin : gen_dvi_if
        
          wire        tft_iic_sda_t_i;
          wire        tft_iic_scl_t_i;
          wire [11:0] dvi_data_a;
          wire [11:0] dvi_data_b;
          genvar i;


          // Generating 24-bit DVI data
          // from 18-bit RGB
          assign dvi_data_a[0]  = GREEN[2];
          assign dvi_data_a[1]  = GREEN[3];
          assign dvi_data_a[2]  = GREEN[4];
          assign dvi_data_a[3]  = GREEN[5];
          assign dvi_data_a[4]  = 1'b0;
          assign dvi_data_a[5]  = 1'b0;
          assign dvi_data_a[6]  = RED[0];
          assign dvi_data_a[7]  = RED[1];
          assign dvi_data_a[8]  = RED[2];
          assign dvi_data_a[9]  = RED[3];
          assign dvi_data_a[10] = RED[4];
          assign dvi_data_a[11] = RED[5];
          assign dvi_data_b[0]  = 1'b0;
          assign dvi_data_b[1]  = 1'b0;
          assign dvi_data_b[2]  = BLUE[0];
          assign dvi_data_b[3]  = BLUE[1];
          assign dvi_data_b[4]  = BLUE[2];
          assign dvi_data_b[5]  = BLUE[3];
          assign dvi_data_b[6]  = BLUE[4];
          assign dvi_data_b[7]  = BLUE[5];
          assign dvi_data_b[8]  = 1'b0;
          assign dvi_data_b[9]  = 1'b0;
          assign dvi_data_b[10] = GREEN[0];
          assign dvi_data_b[11] = GREEN[1];

          /////////////////////////////////////////////////////////////////////
          // ODDR COMPONENT INSTANTIATION FOR IOB OUTPUT REGISTERS
          // -- All output to TFT are registered
          // (C_FAMILY == "virtex4" || "virtex5" || "virtex6")
          /////////////////////////////////////////////////////////////////////           
          //if (C_IOREG_STYLE == 0)   // Virtex-4 style IO generation
          //  begin : gen_v4_v5       // Uses ODDR  


              // DVI Clock P
              ODDR TFT_CLKP_ODDR (.Q(TFT_DVI_CLK_P), 
                                  .C(TFT_Clk), 
                                  .CE(1'b1), 
                                  .R(TFT_Rst), 
                                  .D1(1'b1), 
                                  .D2(1'b0), 
                                  .S(1'b0));
                                  
              // DVI Clock N                    
              ODDR TFT_CLKN_ODDR (.Q(TFT_DVI_CLK_N), 
                                  .C(TFT_Clk), 
                                  .CE(1'b1), 
                                  .R(TFT_Rst), 
                                  .D1(1'b0), 
                                  .D2(1'b1), 
                                  .S(1'b0));

              /////////////////////////////////////////////////////////////////
              // Generate DVI data 
              /////////////////////////////////////////////////////////////////
              for (i=0;i<12;i=i+1) begin : replicate_tft_dvi_data
         
                ODDR ODDR_TFT_DATA (.Q(TFT_DVI_DATA[i]),  
                                    .C(TFT_Clk), 
                                    .CE(1'b1), 
                                    .R(~DE|TFT_Rst), 
                                    .D2(dvi_data_b[i]),      
                                    .D1(dvi_data_a[i]),  
                                    .S(1'b0));
               end 
              /////////////////////////////////////////////////////////////////
                 
            //end        
            
          
          // All TFT ports are grounded
          assign TFT_VGA_CLK = 1'b0;
          assign TFT_VGA_R   = 6'b0;
          assign TFT_VGA_G   = 6'b0;
          assign TFT_VGA_B   = 6'b0;
          
          /////////////////////////////////////////////////////////////////////
          // IIC INIT COMPONENT INSTANTIATION for Chrontel CH-7301
          /////////////////////////////////////////////////////////////////////
          iic_init 
            # (.C_I2C_SLAVE_ADDR(C_I2C_SLAVE_ADDR))
            iic_init
              (
                .Clk              (Bus2IP_Clk),
                .Reset_n          (~Bus2IP_Rst),
                .SDA              (tft_iic_sda_t_i),
                .SCL              (tft_iic_scl_t_i),
                .Done             (I2C_done),
                .IIC_xfer_done    (IIC_xfer_done),
                .TFT_iic_xfer     (TFT_iic_xfer),
                .TFT_iic_reg_addr (TFT_iic_reg_addr),
                .TFT_iic_reg_data (TFT_iic_reg_data)
               );
                       
          assign TFT_IIC_SCL_O = 1'b0;
          assign TFT_IIC_SDA_O = 1'b0;
          assign TFT_IIC_SDA_T = tft_iic_sda_t_i ;
          assign TFT_IIC_SCL_T = tft_iic_scl_t_i ;
          /////////////////////////////////////////////////////////////////////
          
           
        end // End DVI Interface 

      else  // Selects VGA Interface

        begin : gen_vga_if
          
          /////////////////////////////////////////////////////////////////////
          // Generate TFT VGA Clock
          /////////////////////////////////////////////////////////////////////
          if (C_IOREG_STYLE == 0)            // Virtex-4 style IO generation
            begin : gen_v4_v5                // Uses ODDR component 
              
              // TFT VGA Clock 
              ODDR TFT_CLK_ODDR   (.Q(TFT_VGA_CLK), 
                                   .C(TFT_Clk), 
                                   .CE(1'b1), 
                                   .R(TFT_Rst), 
                                   .D1(1'b0), 
                                   .D2(1'b1), 
                                   .S(1'b0));
              
            end                              // Spartan3e style IO generation
          else if (C_IOREG_STYLE == 1)       // Uses ODDR2 component 
            begin : gen_s3e
             
              // TFT VGA Clock 
              ODDR2 TFT_CLK_ODDR2 (.Q(TFT_VGA_CLK), 
                                   .C0(TFT_Clk),
                                   .C1(~TFT_Clk), 
                                   .CE(1'b1), 
                                   .R(TFT_Rst), 
                                   .D0(1'b0), 
                                   .D1(1'b1), 
                                   .S(1'b0));
            
            end 
          else 
            begin : gen_v2p_s3               // Virtex2p style IO generation
                                             // Uses FDDRRSE component 
              
              // TFT VGA Clock 
              FDDRRSE TFT_CLK_FDDRRSE (.Q(TFT_VGA_CLK), 
                                       .C0(TFT_Clk),
                                       .C1(~TFT_Clk), 
                                       .CE(1'b1), 
                                       .R(TFT_Rst), 
                                       .D0(1'b0), 
                                       .D1(1'b1), 
                                       .S(1'b0));
            end   
          /////////////////////////////////////////////////////////////////////
          
          
          /////////////////////////////////////////////////////////////////////
          // TFT VGA RGB Data
          //////////////////////////////////////////////////////////////////////
          FDR FDR_R0 (.Q(TFT_VGA_R[0]), .C(TFT_Clk), .R(TFT_Rst), .D(RED[0]))  ;
          FDR FDR_R1 (.Q(TFT_VGA_R[1]), .C(TFT_Clk), .R(TFT_Rst), .D(RED[1]))  ;
          FDR FDR_R2 (.Q(TFT_VGA_R[2]), .C(TFT_Clk), .R(TFT_Rst), .D(RED[2]))  ;
          FDR FDR_R3 (.Q(TFT_VGA_R[3]), .C(TFT_Clk), .R(TFT_Rst), .D(RED[3]))  ;
          FDR FDR_R4 (.Q(TFT_VGA_R[4]), .C(TFT_Clk), .R(TFT_Rst), .D(RED[4]))  ;
          FDR FDR_R5 (.Q(TFT_VGA_R[5]), .C(TFT_Clk), .R(TFT_Rst), .D(RED[5]))  ;
          FDR FDR_G0 (.Q(TFT_VGA_G[0]), .C(TFT_Clk), .R(TFT_Rst), .D(GREEN[0]));
          FDR FDR_G1 (.Q(TFT_VGA_G[1]), .C(TFT_Clk), .R(TFT_Rst), .D(GREEN[1]));
          FDR FDR_G2 (.Q(TFT_VGA_G[2]), .C(TFT_Clk), .R(TFT_Rst), .D(GREEN[2]));
          FDR FDR_G3 (.Q(TFT_VGA_G[3]), .C(TFT_Clk), .R(TFT_Rst), .D(GREEN[3]));
          FDR FDR_G4 (.Q(TFT_VGA_G[4]), .C(TFT_Clk), .R(TFT_Rst), .D(GREEN[4]));
          FDR FDR_G5 (.Q(TFT_VGA_G[5]), .C(TFT_Clk), .R(TFT_Rst), .D(GREEN[5]));
          FDR FDR_B0 (.Q(TFT_VGA_B[0]), .C(TFT_Clk), .R(TFT_Rst), .D(BLUE[0])) ;
          FDR FDR_B1 (.Q(TFT_VGA_B[1]), .C(TFT_Clk), .R(TFT_Rst), .D(BLUE[1])) ;
          FDR FDR_B2 (.Q(TFT_VGA_B[2]), .C(TFT_Clk), .R(TFT_Rst), .D(BLUE[2])) ;
          FDR FDR_B3 (.Q(TFT_VGA_B[3]), .C(TFT_Clk), .R(TFT_Rst), .D(BLUE[3])) ;
          FDR FDR_B4 (.Q(TFT_VGA_B[4]), .C(TFT_Clk), .R(TFT_Rst), .D(BLUE[4])) ;
          FDR FDR_B5 (.Q(TFT_VGA_B[5]), .C(TFT_Clk), .R(TFT_Rst), .D(BLUE[5])) ;
          //////////////////////////////////////////////////////////////////////
          
          // All DVI interface ports are set to default value            
          assign TFT_DVI_CLK_P  = 1'b0; 
          assign TFT_DVI_CLK_N  = 1'b0;
          assign TFT_DVI_DATA   = 12'b0;
          assign I2C_done       = 1'b1;
          assign IIC_xfer_done  = 1'b0;
          assign TFT_IIC_SCL_O  = 1'b0;
          assign TFT_IIC_SDA_O  = 1'b0;
          assign TFT_IIC_SDA_T  = 1'b1;
          assign TFT_IIC_SCL_T  = 1'b1;
        
        
        end // End VGA Interface
    endgenerate    

endmodule
