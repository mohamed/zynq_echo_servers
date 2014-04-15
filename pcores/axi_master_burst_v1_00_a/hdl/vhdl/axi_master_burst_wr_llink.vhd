-------------------------------------------------------------------------------
-- $Id$
-------------------------------------------------------------------------------
-- axi_master_burst_wr_llink.vhd
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
-- Filename:        axi_master_burst_wr_llink.vhd
--
-- Description:     
--    THis file implements the Write LocalLink to AXI Stream adapter for the
--    AXI Master burst core.              
--                  
--                  
--                  
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              axi_master_burst_wr_llink.vhd
--
-------------------------------------------------------------------------------
-- Revision History:
--
--
-- Author:          DET
-- Revision:        $Revision: 1.1 $
-- Date:            $1/27/2011$
--
-- History:
--   DET   1/27/2011       Initial Version
--
--     DET     2/14/2011     Initial for EDK 13.2
-- ~~~~~~
--    -- Per CR593485
--     - Modified the Error logic to clear the wrllink_llink_busy assertion
--       when the localLink discontinue completes. 
--     - Added logic to complete a Write Discontinue per LocalLink spec after a
--       wrllink_wr_error assertion.
-- ^^^^^^
--
--
-------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;




-------------------------------------------------------------------------------

entity axi_master_burst_wr_llink is
  generic (
    
    C_NATIVE_DWIDTH : INTEGER range 32 to 128 := 32  
        --  Set this equal to desred data bus width needed by IPIC
        --  LocalLink Data Channels.
    
    );
  port (
    
    
    -------------------------------------------------------------------------
    -- Write LocalLink Clock input
    -------------------------------------------------------------------------
    wrllink_aclk               : in  std_logic;
    
    -------------------------------------------------------------------------
    -- Write LocalLink Reset input
    -------------------------------------------------------------------------
    wrllink_areset             : in  std_logic;


    
    -------------------------------------------------------------------------
    -- RDWR Cntlr Internal Error Indication
    -------------------------------------------------------------------------
    wrllink_wr_error           : In  std_logic;
 
    -------------------------------------------------------------------------
    -- LocalLink Enable Control (1 Clock wide pulse)
    -------------------------------------------------------------------------
    wrllink_llink_enable       : In  std_logic;
 
    -------------------------------------------------------------------------
    -- IPIC LocalLink Busy Flag
    -------------------------------------------------------------------------
    wrllink_llink_busy         : Out std_logic;
 
  
  
    -------------------------------------------------------------------------
    -- Write Address Posting Contols/Status
    -------------------------------------------------------------------------
    wrllink_allow_addr_req     : Out std_logic; -- Active High enable (1-clk pulse wide)
    wrllink_addr_req_posted    : In  std_logic; -- ignored
    wrllink_xfer_cmplt         : In  std_logic; -- ignored
  
  
    -------------------------------------------------------------------------
    -- Write AXI Slave Master Channel  
    -------------------------------------------------------------------------
    wrllink_strm_tdata         : Out std_logic_vector(C_NATIVE_DWIDTH-1 downto 0);     -- Write AXI Stream
    wrllink_strm_tstrb         : Out std_logic_vector((C_NATIVE_DWIDTH/8)-1 downto 0); -- Write AXI Stream
    wrllink_strm_tlast         : Out std_logic;                                        -- Write AXI Stream
    wrllink_strm_tvalid        : Out std_logic;                                        -- Write AXI Stream
    wrllink_strm_tready        : In  std_logic;                                        -- Write AXI Stream
    
   
    -------------------------------------------------------------------------
    -- IPIC Write LocalLink Channel
    -------------------------------------------------------------------------
    ip2bus_mstwr_d             : In  std_logic_vector(0 to C_NATIVE_DWIDTH-1);     -- IPIC Write LocalLink
    ip2bus_mstwr_rem           : In  std_logic_vector(0 to (C_NATIVE_DWIDTH/8)-1); -- ignored IPIC Write LocalLink
    ip2bus_mstwr_sof_n         : In  std_logic; -- ignored                         -- IPIC Write LocalLink
    ip2bus_mstwr_eof_n         : In  std_logic;                                    -- IPIC Write LocalLink
    ip2bus_mstwr_src_rdy_n     : In  std_logic;                                    -- IPIC Write LocalLink
    ip2bus_mstwr_src_dsc_n     : In  std_logic; -- ignored                         -- IPIC Write LocalLink
    
    bus2ip_mstwr_dst_rdy_n     : Out std_logic;                                    -- IPIC Write LocalLink
    bus2ip_mstwr_dst_dsc_n     : Out std_logic                                     -- IPIC Write LocalLink
   

    );

end entity axi_master_burst_wr_llink;


architecture implementation of axi_master_burst_wr_llink is

  -- Constants
  Constant STRB_WIDTH : integer := C_NATIVE_DWIDTH/8;
  
  
  
  -- Signals
  signal sig_inv_rem              : std_logic_vector(0 to STRB_WIDTH-1) := (others => '0');
  signal sig_llink_busy           : std_logic := '0';
  signal sig_last_debeat_xfered   : std_logic := '0';
  
  signal sig_allow_wr_requests    : std_logic := '0';
  
  signal sig_llink_dst_ready_n    : std_logic := '0';
  
  signal sig_set_discontinue      : std_logic := '0';
  signal sig_wr_error_reg         : std_logic := '0';
  signal sig_wr_dsc_in_prog       : std_logic := '0';
  signal sig_discontinue_dst_rdy  : std_logic := '0';
  signal sig_discontinue_cmplt    : std_logic := '0';
  signal sig_discontinue_accepted : std_logic := '0';
  signal sig_assert_discontinue   : std_logic := '0';
  
  

begin --(architecture implementation)


  
  -------------------------------------------------------------------------
  -- Write Stream Output Port Assignments
  -------------------------------------------------------------------------
  wrllink_strm_tdata      <= ip2bus_mstwr_d             ;
  
  wrllink_strm_tstrb      <= sig_inv_rem                ;
  
  wrllink_strm_tlast      <= not(ip2bus_mstwr_eof_n)    ;
  
  wrllink_strm_tvalid     <= not(ip2bus_mstwr_src_rdy_n) and
                             sig_llink_busy;
  
  
  
  
  
  
  
  -------------------------------------------------------------------------
  -- Write LocalLink Output Port Assignments
  -------------------------------------------------------------------------
  bus2ip_mstwr_dst_rdy_n  <= sig_llink_dst_ready_n ;
  
  --bus2ip_mstwr_dst_dsc_n  <= not(wrllink_wr_error) ;
  bus2ip_mstwr_dst_dsc_n  <= not(sig_assert_discontinue) ;
  
  sig_llink_dst_ready_n   <= not((wrllink_strm_tready and sig_llink_busy) or
                             sig_discontinue_dst_rdy) ;
  
  
 
  -- Since the PLB Master burst ignored the REM input, Just 
  -- assign the inverted REM to be all asserted. This will be 
  -- used for the AXI Stream output.
  sig_inv_rem <= (others => '1');
 
 
  
  
  -------------------------------------------------------------------------
  -- LocalLink Busy Flag logic
  -------------------------------------------------------------------------
  
  
  wrllink_llink_busy <= sig_llink_busy ;
  
  
   
  -- Detect the last data beat of the incoming LocalLink transfer 
  sig_last_debeat_xfered <= not(ip2bus_mstwr_eof_n     or
                                ip2bus_mstwr_src_rdy_n or
                                sig_llink_dst_ready_n );
   
   
   
   
   
   
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_LLINK_BUSY_FLOP
  --
  -- Process Description:
  --  Implements the LocalLink Busy Flop
  --
  -------------------------------------------------------------
  IMP_LLINK_BUSY_FLOP : process (wrllink_aclk)
    begin
      if (wrllink_aclk'event and wrllink_aclk = '1') then
         if (wrllink_areset = '1') then
  
           sig_llink_busy <= '0';
             
         elsif (wrllink_llink_enable = '1') then
  
           sig_llink_busy <= '1';
             
         elsif (sig_last_debeat_xfered = '1') then
  
           sig_llink_busy <= '0';
             
         else
  
           null;  -- Hold Current State
  
         end if; 
      end if;       
    end process IMP_LLINK_BUSY_FLOP; 
  
  
 
 
 
  
  
  
  -------------------------------------------------------------------------
  -- AXI Write Address Posting Control logic
  -------------------------------------------------------------------------
  
  wrllink_allow_addr_req  <= sig_allow_wr_requests;
  
  
  
  
   
   
   
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_ALLOW_WR_REQ_FLOP
  --
  -- Process Description:
  --  Implements the AXI Write Address Request control flop.
  -- AXI Write Requests will be withheld from the AXI Write Address
  -- Channel until the LocalLink Source is ready to drive data.
  --
  -------------------------------------------------------------
  IMP_ALLOW_WR_REQ_FLOP : process (wrllink_aclk)
    begin
      if (wrllink_aclk'event and wrllink_aclk = '1') then
         if (wrllink_areset        = '1' or
             wrllink_llink_enable  = '1') then
  
           sig_allow_wr_requests <= '0';
             
         elsif (ip2bus_mstwr_src_rdy_n = '0' and
                sig_llink_busy         = '1') then
  
           sig_allow_wr_requests <= '1';
             
         else
  
           null;  -- Hold Current State
  
         end if; 
      end if;       
    end process IMP_ALLOW_WR_REQ_FLOP; 
  
  
  
  
  
  
  
  
  
  
  -------------------------------------------------------------------------
  -- Write Error LLink discontinue logic
  -------------------------------------------------------------------------
  
  
  
  -- Detect rising edge of the Read Error assertion
  sig_set_discontinue     <= wrllink_wr_error      and 
                             not(sig_wr_error_reg) and
                             sig_llink_busy ;
  
  -- Force the assertion of the Dest ready during the discontinue
  -- sequence.
  sig_discontinue_dst_rdy <= sig_wr_dsc_in_prog and 
                             sig_llink_busy;
           
  
  -- Detect the acceptance of discontinue by the source but not
  -- necessarily the completion of the discontinue sequence.
  sig_discontinue_accepted <= Not(ip2bus_mstwr_src_rdy_n) and
                              sig_assert_discontinue;
  
  
  
  -- Detect Completion of the Write Discontinue sequence
  -- when the EOF is transfered by the Source
  sig_discontinue_cmplt   <= sig_discontinue_dst_rdy and 
                             Not(ip2bus_mstwr_src_rdy_n) and
                             not(ip2bus_mstwr_eof_n);
  
  
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_WR_ERROR_FLOP
  --
  -- Process Description:
  --   Implements the register for the write error flag.
  --
  -------------------------------------------------------------
  IMP_WR_ERROR_FLOP : process (wrllink_aclk)
    begin
      if (wrllink_aclk'event and wrllink_aclk = '1') then
         if (wrllink_areset  = '1') then
  
           sig_wr_error_reg <= '0';
  
         else
  
           sig_wr_error_reg <= wrllink_wr_error;
  
         end if; 
      end if;       
    end process IMP_WR_ERROR_FLOP; 
 
                
                
                
  
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_WR_DSC_FLOP
  --
  -- Process Description:
  --   Implements the register for the write discontinue flag
  -- indicating that a discontinue sequence is in progress.
  --
  -------------------------------------------------------------
  IMP_WR_DSC_FLOP : process (wrllink_aclk)
    begin
      if (wrllink_aclk'event and wrllink_aclk = '1') then
         if (wrllink_areset        = '1' or
             sig_discontinue_cmplt = '1') then
  
           sig_wr_dsc_in_prog <= '0';
  
         elsif (sig_set_discontinue = '1') then
  
           sig_wr_dsc_in_prog <= '1';
  
         else
  
           null;  -- Hold Current State
  
         end if; 
      end if;       
    end process IMP_WR_DSC_FLOP; 
 
 
 
 
  
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_SEND_WR_DSC
  --
  -- Process Description:
  --   Implements the register for the flag signaling the 
  -- assertion of the LLink Dest discontinue output.
  --
  -------------------------------------------------------------
  IMP_SEND_WR_DSC : process (wrllink_aclk)
    begin
      if (wrllink_aclk'event and wrllink_aclk = '1') then
         if (wrllink_areset           = '1' or
             sig_discontinue_accepted = '1') then
  
           sig_assert_discontinue <= '0';
  
         elsif (sig_set_discontinue = '1') then
  
           sig_assert_discontinue <= '1';
  
         else
  
           null;  -- Hold Current State
  
         end if; 
      end if;       
    end process IMP_SEND_WR_DSC; 
 
  


end implementation;
