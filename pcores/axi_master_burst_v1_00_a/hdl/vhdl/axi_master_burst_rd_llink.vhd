-------------------------------------------------------------------------------
-- $Id$
-------------------------------------------------------------------------------
-- axi_master_burst_rd_llink.vhd
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
-- Filename:        axi_master_burst_rd_llink.vhd
--
-- Description:     
--    THis file implements the Read LocalLink to AXI Stream adapter for the
--    AXI Master burst core.              
--                  
--                  
--                  
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              axi_master_burst_rd_llink.vhd
--
-------------------------------------------------------------------------------
-- Revision History:
--
--
-- Author:          DET
-- Revision:        $Revision: 1.1 $
-- Date:            $1/29/2011$
--
-- History:
--   DET   1/29/2011       Initial Version
--
--     DET     2/11/2011     Initial for EDK 13.2
-- ~~~~~~
--    -- Per CR593485
--     - Modified the Error logic to clear the rdllink_llink_busy assertion
--       when the localLink discontinue completes. 
--     - Added logic to complete a Read Discontinue per LocalLink spec after a
--       rdllink_rd_error assertion.
-- ^^^^^^
--
--
-------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;




-------------------------------------------------------------------------------

entity axi_master_burst_rd_llink is
  generic (
    
    C_NATIVE_DWIDTH : INTEGER range 32 to 128 := 32  
        --  Set this equal to desred data bus width needed by IPIC
        --  LocalLink Data Channels.
    
    );
  port (
    
    
    -------------------------------------------------------------------------
    -- Read LocalLink Clock input
    -------------------------------------------------------------------------
    rdllink_aclk               : in  std_logic;
    
    -------------------------------------------------------------------------
    -- Read LocalLink Reset input
    -------------------------------------------------------------------------
    rdllink_areset             : in  std_logic;


    
    -------------------------------------------------------------------------
    -- RDWR Cntlr Internal Error Indication
    -------------------------------------------------------------------------
    rdllink_rd_error           : In  std_logic;
 
    -------------------------------------------------------------------------
    -- LocalLink Enable Control (1 Clock wide pulse)
    -------------------------------------------------------------------------
    rdllink_llink_enable       : In  std_logic;
 
    -------------------------------------------------------------------------
    -- IPIC LocalLink Busy Flag
    -------------------------------------------------------------------------
    rdllink_llink_busy         : Out std_logic;
 
  
  
    -------------------------------------------------------------------------
    -- Read Address Posting Contols/Status
    -------------------------------------------------------------------------
    rdllink_allow_addr_req     : Out std_logic; -- Active High enable (1-clk pulse wide)
    rdllink_addr_req_posted    : In  std_logic; -- ignored
    rdllink_xfer_cmplt         : In  std_logic; -- ignored
  
  
    -------------------------------------------------------------------------
    -- Read AXI Master Stream Channel  
    -------------------------------------------------------------------------
    rdllink_strm_tdata         : In  std_logic_vector(C_NATIVE_DWIDTH-1 downto 0);    -- Read AXI Stream
    rdllink_strm_tstrb         : In  std_logic_vector((C_NATIVE_DWIDTH/8)-1 downto 0);-- Read AXI Stream
    rdllink_strm_tlast         : In  std_logic;                                       -- Read AXI Stream
    rdllink_strm_tvalid        : In  std_logic;                                       -- Read AXI Stream
    rdllink_strm_tready        : Out std_logic;                                       -- Read AXI Stream
    
   
    -----------------------------------------------------------------------------
    -- IPIC Read LocalLink Channel
    -----------------------------------------------------------------------------
    bus2ip_mstrd_d             : out std_logic_vector(0 to C_NATIVE_DWIDTH-1);        -- IPIC Read LocalLink
    bus2ip_mstrd_rem           : out std_logic_vector(0 to (C_NATIVE_DWIDTH/8)-1);    -- IPIC Read LocalLink
    bus2ip_mstrd_sof_n         : Out std_logic;                                       -- IPIC Read LocalLink
    bus2ip_mstrd_eof_n         : Out std_logic;                                       -- IPIC Read LocalLink
    bus2ip_mstrd_src_rdy_n     : Out std_logic;                                       -- IPIC Read LocalLink
    bus2ip_mstrd_src_dsc_n     : Out std_logic;                                       -- IPIC Read LocalLink
    
    ip2bus_mstrd_dst_rdy_n     : In  std_logic;                                       -- IPIC Read LocalLink
    ip2bus_mstrd_dst_dsc_n     : In  std_logic  -- ignored                            -- IPIC Read LocalLink

    );

 
 
end entity axi_master_burst_rd_llink;


architecture implementation of axi_master_burst_rd_llink is

  -- Constants
  Constant STRB_WIDTH : integer := C_NATIVE_DWIDTH/8;
  
  
  
  -- Signals
  signal sig_inverted_strbs      : std_logic_vector(STRB_WIDTH-1 downto 0) := (others => '0');
  signal sig_llink_busy          : std_logic := '0';
  signal sig_last_debeat_xfered  : std_logic := '0';
  signal sig_allow_rd_requests   : std_logic := '0';
  signal sig_debeat_xfered       : std_logic := '0';
  signal sig_stream_sof          : std_logic := '0';
  
  signal sig_set_discontinue     : std_logic := '0';
  signal sig_rd_error_reg        : std_logic := '0';
  signal sig_rd_discontinue      : std_logic := '0';
  signal sig_discontinue_src_rdy : std_logic := '0';
  signal sig_discontinue_eof     : std_logic := '0';
  signal sig_discontinue_cmplt   : std_logic := '0';
  
  

begin --(architecture implementation)


  
  -------------------------------------------------------------------------
  -- LocalLink Port Assignments
  -------------------------------------------------------------------------
  
  bus2ip_mstrd_d           <=  rdllink_strm_tdata           ;
  bus2ip_mstrd_rem         <=  sig_inverted_strbs           ;
  bus2ip_mstrd_sof_n       <=  not(sig_stream_sof)          ;  
  
  bus2ip_mstrd_eof_n       <=  not(rdllink_strm_tlast or
                                   sig_discontinue_eof)     ;  
  
  bus2ip_mstrd_src_rdy_n   <=  not(rdllink_strm_tvalid or
                                   sig_discontinue_src_rdy) ;  
  
  bus2ip_mstrd_src_dsc_n   <=  not(sig_discontinue_src_rdy) ;

  
  
  -------------------------------------------------------------------------
  -- Stream Port Assignments
  -------------------------------------------------------------------------
  
  rdllink_strm_tready      <=  Not(ip2bus_mstrd_dst_rdy_n) and
                               sig_llink_busy;
  
  
  
  
  
  
  -------------------------------------------------------------------------
  -- Stream Strobes to LLink REM Conversion
  -------------------------------------------------------------------------
   
 
     
  -------------------------------------------------------------
  -- Combinational Process
  --
  -- Label: IMP_STRBS_INVERT
  --
  -- Process Description:
  --   Inverts the Input Stream Strobe polarity
  --
  -------------------------------------------------------------
  IMP_STRBS_INVERT : process (rdllink_strm_tstrb)
     begin
  
       for bit_index in 0 to STRB_WIDTH-1 loop
       
        sig_inverted_strbs(bit_index) <= not(rdllink_strm_tstrb(bit_index));
       
       end loop;
  
     end process IMP_STRBS_INVERT; 
  
     
     
     
  
  
  -------------------------------------------------------------------------
  -- LocalLink Busy Flag logic
  -------------------------------------------------------------------------
  
  
  rdllink_llink_busy <= sig_llink_busy ;
  
  
   
  -- Detect the last data beat of the Stream to LocalLink transfer 
  sig_last_debeat_xfered <=  rdllink_strm_tlast          and
                             rdllink_strm_tvalid         and 
                             not(ip2bus_mstrd_dst_rdy_n) and
                             sig_llink_busy ;
   
   
   
   
   
   
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_LLINK_BUSY_FLOP
  --
  -- Process Description:
  --  Implements the LocalLink Busy Flop
  --
  -------------------------------------------------------------
  IMP_LLINK_BUSY_FLOP : process (rdllink_aclk)
    begin
      if (rdllink_aclk'event and rdllink_aclk = '1') then
         if (rdllink_areset        = '1' or
             sig_discontinue_cmplt = '1') then
  
           sig_llink_busy <= '0';
             
         elsif (rdllink_llink_enable = '1') then
  
           sig_llink_busy <= '1';
             
         elsif (sig_last_debeat_xfered = '1') then
  
           sig_llink_busy <= '0';
             
         else
  
           null;  -- Hold Current State
  
         end if; 
      end if;       
    end process IMP_LLINK_BUSY_FLOP; 
  
  
 
 
 
  
  
  -------------------------------------------------------------------------
  -- LocalLink SOF Flag logic
  --
  -- Since the input AXI Stream does not have a Start of Frame analog,
  -- one must be generated here and inserted in the LocalLink output on
  -- the first data beat of the Stream to LocalLink transfer,
  -------------------------------------------------------------------------
  
  
   
  -- Detect a data beat tranfer between the LocalLink and Stream 
  sig_debeat_xfered <= rdllink_strm_tvalid         and 
                       not(ip2bus_mstrd_dst_rdy_n) and
                       sig_llink_busy ;
   
   
   
   
   
   
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_LLINK_SOF_FLOP
  --
  -- Process Description:
  --  Implements the LocalLink SOF Flop. There is no SOF Flag
  -- that can be derived from the Stream Input.
  --
  -------------------------------------------------------------
  IMP_LLINK_SOF_FLOP : process (rdllink_aclk)
    begin
      if (rdllink_aclk'event and rdllink_aclk = '1') then
         if (rdllink_areset         = '1' or
             sig_last_debeat_xfered = '1' or
             sig_discontinue_cmplt = '1') then
  
           sig_stream_sof <= '0';
             
         elsif (rdllink_llink_enable = '1') then
  
           sig_stream_sof <= '1';
             
         elsif (sig_debeat_xfered = '1') then
  
           sig_stream_sof <= '0';
             
         else
  
           null;  -- Hold Current State
  
         end if; 
      end if;       
    end process IMP_LLINK_SOF_FLOP; 
  
  
 
 
 
  
  
  
  
  -------------------------------------------------------------------------
  -- AXI Read Address Posting Control logic
  -------------------------------------------------------------------------
  
  rdllink_allow_addr_req  <= sig_allow_rd_requests;
  
  
   
   
   
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_ALLOW_RD_REQ_FLOP
  --
  -- Process Description:
  --   Implements the AXI Read Address Request control flop.
  -- AXI Read Requests will be withheld from the AXI Read Address
  -- Channel until the LocalLink Destination is ready to receive
  -- read data.
  --
  -------------------------------------------------------------
  IMP_ALLOW_RD_REQ_FLOP : process (rdllink_aclk)
    begin
      if (rdllink_aclk'event and rdllink_aclk = '1') then
         if (rdllink_areset       = '1' or
             rdllink_llink_enable = '1') then
  
           sig_allow_rd_requests <= '0';
             
         elsif (ip2bus_mstrd_dst_rdy_n = '0' and
                sig_llink_busy         = '1') then
  
           sig_allow_rd_requests <= '1';
             
         else
  
           null;  -- Hold Current State
  
         end if; 
      end if;       
    end process IMP_ALLOW_RD_REQ_FLOP; 
  
  
  
  
  
  
  
  
  
  -------------------------------------------------------------------------
  -- Read Error LLink discontinue logic
  -------------------------------------------------------------------------
  
  
  
  -- Detect rising edge of the Read Error assertion
  sig_set_discontinue     <= rdllink_rd_error      and 
                             not(sig_rd_error_reg) and
                             sig_llink_busy ;
  
  -- Force the assertion of the Source ready at Discontinue
  sig_discontinue_src_rdy <= sig_rd_discontinue and 
                             sig_llink_busy;
           
  
  -- Detect Completion of the Read Discontinue
  sig_discontinue_cmplt   <= sig_rd_discontinue      and 
                             sig_discontinue_src_rdy and 
                             Not(ip2bus_mstrd_dst_rdy_n);
  
  
  -- Must also assert the EOF on a discontinue
  sig_discontinue_eof    <= sig_discontinue_src_rdy;
  
  
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_RD_ERROR_FLOP
  --
  -- Process Description:
  --   Implements the register for the read discontinue flag.
  --
  -------------------------------------------------------------
  IMP_RD_ERROR_FLOP : process (rdllink_aclk)
    begin
      if (rdllink_aclk'event and rdllink_aclk = '1') then
         if (rdllink_areset  = '1') then
  
           sig_rd_error_reg <= '0';
  
         else
  
           sig_rd_error_reg <= rdllink_rd_error;
  
         end if; 
      end if;       
    end process IMP_RD_ERROR_FLOP; 
 
                
                
                
  
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_RD_DSC_FLOP
  --
  -- Process Description:
  --   Implements the register for the read discontinue flag.
  --
  -------------------------------------------------------------
  IMP_RD_DSC_FLOP : process (rdllink_aclk)
    begin
      if (rdllink_aclk'event and rdllink_aclk = '1') then
         if (rdllink_areset        = '1' or
             sig_discontinue_cmplt = '1') then
  
           sig_rd_discontinue <= '0';
  
         elsif (sig_set_discontinue = '1') then
  
           sig_rd_discontinue <= '1';
  
         else
  
           null;  -- Hold Current State
  
         end if; 
      end if;       
    end process IMP_RD_DSC_FLOP; 
 
  

end implementation;
