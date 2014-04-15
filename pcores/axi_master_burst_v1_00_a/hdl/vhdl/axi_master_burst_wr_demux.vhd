  -------------------------------------------------------------------------------
  -- axi_master_burst_wr_demux.vhd
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
  -- Filename:        axi_master_burst_wr_demux.vhd
  --
  -- Description:     
  --    This file implements the AXI Master Burst Write Strobe De-Multiplexer.                 
  --                  
  --                  
  --                  
  --                  
  -- VHDL-Standard:   VHDL'93
  -------------------------------------------------------------------------------
  -- Structure:   
  --              axi_master_burst_wr_demux.vhd
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
  --     - Adapted from AXi DataMover v2_00_a axi_datamover_wr_demux.vhd
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
  
  entity axi_master_burst_wr_demux is
    generic (
      
      C_SEL_ADDR_WIDTH     : Integer range  1  to  8 :=  5;
      C_MMAP_DWIDTH        : Integer range 32 to 256 := 32;
      C_STREAM_DWIDTH      : Integer range  8 to 256 := 32
      
      );
    port (
      
     
     -- AXI MMap Data Channel Input  -------------------------------
     
      wstrb_in         : In  std_logic_vector((C_STREAM_DWIDTH/8)-1 downto 0);
        -- data input
     
      
      
     -- AXI Master Stream  -----------------------------------
     
      demux_wstrb_out    : Out std_logic_vector((C_MMAP_DWIDTH/8)-1 downto 0);         
        --De-Mux strb output
               
                
                
      -- Command Calculator Interface --------------------------
      
      debeat_saddr_lsb : In std_logic_vector(C_SEL_ADDR_WIDTH-1 downto 0)
         -- The next command start address LSbs to use for the read data
         -- mux (only used if Stream data width is less than the MMap Data
         -- Width).
      
         
      );
  
  end entity axi_master_burst_wr_demux;
  
  
  architecture implementation of axi_master_burst_wr_demux is
  
    
    -- Function Decalarations -------------------------------------------------
    
    -------------------------------------------------------------------
    -- Function
    --
    -- Function Name: func_mux_sel_width
    --
    -- Function Description:
    --   Calculates the number of needed bits for the Mux Select control
    -- based on the number of input channels to the mux.
    --
    -- Note that the number of input mux channels are always a 
    -- power of 2.
    --
    -------------------------------------------------------------------
    function func_mux_sel_width (num_channels : integer) return integer is
    
     Variable var_sel_width : integer := 0;
    
    begin
    
       case num_channels is
         when 2 =>
             var_sel_width := 1;
         when 4 =>
             var_sel_width := 2;
         when 8 =>
             var_sel_width := 3;
-- coverage off         
         when 16 =>
             var_sel_width := 4;
         when 32 =>
             var_sel_width := 5;
-- coverage on         
         when others =>
             var_sel_width := 0; 
       end case;
       
       Return (var_sel_width);
        
        
    end function func_mux_sel_width;
    
    
    
    -------------------------------------------------------------------
    -- Function
    --
    -- Function Name: func_sel_ls_index
    --
    -- Function Description:
    --   Calculates the LS index of the select field to rip from the
    -- input select bus.
    --
    -- Note that the number of input mux channels are always a 
    -- power of 2.
    --
    -------------------------------------------------------------------
    function func_sel_ls_index (stream_width : integer) return integer is
    
     Variable var_sel_ls_index : integer := 0;
    
    begin
    
       case stream_width is
-- coverage off         
         when 16 =>
             var_sel_ls_index := 1;
-- coverage on         
         when 32 =>
             var_sel_ls_index := 2;
         when 64 =>
             var_sel_ls_index := 3;
         when 128 =>
             var_sel_ls_index := 4;
-- coverage off         
         when others =>
             var_sel_ls_index := 0;
-- coverage on         
       end case;
       
       Return (var_sel_ls_index);
        
        
    end function func_sel_ls_index;
    
    
    
    
    
    -- Constant Decalarations -------------------------------------------------
    
    Constant STREAM_WSTB_WIDTH   : integer := C_STREAM_DWIDTH/8;
    Constant MMAP_WSTB_WIDTH     : integer := C_MMAP_DWIDTH/8;
    Constant NUM_MUX_CHANNELS    : integer := MMAP_WSTB_WIDTH/STREAM_WSTB_WIDTH;
    Constant MUX_SEL_WIDTH       : integer := func_mux_sel_width(NUM_MUX_CHANNELS);
    Constant MUX_SEL_LS_INDEX    : integer := func_sel_ls_index(C_STREAM_DWIDTH);
    
    
    -- Signal Declarations  --------------------------------------------
 
    signal sig_demux_wstrb_out   : std_logic_vector(MMAP_WSTB_WIDTH-1 downto 0) := (others => '0');



    
  begin --(architecture implementation)
  
  
  
  
   -- Assign the Output data port 
    demux_wstrb_out        <= sig_demux_wstrb_out;
  


    
    
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: GEN_STRM_EQ_MMAP
    --
    -- If Generate Description:
    --   This IfGen implements the case where the Stream Data Width is 
    -- the same as the Memeory Map read Data width.
    --
    --
    ------------------------------------------------------------
    GEN_STRM_EQ_MMAP : if (C_MMAP_DWIDTH = C_STREAM_DWIDTH) generate
        
       begin
        
          sig_demux_wstrb_out <= wstrb_in;
        
        
       end generate GEN_STRM_EQ_MMAP;
   
   
    
    
    
     
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: GEN_2XN
    --
    -- If Generate Description:
    --  2 channel demux case
    --
    --
    ------------------------------------------------------------
    GEN_2XN : if (NUM_MUX_CHANNELS = 2) generate
    
       -- local signals
       signal sig_demux_sel_slice      : std_logic_vector(MUX_SEL_WIDTH-1 downto 0) := (others => '0');
       signal sig_demux_sel_unsgnd     : unsigned(MUX_SEL_WIDTH-1 downto 0) := (others => '0');
       signal sig_demux_sel_int        : integer range 0 to 31 := 0;
       signal lsig_demux_sel_int_local : integer range 0 to 31 := 0;
       signal lsig_demux_wstrb_out     : std_logic_vector(MMAP_WSTB_WIDTH-1 downto 0) := (others => '0');
       
       begin
    
         
        -- Rip the Mux Select bits needed for the Mux case from the input select bus
         sig_demux_sel_slice   <= debeat_saddr_lsb((MUX_SEL_LS_INDEX + MUX_SEL_WIDTH)-1 downto MUX_SEL_LS_INDEX);
        
         sig_demux_sel_unsgnd  <=  UNSIGNED(sig_demux_sel_slice);  -- convert to unsigned
        
         sig_demux_sel_int     <=  TO_INTEGER(sig_demux_sel_unsgnd); -- convert to integer for MTI compile issue
                                                                 -- with locally static subtype error in each of the
                                                                 -- Mux IfGens
        
         lsig_demux_sel_int_local <= sig_demux_sel_int;
         
         sig_demux_wstrb_out      <= lsig_demux_wstrb_out;
       
         
         -------------------------------------------------------------
         -- Combinational Process
         --
         -- Label: DO_2XN_DEMUX
         --
         -- Process Description:
         --  Implement the 2XN DeMux
         --
         -------------------------------------------------------------
         DO_2XN_DEMUX : process (lsig_demux_sel_int_local,
                                  wstrb_in)
            begin
              
              -- Set default value
              lsig_demux_wstrb_out <=  (others => '0');
              
              case lsig_demux_sel_int_local is
                when 1 =>
                    lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*2)-1 downto STREAM_WSTB_WIDTH*1) <=  wstrb_in;
                when others =>
                    lsig_demux_wstrb_out(STREAM_WSTB_WIDTH-1 downto 0) <=  wstrb_in;
              end case;
              
            end process DO_2XN_DEMUX; 
 
         
       end generate GEN_2XN;
  
 
 
 
  
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: GEN_4XN
    --
    -- If Generate Description:
    --  4 channel demux case
    --
    --
    ------------------------------------------------------------
    GEN_4XN : if (NUM_MUX_CHANNELS = 4) generate
    
       -- local signals
       signal sig_demux_sel_slice      : std_logic_vector(MUX_SEL_WIDTH-1 downto 0) := (others => '0');
       signal sig_demux_sel_unsgnd     : unsigned(MUX_SEL_WIDTH-1 downto 0) := (others => '0');
       signal sig_demux_sel_int        : integer range 0 to 31 := 0;
       signal lsig_demux_sel_int_local : integer range 0 to 31 := 0;
       signal lsig_demux_wstrb_out     : std_logic_vector(MMAP_WSTB_WIDTH-1 downto 0) := (others => '0');
       
       begin
    
         
        -- Rip the Mux Select bits needed for the Mux case from the input select bus
         sig_demux_sel_slice   <= debeat_saddr_lsb((MUX_SEL_LS_INDEX + MUX_SEL_WIDTH)-1 downto MUX_SEL_LS_INDEX);
        
         sig_demux_sel_unsgnd  <=  UNSIGNED(sig_demux_sel_slice);  -- convert to unsigned
        
         sig_demux_sel_int     <=  TO_INTEGER(sig_demux_sel_unsgnd); -- convert to integer for MTI compile issue
                                                                 -- with locally static subtype error in each of the
                                                                 -- Mux IfGens
        
         lsig_demux_sel_int_local <= sig_demux_sel_int;
         
         sig_demux_wstrb_out      <= lsig_demux_wstrb_out;
       
          
          
          
         
         -------------------------------------------------------------
         -- Combinational Process
         --
         -- Label: DO_4XN_DEMUX
         --
         -- Process Description:
         --  Implement the 4XN DeMux
         --
         -------------------------------------------------------------
         DO_4XN_DEMUX : process (lsig_demux_sel_int_local,
                                 wstrb_in)
           begin
              
             -- Set default value
             lsig_demux_wstrb_out <=  (others => '0');
              
             case lsig_demux_sel_int_local is
               when 1 =>
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*2)-1 downto STREAM_WSTB_WIDTH*1) <=  wstrb_in;
               when 2 =>
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*3)-1 downto STREAM_WSTB_WIDTH*2) <=  wstrb_in;
               when 3 =>
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*4)-1 downto STREAM_WSTB_WIDTH*3) <=  wstrb_in;
               when others =>
                   lsig_demux_wstrb_out(STREAM_WSTB_WIDTH-1 downto 0) <=  wstrb_in;
             end case;
             
           end process DO_4XN_DEMUX; 
  
         
       end generate GEN_4XN;
  
 
 
 
  
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: GEN_8XN
    --
    -- If Generate Description:
    --  8 channel demux case
    --
    --
    ------------------------------------------------------------
    GEN_8XN : if (NUM_MUX_CHANNELS = 8) generate
    
       -- local signals
       signal sig_demux_sel_slice      : std_logic_vector(MUX_SEL_WIDTH-1 downto 0) := (others => '0');
       signal sig_demux_sel_unsgnd     : unsigned(MUX_SEL_WIDTH-1 downto 0) := (others => '0');
       signal sig_demux_sel_int        : integer range 0 to 31 := 0;
       signal lsig_demux_sel_int_local : integer range 0 to 31 := 0;
       signal lsig_demux_wstrb_out     : std_logic_vector(MMAP_WSTB_WIDTH-1 downto 0) := (others => '0');
       
       begin
    
         
        -- Rip the Mux Select bits needed for the Mux case from the input select bus
         sig_demux_sel_slice   <= debeat_saddr_lsb((MUX_SEL_LS_INDEX + MUX_SEL_WIDTH)-1 downto MUX_SEL_LS_INDEX);
        
         sig_demux_sel_unsgnd  <=  UNSIGNED(sig_demux_sel_slice);  -- convert to unsigned
        
         sig_demux_sel_int     <=  TO_INTEGER(sig_demux_sel_unsgnd); -- convert to integer for MTI compile issue
                                                                 -- with locally static subtype error in each of the
                                                                 -- Mux IfGens
        
         lsig_demux_sel_int_local <= sig_demux_sel_int;
         
         sig_demux_wstrb_out      <= lsig_demux_wstrb_out;
       
          
          
          
         
         -------------------------------------------------------------
         -- Combinational Process
         --
         -- Label: DO_8XN_DEMUX
         --
         -- Process Description:
         --  Implement the 8XN DeMux
         --
         -------------------------------------------------------------
         DO_8XN_DEMUX : process (lsig_demux_sel_int_local,
                                 wstrb_in)
           begin
             
             -- Set default value
             lsig_demux_wstrb_out <=  (others => '0');
              
             case lsig_demux_sel_int_local is
               when 1 =>
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*2)-1 downto STREAM_WSTB_WIDTH*1) <=  wstrb_in;
               when 2 =>                                                             
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*3)-1 downto STREAM_WSTB_WIDTH*2) <=  wstrb_in;
               when 3 =>                                                             
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*4)-1 downto STREAM_WSTB_WIDTH*3) <=  wstrb_in;
               when 4 =>                                                             
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*5)-1 downto STREAM_WSTB_WIDTH*4) <=  wstrb_in;
               when 5 =>                                                             
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*6)-1 downto STREAM_WSTB_WIDTH*5) <=  wstrb_in;
               when 6 =>                                                             
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*7)-1 downto STREAM_WSTB_WIDTH*6) <=  wstrb_in;
               when 7 =>                                                             
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*8)-1 downto STREAM_WSTB_WIDTH*7) <=  wstrb_in;
               when others =>
                   lsig_demux_wstrb_out(STREAM_WSTB_WIDTH-1 downto 0) <=  wstrb_in;
             end case;
                 
           end process DO_8XN_DEMUX; 
 
         
       end generate GEN_8XN;
  
 
 
 
  
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: GEN_16XN
    --
    -- If Generate Description:
    --  16 channel demux case
    --
    --
    ------------------------------------------------------------
    GEN_16XN : if (NUM_MUX_CHANNELS = 16) generate
    
       -- local signals
       signal sig_demux_sel_slice      : std_logic_vector(MUX_SEL_WIDTH-1 downto 0) := (others => '0');
       signal sig_demux_sel_unsgnd     : unsigned(MUX_SEL_WIDTH-1 downto 0) := (others => '0');
       signal sig_demux_sel_int        : integer range 0 to 31 := 0;
       signal lsig_demux_sel_int_local : integer range 0 to 31 := 0;
       signal lsig_demux_wstrb_out     : std_logic_vector(MMAP_WSTB_WIDTH-1 downto 0) := (others => '0');
       
       begin
    
         
        -- Rip the Mux Select bits needed for the Mux case from the input select bus
         sig_demux_sel_slice   <= debeat_saddr_lsb((MUX_SEL_LS_INDEX + MUX_SEL_WIDTH)-1 downto MUX_SEL_LS_INDEX);
        
         sig_demux_sel_unsgnd  <=  UNSIGNED(sig_demux_sel_slice);  -- convert to unsigned
        
         sig_demux_sel_int     <=  TO_INTEGER(sig_demux_sel_unsgnd); -- convert to integer for MTI compile issue
                                                                 -- with locally static subtype error in each of the
                                                                 -- Mux IfGens
        
         lsig_demux_sel_int_local <= sig_demux_sel_int;
         
         sig_demux_wstrb_out      <= lsig_demux_wstrb_out;
       
          
          
         
         -------------------------------------------------------------
         -- Combinational Process
         --
         -- Label: DO_16XN_DEMUX
         --
         -- Process Description:
         --  Implement the 16XN DeMux
         --
         -------------------------------------------------------------
         DO_16XN_DEMUX : process (lsig_demux_sel_int_local,
                                  wstrb_in)
           begin
             
             -- Set default value
             lsig_demux_wstrb_out <=  (others => '0');
              
             case lsig_demux_sel_int_local is
               when 1 =>
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*2)-1 downto STREAM_WSTB_WIDTH*1)   <=  wstrb_in;
               when 2 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*3)-1 downto STREAM_WSTB_WIDTH*2)   <=  wstrb_in;
               when 3 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*4)-1 downto STREAM_WSTB_WIDTH*3)   <=  wstrb_in;
               when 4 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*5)-1 downto STREAM_WSTB_WIDTH*4)   <=  wstrb_in;
               when 5 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*6)-1 downto STREAM_WSTB_WIDTH*5)   <=  wstrb_in;
               when 6 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*7)-1 downto STREAM_WSTB_WIDTH*6)   <=  wstrb_in;
               when 7 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*8)-1 downto STREAM_WSTB_WIDTH*7)   <=  wstrb_in;
               when 8 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*9)-1 downto STREAM_WSTB_WIDTH*8)   <=  wstrb_in;
               when 9 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*10)-1 downto STREAM_WSTB_WIDTH*9)  <=  wstrb_in;
               when 10 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*11)-1 downto STREAM_WSTB_WIDTH*10) <=  wstrb_in;
               when 11 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*12)-1 downto STREAM_WSTB_WIDTH*11) <=  wstrb_in;
               when 12 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*13)-1 downto STREAM_WSTB_WIDTH*12) <=  wstrb_in;
               when 13 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*14)-1 downto STREAM_WSTB_WIDTH*13) <=  wstrb_in;
               when 14 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*15)-1 downto STREAM_WSTB_WIDTH*14) <=  wstrb_in;
               when 15 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*16)-1 downto STREAM_WSTB_WIDTH*15) <=  wstrb_in;
               when others =>
                   lsig_demux_wstrb_out(STREAM_WSTB_WIDTH-1 downto 0) <=  wstrb_in;
             end case;
          
           end process DO_16XN_DEMUX; 
 
         
       end generate GEN_16XN;
  
 
 
 
  
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: GEN_32XN
    --
    -- If Generate Description:
    --  32 channel demux case
    --
    --
    ------------------------------------------------------------
    GEN_32XN : if (NUM_MUX_CHANNELS = 32) generate
    
       -- local signals
       signal sig_demux_sel_slice      : std_logic_vector(MUX_SEL_WIDTH-1 downto 0) := (others => '0');
       signal sig_demux_sel_unsgnd     : unsigned(MUX_SEL_WIDTH-1 downto 0) := (others => '0');
       signal sig_demux_sel_int        : integer range 0 to 31 := 0;
       signal lsig_demux_sel_int_local : integer range 0 to 31 := 0;
       signal lsig_demux_wstrb_out     : std_logic_vector(MMAP_WSTB_WIDTH-1 downto 0) := (others => '0');
       
       begin
    
         
        -- Rip the Mux Select bits needed for the Mux case from the input select bus
         sig_demux_sel_slice   <= debeat_saddr_lsb((MUX_SEL_LS_INDEX + MUX_SEL_WIDTH)-1 downto MUX_SEL_LS_INDEX);
        
         sig_demux_sel_unsgnd  <=  UNSIGNED(sig_demux_sel_slice);  -- convert to unsigned
        
         sig_demux_sel_int     <=  TO_INTEGER(sig_demux_sel_unsgnd); -- convert to integer for MTI compile issue
                                                                 -- with locally static subtype error in each of the
                                                                 -- Mux IfGens
        
         lsig_demux_sel_int_local <= sig_demux_sel_int;
         
         sig_demux_wstrb_out      <= lsig_demux_wstrb_out;
       
          
          
          
         
         -------------------------------------------------------------
         -- Combinational Process
         --
         -- Label: DO_32XN_DEMUX
         --
         -- Process Description:
         --  Implement the 32XN DeMux
         --
         -------------------------------------------------------------
         DO_32XN_DEMUX : process (lsig_demux_sel_int_local,
                                  wstrb_in)
           begin
             
             -- Set default value
             lsig_demux_wstrb_out <=  (others => '0');
              
             case lsig_demux_sel_int_local is
               when 1 =>
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*2)-1 downto STREAM_WSTB_WIDTH*1)   <=  wstrb_in;
               when 2 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*3)-1 downto STREAM_WSTB_WIDTH*2)   <=  wstrb_in;
               when 3 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*4)-1 downto STREAM_WSTB_WIDTH*3)   <=  wstrb_in;
               when 4 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*5)-1 downto STREAM_WSTB_WIDTH*4)   <=  wstrb_in;
               when 5 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*6)-1 downto STREAM_WSTB_WIDTH*5)   <=  wstrb_in;
               when 6 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*7)-1 downto STREAM_WSTB_WIDTH*6)   <=  wstrb_in;
               when 7 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*8)-1 downto STREAM_WSTB_WIDTH*7)   <=  wstrb_in;
               when 8 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*9)-1 downto STREAM_WSTB_WIDTH*8)   <=  wstrb_in;
               when 9 =>                                                               
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*10)-1 downto STREAM_WSTB_WIDTH*9)  <=  wstrb_in;
               when 10 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*11)-1 downto STREAM_WSTB_WIDTH*10) <=  wstrb_in;
               when 11 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*12)-1 downto STREAM_WSTB_WIDTH*11) <=  wstrb_in;
               when 12 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*13)-1 downto STREAM_WSTB_WIDTH*12) <=  wstrb_in;
               when 13 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*14)-1 downto STREAM_WSTB_WIDTH*13) <=  wstrb_in;
               when 14 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*15)-1 downto STREAM_WSTB_WIDTH*14) <=  wstrb_in;
               when 15 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*16)-1 downto STREAM_WSTB_WIDTH*15) <=  wstrb_in;
               when 16 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*17)-1 downto STREAM_WSTB_WIDTH*16) <=  wstrb_in;
               when 17 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*18)-1 downto STREAM_WSTB_WIDTH*17) <=  wstrb_in;
               when 18 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*19)-1 downto STREAM_WSTB_WIDTH*18) <=  wstrb_in;
               when 19 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*20)-1 downto STREAM_WSTB_WIDTH*19) <=  wstrb_in;
               when 20 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*21)-1 downto STREAM_WSTB_WIDTH*20) <=  wstrb_in;
               when 21 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*22)-1 downto STREAM_WSTB_WIDTH*21) <=  wstrb_in;
               when 22 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*23)-1 downto STREAM_WSTB_WIDTH*22) <=  wstrb_in;
               when 23 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*24)-1 downto STREAM_WSTB_WIDTH*23) <=  wstrb_in;
               when 24 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*25)-1 downto STREAM_WSTB_WIDTH*24) <=  wstrb_in;
               when 25 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*26)-1 downto STREAM_WSTB_WIDTH*25) <=  wstrb_in;
               when 26 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*27)-1 downto STREAM_WSTB_WIDTH*26) <=  wstrb_in;
               when 27 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*28)-1 downto STREAM_WSTB_WIDTH*27) <=  wstrb_in;
               when 28 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*29)-1 downto STREAM_WSTB_WIDTH*28) <=  wstrb_in;
               when 29 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*30)-1 downto STREAM_WSTB_WIDTH*29) <=  wstrb_in;
               when 30 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*31)-1 downto STREAM_WSTB_WIDTH*30) <=  wstrb_in;
               when 31 =>                                                              
                   lsig_demux_wstrb_out((STREAM_WSTB_WIDTH*32)-1 downto STREAM_WSTB_WIDTH*31) <=  wstrb_in;
               when others =>
                   lsig_demux_wstrb_out(STREAM_WSTB_WIDTH-1 downto 0) <=  wstrb_in;
             end case;
          
           end process DO_32XN_DEMUX; 
 
         
       end generate GEN_32XN;
  
 
  
  
  
  
  end implementation;
