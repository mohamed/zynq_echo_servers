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
// iic_init.v   
//-----------------------------------------------------------------------------
// Filename:        iic_init.v
// Version:         v1.00.a
// Description:     This module consists of logic to configur the Chrontel 
//                  CH-7301 DVI transmitter chip through I2C interface.
//
// Verilog-Standard: Verilog'2001
//-----------------------------------------------------------------------------
// Structure:   
//                  axi_tft.vhd
//                     -- axi_master_burst.vhd               
//                     -- axi_lite_ipif.vhd
//                     -- tft_controller.v
//                            -- tft_control.v
//                            -- line_buffer.v
//                            -- v_sync.v
//                            -- h_sync.v
//                            -- slave_register.v
//                            -- tft_interface.v
//                                -- iic_init.v
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
module iic_init( 
  Clk,                          // Clock input
  Reset_n,                      // Reset input
  SDA,                          // I2C data
  SCL,                          // I2C clock
  Done,                         // I2C configuration done
  IIC_xfer_done,                // IIC configuration done
  TFT_iic_xfer,                 // IIC configuration request
  TFT_iic_reg_addr,             // IIC register address
  TFT_iic_reg_data              // IIC register data
  );

///////////////////////////////////////////////////////////////////////////////
// Parameter Declarations
///////////////////////////////////////////////////////////////////////////////
                 
parameter C_I2C_SLAVE_ADDR = "1110110";

parameter CLK_RATE_MHZ = 50,  
          SCK_PERIOD_US = 30, 
          TRANSITION_CYCLE = (CLK_RATE_MHZ * SCK_PERIOD_US) / 2,
          TRANSITION_CYCLE_MSB = 11;  



input          Clk;
input          Reset_n;
inout          SDA;
inout          SCL;
output         Done;
output         IIC_xfer_done;
input          TFT_iic_xfer;
input [0:7]    TFT_iic_reg_addr;
input [0:7]    TFT_iic_reg_data;

  
          
localparam    IDLE           = 3'd0,
              INIT           = 3'd1,
              START          = 3'd2,
              CLK_FALL       = 3'd3,
              SETUP          = 3'd4,
              CLK_RISE       = 3'd5,
              WAIT_IIC       = 3'd6,
              XFER_DONE      = 3'd7,
              START_BIT      = 1'b1,
              ACK            = 1'b1,
              WRITE          = 1'b0,
              REG_ADDR0      = 8'h49,
              REG_ADDR1      = 8'h21,
              REG_ADDR2      = 8'h33,
              REG_ADDR3      = 8'h34,
              REG_ADDR4      = 8'h36,
              DATA0          = 8'hC0,
              DATA1          = 8'h09,
              DATA2a         = 8'h06,
              DATA3a         = 8'h26,
              DATA4a         = 8'hA0,
              DATA2b         = 8'h08,
              DATA3b         = 8'h16,
              DATA4b         = 8'h60,
              STOP_BIT       = 1'b0,            
              SDA_BUFFER_MSB = 27; 
          
wire [6:0]    SLAVE_ADDR = C_I2C_SLAVE_ADDR ;
          

reg                          SDA_out; 
reg                          SCL_out;  
reg [TRANSITION_CYCLE_MSB:0] cycle_count;
reg [2:0]                    c_state;
reg [2:0]                    n_state;
reg                          Done;   
reg [2:0]                    write_count;
reg [31:0]                   bit_count;
reg [SDA_BUFFER_MSB:0]       SDA_BUFFER;
wire                         transition; 
reg                          IIC_xfer_done;


// Generate I2C clock and data 
always @ (posedge Clk) 
begin : I2C_CLK_DATA
    if (~Reset_n || c_state == IDLE )
      begin
        SDA_out <= 1'b1;
        SCL_out <= 1'b1;
      end
    else if (c_state == INIT && transition) 
      begin 
        SDA_out <= 1'b0;
      end
    else if (c_state == SETUP) 
      begin
        SDA_out <= SDA_BUFFER[SDA_BUFFER_MSB];
      end
    else if (c_state == CLK_RISE && cycle_count == TRANSITION_CYCLE/2 
                                 && bit_count == SDA_BUFFER_MSB) 
      begin
        SDA_out <= 1'b1;
      end
    else if (c_state == CLK_FALL) 
      begin
        SCL_out <= 1'b0;
      end
    
    else if (c_state == CLK_RISE) 
      begin
        SCL_out <= 1'b1;
      end
end

assign SDA = SDA_out;
assign SCL = SCL_out;
                        

// Fill the SDA buffer 
always @ (posedge Clk) 
begin : SDA_BUF
    //reset or end condition
    if(~Reset_n) 
      begin
        SDA_BUFFER  <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR0,ACK,DATA0,ACK,STOP_BIT};
        cycle_count <= 0;
      end
    //setup sda for sck rise
    else if ( c_state==SETUP && cycle_count==TRANSITION_CYCLE)
      begin
        SDA_BUFFER <= {SDA_BUFFER[SDA_BUFFER_MSB-1:0],1'b0};
        cycle_count <= 0; 
      end
    //reset count at end of state
    else if ( cycle_count==TRANSITION_CYCLE)
       cycle_count <= 0; 
    //reset sda_buffer   
    else if (c_state==INIT && TFT_iic_xfer==1'b1) 
      begin
       SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,TFT_iic_reg_addr,
                                       ACK,TFT_iic_reg_data, ACK,STOP_BIT};
       cycle_count <= cycle_count+1;
      end   
    else if (c_state==WAIT_IIC )
      begin
        case(write_count)
          0:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR1,ACK,DATA1, 
                                                          ACK,STOP_BIT};
          1:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR2,ACK,DATA2b,
                                                          ACK,STOP_BIT};
          2:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR3,ACK,DATA3b,
                                                          ACK,STOP_BIT};
          3:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR4,ACK,DATA4b,
                                                          ACK,STOP_BIT};
        default: SDA_BUFFER <=28'dx;
        endcase 
        cycle_count <= cycle_count+1;
      end
    else
      cycle_count <= cycle_count+1;
end


// Generate write_count signal
always @ (posedge Clk)
begin : GEN_WRITE_CNT
 if(~Reset_n)
   write_count<=3'd0;
 else if (c_state == WAIT_IIC && cycle_count == TRANSITION_CYCLE && IIC_xfer_done==1'b0 )
   write_count <= write_count+1;
end    

// Transaction done signal                        
always @ (posedge Clk) 
begin : TRANS_DONE
    if(~Reset_n)
      Done <= 1'b0;
    else if (c_state == IDLE)
      Done <= 1'b1;
end
 
       
// Generate bit_count signal
always @ (posedge Clk) 
begin : BIT_CNT
    if(~Reset_n || (c_state == WAIT_IIC)) 
       bit_count <= 0;
    else if ( c_state == CLK_RISE && cycle_count == TRANSITION_CYCLE)
       bit_count <= bit_count+1;
end    

// Next state block
always @ (posedge Clk) 
begin : NEXT_STATE
    if(~Reset_n)
       c_state <= INIT;
    else 
       c_state <= n_state;
end    

// generate transition for I2C
assign transition = (cycle_count == TRANSITION_CYCLE); 
              
//Next state              
//always @ (*) 
always @ (Reset_n, TFT_iic_xfer, transition, bit_count, write_count,
          c_state) 
begin : I2C_SM_CMB
   case(c_state) 
       //////////////////////////////////////////////////////////////
       //  IDLE STATE
       //////////////////////////////////////////////////////////////
       IDLE: begin
           if(~Reset_n | TFT_iic_xfer) 
             n_state = INIT;
           else 
             n_state = IDLE;
           IIC_xfer_done = 1'b0;

       end
       //////////////////////////////////////////////////////////////
       //  INIT STATE
       //////////////////////////////////////////////////////////////
       INIT: begin
          if (transition) 
            n_state = START;
          else 
            n_state = INIT;
          IIC_xfer_done = 1'b0;
       end
       //////////////////////////////////////////////////////////////
       //  START STATE
       //////////////////////////////////////////////////////////////
       START: begin
          if( transition) 
            n_state = CLK_FALL;
          else 
            n_state = START;
          IIC_xfer_done = 1'b0;
       end
       //////////////////////////////////////////////////////////////
       //  CLK_FALL STATE
       //////////////////////////////////////////////////////////////
       CLK_FALL: begin
          if( transition) 
            n_state = SETUP;
          else 
            n_state = CLK_FALL;
          IIC_xfer_done = 1'b0;
       end
       //////////////////////////////////////////////////////////////
       //  SETUP STATE
       //////////////////////////////////////////////////////////////
       SETUP: begin
          if( transition) 
            n_state = CLK_RISE;
          else 
            n_state = SETUP;
          IIC_xfer_done = 1'b0;
       end
       //////////////////////////////////////////////////////////////
       //  CLK_RISE STATE
       //////////////////////////////////////////////////////////////
       CLK_RISE: begin
          if( transition && bit_count == SDA_BUFFER_MSB) 
            n_state = WAIT_IIC;
          else if (transition )
            n_state = CLK_FALL;  
          else 
            n_state = CLK_RISE;
          IIC_xfer_done = 1'b0;
       end  
       //////////////////////////////////////////////////////////////
       //  WAIT_IIC STATE
       //////////////////////////////////////////////////////////////
       WAIT_IIC: begin
          IIC_xfer_done = 1'b0;          
          if((transition && write_count <= 3'd3))
            begin
              n_state = INIT;
            end
          else if (transition ) 
            begin
              n_state = XFER_DONE;
            end  
          else 
            begin 
              n_state = WAIT_IIC;
            end  
         end 

       //////////////////////////////////////////////////////////////
       //  XFER_DONE STATE
       //////////////////////////////////////////////////////////////
       XFER_DONE: begin
          
          IIC_xfer_done = 1'b1;
          
          if(transition)
              n_state = IDLE;
          else 
              n_state = XFER_DONE;
         end 

       default: n_state = IDLE;


     
   endcase
end


endmodule
