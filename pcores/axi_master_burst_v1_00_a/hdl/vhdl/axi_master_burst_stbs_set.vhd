  -------------------------------------------------------------------------------
  -- axi_master_burst_stbs_set.vhd
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
  -- Filename:        axi_master_burst_stbs_set.vhd
  --
  -- Description:     
  --    This file implements a module to count the number of strobe bits that 
  --    are asserted active high on the input strobe bus. This module does not
  --    support sparse strobe assertions (asserted strobes must be contiguous
  --    with each other).              
  --                  
  -- VHDL-Standard:   VHDL'93
  -------------------------------------------------------------------------------
  -- Structure:   
  --              axi_master_burst_stbs_set.vhd
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
  
  entity axi_master_burst_stbs_set is
    generic (
      
      C_STROBE_WIDTH    : Integer range 1 to 32 := 8
        -- Specifies the width (in bits) ob the input strobe bus.
      
      );
    port (
      
      tstrb_in          : in  std_logic_vector(C_STROBE_WIDTH-1 downto 0);
        -- Input Strobe bus
     
      num_stbs_asserted : Out std_logic_vector(7 downto 0)
        -- Indicates the number of asserted tstrb_in bits 
     
 
      );
  
  end entity axi_master_burst_stbs_set;
  
  
  architecture implementation of axi_master_burst_stbs_set is
  
    
    -- Function
    -------------------------------------------------------------------
    -- Function
    --
    -- Function Name: funct_8bit_stbs_set
    --
    -- Function Description:
    --  Implements an 8-bit lookup table for calculating the number
    -- of asserted bits within an 8-bit strobe vector.
    --
    -- Note that this function assumes that asserted strobes are 
    -- contiguous with each other (no sparse strobe assertions). 
    --
    -------------------------------------------------------------------
    function funct_8bit_stbs_set (strb_8 : std_logic_vector(7 downto 0)) return unsigned is
    
      Constant ASSERTED_VALUE_WIDTH : integer := 4;-- 4 bits needed
      
      
      Variable lvar_num_set : Integer range 0 to 8 := 0;
    
    begin
    
      case strb_8 is
        
        -------  1 bit --------------------------
        when "00000001" | "00000010" | "00000100" | "00001000" | 
             "00010000" | "00100000" | "01000000" | "10000000" =>
        
          lvar_num_set := 1;
        
        
        -------  2 bit --------------------------
        when "00000011" | "00000110" | "00001100" | "00011000" | 
             "00110000" | "01100000" | "11000000"  =>
        
          lvar_num_set := 2;
        
        
        -------  3 bit --------------------------
        when "00000111" | "00001110" | "00011100" | "00111000" | 
             "01110000" | "11100000"   =>
        
          lvar_num_set := 3;
        
        
        -------  4 bit --------------------------
        when "00001111" | "00011110" | "00111100" | "01111000" | 
             "11110000"    =>
        
          lvar_num_set := 4;
        
        
        -------  5 bit --------------------------
        when "00011111" | "00111110" | "01111100" | "11111000"  =>
        
          lvar_num_set := 5;
        
        
        -------  6 bit --------------------------
        when "00111111" | "01111110" | "11111100"  =>
        
          lvar_num_set := 6;
        
        
        -------  7 bit --------------------------
        when "01111111" | "11111110"   =>
        
          lvar_num_set := 7;
        
        
        -------  8 bit --------------------------
        when "11111111"    =>
        
          lvar_num_set := 8;
        
        
        ------- all zeros or sparse strobes ------
        When others =>  
        
          lvar_num_set := 0;
        
      end case;
      
      
      Return (TO_UNSIGNED(lvar_num_set, ASSERTED_VALUE_WIDTH));
       
       
      
    end function funct_8bit_stbs_set;
    
    
    
    
    
    
    -- Constants
    
    Constant LOGIC_LOW              : std_logic := '0';
    Constant LOGIC_HIGH             : std_logic := '1';
    Constant BITS_FOR_STBS_ASSERTED : integer := 8; -- increments of 8 bits
    Constant NUM_ZEROS_WIDTH        : integer := BITS_FOR_STBS_ASSERTED;
    
    
    -- Signals
    
    signal sig_strb_input           : std_logic_vector(C_STROBE_WIDTH-1 downto 0) := (others => '0');
    signal sig_stbs_asserted        : std_logic_vector(BITS_FOR_STBS_ASSERTED-1 downto 0) := (others => '0');


    
    
  begin --(architecture implementation)
  
   
   num_stbs_asserted     <= sig_stbs_asserted;
   
   sig_strb_input        <= tstrb_in         ;
    
    
    
    
 
 
    -------------------------------------------------------------------------
    ----------------  Asserted TSTRB calculation logic  --------------------- 
    -------------------------------------------------------------------------
    
    
 
   
     
     ------------------------------------------------------------
     -- If Generate
     --
     -- Label: GEN_1_STRB
     --
     -- If Generate Description:
     --   1-bit strobe bus width case
     --
     --
     ------------------------------------------------------------
     GEN_1_STRB : if (C_STROBE_WIDTH = 1) generate
     
     
        begin
     
          -------------------------------------------------------------
          -- Combinational Process
          --
          -- Label: IMP_1BIT_STRB
          --
          -- Process Description:
          --
          --
          -------------------------------------------------------------
          IMP_1BIT_STRB : process (sig_strb_input)
             begin
          
               
               -- Concatonate the strobe to the ls bit of
               -- the asserted value
               sig_stbs_asserted <= "0000000" &
                                    sig_strb_input(0);
          
             end process IMP_1BIT_STRB; 
        
        end generate GEN_1_STRB;
   
   
   
   
   
   
     ------------------------------------------------------------
     -- If Generate
     --
     -- Label: GEN_2_STRB
     --
     -- If Generate Description:
     --   2-bit strobe bus width case
     --
     --
     ------------------------------------------------------------
     GEN_2_STRB : if (C_STROBE_WIDTH = 2) generate
     
     
        signal lsig_num_set     : integer range 0 to 2 := 0;
        signal lsig_strb_vect   : std_logic_vector(1 downto 0) := (others => '0');
        
        begin
     
          
          lsig_strb_vect <=  sig_strb_input;
          
          
          -------------------------------------------------------------
          -- Combinational Process
          --
          -- Label: IMP_2BIT_STRB
          --
          -- Process Description:
          --  Calculates the number of strobes set fo the 2-bit 
          -- strobe case
          --
          -------------------------------------------------------------
          IMP_2BIT_STRB : process (lsig_strb_vect)
             begin
              
               case lsig_strb_vect is
                 when "01" | "10" =>
                   lsig_num_set <= 1;
                 when "11" =>
                   lsig_num_set <= 2;
                 when others =>
                   lsig_num_set <= 0;
               end case;
               
             end process IMP_2BIT_STRB; 
             
          
          sig_stbs_asserted <= STD_LOGIC_VECTOR(TO_UNSIGNED(lsig_num_set,
                                                            BITS_FOR_STBS_ASSERTED));
     
        
        end generate GEN_2_STRB;
   
   
   
   
     ------------------------------------------------------------
     -- If Generate
     --
     -- Label: GEN_4_STRB
     --
     -- If Generate Description:
     --   4-bit strobe bus width case
     --
     --
     ------------------------------------------------------------
     GEN_4_STRB : if (C_STROBE_WIDTH = 4) generate
     
     
       signal lsig_strb_vect   : std_logic_vector(7 downto 0) := (others => '0');
        
       begin
     
          
         lsig_strb_vect <=  "0000" & sig_strb_input; -- make and 8-bit vector 
                                                     -- for the function call
          
          
         sig_stbs_asserted <= STD_LOGIC_VECTOR(RESIZE(funct_8bit_stbs_set(lsig_strb_vect),
                                                      BITS_FOR_STBS_ASSERTED));
     
     
       end generate GEN_4_STRB;
   
   
  
  
   
   
     ------------------------------------------------------------
     -- If Generate
     --
     -- Label: GEN_8_STRB
     --
     -- If Generate Description:
     --   8-bit strobe bus width case
     --
     --
     ------------------------------------------------------------
     GEN_8_STRB : if (C_STROBE_WIDTH = 8) generate
     
     
       signal lsig_strb_vect   : std_logic_vector(7 downto 0) := (others => '0');
        
       begin
     
          
         lsig_strb_vect <=  sig_strb_input; -- make and 8-bit vector 
                                            -- for the function call
          
          
         sig_stbs_asserted <= STD_LOGIC_VECTOR(RESIZE(funct_8bit_stbs_set(lsig_strb_vect),
                                                           BITS_FOR_STBS_ASSERTED));
     
     
       end generate GEN_8_STRB;
   
   
   
   
   
     ------------------------------------------------------------
     -- If Generate
     --
     -- Label: GEN_16_STRB
     --
     -- If Generate Description:
     --   16-bit strobe bus width case
     --
     --
     ------------------------------------------------------------
     GEN_16_STRB : if (C_STROBE_WIDTH = 16) generate
     
       Constant RESULT_BIT_WIDTH : integer := 8;
       
       signal lsig_strb_vect1    : std_logic_vector(7 downto 0) := (others => '0');
       signal lsig_strb_vect2    : std_logic_vector(7 downto 0) := (others => '0');
       signal lsig_num_in_stbs1  : unsigned(3 downto 0) := (others => '0');
       signal lsig_num_in_stbs2  : unsigned(3 downto 0) := (others => '0');
       signal lsig_num_total     : unsigned(RESULT_BIT_WIDTH-1 downto 0) := (others => '0');
        
       begin
     
          
         lsig_strb_vect1   <=  sig_strb_input(7 downto 0); -- make and 8-bit vector 
                                                           -- for the function call
          
         lsig_strb_vect2   <=  sig_strb_input(15 downto 8); -- make and 8-bit vector 
                                                            -- for the function call
          
          
         lsig_num_in_stbs1 <=  funct_8bit_stbs_set(lsig_strb_vect1) ;
          
         lsig_num_in_stbs2 <=  funct_8bit_stbs_set(lsig_strb_vect2) ;
          
          
         lsig_num_total    <= RESIZE(lsig_num_in_stbs1 , RESULT_BIT_WIDTH) +
                              RESIZE(lsig_num_in_stbs2 , RESULT_BIT_WIDTH);
          
          
          
         sig_stbs_asserted <= STD_LOGIC_VECTOR(lsig_num_total);
     
     
       end generate GEN_16_STRB;
   
   
   
   
   
   
   
     ------------------------------------------------------------
     -- If Generate
     --
     -- Label: GEN_32_STRB
     --
     -- If Generate Description:
     --   32-bit strobe bus width case
     --
     --
     ------------------------------------------------------------
     GEN_32_STRB : if (C_STROBE_WIDTH = 32) generate
     
       Constant RESULT_BIT_WIDTH : integer := 8;
       
       signal lsig_strb_vect1   : std_logic_vector(7 downto 0) := (others => '0');
       signal lsig_strb_vect2   : std_logic_vector(7 downto 0) := (others => '0');
       signal lsig_strb_vect3   : std_logic_vector(7 downto 0) := (others => '0');
       signal lsig_strb_vect4   : std_logic_vector(7 downto 0) := (others => '0');
       signal lsig_num_in_stbs1 : unsigned(3 downto 0) := (others => '0');
       signal lsig_num_in_stbs2 : unsigned(3 downto 0) := (others => '0');
       signal lsig_num_in_stbs3 : unsigned(3 downto 0) := (others => '0');
       signal lsig_num_in_stbs4 : unsigned(3 downto 0) := (others => '0');
       signal lsig_num_total    : unsigned(RESULT_BIT_WIDTH-1 downto 0) := (others => '0');
        
       begin
     
          
         lsig_strb_vect1   <=  sig_strb_input(7 downto 0);   -- make and 8-bit vector 
                                                       -- for the function call
          
         lsig_strb_vect2   <=  sig_strb_input(15 downto 8);  -- make and 8-bit vector 
                                                       -- for the function call
          
         lsig_strb_vect3   <=  sig_strb_input(23 downto 16); -- make and 8-bit vector 
                                                       -- for the function call
          
         lsig_strb_vect4   <=  sig_strb_input(31 downto 24); -- make and 8-bit vector 
                                                       -- for the function call
          
          
         lsig_num_in_stbs1 <=  funct_8bit_stbs_set(lsig_strb_vect1) ;
          
         lsig_num_in_stbs2 <=  funct_8bit_stbs_set(lsig_strb_vect2) ;
         
         lsig_num_in_stbs3 <=  funct_8bit_stbs_set(lsig_strb_vect3) ;
         
         lsig_num_in_stbs4 <=  funct_8bit_stbs_set(lsig_strb_vect4) ;
          
          
         lsig_num_total    <= RESIZE(lsig_num_in_stbs1 , RESULT_BIT_WIDTH) +
                              RESIZE(lsig_num_in_stbs2 , RESULT_BIT_WIDTH) +
                              RESIZE(lsig_num_in_stbs3 , RESULT_BIT_WIDTH) +
                              RESIZE(lsig_num_in_stbs4 , RESULT_BIT_WIDTH);
          
          
          
         sig_stbs_asserted <= STD_LOGIC_VECTOR(lsig_num_total);
     
     
       end generate GEN_32_STRB;
   
   
   
 
 
  
  
  end implementation;
