-------------------------------------------------------------------------------
-- axi_master_burst_strb_gen.vhd
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
-- Filename:        axi_master_burst_strb_gen.vhd
--
-- Description:     
--   AXI Strobe Generator module.               
--                  
--                  
--                  
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              axi_master_burst_strb_gen.vhd
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
--     - Adapted from AXI DataMover V2_00_a axi_datamover_strb_gen.vhd
-- ^^^^^^
--
--     DET     2/15/2011     Initial for EDk 13.2
-- ~~~~~~
--    -- Per CR593812
--     - Modifications to remove unused features to improve Code coverage.
--       Used "-- coverage off" and "-- coverage on" strings.
-- ^^^^^^
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;




-------------------------------------------------------------------------------

entity axi_master_burst_strb_gen is
  generic (
    C_ADDR_MODE          : Integer := 0; -- 0 = normal, 1 = Address only 
    C_STRB_WIDTH         : Integer := 8; -- number of addr bits needed
    C_OFFSET_WIDTH       : Integer := 3; -- log2(C_STRB_WIDTH)
    C_NUM_BYTES_WIDTH    : Integer := 3  -- log2(C_STRB_WIDTH)+1 in normal mode
                                         -- log2(C_STRB_WIDTH) in addr mode
    );
  port (
    start_addr_offset    : In  std_logic_vector(C_OFFSET_WIDTH-1 downto 0);   -- Starting address byte offset
    num_valid_bytes      : In  std_logic_vector(C_NUM_BYTES_WIDTH-1 downto 0);-- Number of valid bytes from offset 

    strb_out             : out std_logic_vector(C_STRB_WIDTH-1 downto 0)      -- Strobes generated from the inputs
    );

end entity axi_master_burst_strb_gen;


architecture implementation of axi_master_burst_strb_gen is

  
 
  

begin --(architecture implementation)

 
 
 
 
  ------------------------------------------------------------
  -- If Generate
  --
  -- Label: GEN_OFFSET_MODE
  --
  -- If Generate Description:
  -- Normal mode strobe generation where a starting address 
  -- offset is provided and a number of bytes beyond that 
  -- address that remain. 
  --
  --
  ------------------------------------------------------------
  GEN_OFFSET_MODE : if (C_ADDR_MODE = 0) generate
  
     -- Constants Declarations
   
      Constant INTERNAL_CALC_WIDTH    : integer  := C_NUM_BYTES_WIDTH+2; -- 2 bits of math headroom
      Constant ONE                    : unsigned := TO_UNSIGNED(1, INTERNAL_CALC_WIDTH);
   
     -- local signals
      signal sig_addr_offset_us       : unsigned(INTERNAL_CALC_WIDTH-1 downto 0) := (others => '0');
      signal sig_num_valid_bytes_us   : unsigned(INTERNAL_CALC_WIDTH-1 downto 0) := (others => '0');
      signal sig_incr_offset_bytes_us : unsigned(INTERNAL_CALC_WIDTH-1 downto 0) := (others => '0');
      signal sig_end_addr_us          : unsigned(INTERNAL_CALC_WIDTH-1 downto 0) := (others => '0');
      signal sig_end_addr_int         : integer := 0;
      signal sig_strt_addr_int        : integer := 0;
      signal sig_strb_value           : std_logic_vector(C_STRB_WIDTH-1 downto 0) := (others => '0');
      signal sig_select_value         : std_logic_vector(C_STRB_WIDTH-1 downto 0) := (others => '0');
     
      
  
     begin
  
       -- assign output
       strb_out                 <= sig_strb_value;

       sig_addr_offset_us       <= RESIZE(UNSIGNED(start_addr_offset), INTERNAL_CALC_WIDTH);
       
       sig_num_valid_bytes_us   <= RESIZE(UNSIGNED(num_valid_bytes)  , INTERNAL_CALC_WIDTH);

       sig_incr_offset_bytes_us <= sig_num_valid_bytes_us - ONE;
       
       sig_end_addr_us          <= sig_addr_offset_us + sig_incr_offset_bytes_us;
      
       sig_strt_addr_int        <= TO_INTEGER(sig_addr_offset_us);
       
       sig_end_addr_int         <= TO_INTEGER(sig_end_addr_us);
      
       
       -------------------------------------------------------------
       -- Combinational Process
       --
       -- Label: IMP_STRB_FILL
       --
       -- Process Description:
       --  Fills in the strobes between the start index and end index.
       --
       -------------------------------------------------------------
       IMP_STRB_FILL : process (sig_strt_addr_int,
                                sig_end_addr_int)
         
         Variable temp_strb   : std_logic_vector(C_STRB_WIDTH-1 downto 0) := (others => '0');
         Variable strt_offset : Integer := 0;
         Variable end_offset  : Integer := 0;
         
         
         begin
      
           
           
           -- Establish the Start offset with clipping
-- coverage off           
           If (sig_strt_addr_int > C_STRB_WIDTH-1) Then
        
             strt_offset := C_STRB_WIDTH-1;
-- coverage on             
           
           else   
           
             strt_offset := sig_strt_addr_int; 
           
           End if;
           
           
           
           
           -- Establish the end offset with clipping
           If (sig_end_addr_int > C_STRB_WIDTH-1) Then
        
             end_offset := C_STRB_WIDTH-1;
             
           else   
           
             end_offset := sig_end_addr_int;
           
           End if;
           
           
            
           -- Set the appropriate strobe bits
           for loop_index in 0 to C_STRB_WIDTH-1 loop
           
             If (loop_index >= strt_offset and
                 loop_index <= end_offset) Then
             
              temp_strb(loop_index) := '1';
              
             Else 

              temp_strb(loop_index) := '0';
             
             End if;
           
           
           end loop;



           sig_strb_value <= temp_strb;

       
         end process IMP_STRB_FILL; 
       
      
   
   
   
     end generate GEN_OFFSET_MODE;
 
 
 
 
 
 
 
 
  ------------------------------------------------------------
  -- If Generate
  --
  -- Label: GEN_ADDR_MODE
  --
  -- If Generate Description:
  -- Address mode strobe generation where a starting address 
  -- offset is provided and a ending address offset is provided. 
  --
  --
  ------------------------------------------------------------
  GEN_ADDR_MODE : if (C_ADDR_MODE = 1) generate
  
     -- Local Constants Declarations
      Constant INTERNAL_CALC_WIDTH    : integer  := C_NUM_BYTES_WIDTH; -- use math clipping
      Constant ONE                    : unsigned := TO_UNSIGNED(1, INTERNAL_CALC_WIDTH);
   
     -- local signals
      signal sig_addr_offset_us       : unsigned(INTERNAL_CALC_WIDTH-1 downto 0) := (others => '0');
      signal sig_num_valid_bytes_us   : unsigned(INTERNAL_CALC_WIDTH-1 downto 0) := (others => '0');
      signal sig_incr_offset_bytes_us : unsigned(INTERNAL_CALC_WIDTH-1 downto 0) := (others => '0');
      signal sig_end_addr_us          : unsigned(INTERNAL_CALC_WIDTH-1 downto 0) := (others => '0');
      signal sig_end_addr_int         : integer := 0;
      signal sig_strt_addr_int        : integer := 0;
      signal sig_strb_value           : std_logic_vector(C_STRB_WIDTH-1 downto 0) := (others => '0');
      signal sig_select_value         : std_logic_vector(C_STRB_WIDTH-1 downto 0) := (others => '0');
  
     begin
  
       -- assign output
       strb_out                 <= sig_strb_value;

       sig_addr_offset_us       <= RESIZE(UNSIGNED(start_addr_offset), INTERNAL_CALC_WIDTH);
       
       sig_num_valid_bytes_us   <= RESIZE(UNSIGNED(num_valid_bytes)  , INTERNAL_CALC_WIDTH);

       sig_incr_offset_bytes_us <= sig_num_valid_bytes_us - ONE;
       
       sig_end_addr_us          <= sig_addr_offset_us + sig_incr_offset_bytes_us;
      
       sig_strt_addr_int        <= TO_INTEGER(sig_addr_offset_us);
       
       sig_end_addr_int         <= TO_INTEGER(sig_end_addr_us);
      
       
       -------------------------------------------------------------
       -- Combinational Process
       --
       -- Label: IMP_STRB_FILL
       --
       -- Process Description:
       --  Fills in the strobes between the start index and end index.
       --
       -------------------------------------------------------------
       IMP_STRB_FILL : process (sig_strt_addr_int,
                                sig_end_addr_int)
          
         
         Variable temp_strb : std_logic_vector(C_STRB_WIDTH-1 downto 0) := (others => '0');
        
         Variable strt_offset : Integer := 0;
         Variable end_offset  : Integer := 0;
         
         
         
         begin
      
           
           
           -- Establish the Start offset with clipping
-- coverage off           
           If (sig_strt_addr_int > C_STRB_WIDTH-1) Then
        
             strt_offset := C_STRB_WIDTH-1;
-- coverage on           
             
           else   
           
             strt_offset := sig_strt_addr_int; 
           
           End if;
           
           
           
           
           -- Establish the end offset with clipping
-- coverage off           
           If (sig_end_addr_int > C_STRB_WIDTH-1) Then
        
             end_offset := C_STRB_WIDTH-1;
-- coverage on           
             
           else   
           
             end_offset := sig_end_addr_int;
           
           End if;
           
           
            
           -- Set the appropriate strobe bits
           for loop_index in 0 to C_STRB_WIDTH-1 loop
           
             If (loop_index >= strt_offset and
                 loop_index <= end_offset) Then
             
              temp_strb(loop_index) := '1';
              
             Else 

              temp_strb(loop_index) := '0';
             
             End if;
           
           
           end loop;



           sig_strb_value <= temp_strb;

       
         end process IMP_STRB_FILL; 
       
      
   
   
   
     end generate GEN_ADDR_MODE;
 
 
 
 

end implementation;
