  -------------------------------------------------------------------------------
  -- axi_master_burst_first_stb_offset.vhd
  -------------------------------------------------------------------------------
  --
  -- *************************************************************************
  --                                                                      
  -- (c) Copyright 2011 Xilinx, Inc. All rights reserved.
  --
  -- This file contains confidential and proprietary information
  -- of Xilinx, Inc. and is protected under U.S. and 
  -- international copyright and other intellectual property
  -- laws.
  --
  -- DISCLAIMER
  -- This disclaimer is not a license and does not grant any
  -- rights to the materials distributed herewith. Except as
  -- otherwise provided in a valid license issued to you by
  -- Xilinx, and to the maximum extent permitted by applicable
  -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
  -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
  -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
  -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
  -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
  -- (2) Xilinx shall not be liable (whether in contract or tort,
  -- including negligence, or under any other theory of
  -- liability) for any loss or damage of any kind or nature
  -- related to, arising under or in connection with these
  -- materials, including for any direct, or any indirect,
  -- special, incidental, or consequential loss or damage
  -- (including loss of data, profits, goodwill, or any type of
  -- loss or damage suffered as a result of any action brought
  -- by a third party) even if such damage or loss was
  -- reasonably foreseeable or Xilinx had been advised of the
  -- possibility of the same.
  --
  -- CRITICAL APPLICATIONS
  -- Xilinx products are not designed or intended to be fail-
  -- safe, or for use in any application requiring fail-safe
  -- performance, such as life-support or safety devices or
  -- systems, Class III medical devices, nuclear facilities,
  -- applications related to the deployment of airbags, or any
  -- other applications that could lead to death, personal
  -- injury, or severe property or environmental damage
  -- (individually and collectively, "Critical
  -- Applications"). Customer assumes the sole risk and
  -- liability of any use of Xilinx products in Critical
  -- Applications, subject only to applicable laws and
  -- regulations governing limitations on product liability.
  --
  -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
  -- PART OF THIS FILE AT ALL TIMES.
  --
  -- *************************************************************************
  --
  -------------------------------------------------------------------------------
  -- Filename:        axi_master_burst_first_stb_offset.vhd
  --
  -- Description:     
  --    This file implements a module to find the address offset of the first 
  --    strobe bit asserted active high on the input strobe bus. This module 
  --    does not support sparse strobe assertions (asserted strobes must be 
  --    contiguous with each other).              
  --                  
  -- VHDL-Standard:   VHDL'93
  -------------------------------------------------------------------------------
  -- Structure:   
  --              axi_master_burst_first_stb_offset.vhd
  --
  -------------------------------------------------------------------------------
  -- Revision History:
  --
  --
  -- Author:          DET
  -- Revision:        $Revision: 1.0 $
  -- Date:            $1/19/2011$
  --
  -- History:
  --     DET     1/19/2011     Initial
  -- ~~~~~~
  --     - Adapted from AXI DataMover v2_00_a axi_datamvore_stbs_set.vhd
  -- ^^^^^^
  --
  --
  -------------------------------------------------------------------------------
  library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
  


  
  -------------------------------------------------------------------------------
  
  entity axi_master_burst_first_stb_offset is
    generic (
      
      C_STROBE_WIDTH    : Integer range 1 to 32 := 8;
        -- Specifies the width (in bits) ob the input strobe bus.
      C_OFFSET_WIDTH    : Integer range 1 to 16 := 8
        -- Indicates the bit width of the offset output port
      
      );
    port (
      
      tstrb_in          : in  std_logic_vector(C_STROBE_WIDTH-1 downto 0);
        -- Input Strobe bus
     
      first_offset      : Out unsigned(C_OFFSET_WIDTH-1 downto 0)
        -- Offset output port
     
 
      );
  
  end entity axi_master_burst_first_stb_offset;
  
  
  architecture implementation of axi_master_burst_first_stb_offset is
  
    
    -- Function Declarations
    
    
    -------------------------------------------------------------------
    -- Function
    --
    -- Function Name: funct_4bit_first_be_set
    --
    -- Function Description:
    --  Implements an 4-bit lookup table for calculating the index
    -- of the first BE asserted within an 4-bit BE vector.
    --
    -- Note that this function assumes that asserted strobes are 
    -- contiguous with each other (no sparse strobe assertions). 
    --
    -------------------------------------------------------------------
    function funct_4bit_first_be_set (be_4bit : std_logic_vector(3 downto 0)) return Integer is
    
      
      Variable lvar_first_be_set : Integer range 0 to 3 := 0;
    
    begin
    
      case be_4bit is
        
        -- -------  0 bit --------------------------
        -- when "0001" | "0011" | "0111" | "1111" =>
        -- 
        --   lvar_first_be_set := 0;
        
        
        -------  1 bit --------------------------
        when "0010" | "0110" | "1110"  =>
        
          lvar_first_be_set := 1;
        
        
        -------  2 bit --------------------------
        when "0100" | "1100" =>
        
          lvar_first_be_set := 2;
        
        
        -------  3 bit --------------------------
        when "1000" =>
        
          lvar_first_be_set := 3;
        
        
        ------- bit 0, or all zeros, or sparse strobes ------
        When others =>  
        
          lvar_first_be_set := 0;
        
      end case;
      
      
      Return (lvar_first_be_set);
       
       
      
    end function funct_4bit_first_be_set;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    -------------------------------------------------------------------
    -- Function
    --
    -- Function Name: funct_8bit_first_be_set
    --
    -- Function Description:
    --  Implements an 8-bit lookup table for calculating the index
    -- of the first BE asserted within an 8-bit BE vector.
    --
    -- Note that this function assumes that asserted strobes are 
    -- contiguous with each other (no sparse strobe assertions). 
    --
    -------------------------------------------------------------------
    function funct_8bit_first_be_set(be_8bit : std_logic_vector(7 downto 0)) return integer is
    
      
      Variable lvar_first_be_set : Integer range 0 to 7 := 0;
    
    begin
    
      case be_8bit is
        
        -- -------  0 bit --------------------------
        -- when "00000001" | "00000011" | "00000111" | "00001111" | 
        --      "00011111" | "00111111" | "01111111" | "11111111" =>
        -- 
        --   lvar_first_be_set := 0;
        
        
        -------  1 bit --------------------------
        when "00000010" | "00000110" | "00001110" | "00011110" | 
             "00111110" | "01111110" | "11111110"  =>
        
          lvar_first_be_set := 1;
        
        
        -------  2 bit --------------------------
        when "00000100" | "00001100" | "00011100" | "00111100" | 
             "01111100" | "11111100"   =>
        
          lvar_first_be_set := 2;
        
        
        -------  3 bit --------------------------
        when "00001000" | "00011000" | "00111000" | "01111000" | 
             "11111000"    =>
        
          lvar_first_be_set := 3;
        
        
        -------  4 bit --------------------------
        when "00010000" | "00110000" | "01110000" | "11110000"  =>
        
          lvar_first_be_set := 4;
        
        
        -------  5 bit --------------------------
        when "00100000" | "01100000" | "11100000"  =>
        
          lvar_first_be_set := 5;
        
        
        -------  6 bit --------------------------
        when "01000000" | "11000000"   =>
        
          lvar_first_be_set := 6;
        
        
        -------  7 bit --------------------------
        when "10000000"    =>
        
          lvar_first_be_set := 7;
        
        
        ------- bit 0, or all zeros, or sparse strobes ------
        When others =>  
        
          lvar_first_be_set := 0;
        
      end case;
      
      
      Return (lvar_first_be_set);
       
       
      
    end function funct_8bit_first_be_set;
    
    
    
    
    -------------------------------------------------------------------
    -- Function
    --
    -- Function Name: funct_16bit_first_be_set
    --
    -- Function Description:
    --  Implements an 16-bit lookup table for calculating the index
    -- of the first BE asserted within an 16-bit BE vector.
    --
    -- Note that this function assumes that asserted strobes are 
    -- contiguous with each other (no sparse strobe assertions). 
    --
    -------------------------------------------------------------------
    function funct_16bit_first_be_set(be_16bit : std_logic_vector(15 downto 0)) return integer is
    
      
      Variable lvar_first_be_set : Integer range 0 to 15 := 0;
    
    begin
    
      case be_16bit is
        
        ---------  0 bit --------------------------
        --when "0000000000000001" | "0000000000000011" | "0000000000000111" | "0000000000001111" | 
        --     "0000000000011111" | "0000000000111111" | "0000000001111111" | "0000000011111111" | 
        --     "0000000111111111" | "0000001111111111" | "0000011111111111" | "0000111111111111" | 
        --     "0001111111111111" | "0011111111111111" | "0111111111111111" | "1111111111111111" =>
        --
        --  lvar_first_be_set := 0;
        
        
        -------  1 bit --------------------------
        when "0000000000000010" | "0000000000000110" | "0000000000001110" | "0000000000011110" | 
             "0000000000111110" | "0000000001111110" | "0000000011111110" | "0000000111111110" |
             "0000001111111110" | "0000011111111110" | "0000111111111110" | "0001111111111110" | 
             "0011111111111110" | "0111111111111110" | "1111111111111110"  =>
        
          lvar_first_be_set := 1;
        
        
        -------  2 bit --------------------------
        when "0000000000000100" | "0000000000001100" | "0000000000011100" | "0000000000111100" | 
             "0000000001111100" | "0000000011111100" | "0000000111111100" | "0000001111111100" |
             "0000011111111100" | "0000111111111100" | "0001111111111100" | "0011111111111100" |
             "0111111111111100" | "1111111111111100" =>
        
          lvar_first_be_set := 2;
        
        
        -------  3 bit --------------------------
        when "0000000000001000" | "0000000000011000" | "0000000000111000" | "0000000001111000" | 
             "0000000011111000" | "0000000111111000" | "0000001111111000" | "0000011111111000" |
             "0000111111111000" | "0001111111111000" | "0011111111111000" | "0111111111111000" |
             "1111111111111000" =>
        
          lvar_first_be_set := 3;
        
        
        -------  4 bit --------------------------
        when "0000000000010000" | "0000000000110000" | "0000000001110000" | "0000000011110000"  |
             "0000000111110000" | "0000001111110000" | "0000011111110000" | "0000111111110000"  |
             "0001111111110000" | "0011111111110000" | "0111111111110000" | "1111111111110000" =>
        
          lvar_first_be_set := 4;
        
        
        -------  5 bit --------------------------
        when "0000000000100000" | "0000000001100000" | "0000000011100000" | "0000000111100000" |
             "0000001111100000" | "0000011111100000" | "0000111111100000" | "0001111111100000" |
             "0011111111100000" | "0111111111100000" | "1111111111100000" =>
        
          lvar_first_be_set := 5;
        
        
        -------  6 bit --------------------------
        when "0000000001000000" | "0000000011000000" | "0000000111000000" | "0000001111000000" |
             "0000011111000000" | "0000111111000000" | "0001111111000000" | "0011111111000000" |
             "0111111111000000" | "1111111111000000" =>
        
          lvar_first_be_set := 6;
        
        
        -------  7 bit --------------------------
        when "0000000010000000" | "0000000110000000" | "0000001110000000" | "0000011110000000" |
             "0000111110000000" | "0001111110000000" | "0011111110000000" | "0111111110000000"  |
             "1111111110000000" =>
        
          lvar_first_be_set := 7;
        
        
        -------  8 bit --------------------------
        when "0000000100000000" | "0000001100000000" | "0000011100000000" | "0000111100000000" |
             "0001111100000000" | "0011111100000000" | "0111111100000000" | "1111111100000000"  =>
        
          lvar_first_be_set := 8;
        
        
        
        -------  9 bit --------------------------
        when "0000001000000000" | "0000011000000000" | "0000111000000000" | "0001111000000000" |
             "0011111000000000" | "0111111000000000" | "1111111000000000"  =>
        
          lvar_first_be_set := 9;
      
        
        -------  10 bit --------------------------
        when "0000010000000000" | "0000110000000000" | "0001110000000000" | "0011110000000000" |
             "0111110000000000" | "1111110000000000"  =>
        
          lvar_first_be_set := 10;
      
        
        -------  11 bit --------------------------
        when "0000100000000000" | "0001100000000000" | "0011100000000000" | "0111100000000000" |
             "1111100000000000" =>
        
          lvar_first_be_set := 11;
        
        
        -------  12 bit --------------------------
        when "0001000000000000" | "0011000000000000" | "0111000000000000" | "1111000000000000" =>
        
          lvar_first_be_set := 12;
        
        
        -------  13 bit --------------------------
        when "0010000000000000" | "0110000000000000" | "1110000000000000" =>
        
          lvar_first_be_set := 13;
        
        
        -------  14 bit --------------------------
        when "0100000000000000" | "1100000000000000" =>
        
          lvar_first_be_set := 14;
        
        
        -------  15 bit --------------------------
        when "1000000000000000" =>
        
          lvar_first_be_set := 15;
        

        
        ------- Bit 0, or all zeros, or sparse strobes ------
        When others =>  
        
          lvar_first_be_set := 0;
        
      end case;
      
      
      Return (lvar_first_be_set);
       
       
      
    end function funct_16bit_first_be_set;
    
    
    
    
    -- Signals
    
    signal sig_strb_input           : std_logic_vector(C_STROBE_WIDTH-1 downto 0) := (others => '0');
    
    signal sig_first_offset_unsgnd  : unsigned(C_OFFSET_WIDTH-1 downto 0) := (others => '0');
    
    
  begin --(architecture implementation)
  
   
    
    
    
    -- Assign the input port value
    sig_strb_input <= tstrb_in;
  
    
    
    -- Assign the output port value
    first_offset   <= sig_first_offset_unsgnd;
  
  
    
    
    
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: GEN_4BIT_CASE
    --
    -- If Generate Description:
    --   Implement the 4-bit strobe width case
    --
    --
    ------------------------------------------------------------
    GEN_4BIT_CASE : if (C_STROBE_WIDTH = 4) generate
    
      signal sig_first_offset         : integer range 0 to 15 := 0;
   
      begin
        
        sig_first_offset        <= funct_4bit_first_be_set(sig_strb_input);
        sig_first_offset_unsgnd <= TO_UNSIGNED(sig_first_offset, C_OFFSET_WIDTH);
        
      end generate GEN_4BIT_CASE;
 
 
 
  
  
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: GEN_8BIT_CASE
    --
    -- If Generate Description:
    --   Implement the 8-bit strobe width case
    --
    --
    ------------------------------------------------------------
    GEN_8BIT_CASE : if (C_STROBE_WIDTH = 8) generate
    
      signal sig_first_offset         : integer range 0 to 15 := 0;
   
      begin
   
        sig_first_offset         <= funct_8bit_first_be_set(sig_strb_input);
         sig_first_offset_unsgnd <= TO_UNSIGNED(sig_first_offset, C_OFFSET_WIDTH);
        
      end generate GEN_8BIT_CASE;
 
  
  
  
  
  
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: GEN_16BIT_CASE
    --
    -- If Generate Description:
    --   Implement the 16-bit strobe width case
    --
    --
    ------------------------------------------------------------
    GEN_16BIT_CASE : if (C_STROBE_WIDTH = 16) generate
    
      signal sig_first_offset         : integer range 0 to 15 := 0;
   
      begin
   
        sig_first_offset        <= funct_16bit_first_be_set(sig_strb_input);
        sig_first_offset_unsgnd <= TO_UNSIGNED(sig_first_offset, C_OFFSET_WIDTH);
        
      end generate GEN_16BIT_CASE;
 
  
  
  
  
  
  
  
  
  end implementation;
