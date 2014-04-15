-------------------------------------------------------------------------------
-- axi_master_burst_cmd_status.vhd
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
-- Filename:        axi_master_burst_cmd_status.vhd
--
-- Description:     
--    This file implements the AXI Master Burst Command and Status interfaces.                 
--                  
--                  
--                  
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              axi_master_burst_cmd_status.vhd
--
-------------------------------------------------------------------------------
-- Revision History:
--
--
-- Author:          DET
-- Revision:        $Revision: 1.0 $
-- Date:            $1/20/2011$
--
-- History:
--     DET     1/20/2011     Initial
-- ~~~~~~
--     - New file for AXi Master burst
-- ^^^^^^
--
--     DET     2/10/2011     Initial for 13.2
-- ~~~~~~
--     - Registered the bus2ip_mst_cmdack and bus2ip_mst_cmplt ouputs per
--       Linting guidelines.
-- ^^^^^^
--
--     DET     2/17/2011     Initial for 13.2
-- ~~~~~~
--    -- Per CR593967
--     - Added the port rdwr2llink_int_err. This output is now used to initiate
--       a Locallink discontinue when an internal error is detected.
--     - Added the logic for to drive the new rdwr2llink_int_err port.
-- ^^^^^^
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library axi_master_burst_v1_00_a;
Use axi_master_burst_v1_00_a.axi_master_burst_stbs_set ;
Use axi_master_burst_v1_00_a.axi_master_burst_first_stb_offset;
-------------------------------------------------------------------------------

entity axi_master_burst_cmd_status is
  generic (
    
    C_ADDR_WIDTH         : Integer range 32 to  64 := 32;
      -- The bit width of the AXI address Buses
      
    C_NATIVE_DWIDTH      : Integer range 32 to 128 := 32;
      -- The bit width of the Master's data Buses
      
    C_CMD_WIDTH          : Integer range 64 to 128 := 68;
      -- The bit width of the command bus to the RD/WR Controller
    
    C_CMD_BTT_USED_WIDTH : Integer range 12 to  20 := 12;
      -- The bit width of the input ip2bus_mst_length (Bytes to Transfer)
    
    C_STS_WIDTH          : Integer                 :=  8;
      -- The bit width of the input status bus from the Rd/Wr Controller
    
    C_FAMILY             : string                  := "virtex6"
      -- The target FPGA device familiy
    
    );
  port (
    
    -- Clock inputs
    axi_aclk                : in  std_logic;

    -- Reset inputs
    axi_reset               : in  std_logic;
    
    -----------------------------------------------------------------------------
    -- RW_ERROR Output Discrete
    -----------------------------------------------------------------------------
    rw_error                : Out std_logic;
    
    -----------------------------------------------------------------------------
    -- Internal error Output Discrete to LocalLink backends 
    -- (Asserted until Pertinent LocalLink IF is not busy)
    -----------------------------------------------------------------------------
    rdwr2llink_int_err      : Out std_logic;
    
    -----------------------------------------------------------------------------
    -- IPIC Request/Qualifiers
    -----------------------------------------------------------------------------
    ip2bus_mstrd_req        : In  std_logic;                                     -- IPIC Cmd
    ip2bus_mstwr_req        : In  std_logic;                                     -- IPIC Cmd
    ip2bus_mst_addr         : in  std_logic_vector(0 to C_ADDR_WIDTH-1);         -- IPIC Cmd
    ip2bus_mst_length       : in  std_logic_vector(0 to C_CMD_BTT_USED_WIDTH-1); -- IPIC Cmd
    ip2bus_mst_be           : in  std_logic_vector(0 to (C_NATIVE_DWIDTH/8)-1);  -- IPIC Cmd
                                                                                 
    ip2bus_mst_type         : in  std_logic;                                     -- IPIC Cmd
    ip2bus_mst_lock         : In  std_logic;                                     -- IPIC Cmd
    ip2bus_mst_reset        : In  std_logic;                                     -- IPIC Cmd
     
    
    -----------------------------------------------------------------------------
    -- IPIC Request Status Reply
    -----------------------------------------------------------------------------
    bus2ip_mst_cmdack       : Out std_logic;                                     -- IPIC Status Reply
    bus2ip_mst_cmplt        : Out std_logic;                                     -- IPIC Status Reply
    bus2ip_mst_error        : Out std_logic;                                     -- IPIC Status Reply
    bus2ip_mst_rearbitrate  : Out std_logic;                                     -- IPIC Status Reply
    bus2ip_mst_cmd_timeout  : out std_logic;                                     -- IPIC Status Reply

     
    -----------------------------------------------------------------------------
    -- IPIC LocalLink Busy Flag
    -----------------------------------------------------------------------------
    mstrd_llink_busy        : In  std_logic;                                    -- LLink Busy Ooutput Discrete
    mstwr_llink_busy        : In  std_logic;                                    -- LLink Busy Ooutput Discrete
  
    
    -----------------------------------------------------------------------------
    -- PCC Command Interface
    -----------------------------------------------------------------------------
    pcc2cmd_cmd_ready      : in  std_logic;
       -- Handshake bit indicating the Predictive Command Calculator is ready  
       -- to accept another command
    
    cmd2pcc_cmd_valid      : Out std_logic;
       -- Handshake bit indicating the Command module has at least 1 valid 
       -- command entry
       
    cmd2pcc_command        : Out std_logic_vector(C_CMD_WIDTH-1 downto 0);
       -- The next command value available from the Command Register
       
    
    
    -----------------------------------------------------------------------------
    -- Read/Write Command Indicator Interface
    -----------------------------------------------------------------------------
    cmd2all_doing_read     : out std_logic;
       -- Indication that the current command is a read
    
    cmd2all_doing_write    : out std_logic;
       -- Indication that the current command is a write
    
    
    
    
    
    
    -----------------------------------------------------------------------------
    -- Read Status Controller Interface
    -----------------------------------------------------------------------------
    stat2rsc_status_ready  : Out std_logic;
       -- Handshake bit indicating that the Status FIFO/Register is ready for transfer
       
    rsc2stat_status_valid  : In  std_logic ;
       -- Handshake bit for writing the Status value into the Status FIFO/Register
   
    rsc2stat_status        : in  std_logic_vector(C_STS_WIDTH-1 downto 0);
       -- The input for writing the status value to the Status FIFO/Register
  
   
     
    -----------------------------------------------------------------------------
    -- Write Status Controller Interface
    -----------------------------------------------------------------------------
    stat2wsc_status_ready  : Out std_logic;
       -- Handshake bit indicating that the Status FIFO/Register is ready for transfer
       
    wsc2stat_status_valid  : In  std_logic ;
       -- Handshake bit for writing the Status value into the Status FIFO/Register
   
    wsc2stat_status        : in  std_logic_vector(C_STS_WIDTH-1 downto 0)
       -- The input for writing the status value to the Status FIFO/Register
  
      );
  
  end entity axi_master_burst_cmd_status;
  
  
  architecture implementation of axi_master_burst_cmd_status is
  
    
    
    
    -- Functions
    
    
    
    
    
    
     -------------------------------------------------------------------
     -- Function
     --
     -- Function Name: get_addr_lsb_slice_width
     --
     -- Function Description:
     --   Calculates the number of Least significant Address bits that
     -- need to be overridden by the position of the first asserted BE
     -- specified during a commanded single data beat transfer.
     -------------------------------------------------------------------
     function get_addr_lsb_slice_width (native_dwidth: integer) return integer is
     
       Variable temp_ls_slice_width : natural := 2;
     
     
     begin
     
       case native_dwidth is
         when 32 =>
           temp_ls_slice_width := 2; -- 4 bytes max transfer
         when 64 =>
           temp_ls_slice_width := 3; -- 8 bytes max transfer
         when others => -- assume 128 bit
           temp_ls_slice_width := 4; -- 16 bytes max transfer
       end case;
      
      
       Return (temp_ls_slice_width);
      
      
       
     end function get_addr_lsb_slice_width;
    
    
    
    
    
    
     
    
    -- Constants 
    
    -- Constant REGISTER_TYPE  : integer := 0; 
    -- Constant BRAM_TYPE      : integer := 1; 
    -- Constant SRL_TYPE       : integer := 2; 
    -- Constant FIFO_PRIM_TYPE : integer := SRL_TYPE;
        
        
     Constant STRB_WIDTH            : integer := C_NATIVE_DWIDTH/8;
     Constant BE_WIDTH              : integer := C_NATIVE_DWIDTH/8;
     Constant CMD_BTT_WIDTH         : integer := 23;
     Constant CMD_BTT_USED_WIDTH    : integer := C_CMD_BTT_USED_WIDTH;
     Constant CMD_BTT_NOTUSED_WIDTH : integer := CMD_BTT_WIDTH-CMD_BTT_USED_WIDTH;
     Constant CMD_TAG_WIDTH         : integer := C_CMD_WIDTH-64;
     Constant CMD_DSA_WIDTH         : integer := 6;
     Constant STRB_ASSERTED_WIDTH   : integer := 8;
     Constant OFFSET_WIDTH          : Integer := 8;
     
     
     
     Constant TAG_CNTR_ONE          : unsigned(CMD_TAG_WIDTH-1 downto 0) := 
                                      TO_UNSIGNED(1, CMD_TAG_WIDTH);
     
     Constant ADDR_LS_SLICE_WIDTH      : integer := get_addr_lsb_slice_width(C_NATIVE_DWIDTH);
     Constant ADDR_MS_SLICE_WIDTH      : integer := C_ADDR_WIDTH - ADDR_LS_SLICE_WIDTH;
     Constant ADDR_LS_SLICE_HIGH_INDEX : integer := ADDR_LS_SLICE_WIDTH-1;
     Constant ADDR_MS_SLICE_LOW_INDEX  : integer := ADDR_LS_SLICE_WIDTH;
     
     Constant STAT_OKAY_BIT            : integer := 7;
     Constant STAT_SLVERR_BIT          : integer := 6;
     Constant STAT_DECERR_BIT          : integer := 5;
     Constant STAT_INTERR_BIT          : integer := 4;
     Constant STAT_TAG_MSBIT           : integer := 3;
     
     
     
    
    -- Signals
    
     --signal sig_cmd_ack            : std_logic := '0';
     signal sig_cmd_cmplt          : std_logic := '0';
     signal sig_cmd_error          : std_logic := '0';
      
     
     signal sig_addr_out           : std_logic_vector(C_ADDR_WIDTH-1 downto 0) := (others => '0');
     signal sig_addr_ms_slice      : std_logic_vector(ADDR_MS_SLICE_WIDTH-1 downto 0) := (others => '0');
     signal sig_addr_ls_slice      : std_logic_vector(ADDR_LS_SLICE_WIDTH-1 downto 0) := (others => '0');
     signal sig_addr_be_offset     : std_logic_vector(ADDR_LS_SLICE_WIDTH-1 downto 0) := (others => '0');
     
     signal sig_cmd_mstrd_req      : std_logic;
     signal sig_cmd_mstwr_req      : std_logic;
     signal sig_cmd_mst_addr       : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
     signal sig_cmd_mst_length     : std_logic_vector(CMD_BTT_USED_WIDTH-1 downto 0);
     signal sig_cmd_mst_be         : std_logic_vector((C_NATIVE_DWIDTH/8)-1 downto 0);     
     signal sig_cmd_type_req       : std_logic;
      
     
     signal sig_init_done          : std_logic := '0';
     signal sig_init_reg1          : std_logic := '0';
     signal sig_init_reg2          : std_logic := '0';
     
     signal sig_muxed_length       : std_logic_vector(CMD_BTT_USED_WIDTH-1 downto 0) := (others => '0');
     
     signal sig_sngl_beat_length   : std_logic_vector(CMD_BTT_USED_WIDTH-1 downto 0) := (others => '0');
     
     signal sig_num_stbs_asserted  : std_logic_vector(STRB_ASSERTED_WIDTH-1 downto 0) := (others => '0');
     
     signal sig_cmd_full_reg       : std_logic := '0';
     signal sig_cmd_empty_reg      : std_logic := '0';
     signal sig_push_cmd_reg       : std_logic := '0';
     signal sig_pop_cmd_reg        : std_logic := '0';
 
     signal sig_cmd_tag_slice      : std_logic_vector(CMD_TAG_WIDTH-1 downto 0) := (others => '0');
     signal sig_cmd_addr_slice     : std_logic_vector(C_ADDR_WIDTH-1 downto 0)  := (others => '0');
     signal sig_cmd_drr_slice      : std_logic := '0';
     signal sig_cmd_eof_slice      : std_logic := '0';
     signal sig_cmd_dsa_slice      : std_logic_vector(CMD_DSA_WIDTH-1 downto 0) := (others => '0');
     signal sig_cmd_type_slice     : std_logic := '0';
     signal sig_cmd_btt_rsvd_slice : std_logic_vector(CMD_BTT_NOTUSED_WIDTH-1 downto 0) := (others => '0');
     signal sig_cmd_btt_slice      : std_logic_vector(CMD_BTT_USED_WIDTH-1 downto 0)    := (others => '0');
   
     signal sig_pcc_cmd_rdy        : std_logic := '0';
     signal sig_pcc_taking_command : std_logic := '0';
     
     signal sig_incr_tag_cnt       : std_logic := '0';
     Signal sig_tag_counter        : unsigned(CMD_TAG_WIDTH-1 downto 0) := (others => '0'); 
     
     signal sig_strt_addr_offset   : unsigned(OFFSET_WIDTH-1 downto 0) ;

     signal sig_doing_read_reg     : std_logic := '0';
     signal sig_doing_write_reg    : std_logic := '0';
     
     signal sig_push_status        : std_logic := '0';
     signal sig_pop_status         : std_logic := '0';
     signal sig_status_reg         : std_logic_vector(C_STS_WIDTH-1 downto 0) := (others => '0');
     signal sig_status_reg_full    : std_logic := '0';
     signal sig_status_reg_empty   : std_logic := '0';
     signal sig_status_valid       : std_logic := '0';
     
     signal sig_muxed_status       : std_logic_vector(C_STS_WIDTH-1 downto 0) := (others => '0');
     
     signal sig_stat_tag           : std_logic_vector(CMD_TAG_WIDTH-1 downto 0) := (others => '0');
     signal sig_stat_tag_reg       : std_logic_vector(CMD_TAG_WIDTH-1 downto 0) := (others => '0');
     signal sig_stat_error         : std_logic := '0';
     signal sig_stat_error_reg     : std_logic := '0';
     signal sig_stat_int_error     : std_logic := '0';
     
     signal sig_error_sh_reg       : std_logic := '0';
     signal sig_int_error_pulse_reg   : std_logic := '0';
     
     signal sig_cmdack_reg         : std_logic := '0';
     signal sig_cmd_cmplt_reg      : std_logic := '0';
     signal sig_llink_busy         : std_logic := '0';
     
     
  
  begin --(architecture implementation)
  
    
   
    -- IPIC Status Reply Port
   
    bus2ip_mst_cmdack        <= sig_cmdack_reg    ;
    bus2ip_mst_cmplt         <= sig_cmd_cmplt_reg ;
    bus2ip_mst_error         <= sig_cmd_error     ;
    bus2ip_mst_rearbitrate   <= '0'               ;
    bus2ip_mst_cmd_timeout   <= '0'               ;
   
   
   
    -- Type of command discrete indicators
    cmd2all_doing_read       <= sig_doing_read_reg  ;
     
    cmd2all_doing_write      <= sig_doing_write_reg ;
     
     
     
    -- PCC Command Interface Port Assignments 
    sig_pcc_cmd_rdy          <= pcc2cmd_cmd_ready;
     
    cmd2pcc_cmd_valid        <= sig_cmd_full_reg ;
     
    cmd2pcc_command          <= sig_cmd_tag_slice      &
                                sig_cmd_addr_slice     &
                                sig_cmd_drr_slice      &
                                sig_cmd_eof_slice      &
                                sig_cmd_dsa_slice      &
                                sig_cmd_type_slice     &
                                sig_cmd_btt_rsvd_slice &
                                sig_cmd_btt_slice ;
     
     
    -- Generate a flag indicating the PCC is accepting the 
    -- new command being output
    sig_pcc_taking_command  <= sig_cmd_full_reg and                     
                               pcc2cmd_cmd_ready;   
                         
     
     
   -- Build the PCC command from the input IPIC Command Qualifiers
   
    sig_cmd_tag_slice       <= STD_LOGIC_VECTOR(sig_tag_counter); -- tag count
   
    sig_cmd_addr_slice      <= sig_addr_out;     -- formulated starting address
   
    sig_cmd_drr_slice       <= '1';              -- always a sof started packet
   
    sig_cmd_eof_slice       <= '1';              -- always a eof terminated packet
   
    sig_cmd_dsa_slice       <= (others => '0');  -- no DRE so set to zeros
   
    sig_cmd_type_slice      <= '0';              -- reserved, set to zero
   
    sig_cmd_btt_rsvd_slice  <= (others => '0');  -- unused portion of the BTT field
   
    sig_cmd_btt_slice       <= sig_muxed_length; -- transfer length in bytes
   
  
  
    
    -- Resize the strobes asserted value (from the BE) up to a 20-bit value. This is
    -- only used for Single Beat commands
    sig_sngl_beat_length  <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(sig_num_stbs_asserted), CMD_BTT_USED_WIDTH));  
      
    
    
    -- If a single beat command, then the length must be derived
    -- from the asserted BE bits, else just use the command's length
    -- when the command is a burst.
    sig_muxed_length <= sig_sngl_beat_length
      When (sig_cmd_type_req = '0')
      Else sig_cmd_mst_length;
    
    
    
    -- Rip the upper address bit field from the input command address.
    sig_addr_ms_slice <= sig_cmd_mst_addr(C_ADDR_WIDTH-1 downto ADDR_MS_SLICE_LOW_INDEX);
    
    
    -- If the command is a single beat request, then the LS Bits of the AXI 
    -- Address must be set to the byte offset of the first asserted BE in the
    -- input BE command qualifier. Otherwise, it is a burst request so use the 
    -- original address offset from the command.
    sig_addr_ls_slice <= sig_cmd_mst_addr(ADDR_LS_SLICE_HIGH_INDEX downto 0)
      When (sig_cmd_type_req = '1')
      Else sig_addr_be_offset;
   
    
    -- Formulate the final address to be used for the starting AXI4 Address by
    -- concatonating the Upper address slice with the multiplexed lower address
    -- slice.
    sig_addr_out <=  sig_addr_ms_slice & sig_addr_ls_slice;
    
    
    
    
    ---------------------------------------------------------------------------------
    --  IPIC Status IF Registering 
    ---------------------------------------------------------------------------------
     
    
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_CMDACK_REG
    --
    -- Process Description:
    --   Generates a 1-clock wide command acknowledge pulse.
    --
    -------------------------------------------------------------
    IMP_CMDACK_REG : process (axi_aclk)
      begin
        if (axi_aclk'event and axi_aclk = '1') then
           if (axi_reset      = '1' or 
               sig_cmdack_reg = '1') then
    
             sig_cmdack_reg <= '0';
    
           else
    
             sig_cmdack_reg <= sig_push_cmd_reg;
    
           end if; 
        end if;       
      end process IMP_CMDACK_REG; 
    
    
    
    
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_CMDCMPLT_REG
    --
    -- Process Description:
    --   Generates a 1-clock wide command complete pulse and the
    -- status register pop control.
    --
    -------------------------------------------------------------
    IMP_CMDCMPLT_REG : process (axi_aclk)
      begin
        if (axi_aclk'event and axi_aclk = '1') then
           if (axi_reset         = '1' or 
               sig_cmd_cmplt_reg = '1') then
    
             sig_cmd_cmplt_reg <= '0';
             sig_pop_status    <= '0';
    
           else
    
             sig_cmd_cmplt_reg <= sig_cmd_cmplt;
             sig_pop_status    <= sig_cmd_cmplt;
    
           end if; 
        end if;       
      end process IMP_CMDCMPLT_REG; 
    
    
    
    
    
    
    
    
    
    
    
    
     
    ---------------------------------------------------------------------------------
    --  User Command Input Register 
    ---------------------------------------------------------------------------------
     
     
    sig_push_cmd_reg        <= (ip2bus_mstrd_req or
                               ip2bus_mstwr_req) and
                               sig_cmd_empty_reg;
    
    
    sig_pop_cmd_reg         <= sig_pcc_taking_command;
     
    
    
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_CMD_REG_FIFO
    --
    -- Process Description:
    --    This process implements the input command register and  
    -- associated full flag (emulates a 1-deep FIFO). It also
    -- re-orders the vector bit sequence from (x to y) to 
    -- (y downto x). 
    --
    -------------------------------------------------------------
    IMP_CMD_REG_FIFO : process (axi_aclk)
      begin
        if (axi_aclk'event and axi_aclk = '1') then
          if (axi_reset    = '1' or
              (sig_pop_cmd_reg  = '1' and
               sig_push_cmd_reg = '0')) then
            
            sig_cmd_mstrd_req   <= '0';
            sig_cmd_mstwr_req   <= '0';
            sig_cmd_mst_addr    <= (others => '0');
            sig_cmd_mst_length  <= (others => '0');
            sig_cmd_mst_be      <= (others => '0');
            sig_cmd_type_req    <= '0'; 
            
            sig_cmd_full_reg    <= '0';
            
          elsif (sig_push_cmd_reg = '1') then
            
            
            sig_cmd_mstrd_req  <= ip2bus_mstrd_req  ;
            sig_cmd_mstwr_req  <= ip2bus_mstwr_req  ;
            sig_cmd_mst_addr   <= ip2bus_mst_addr   ;
            sig_cmd_mst_length <= ip2bus_mst_length ;
            sig_cmd_mst_be     <= ip2bus_mst_be     ;
            sig_cmd_type_req   <= ip2bus_mst_type   ;
            
            sig_cmd_full_reg   <= '1';
            
          else
            null;  -- don't change state
          end if; 
        end if;       
      end process IMP_CMD_REG_FIFO; 
    
     
    
    
    
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_CMD_REG_EMPTY_FLOP
    --
    -- Process Description:
    --    This process implements the empty flag for the 
    -- register fifo. The register is only allowed to go empty
    -- on reset or when a command has completed (as indicated
    -- by the assertion of the Command Complete status output).
    --
    -------------------------------------------------------------
    IMP_CMD_REG_EMPTY_FLOP : process (axi_aclk)
      begin
        if (axi_aclk'event and axi_aclk = '1') then
          if (axi_reset    = '1') then
            
            sig_cmd_empty_reg <= '0'; -- since this is used for the ready (invertd)
                                      -- it can't be asserted during reset
            
          --elsif (sig_pop_cmd_reg  = '1' or
          elsif (sig_cmd_cmplt_reg = '1' or
                 sig_init_done     = '1') then
            
            sig_cmd_empty_reg <= '1';
            
          elsif (sig_push_cmd_reg = '1') then
            
            sig_cmd_empty_reg <= '0';
            
          else
            null;  -- don't change state
          end if; 
        end if;       
      end process IMP_CMD_REG_EMPTY_FLOP; 
    

 
 
 
 
 
  
    
    ---------------------------------------------------------------------
    -- Single DataBeat Support logic
    ---------------------------------------------------------------------
    
    
    sig_addr_be_offset <= STD_LOGIC_VECTOR(RESIZE(sig_strt_addr_offset, ADDR_LS_SLICE_WIDTH));

    
    ------------------------------------------------------------
    -- Instance: I_FIRST_BE_OFFSET 
    --
    -- Description:
    --  Finds the first asserted BE bit (searching from ls to 
    -- ms bit) and returns the address offset of that asserted 
    -- strobe.   
    --
    ------------------------------------------------------------
    I_FIRST_BE_OFFSET : entity axi_master_burst_v1_00_a.axi_master_burst_first_stb_offset
    generic map(
      
      C_STROBE_WIDTH    => BE_WIDTH     ,  
      C_OFFSET_WIDTH    => OFFSET_WIDTH
      
      )
    port map(
      
      tstrb_in          => sig_cmd_mst_be      ,  
     
      first_offset      => sig_strt_addr_offset   
     
      );



   
        
        
    ------------------------------------------------------------
    -- Instance: I_GET_BE_SET 
    --
    -- Description:
    -- Calculates the number of asserted BE in a single beat transfer
    -- type.    
    --
    ------------------------------------------------------------
    I_GET_BE_SET : entity axi_master_burst_v1_00_a.axi_master_burst_stbs_set
    generic map (

       C_STROBE_WIDTH    =>  BE_WIDTH

      )
    port map (

       tstrb_in          =>  sig_cmd_mst_be,
      
       num_stbs_asserted =>  sig_num_stbs_asserted

      );

      
    
    
   
   
   
   

    ---------------------------------------------------------------------------------
    --  TAG Counter Logic 
    ---------------------------------------------------------------------------------
     
    
    
    
    sig_incr_tag_cnt <= sig_push_cmd_reg;
    
    
    
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_TAG_CNTR
    --
    -- Process Description:
    --  Implements the TAG counter used for tracking commands
    -- through the pipeline back to status generation.
    --
    -------------------------------------------------------------
    IMP_TAG_CNTR : process (axi_aclk)
      begin
        if (axi_aclk'event and axi_aclk = '1') then
           if (axi_reset = '1') then
    
             sig_tag_counter <= (others => '1'); -- Init to max count
                                                 -- Will roll to zero on first command push
    
           elsif (sig_incr_tag_cnt = '1') then
    
             sig_tag_counter <= sig_tag_counter + TAG_CNTR_ONE;
    
           else
    
             null;  -- Hold Current State
    
           end if; 
        end if;       
      end process IMP_TAG_CNTR; 



  
  
  
  
  
  
    ---------------------------------------------------------------------------------
    --  Doing a Read discrete Register 
    ---------------------------------------------------------------------------------
     
    
    
  
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_DOING_READ_FLOP
    --
    -- Process Description:
    --   Implement the Doing Read discrete Register.
    --
    -------------------------------------------------------------
    IMP_DOING_READ_FLOP : process (axi_aclk)
      begin
        if (axi_aclk'event and axi_aclk = '1') then
           if (axi_reset         = '1' or
               sig_cmd_cmplt_reg = '1') then
    
             sig_doing_read_reg <= '0';
    
           elsif (sig_pcc_taking_command = '1') then
    
             sig_doing_read_reg <= sig_cmd_mstrd_req;
    
           else
    
             null;  -- Hold Current State
    
           end if; 
        end if;       
      end process IMP_DOING_READ_FLOP; 
  
  
  
    
    
    
    
    
    
    ---------------------------------------------------------------------------------
    --  Doing a Write discrete Register 
    ---------------------------------------------------------------------------------
     
    
    
  
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_DOING_WRITE_FLOP
    --
    -- Process Description:
    --   Implement the Doing Write discrete Register.
    --
    -------------------------------------------------------------
    IMP_DOING_WRITE_FLOP : process (axi_aclk)
      begin
        if (axi_aclk'event and axi_aclk = '1') then
           if (axi_reset         = '1' or
               sig_cmd_cmplt_reg = '1') then
    
             sig_doing_write_reg <= '0';
    
           elsif (sig_pcc_taking_command = '1') then
    
             sig_doing_write_reg <= sig_cmd_mstwr_req;
    
           else
    
             null;  -- Hold Current State
    
           end if; 
        end if;       
      end process IMP_DOING_WRITE_FLOP; 
  
  
  
  
  
    
    
    
  
    ---------------------------------------------------------------------------------
    --  Status Register Support Logic
    -- 
    -- Input status is either from the Write Status Controller or the Read Status
    -- Controller depending on if a Read or Write in being performed.
    ---------------------------------------------------------------------------------
     
     
    -- sig_cmd_cmplt  <=  ((sig_doing_read_reg and not(mstrd_llink_busy))   or 
    --                    (sig_doing_write_reg and not(mstwr_llink_busy))) and
    --                     sig_status_reg_full;  
    
    
    sig_llink_busy  <= (sig_doing_read_reg  and mstrd_llink_busy) or 
                       (sig_doing_write_reg and mstwr_llink_busy);                
    
    
    sig_cmd_cmplt   <= not(sig_llink_busy) and
                       sig_status_reg_full;  
    
    
    sig_cmd_error   <= sig_stat_error_reg;
    
    
    
    -- Mux the input status value from either the Write status
    -- controller or the Read Status Controller.
    sig_muxed_status   <= wsc2stat_status
     When (sig_doing_write_reg = '1')
     Else rsc2stat_status;
    
    
    
     sig_stat_tag   <=  sig_muxed_status(STAT_TAG_MSBIT downto 0);
    
    
     -- Merge Slave error, Decode Error, and Internal Error into 1 flag
     sig_stat_error <=  sig_muxed_status(STAT_SLVERR_BIT) or
                        sig_muxed_status(STAT_DECERR_BIT) or
                        sig_muxed_status(STAT_INTERR_BIT);
    
    
    -- Rip the internal error status bit for use in causeing the
    -- LocalLink backends to assert discontinue if needed.
    sig_stat_int_error  <= sig_muxed_status(STAT_INTERR_BIT);
    
    
    
    stat2rsc_status_ready  <= sig_status_reg_empty and sig_doing_read_reg;
    
    stat2wsc_status_ready  <= sig_status_reg_empty and sig_doing_write_reg;
    
    
   
   
    sig_status_valid  <= wsc2stat_status_valid
      when (sig_doing_write_reg = '1')
      Else rsc2stat_status_valid
      When (sig_doing_read_reg = '1')
      Else '0';
    
    
    sig_push_status        <=  sig_status_valid and
                               sig_status_reg_empty;
    
    
    
    
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_STATUS_REG_FIFO
    --
    -- Process Description:
    --    This process implements the input status register and  
    -- associated full flag (emulates a 1-deep FIFO). 
    --
    -------------------------------------------------------------
    IMP_STATUS_REG_FIFO : process (axi_aclk)
      begin
        if (axi_aclk'event and axi_aclk = '1') then
          if (axi_reset    = '1' or
              (sig_pop_status  = '1' and
               sig_push_status = '0')) then
            
            sig_stat_tag_reg     <= (others => '0');
            sig_stat_error_reg   <= '0';
            
            sig_status_reg_full  <= '0';
            
          elsif (sig_push_status = '1') then
            
            sig_stat_tag_reg     <= sig_stat_tag   ;
            sig_stat_error_reg   <= sig_stat_error ;
            
            
            sig_status_reg_full  <= '1';
            
          else
            null;  -- don't change state
          end if; 
        end if;       
      end process IMP_STATUS_REG_FIFO; 
    
     
    
    
    
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_STATUS_REG_EMPTY_FLOP
    --
    -- Process Description:
    --    This process implements the empty flag for the 
    -- register fifo. The register is only allowed to go empty
    -- on reset or when a command has completed (as indicated
    -- by the assertion of the Command Complete status output).
    --
    -------------------------------------------------------------
    IMP_STATUS_REG_EMPTY_FLOP : process (axi_aclk)
      begin
        if (axi_aclk'event and axi_aclk = '1') then
          if (axi_reset    = '1') then
            
            sig_status_reg_empty <= '0'; -- since this is used for the ready (invertd)
                                         -- it can't be asserted during reset
            
          --elsif (sig_pop_cmd_reg  = '1' or
          elsif (sig_cmd_cmplt_reg    = '1' or
                 sig_init_done    = '1') then
            
            sig_status_reg_empty <= '1';
            
          elsif (sig_push_status = '1') then
            
            sig_status_reg_empty <= '0';
            
          else
            null;  -- don't change state
          end if; 
        end if;       
      end process IMP_STATUS_REG_EMPTY_FLOP; 
    

 
 
   
   
   
 
 
    -----------------------------------------------------------------------------
    -- RW_ERROR Output Discrete Logic
    -----------------------------------------------------------------------------
    
    rw_error      <= sig_error_sh_reg ;
    
    
    
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_ERROR_SH_REG
    --
    -- Process Description:
    --   Sample and Hold register for the rw_error output 
    -- discrete port. This is a sticky register. Once set,
    -- it can only be cleared by a reset.
    --
    -------------------------------------------------------------
    IMP_ERROR_SH_REG : process (axi_aclk)
      begin
        if (axi_aclk'event and axi_aclk = '1') then
           if (axi_reset = '1') then
    
             sig_error_sh_reg <= '0';
    
           elsif (sig_push_status  = '1' and
                  sig_error_sh_reg = '0') then
    
             sig_error_sh_reg <= sig_stat_error;
    
           else
    
             null;  -- Hold Current State
    
           end if; 
        end if;       
      end process IMP_ERROR_SH_REG; 
    
    
    
    
    
    
    
    
    -----------------------------------------------------------------------------
    -- Internal Error Output Discrete Logic
    -----------------------------------------------------------------------------
    
    rdwr2llink_int_err     <= sig_int_error_pulse_reg ;
                               
    
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_INT_ERROR_REG
    --
    -- Process Description:
    --   Creates a 1-clock wide pulse when an internal error is 
    -- reported by the status controllers. This pulse is sent to  
    -- the LocalLink modules causing them to initiate a discontinue 
    -- sequence (if needed) to terminate a LocalLink transfer in
    -- progress.
    --
    -------------------------------------------------------------
    IMP_INT_ERROR_REG : process (axi_aclk)
      begin
        if (axi_aclk'event and axi_aclk = '1') then
          if (axi_reset      = '1' or
              sig_llink_busy = '0') then
   
            sig_int_error_pulse_reg <= '0';
   
          elsif (sig_push_status = '1') then
   
            sig_int_error_pulse_reg <= sig_stat_int_error;
   
          else
   
            null;  -- Hold Current State
   
          end if; 
        end if;       
      end process IMP_INT_ERROR_REG; 
    
    
    
    
    
    
    
    
    
    
  
  
    ---------------------------------------------------------------------------------
    --  Init Done Logic
    -- 
    -- This is used to keep some logic in reset for an extra 2 clock cycles after
    -- reset de-asserts. This is used to keep any AXI-Like Ready signals from
    -- asserting during reset but allows assertion after coming out of reset.
    ---------------------------------------------------------------------------------
  
                     
    sig_init_done <= sig_init_reg1 and not(sig_init_reg2) ;
  
     
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: IMP_INIT_DONE_REGS
    --
    -- Process Description:
    --   Creates a 1 clock period wide pulse that asserts 1 clock 
    -- after reset de-asserts.
    --
    -------------------------------------------------------------
    IMP_INIT_DONE_REGS : process (axi_aclk)
      begin
        if (axi_aclk'event and axi_aclk = '1') then
           if (axi_reset = '1') then
    
             sig_init_reg1 <= '0';
             sig_init_reg2 <= '0';
    
           else
    
             sig_init_reg1 <= '1';
             sig_init_reg2 <= sig_init_reg1;
    
           end if; 
        end if;       
      end process IMP_INIT_DONE_REGS; 
  
  
  
  
 
  
  end implementation;
