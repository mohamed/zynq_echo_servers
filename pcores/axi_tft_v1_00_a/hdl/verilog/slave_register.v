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
// slave_register.v   
//-----------------------------------------------------------------------------
// Filename:        slave_register.v
// Version:         v1.00a
// Description:     This module contains TFT control register and provides
//                  AXI interface to access those registers.
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
//    --  Added PLB slave and DCR slave interface to access TFT Registers. 
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

`timescale 1 ps / 1 ps

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////

module slave_register(
  // AXI Slave Interface
  S_AXI_Clk,          // Slave Interface clock
  S_AXI_Rst,          // Slave Interface reset
  Bus2IP_Data,      // Bus to IP data bus
  Bus2IP_RdCE,      // Bus to IP read chip enable
  Bus2IP_WrCE,      // Bus to IP write chip enable
  Bus2IP_BE,        // Bus to IP byte enable
  IP2Bus_Data,      // IP to Bus data bus
  IP2Bus_RdAck,     // IP to Bus read transfer acknowledgement
  IP2Bus_WrAck,     // IP to Bus write transfer acknowledgement
  IP2Bus_Error,     // IP to Bus error response

  // Registers
  TFT_base_addr,    // TFT Base Address reg    
  TFT_dps_reg,      // TFT display scan reg
  TFT_on_reg,       // TFT display on reg
  TFT_intr_en,      // TFT frame complete interrupt enable reg
  TFT_status,       // TFT frame complete status reg
  IIC_xfer_done,    // IIC configuration done
  TFT_iic_xfer,     // IIC configuration request
  TFT_iic_reg_addr, // IIC register address
  TFT_iic_reg_data  // IIC register data
  );


///////////////////////////////////////////////////////////////////////////////
// Parameter Declarations
///////////////////////////////////////////////////////////////////////////////

  parameter         C_DEFAULT_TFT_BASE_ADDR  = "11110000000";
  parameter integer C_SLV_DWIDTH             = 32;
  parameter integer C_NUM_REG                = 4;

///////////////////////////////////////////////////////////////////////////////
// Port Declarations
/////////////////////////////////////////////////////////////////////////////// 

  input                         S_AXI_Clk;
  input                         S_AXI_Rst;
  input  [0 : C_SLV_DWIDTH-1]   Bus2IP_Data;
  input  [0 : C_NUM_REG-1]      Bus2IP_RdCE;
  input  [0 : C_NUM_REG-1]      Bus2IP_WrCE;
  input  [0 : C_SLV_DWIDTH/8-1] Bus2IP_BE;
  output [0 : C_SLV_DWIDTH-1]   IP2Bus_Data;
  output                        IP2Bus_RdAck;
  output                        IP2Bus_WrAck;
  output                        IP2Bus_Error;
  output [0:10]                 TFT_base_addr;
  output                        TFT_dps_reg;
  output                        TFT_on_reg;
  output                        TFT_intr_en;
  input                         TFT_status;
  input                         IIC_xfer_done;
  output                        TFT_iic_xfer;
  output [0:7]                  TFT_iic_reg_addr;
  output [0:7]                  TFT_iic_reg_data;

///////////////////////////////////////////////////////////////////////////////
// Signal Declaration
///////////////////////////////////////////////////////////////////////////////
  reg                           TFT_intr_en;
  reg                           TFT_status_reg;
  reg                           TFT_dps_reg;
  reg                           TFT_on_reg;
  reg  [0:10]                   TFT_base_addr;
  reg  [0:C_SLV_DWIDTH-1]       IP2Bus_Data; 
  reg                           tft_status_d1;
  reg                           tft_status_d2;
  reg                           TFT_iic_xfer;
  reg [0:7]                     TFT_iic_reg_addr;
  reg [0:7]                     TFT_iic_reg_data;
  reg                           iic_xfer_done_d1;
  reg                           iic_xfer_done_d2;
  
///////////////////////////////////////////////////////////////////////////////
// TFT Register Interface 
///////////////////////////////////////////////////////////////////////////////
//---------------------
// Register         DCR  AXI  
//-- AR  - offset - 00 - 00
//-- CR  -        - 01 - 04
//-- ICR -        - 02 - 08
//-- Reserved     - 03 - 0C
//---------------------
//-- TFT Address Register(AR)
//-- BSR bits
//-- bit 0:10  - 11 MSB of Video Memory Address
//-- bit 11:31 - Reserved
//---------------------
//-- TFT Control Register(CR)
//-- BSR bits
//-- bit 0:29  - Reserved
//-- bit 30    - Display scan control bit
//-- bit 31    - TFT Display enable bit
///////////////////////////////////////////////////////////////////////////////
//---------------------
//-- TFT Interrupt Control Register(ICR)
//-- BSR bits
//-- bit 0:27  - Reserved
//-- bit 28    - Interrupt enable bit 
//-- bit 29:30 - Reserved
//-- bit 31    - Frame Complete Status bit
///////////////////////////////////////////////////////////////////////////////

        wire bus2ip_rdce_or;
        wire bus2ip_wrce_or;
        wire bus2ip_rdce_pulse;
        wire bus2ip_wrce_pulse;
        reg  bus2ip_rdce_d1;
        reg  bus2ip_rdce_d2;
        reg  bus2ip_wrce_d1;
        reg  bus2ip_wrce_d2;
        wire word_access; 
        //Ravi reg  [0:31] bus2ip_data_d1;
       
        // oring of bus2ip_rdce and wrce
        assign bus2ip_rdce_or = Bus2IP_RdCE[0] | Bus2IP_RdCE[1] |
                                Bus2IP_RdCE[2] | Bus2IP_RdCE[3];

        assign bus2ip_wrce_or = Bus2IP_WrCE[0] | Bus2IP_WrCE[1] | 
                                Bus2IP_WrCE[2] | Bus2IP_WrCE[3];

        assign word_access    = (Bus2IP_BE == 4'b1111)? 1'b1 : 1'b0; 
        
        //---------------------------------------------------------------------
        //-- register combinational rdce 
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : REG_CE
          if (S_AXI_Rst)
            begin 
              bus2ip_rdce_d1 <= 1'b0; 
              bus2ip_rdce_d2 <= 1'b0;               
              bus2ip_wrce_d1 <= 1'b0; 
              bus2ip_wrce_d2 <= 1'b0;               
            end
          else 
            begin
              bus2ip_rdce_d1 <= bus2ip_rdce_or; 
              bus2ip_rdce_d2 <= bus2ip_rdce_d1;               
              bus2ip_wrce_d1 <= bus2ip_wrce_or; 
              bus2ip_wrce_d2 <= bus2ip_wrce_d1;               
            end
        end
           
        // generate pulse for bus2ip_rdce & bus2ip_wrce
        assign bus2ip_rdce_pulse = bus2ip_rdce_d1 & ~bus2ip_rdce_d2;
        assign bus2ip_wrce_pulse = bus2ip_wrce_d1 & ~bus2ip_wrce_d2;

        
        //---------------------------------------------------------------------
        //-- Generating the acknowledgement signals
        //---------------------------------------------------------------------
        assign IP2Bus_RdAck = bus2ip_rdce_pulse;
        
        assign IP2Bus_WrAck = bus2ip_wrce_pulse;
        
        assign IP2Bus_Error = ((bus2ip_rdce_pulse | bus2ip_wrce_pulse) && 
                                 (word_access == 1'b0))? 1'b1 : 1'b0;
        //---------------------------------------------------------------------
        //-- flopping BUS2IP_data signal
        //---------------------------------------------------------------------
        //Ravi always @(posedge S_AXI_Clk)
        //Ravi begin : DATA_DELAY
        //Ravi   if (S_AXI_Rst)
        //Ravi     begin 
        //Ravi       bus2ip_data_d1 <= 32'b0; 
        //Ravi     end
        //Ravi   else 
        //Ravi     begin 
        //Ravi       bus2ip_data_d1 <= Bus2IP_Data; 
        //Ravi     end
        //Ravi end
        
        
        //---------------------------------------------------------------------
        //-- Writing to TFT Registers
        //---------------------------------------------------------------------
        // writing AR
        always @(posedge S_AXI_Clk)
        begin : WRITE_AR
          if (S_AXI_Rst)
            begin 
              TFT_base_addr <= C_DEFAULT_TFT_BASE_ADDR; 
            end
          else if (Bus2IP_WrCE[0] == 1'b1 & word_access == 1'b1)
            begin
              TFT_base_addr <= Bus2IP_Data[0:10];
              //Ravi TFT_base_addr <= bus2ip_data_d1[0:10];
            end
        end
        
        //---------------------------------------------------------------------
        // Writing CR
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : WRITE_CR
          if (S_AXI_Rst)
            begin 
              TFT_dps_reg   <= 1'b0; 
              TFT_on_reg    <= 1'b1; 
            end
          else if (Bus2IP_WrCE[1] == 1'b1 & word_access == 1'b1)
            begin
              TFT_dps_reg   <= Bus2IP_Data[30]; 
              //Ravi TFT_dps_reg   <= bus2ip_data_d1[30]; 
              TFT_on_reg    <= Bus2IP_Data[31]; 
              //Ravi TFT_on_reg    <= bus2ip_data_d1[31]; 
            end
        end
        

        //---------------------------------------------------------------------
        // Writing ICR - Interrupt Enable
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : WRITE_ICR_IE
          if (S_AXI_Rst)
            begin 
              TFT_intr_en     <= 1'b0; 
            end
          else if (Bus2IP_WrCE[2] == 1'b1 & word_access == 1'b1)
            begin
              TFT_intr_en     <= Bus2IP_Data[28]; 
              //Ravi TFT_intr_en     <= bus2ip_data_d1[28]; 
            end
        end

        //---------------------------------------------------------------------
        // Writing ICR - Frame Complete status 
        // For polled mode operation
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : WRITE_ICR_STAT
          if (S_AXI_Rst)
            begin 
              TFT_status_reg  <= 1'b0; 
            end
          else if (Bus2IP_WrCE[0] == 1'b1 & word_access == 1'b1)
            begin
              TFT_status_reg  <= 1'b0; 
            end
          else if (Bus2IP_WrCE[2] == 1'b1 & word_access == 1'b1)
            begin
              TFT_status_reg  <= Bus2IP_Data[31]; 
              //Ravi TFT_status_reg  <= bus2ip_data_d1[31]; 
            end
          else if (tft_status_d2 == 1'b1)
            begin
              TFT_status_reg  <= 1'b1; 
            end
  
        end


        //---------------------------------------------------------------------
        // Writing IICR - IIC Register
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : WRITE_IICR
          if (S_AXI_Rst)
            begin 
              TFT_iic_reg_addr <= 8'b0;
              TFT_iic_reg_data <= 8'b0;
            end
          else if (Bus2IP_WrCE[3] == 1'b1 & word_access == 1'b1)
            begin
              TFT_iic_reg_addr  <= Bus2IP_Data[16:23]; 
              //Ravi TFT_iic_reg_addr  <= bus2ip_data_d1[16:23]; 
              TFT_iic_reg_data  <= Bus2IP_Data[24:31]; 
              //Ravi TFT_iic_reg_data  <= bus2ip_data_d1[24:31]; 
            end
        end


        //---------------------------------------------------------------------
        // Writing IICR - XFER Register
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : WRITE_XFER
          if (S_AXI_Rst)
            begin 
              TFT_iic_xfer  <= 1'b0; 
            end
          else if (Bus2IP_WrCE[3] == 1'b1 & word_access == 1'b1)
            begin
              TFT_iic_xfer  <= Bus2IP_Data[0]; 
              //Ravi TFT_iic_xfer  <= bus2ip_data_d1[0]; 
            end
          else if (iic_xfer_done_d2 == 1'b1)
            begin
              TFT_iic_xfer  <= 1'b0; 
            end
        end

        //---------------------------------------------------------------------
        // Synchronize the IIC_xfer_done signal w.r.t. S_AXI_CLK
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : IIC_XFER_DONE_AXI_SYNC
          if (S_AXI_Rst)
            begin 
              iic_xfer_done_d1 <= 1'b0;
              iic_xfer_done_d2 <= 1'b0;
            end
          else
            begin
              iic_xfer_done_d1 <= IIC_xfer_done;
              iic_xfer_done_d2 <= iic_xfer_done_d1;
            end  
        end

        //---------------------------------------------------------------------
        // Synchronize the vsync_intr signal w.r.t. S_AXI_CLK
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : VSYNC_INTR_AXI_SYNC
          if (S_AXI_Rst)
            begin 
              tft_status_d1 <= 1'b0;
              tft_status_d2 <= 1'b0;
            end
          else
            begin
              tft_status_d1 <= TFT_status;
              tft_status_d2 <= tft_status_d1;
            end  
        end

        
        //---------------------------------------------------------------------
        //-- Reading from TFT Registers
        //-- Bus2IP_RdCE[0] == AR
        //-- Bus2IP_RdCE[1] == CR
        //-- Bus2IP_RdCE[2] == ICR
        //-- Bus2IP_RdCE[3] == Reserved
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : READ_REG
          
          
          if (S_AXI_Rst | ~word_access ) 
            begin 
              IP2Bus_Data[0:27]  <= 28'b0;
              IP2Bus_Data[28:31] <= 4'b0;
            end
          else if (Bus2IP_RdCE[0] == 1'b1)
            begin
              IP2Bus_Data[0:10]  <= TFT_base_addr;
              IP2Bus_Data[11:31] <= 20'b0;
            end
          else if (Bus2IP_RdCE[1] == 1'b1)
            begin
              IP2Bus_Data[0:29]  <= 30'b0;
              IP2Bus_Data[30]    <= TFT_dps_reg; 
              IP2Bus_Data[31]    <= TFT_on_reg;
            end
          else if (Bus2IP_RdCE[2] == 1'b1)
            begin
              IP2Bus_Data[0:27]  <= 28'b0;
              IP2Bus_Data[28]    <= TFT_intr_en;
              IP2Bus_Data[29:30] <= 2'b0;
              IP2Bus_Data[31]    <= TFT_status_reg; 
            end
          else if (Bus2IP_RdCE[3] == 1'b1)
            begin
              IP2Bus_Data[0]     <= TFT_iic_xfer;
              IP2Bus_Data[1: 15] <= 15'b0;
              IP2Bus_Data[16:23] <= TFT_iic_reg_addr;
              IP2Bus_Data[24:31] <= TFT_iic_reg_data; 
            end
          else 
            begin
              IP2Bus_Data  <= 32'b0;
            end
        end

        
endmodule


