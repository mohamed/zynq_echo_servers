-------------------------------------------------------------------------------
-- axi_master_burst_rd_wr_cntlr.vhd
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
-- Filename:        axi_master_burst_rd_wr_cntlr.vhd
--
-- Description:
--    This file implements the DataMover MM2S Full Wrapper.
--
--
--
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--
--      axi_master_burst.vhd
--          |
--          |-- proc_common_v3_00_a (helper library)
--          |
--          |-- axi_master_burst_reset.vhd
--          |
--          |-- axi_master_rd_llink.vhd
--          |
--          |-- axi_master_wr_llink.vhd
--          |
--          |
--          |-- axi_master_burst_cmd_status.vhd
--          |       |-- axi_master_burst_first_stb_offset.vhd
--          |       |-- axi_master_burst_stbs_set.vhd
--          |
--          |-- axi_master_burst_rd_wr_cntlr.vhd
--                  |--  axi_master_burst_pcc.vhd
--                  |        |--  axi_master_burst_strb_gen.vhd
--                  |--  axi_master_burst_addr_cntl.vhd
--                  |--  axi_master_burst_rddata_cntl.vhd
--                  |--  axi_master_burst_wrdata_cntl.vhd
--                  |--  axi_master_burst_rd_status_cntl.vhd
--                  |--  axi_master_burst_wr_status_cntl.vhd
--                  |--  axi_master_burst_skid_buf.vhd
--                  |--  axi_master_burst_skid2mm_buf.vhd
--
--
--
-------------------------------------------------------------------------------
-- Revision History:
--
--
-- Author:          DET
-- Revision:        $Revision: 1.0 $
-- Date:            $01/18/2011$
--
-- History:
--   DET   01/18/2011       Initial Version
--
--     DET     2/10/2011     Initial for EDk 13.2
-- ~~~~~~
--    -- Per CR593239
--     - Added Min BTT width correction logic (adapted from Datamover)
-- ^^^^^^
--     DET     2/10/2011     Initial for EDK 13.2
-- ~~~~~~
--     - Updated the Addr Cntlr Instance with new ports for avalid
--       registering. Cleaned up a*valid signal generation. 
--     - Added missing port mstr2dre_cmd_cmplt to the PCC instance
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



-- axi_master_burst Library Modules
library axi_master_burst_v1_00_a                            ;
use axi_master_burst_v1_00_a.axi_master_burst_pcc           ;
use axi_master_burst_v1_00_a.axi_master_burst_addr_cntl     ;
use axi_master_burst_v1_00_a.axi_master_burst_rddata_cntl   ;
use axi_master_burst_v1_00_a.axi_master_burst_wrdata_cntl   ;
use axi_master_burst_v1_00_a.axi_master_burst_rd_status_cntl;
use axi_master_burst_v1_00_a.axi_master_burst_wr_status_cntl;
use axi_master_burst_v1_00_a.axi_master_burst_skid_buf      ;
use axi_master_burst_v1_00_a.axi_master_burst_skid2mm_buf   ;









-------------------------------------------------------------------------------

entity axi_master_burst_rd_wr_cntlr is
  generic (

    C_RDWR_ARID               : Integer range 0 to  255 :=  0;
       -- Specifies the constant value to output on
       -- the ARID output port

    C_RDWR_ID_WIDTH           : Integer range 1 to  8 :=  4;
       -- Specifies the width of the MM2S ID port

    C_RDWR_ADDR_WIDTH         : Integer range 32 to  64 :=  32;
       -- Specifies the width of the MMap Read Address Channel
       -- Address bus

    C_RDWR_MDATA_WIDTH        : Integer range 32 to 256 :=  32;
       -- Specifies the width of the MMap Read Data Channel
       -- data bus

    C_RDWR_SDATA_WIDTH        : Integer range 8 to 256 :=  32;
       -- Specifies the width of the MM2S Master Stream Data
       -- Channel data bus

    C_RDWR_MAX_BURST_LEN         : Integer range 16 to  256 :=  16;
       -- Specifies the max number of databeats to use for MMap
       -- burst transfers by the MM2S function

    C_RDWR_BTT_USED           : Integer range 8 to  23 :=  12;
      -- Specifies the number of bits used from the BTT field
      -- of the input Command Word of the MM2S Command Interface

    C_RDWR_ADDR_PIPE_DEPTH     : Integer range 1 to 30 := 2;
      -- This parameter specifies the depth of the RDWR internal
      -- child command queues in the Read Address Controller and
      -- the Read Data Controller. Increasing this value will
      -- allow more Read Addresses to be issued to the AXI4 Read
      -- Address Channel before receipt of the associated read
      -- data on the Read Data Channel.

    C_RDWR_PCC_CMD_WIDTH       : Integer range 68 to 68 :=  68;
       -- Specifies the width of the PCC Command input

    C_RDWR_STATUS_WIDTH       : Integer range 8 to 8     :=  8;
       -- Specifies the width of the Status Output bus


    C_FAMILY                  : String := "virtex6"
       -- Specifies the target FPGA family type

    );
  port (


    -------------------------------------------------------------------------
    -- RDWR Primary Clock input
    -------------------------------------------------------------------------
    rdwr_aclk              : in  std_logic;
       -- Primary synchronization clock for the Master side
       -- interface and internal logic. It is also used
       -- for the User interface synchronization when
       -- C_STSCMD_IS_ASYNC = 0.

    -------------------------------------------------------------------------
    -- RDWR Primary Reset input
    -------------------------------------------------------------------------
    rdwr_areset           : in  std_logic;
       -- Reset used for the internal master logic

    -------------------------------------------------------------------------
    -- RDWR Master detected Error Output Discrete
    -------------------------------------------------------------------------
    rdwr_md_error          : out  std_logic;
       -- Master detected error output (acive high)



    -------------------------------------------------------------------------
    -- Command/Status Module PCC Command Interface (AXI Stream Like)
    -------------------------------------------------------------------------
    cmd2rdwr_cmd_valid      : in  std_logic;                                          -- Command IF
    rdwr2cmd_cmd_ready      : out std_logic;                                          -- Command IF
    cmd2rdwr_cmd_data       : in  std_logic_vector(C_RDWR_PCC_CMD_WIDTH-1 downto 0);  -- Command IF

    -------------------------------------------------------------------------
    -- Command/Status Module Type Interface
    -------------------------------------------------------------------------
    cmd2rdwr_doing_read     : in  std_logic;                                          -- Read Active Discrete
    cmd2rdwr_doing_write    : in  std_logic;                                          -- Write Active Discrete





    -------------------------------------------------------------------------
    -- Command/Status Module Read Status Ports (AXI Stream Like)
    -------------------------------------------------------------------------
    stat2rsc_status_ready   : in  std_logic;                                          -- Read Status
    rsc2stat_status_valid   : out std_logic;                                          -- Read Status
    rsc2stat_status         : out std_logic_vector(C_RDWR_STATUS_WIDTH-1 downto 0);   -- Read Status

    -------------------------------------------------------------------------
    -- Command/Status Module Write Status Ports (AXI Stream Like)
    -------------------------------------------------------------------------
    stat2wsc_status_ready   : in  std_logic;                                          -- Write Status
    wsc2stat_status_valid   : out std_logic;                                          -- Write Status
    wsc2stat_status         : out std_logic_vector(C_RDWR_STATUS_WIDTH-1 downto 0);   -- Write Status





    -------------------------------------------------------------------------
    -- LocalLink Enable Outputs (1 clock pulse)
    -------------------------------------------------------------------------
    rd_llink_enable         : out std_logic;                                          -- Read LLink Enable
    wr_llink_enable         : out std_logic;                                          -- Write LLink Enable



    -------------------------------------------------------------------------
    -- Read Address Posting Contols/Status
    -------------------------------------------------------------------------
    rd_allow_addr_req       : in  std_logic;                                          -- Read Address Posting
    rd_addr_req_posted      : out std_logic;                                          -- Read Address Posting
    rd_xfer_cmplt           : out std_logic;                                          -- Read Address Posting

    -------------------------------------------------------------------------
    -- Write Address Posting Contols/Status
    -------------------------------------------------------------------------
    wr_allow_addr_req       : in  std_logic;                                          -- Write Address Posting
    wr_addr_req_posted      : out std_logic;                                          -- Write Address Posting
    wr_xfer_cmplt           : out std_logic;                                          -- Write Address Posting




    -------------------------------------------------------------------------
    -- AXI Read Address Channel I/O
    -------------------------------------------------------------------------
    rd_arid                 : out std_logic_vector(C_RDWR_ID_WIDTH-1 downto 0);       -- AXI4
    rd_araddr               : out std_logic_vector(C_RDWR_ADDR_WIDTH-1 downto 0);     -- AXI4
    rd_arlen                : out std_logic_vector(7 downto 0);                       -- AXI4
    rd_arsize               : out std_logic_vector(2 downto 0);                       -- AXI4
    rd_arburst              : out std_logic_vector(1 downto 0);                       -- AXI4
    rd_arprot               : out std_logic_vector(2 downto 0);                       -- AXI4
    rd_arcache              : out std_logic_vector(3 downto 0);                       -- AXI4
    rd_arvalid              : out std_logic;                                          -- AXI4
    rd_arready              : in  std_logic;                                          -- AXI4

    -------------------------------------------------------------------------
    -- AXI Read Data Channel I/O
    -------------------------------------------------------------------------
    rd_rdata                : In  std_logic_vector(C_RDWR_MDATA_WIDTH-1 downto 0);    -- AXI4
    rd_rresp                : In  std_logic_vector(1 downto 0);                       -- AXI4
    rd_rlast                : In  std_logic;                                          -- AXI4
    rd_rvalid               : In  std_logic;                                          -- AXI4
    rd_rready               : Out std_logic;                                          -- AXI4

    -------------------------------------------------------------------------
    -- AXI Read Master Stream Channel I/O
    -------------------------------------------------------------------------         -- AXI4 Stream
    rd_strm_tdata           : Out std_logic_vector(C_RDWR_SDATA_WIDTH-1 downto 0);    -- AXI4 Stream
    rd_strm_tstrb           : Out std_logic_vector((C_RDWR_SDATA_WIDTH/8)-1 downto 0);-- AXI4 Stream
    rd_strm_tlast           : Out std_logic;                                          -- AXI4 Stream
    rd_strm_tvalid          : Out std_logic;                                          -- AXI4 Stream
    rd_strm_tready          : In  std_logic;                                          -- AXI4 Stream






    -------------------------------------------------------------------------
    -- AXI Write Address Channel I/O
    -------------------------------------------------------------------------
    wr_awid                 : out std_logic_vector(C_RDWR_ID_WIDTH-1 downto 0);       -- AXI4
    wr_awaddr               : out std_logic_vector(C_RDWR_ADDR_WIDTH-1 downto 0);     -- AXI4
    wr_awlen                : out std_logic_vector(7 downto 0);                       -- AXI4
    wr_awsize               : out std_logic_vector(2 downto 0);                       -- AXI4
    wr_awburst              : out std_logic_vector(1 downto 0);                       -- AXI4
    wr_awprot               : out std_logic_vector(2 downto 0);                       -- AXI4
    wr_awcache              : out std_logic_vector(3 downto 0);                       -- AXI4
    wr_awvalid              : out std_logic;                                          -- AXI4
    wr_awready              : in  std_logic;                                          -- AXI4

    -------------------------------------------------------------------------
    -- RDWR AXI Write Data Channel I/O
    -------------------------------------------------------------------------
    wr_wdata                : Out  std_logic_vector(C_RDWR_MDATA_WIDTH-1 downto 0);     -- AXI4 
    wr_wstrb                : Out  std_logic_vector((C_RDWR_MDATA_WIDTH/8)-1 downto 0); -- AXI4 
    wr_wlast                : Out  std_logic;                                           -- AXI4 
    wr_wvalid               : Out  std_logic;                                           -- AXI4 
    wr_wready               : In   std_logic;                                           -- AXI4 

    -------------------------------------------------------------------------
    -- RDWR AXI Write response Channel I/O
    -------------------------------------------------------------------------
    wr_bresp                : In   std_logic_vector(1 downto 0);                       -- AXI4 
    wr_bvalid               : In   std_logic;                                          -- AXI4 
    wr_bready               : Out  std_logic;                                          -- AXI4 


    -------------------------------------------------------------------------
    -- RDWR AXI Slave Stream Channel I/O
    -------------------------------------------------------------------------
    wr_strm_tdata           : In  std_logic_vector(C_RDWR_SDATA_WIDTH-1 downto 0);     -- AXI4 Stream
    wr_strm_tstrb           : In  std_logic_vector((C_RDWR_SDATA_WIDTH/8)-1 downto 0); -- AXI4 Stream
    wr_strm_tlast           : In  std_logic;                                           -- AXI4 Stream
    wr_strm_tvalid          : In  std_logic;                                           -- AXI4 Stream
    wr_strm_tready          : Out std_logic                                            -- AXI4 Stream

    );

end entity axi_master_burst_rd_wr_cntlr;


architecture implementation of axi_master_burst_rd_wr_cntlr is



  -- Function Declarations   ----------------------------------------

  -------------------------------------------------------------------
  -- Function
  --
  -- Function Name: func_calc_rdmux_sel_bits
  --
  -- Function Description:
  --  This function calculates the number of address bits needed for
  -- the Read data mux select control.
  --
  -------------------------------------------------------------------
  function func_calc_rdmux_sel_bits (mmap_dwidth_value : integer) return integer is

    Variable num_addr_bits_needed : Integer range 1 to 5 := 1;

  begin

    case mmap_dwidth_value is
      when 32 =>
        num_addr_bits_needed := 2;
      when 64 =>
        num_addr_bits_needed := 3;
      when 128 =>
        num_addr_bits_needed := 4;
      when others => -- 256 bits
        num_addr_bits_needed := 5;
    end case;

    Return (num_addr_bits_needed);

  end function func_calc_rdmux_sel_bits;





   -------------------------------------------------------------------
   -- Function
   --
   -- Function Name: funct_get_min_btt_width
   --
   -- Function Description:
   --   This function calculates the minimum required value  
   -- for the used width of the command BTT field. 
   --
   -------------------------------------------------------------------
   function funct_get_min_btt_width (max_burst_beats : integer;
                                     bytes_per_beat  : integer ) return integer is
   
     Variable var_min_btt_needed      : Integer;
     Variable var_max_bytes_per_burst : Integer;
   
   
   begin
   
     var_max_bytes_per_burst := max_burst_beats*bytes_per_beat;
     
-- coverage off     
     if (var_max_bytes_per_burst <= 16) then
     
        var_min_btt_needed := 5;
     
     elsif (var_max_bytes_per_burst <= 32) then
     
        var_min_btt_needed := 6;
-- coverage on     
     
     elsif (var_max_bytes_per_burst <= 64) then
     
        var_min_btt_needed := 7;
     
     elsif (var_max_bytes_per_burst <= 128) then
     
        var_min_btt_needed := 8;
     
     elsif (var_max_bytes_per_burst <= 256) then
     
        var_min_btt_needed := 9;
     
     elsif (var_max_bytes_per_burst <= 512) then
     
        var_min_btt_needed := 10;
     
     elsif (var_max_bytes_per_burst <= 1024) then
     
        var_min_btt_needed := 11;
     
     elsif (var_max_bytes_per_burst <= 2048) then
     
        var_min_btt_needed := 12;
     
     elsif (var_max_bytes_per_burst <= 4096) then
     
        var_min_btt_needed := 13;
     
-- coverage off     
     else   -- 8K byte range
     
        var_min_btt_needed := 14;
-- coverage on     
          
     end if;
     
     
     
     Return (var_min_btt_needed);
   
     
   end function funct_get_min_btt_width;
   
   
   
   
   
   -------------------------------------------------------------------
   -- Function
   --
   -- Function Name: funct_fix_btt_used
   --
   -- Function Description:
   --  THis function makes sure the BTT width used is at least the
   -- minimum needed.
   --
   -------------------------------------------------------------------
   function funct_fix_btt_used (requested_btt_width : integer;
                                min_btt_width       : integer) return integer is
   
     Variable var_corrected_btt_width : Integer;
   
   begin
   
     
     If (requested_btt_width < min_btt_width) Then
         
       var_corrected_btt_width :=  min_btt_width;
     
     else
         
       var_corrected_btt_width :=  requested_btt_width;
     
     End if;
     
     
     Return (var_corrected_btt_width);
   
     
   end function funct_fix_btt_used;
   
   
   
   
   
   
   



  -- Constant Declarations   ----------------------------------------

 Constant LOGIC_LOW                 : std_logic := '0';
 Constant LOGIC_HIGH                : std_logic := '1';

 Constant RDWR_ARID_VALUE           : integer range  0 to 255 := C_RDWR_ARID;
 Constant RDWR_ARID_WIDTH           : integer range  1 to  8  := C_RDWR_ID_WIDTH;
 Constant RDWR_ADDR_WIDTH           : integer range 32 to  64 := C_RDWR_ADDR_WIDTH;
 Constant RDWR_MDATA_WIDTH          : integer range 32 to 256 := C_RDWR_MDATA_WIDTH;
 Constant RDWR_SDATA_WIDTH          : integer range  8 to 256 := C_RDWR_SDATA_WIDTH;

 Constant BASE_PCC_CMD_WIDTH        : integer := 64;
 Constant RDWR_TAG_WIDTH            : integer range  1 to   8 := C_RDWR_PCC_CMD_WIDTH-BASE_PCC_CMD_WIDTH;
 Constant RDWR_CMD_WIDTH            : integer                 := C_RDWR_PCC_CMD_WIDTH;

 Constant RDWR_STS_WIDTH            : integer                 := C_RDWR_STATUS_WIDTH;
 Constant INCLUDE_RDWR_STSFIFO      : integer range  0 to   1 := 1;
 Constant RDWR_STSCMD_FIFO_DEPTH    : integer range  1 to  16 := 1;
 Constant RDWR_STSCMD_IS_ASYNC      : integer range  0 to   1 := 0;
 Constant ADDR_CNTL_FIFO_DEPTH      : integer range  1 to  30 := C_RDWR_ADDR_PIPE_DEPTH;
 Constant RD_DATA_CNTL_FIFO_DEPTH   : integer range  1 to  30 := C_RDWR_ADDR_PIPE_DEPTH;
 Constant WR_DATA_CNTL_FIFO_DEPTH   : integer range  1 to  30 := C_RDWR_ADDR_PIPE_DEPTH;
 Constant SEL_ADDR_WIDTH            : integer range  2 to   5 := func_calc_rdmux_sel_bits(RDWR_MDATA_WIDTH);
 
 
 Constant RDWR_BTT_USED             : integer range  8 to  23 := C_RDWR_BTT_USED;
 Constant RDWR_MAX_BURST_LEN        : integer range 16 to 256 := C_RDWR_MAX_BURST_LEN;
 Constant RDWR_BYTES_PER_BEAT       : integer range  4 to  16 := RDWR_SDATA_WIDTH/8;
 
 Constant RDWR_MIN_BTT_NEEDED       : integer := funct_get_min_btt_width(RDWR_MAX_BURST_LEN,
                                                                         RDWR_BYTES_PER_BEAT);
 
 Constant RDWR_CORRECTED_BTT_USED   : integer := funct_fix_btt_used(RDWR_BTT_USED,
                                                                    RDWR_MIN_BTT_NEEDED);
 
 Constant OMIT_INDET_BTT            : integer range  0 to   1 := 0;
 Constant OMIT_DRE                  : integer range  0 to   1 := 0;
 Constant DRE_ALIGN_WIDTH           : integer range  1 to   3 := 1;
 Constant WR_STATUS_CNTL_FIFO_DEPTH : integer range  1 to  32 := WR_DATA_CNTL_FIFO_DEPTH+2; -- 2 added for going
                                                                                              -- full thresholding
                                                                                              -- in WSC
 Constant WSC_BYTES_RCVD_WIDTH      : integer range  8 to  32 := RDWR_CORRECTED_BTT_USED;
 Constant OMIT_STORE_FORWARD        : integer range  0 to   1 := 0;





 -- Signal Declarations  ------------------------------------------

 signal sig_md_error_reg             : std_logic := '0';
 signal sig_doing_read               : std_logic := '0';
 signal sig_doing_write              : std_logic := '0';

 signal sig_axi2addr_aready          : std_logic := '0';
 signal sig_addr2axi_arvalid         : std_logic := '0';
 signal sig_addr2axi_awvalid         : std_logic := '0';
 signal sig_addr2axi_aid             : std_logic_vector(RDWR_ARID_WIDTH-1 downto 0) := (others => '0');
 signal sig_addr2axi_aaddr           : std_logic_vector(RDWR_ADDR_WIDTH-1 downto 0) := (others => '0');
 signal sig_addr2axi_alen            : std_logic_vector(7 downto 0) := (others => '0');
 signal sig_addr2axi_asize           : std_logic_vector(2 downto 0) := (others => '0');
 signal sig_addr2axi_aburst          : std_logic_vector(1 downto 0) := (others => '0');
 signal sig_addr2axi_aprot           : std_logic_vector(2 downto 0) := (others => '0');

 signal sig_rdc2axi_rready           : std_logic := '0';
 signal sig_axi2rdc_rvalid           : std_logic := '0';
 signal sig_axi2rdc_rdata            : std_logic_vector(RDWR_MDATA_WIDTH-1 downto 0) := (others => '0');
 signal sig_axi2rdc_rresp            : std_logic_vector(1 downto 0) := (others => '0');
 signal sig_axi2rdc_rlast            : std_logic := '0';

 signal sig_wdc2wrskid_addr_lsb      : std_logic_vector(SEL_ADDR_WIDTH-1 downto 0) := (others => '0');
 signal sig_wrskid2wdc_wready        : std_logic := '0';
 signal sig_wdc2wrskid_wvalid        : std_logic := '0';
 signal sig_wdc2wrskid_wdata         : std_logic_vector(RDWR_SDATA_WIDTH-1 downto 0) := (others => '0');
 signal sig_wdc2wrskid_wstrb         : std_logic_vector((RDWR_SDATA_WIDTH/8)-1 downto 0) := (others => '0');
 signal sig_wdc2wrskid_wlast         : std_logic := '0';

 signal sig_axi2wrskid_wready        : std_logic := '0';
 signal sig_wrskid2axi_wvalid        : std_logic := '0';
 signal sig_wrskid2axi_wdata         : std_logic_vector(RDWR_MDATA_WIDTH-1 downto 0) := (others => '0');
 signal sig_wrskid2axi_wstrb         : std_logic_vector((RDWR_MDATA_WIDTH/8)-1 downto 0) := (others => '0');
 signal sig_wrskid2axi_wlast         : std_logic := '0';

 signal sig_wsc2axi_bready           : std_logic := '0';
 signal sig_axi2wsc_bvalid           : std_logic := '0';
 signal sig_axi2wsc_bresp            : std_logic_vector(1 downto 0) := (others => '0');

 signal sig_rdskid2rdc_tready        : std_logic := '0';
 signal sig_rdc2rdskid_tvalid        : std_logic := '0';
 signal sig_rdc2rdskid_tdata         : std_logic_vector(RDWR_SDATA_WIDTH-1 downto 0) := (others => '0');
 signal sig_rdc2rdskid_tstrb         : std_logic_vector((RDWR_SDATA_WIDTH/8)-1 downto 0) := (others => '0');
 signal sig_rdc2rdskid_tlast         : std_logic := '0';

 signal sig_strm2rdskid_tready       : std_logic := '0';
 signal sig_rdskid2strm_tvalid       : std_logic := '0';
 signal sig_rdskid2strm_tdata        : std_logic_vector(RDWR_SDATA_WIDTH-1 downto 0) := (others => '0');
 signal sig_rdskid2strm_tstrb        : std_logic_vector((RDWR_SDATA_WIDTH/8)-1 downto 0) := (others => '0');
 signal sig_rdskid2strm_tlast        : std_logic := '0';

 signal sig_wrskid2strm_tready       : std_logic := '0';
 signal sig_strm2wrskid_tvalid       : std_logic := '0';
 signal sig_strm2wrskid_tdata        : std_logic_vector(RDWR_SDATA_WIDTH-1 downto 0) := (others => '0');
 signal sig_strm2wrskid_tstrb        : std_logic_vector((RDWR_SDATA_WIDTH/8)-1 downto 0) := (others => '0');
 signal sig_strm2wrskid_tlast        : std_logic := '0';

 signal sig_wdc2wrskid_tready        : std_logic := '0';
 signal sig_wrskid2wdc_tvalid        : std_logic := '0';
 signal sig_wrskid2wdc_tdata         : std_logic_vector(RDWR_SDATA_WIDTH-1 downto 0) := (others => '0');
 signal sig_wrskid2wdc_tstrb         : std_logic_vector((RDWR_SDATA_WIDTH/8)-1 downto 0) := (others => '0');
 signal sig_wrskid2wdc_tlast         : std_logic := '0';

 signal sig_cmd2pcc_command          : std_logic_vector(RDWR_CMD_WIDTH-1 downto 0) := (others => '0');
 signal sig_cmd2pcc_cmd_valid        : std_logic := '0';
 signal sig_pcc2cmd_cmd_ready        : std_logic := '0';

 signal sig_pcc2addr_tag             : std_logic_vector(RDWR_TAG_WIDTH-1 downto 0) := (others => '0');
 signal sig_pcc2addr_addr            : std_logic_vector(RDWR_ADDR_WIDTH-1 downto 0) := (others => '0');
 signal sig_pcc2addr_len             : std_logic_vector(7 downto 0) := (others => '0');
 signal sig_pcc2addr_size            : std_logic_vector(2 downto 0) := (others => '0');
 signal sig_pcc2addr_burst           : std_logic_vector(1 downto 0) := (others => '0');
 signal sig_pcc2addr_cmd_cmplt       : std_logic := '0';
 signal sig_pcc2addr_calc_error      : std_logic := '0';
 signal sig_pcc2addr_cmd_valid       : std_logic := '0';
 signal sig_addr2pcc_cmd_ready       : std_logic := '0';

 signal sig_pcc2data_tag             : std_logic_vector(RDWR_TAG_WIDTH-1 downto 0) := (others => '0');
 signal sig_pcc2data_saddr_lsb       : std_logic_vector(SEL_ADDR_WIDTH-1 downto 0) := (others => '0');
 signal sig_pcc2data_len             : std_logic_vector(7 downto 0) := (others => '0');
 signal sig_pcc2data_strt_strb       : std_logic_vector((RDWR_SDATA_WIDTH/8)-1 downto 0) := (others => '0');
 signal sig_pcc2data_last_strb       : std_logic_vector((RDWR_SDATA_WIDTH/8)-1 downto 0) := (others => '0');
 signal sig_pcc2data_drr             : std_logic := '0';
 signal sig_pcc2data_eof             : std_logic := '0';
 signal sig_pcc2data_sequential      : std_logic := '0';
 signal sig_pcc2data_calc_error      : std_logic := '0';
 signal sig_pcc2data_cmd_cmplt       : std_logic := '0';
 signal sig_pcc2data_dre_src_align   : std_logic_vector(DRE_ALIGN_WIDTH-1 downto 0) := (others => '0');
 signal sig_pcc2data_dre_dest_align  : std_logic_vector(DRE_ALIGN_WIDTH-1 downto 0) := (others => '0');

 signal sig_pcc2all_calc_err         : std_logic := '0';

 signal sig_pcc2data_cmd_valid       : std_logic := '0';
 signal sig_pcc2rdc_cmd_valid        : std_logic := '0';
 signal sig_pcc2wdc_cmd_valid        : std_logic := '0';

 signal sig_data2pcc_cmd_ready       : std_logic := '0';
 signal sig_rdc2pcc_cmd_ready        : std_logic := '0';
 signal sig_wdc2pcc_cmd_ready        : std_logic := '0';

 signal sig_addr2data_addr_posted    : std_logic := '0';
 signal sig_addr2wdc_addr_posted     : std_logic := '0';
 signal sig_addr2rdc_addr_posted     : std_logic := '0';

 signal sig_rdc2skid_halt            : std_logic := '0';
 signal sig_wdc2skid_halt            : std_logic := '0';

 signal sig_rd_xfer_cmplt            : std_logic := '0';
 signal sig_wr_xfer_cmplt            : std_logic := '0';

 signal sig_data2addr_stop_req       : std_logic := '0';
 signal sig_rdc2addr_stop_req        : std_logic := '0';
 signal sig_wdc2addr_stop_req        : std_logic := '0';
 signal sig_wsc2wdc_halt_pipe        : std_logic := '0';

 signal sig_addr2stat_calc_error     : std_logic := '0';
 signal sig_addr2rsc_calc_error      : std_logic := '0';
 signal sig_addr2wsc_calc_error      : std_logic := '0';

 signal sig_addr2stat_cmd_fifo_empty : std_logic := '0';
 signal sig_addr2rsc_cmd_fifo_empty  : std_logic := '0';
 signal sig_addr2wsc_cmd_fifo_empty  : std_logic := '0';

 signal sig_rdc2rsc_tag              : std_logic_vector(RDWR_TAG_WIDTH-1 downto 0) := (others => '0');
 signal sig_rdc2rsc_calc_err         : std_logic := '0';
 signal sig_rdc2rsc_okay             : std_logic := '0';
 signal sig_rdc2rsc_decerr           : std_logic := '0';
 signal sig_rdc2rsc_slverr           : std_logic := '0';
 signal sig_rdc2rsc_cmd_cmplt        : std_logic := '0';
 signal sig_rsc2rdc_ready            : std_logic := '0';
 signal sig_rdc2rsc_valid            : std_logic := '0';

 signal sig_rsc2rdc_halt_pipe        : std_logic := '0';

 signal sig_allow_addr_req           : std_logic := '0';
 signal sig_addr_req_posted          : std_logic := '0';

 signal sig_stat2rsc_status_ready    : std_logic := '0';
 signal sig_rsc2stat_status_valid    : std_logic := '0';
 signal sig_rsc2stat_status          : std_logic_vector(RDWR_STS_WIDTH-1 downto 0) := (others => '0');

 signal sig_stat2wsc_status_ready    : std_logic := '0';
 signal sig_wsc2stat_status_valid    : std_logic := '0';
 signal sig_wsc2stat_status          : std_logic_vector(RDWR_STS_WIDTH-1 downto 0) := (others => '0');

 signal sig_wdc_stbs_asserted        : std_logic_vector(7 downto 0) := (others => '0');

 signal sig_wdc2wsc_tag              : std_logic_vector(RDWR_TAG_WIDTH-1 downto 0) := (others => '0');
 signal sig_wdc2wsc_calc_err         : std_logic := '0';
 signal sig_wdc2wsc_last_err         : std_logic := '0';
 signal sig_wdc2wsc_cmd_cmplt        : std_logic := '0';
 signal sig_wsc2wdc_ready            : std_logic := '0';
 signal sig_wdc2wsc_valid            : std_logic := '0';
 signal sig_wdc2wsc_eop              : std_logic := '0';
 signal sig_wdc2wsc_bytes_rcvd       : std_logic_vector(WSC_BYTES_RCVD_WIDTH-1 downto 0) := (others => '0');

 signal sig_enable_rd_llink          : std_logic := '0';
 signal sig_enable_wr_llink          : std_logic := '0';

 signal sig_doing_read_reg           : std_logic := '0';
 signal sig_doing_write_reg          : std_logic := '0';
 
 signal sig_rst2all_stop_request     : std_logic := '0';
 signal sig_realign2wdc_eop_error    : std_logic := '0';


begin --(architecture implementation)




  ---------------------------------------------------------------
  -- Command Type Discrete Assignements
  ---------------------------------------------------------------
  sig_doing_read  <= cmd2rdwr_doing_read;
  sig_doing_write <= cmd2rdwr_doing_write;




  ---------------------------------------------------------------
  -- Read Address Pipelining Assignements
  ---------------------------------------------------------------
  rd_addr_req_posted <= sig_addr_req_posted
    When  (sig_doing_read = '1')
    Else '0';


  rd_xfer_cmplt  <= sig_rd_xfer_cmplt ;




  ---------------------------------------------------------------
  -- Write Address Pipelining Assignements
  ---------------------------------------------------------------
  wr_addr_req_posted <= sig_addr_req_posted
    When  (sig_doing_write = '1')
    Else '0';


  wr_xfer_cmplt <=  sig_wr_xfer_cmplt;




  ---------------------------------------------------------------
  -- AXI Read Addess Channel AREADY Port Assignments
  -- This is a composite of the Read and Write Address ready 
  -- inputs.
  ---------------------------------------------------------------
  sig_axi2addr_aready <= rd_arready
    when (sig_doing_read = '1')
    Else  wr_awready
    when (sig_doing_write = '1')
    else '0' ;


  ---------------------------------------------------------------
  -- AXI Read Addess Channel Port Assignments
  ---------------------------------------------------------------
  rd_arvalid          <= sig_addr2axi_arvalid;

  rd_arid             <= sig_addr2axi_aid    ;
  rd_araddr           <= sig_addr2axi_aaddr  ;
  rd_arlen            <= sig_addr2axi_alen   ;
  rd_arsize           <= sig_addr2axi_asize  ;
  rd_arburst          <= sig_addr2axi_aburst ;
  rd_arprot           <= sig_addr2axi_aprot  ;
  rd_arcache          <= "0011"              ;  -- Per Interface-X guidelines for Masters ;




  ---------------------------------------------------------------
  -- AXI Read Data Channel Port Assignments
  ---------------------------------------------------------------
  rd_rready           <= sig_rdc2axi_rready  ;
  sig_axi2rdc_rvalid  <= rd_rvalid           ;
  sig_axi2rdc_rdata   <= rd_rdata            ;
  sig_axi2rdc_rresp   <= rd_rresp            ;
  sig_axi2rdc_rlast   <= rd_rlast            ;





  ---------------------------------------------------------------
  -- AXI Write Addess Channel Port Assignments
  ---------------------------------------------------------------
  wr_awvalid          <= sig_addr2axi_awvalid;

  wr_awid             <= sig_addr2axi_aid    ;
  wr_awaddr           <= sig_addr2axi_aaddr  ;
  wr_awlen            <= sig_addr2axi_alen   ;
  wr_awsize           <= sig_addr2axi_asize  ;
  wr_awburst          <= sig_addr2axi_aburst ;
  wr_awprot           <= sig_addr2axi_aprot  ;
  wr_awcache          <= "0011"              ;  -- Per Interface-X guidelines for Masters ;



  -------------------------------------------------------------------------
  -- AXI Write Data Channel Port Assignments
  -------------------------------------------------------------------------
  sig_axi2wrskid_wready  <=  wr_wready           ;
  wr_wvalid              <=  sig_wrskid2axi_wvalid  ;
  wr_wdata               <=  sig_wrskid2axi_wdata   ;
  wr_wstrb               <=  sig_wrskid2axi_wstrb   ;
  wr_wlast               <=  sig_wrskid2axi_wlast   ;


  -------------------------------------------------------------------------
  -- AXI Write Response Channel Port Assignments
  -------------------------------------------------------------------------
  wr_bready            <=  sig_wsc2axi_bready  ;
  sig_axi2wsc_bvalid   <=  wr_bvalid           ;
  sig_axi2wsc_bresp    <=  wr_bresp            ;







  -------------------------------------------------------------------------
  -- AXI Read Master Stream Channel Port Assignments
  -------------------------------------------------------------------------
  sig_strm2rdskid_tready   <= rd_strm_tready         ;
  rd_strm_tvalid           <= sig_rdskid2strm_tvalid ;
  rd_strm_tdata            <= sig_rdskid2strm_tdata  ;
  rd_strm_tstrb            <= sig_rdskid2strm_tstrb  ;
  rd_strm_tlast            <= sig_rdskid2strm_tlast  ;



  -------------------------------------------------------------------------
  -- AXI Write Stream Channel Port Assignments
  -------------------------------------------------------------------------
  wr_strm_tready           <= sig_wrskid2strm_tready ;
  sig_strm2wrskid_tvalid   <= wr_strm_tvalid         ;
  sig_strm2wrskid_tdata    <= wr_strm_tdata          ;
  sig_strm2wrskid_tstrb    <= wr_strm_tstrb          ;
  sig_strm2wrskid_tlast    <= wr_strm_tlast          ;




  -------------------------------------------------------------------------
  -- Read Status I/O Port Assignments
  -------------------------------------------------------------------------
  sig_stat2rsc_status_ready  <=  stat2rsc_status_ready     ;
  rsc2stat_status_valid      <=  sig_rsc2stat_status_valid ;
  rsc2stat_status            <=  sig_rsc2stat_status       ;


  -------------------------------------------------------------------------
  -- Write Status I/O Port Assignments
  -------------------------------------------------------------------------
  sig_stat2wsc_status_ready  <=  stat2wsc_status_ready     ;
  wsc2stat_status_valid      <=  sig_wsc2stat_status_valid ;
  wsc2stat_status            <=  sig_wsc2stat_status       ;




  -------------------------------------------------------------------------
  -- Internal error output discrete
  -------------------------------------------------------------------------
  rdwr_md_error      <=  sig_md_error_reg;




  -------------------------------------------------------------------------
  -- Assign the PCC Command Interface Ports
  -------------------------------------------------------------------------
  sig_cmd2pcc_command     <=  cmd2rdwr_cmd_data        ;
  sig_cmd2pcc_cmd_valid   <=  cmd2rdwr_cmd_valid       ;
  rdwr2cmd_cmd_ready      <=  sig_pcc2cmd_cmd_ready    ;








 -------------------------------------------------------------------------
 -- Misc. Logic
 -------------------------------------------------------------------------

 sig_rst2all_stop_request  <= '0';

 
 
 
 
 
 
 
 -------------------------------------------------------------------------
 -- LocalLink Enables Logic
 -------------------------------------------------------------------------

 rd_llink_enable <=  sig_enable_rd_llink;
 
 wr_llink_enable <=  sig_enable_wr_llink;
 
 
 -- create a 1 clock pulse for enabling the Read LocalLink on
 -- the rising edge of the sig_doing_read signal.
 sig_enable_rd_llink <= not(sig_doing_read_reg) and
                        sig_doing_read ;

 -- create a 1 clock pulse for enabling the write LocalLink on
 -- the rising edge of the sig_doing_write signal.
 sig_enable_wr_llink <= not(sig_doing_write_reg) and
                        sig_doing_write ;


 -------------------------------------------------------------
 -- Synchronous Process with Sync Reset
 --
 -- Label: IMP_DOING_RD_FLOP
 --
 -- Process Description:
 --   Registers the Doing Read input signal
 --
 -------------------------------------------------------------
 IMP_DOING_RD_FLOP : process (rdwr_aclk)
   begin
     if (rdwr_aclk'event and rdwr_aclk = '1') then
        if (rdwr_areset = '1') then
 
          sig_doing_read_reg <= '0';
 
        else
 
          sig_doing_read_reg <= sig_doing_read;
 
        end if; 
     end if;       
   end process IMP_DOING_RD_FLOP; 
  
  
  
  
 -------------------------------------------------------------
 -- Synchronous Process with Sync Reset
 --
 -- Label: IMP_DOING_WR_FLOP
 --
 -- Process Description:
 --   Registers the Doing Write input signal
 --
 -------------------------------------------------------------
 IMP_DOING_WR_FLOP : process (rdwr_aclk)
   begin
     if (rdwr_aclk'event and rdwr_aclk = '1') then
        if (rdwr_areset = '1') then
 
          sig_doing_write_reg <= '0';
 
        else
 
          sig_doing_write_reg <= sig_doing_write;
 
        end if; 
     end if;       
   end process IMP_DOING_WR_FLOP; 
  
  
  
  
  
  

 -------------------------------------------------------------------------
 -- Predictive Command Calculator Logic
 -------------------------------------------------------------------------

 sig_data2pcc_cmd_ready <= sig_rdc2pcc_cmd_ready
   When (sig_doing_read = '1')
   Else sig_wdc2pcc_cmd_ready
   When (sig_doing_write = '1')
   Else '0';

 sig_pcc2rdc_cmd_valid <= sig_pcc2data_cmd_valid
   when (sig_doing_read = '1')
   Else '0';


 sig_pcc2wdc_cmd_valid <= sig_pcc2data_cmd_valid
   when (sig_doing_write = '1')
   Else '0';


 ------------------------------------------------------------
 -- Instance: I_MSTR_PCC
 --
 -- Description:
 -- Predictive Command Calculator Block
 --
 ------------------------------------------------------------
  I_MSTR_PCC : entity axi_master_burst_v1_00_a.axi_master_burst_pcc
  generic map (

    C_DRE_ALIGN_WIDTH         =>  DRE_ALIGN_WIDTH             ,
    C_SEL_ADDR_WIDTH          =>  SEL_ADDR_WIDTH              ,
    C_ADDR_WIDTH              =>  RDWR_ADDR_WIDTH             ,
    C_STREAM_DWIDTH           =>  RDWR_SDATA_WIDTH            ,
    C_MAX_BURST_LEN           =>  RDWR_MAX_BURST_LEN          ,
    C_CMD_WIDTH               =>  RDWR_CMD_WIDTH              ,
    C_TAG_WIDTH               =>  RDWR_TAG_WIDTH              ,
    C_BTT_USED                =>  RDWR_CORRECTED_BTT_USED     ,
    C_SUPPORT_INDET_BTT       =>  OMIT_INDET_BTT

    )
  port map (

    -- Clock input
    primary_aclk              =>  rdwr_aclk                   ,
    mmap_reset                =>  rdwr_areset                 ,
    cmd2mstr_command          =>  sig_cmd2pcc_command         ,
    cmd2mstr_cmd_valid        =>  sig_cmd2pcc_cmd_valid       ,
    mst2cmd_cmd_ready         =>  sig_pcc2cmd_cmd_ready       ,

    mstr2addr_tag             =>  sig_pcc2addr_tag            ,
    mstr2addr_addr            =>  sig_pcc2addr_addr           ,
    mstr2addr_len             =>  sig_pcc2addr_len            ,
    mstr2addr_size            =>  sig_pcc2addr_size           ,
    mstr2addr_burst           =>  sig_pcc2addr_burst          ,
    mstr2addr_cmd_cmplt       =>  sig_pcc2addr_cmd_cmplt      ,
    mstr2addr_calc_error      =>  sig_pcc2addr_calc_error     ,
    mstr2addr_cmd_valid       =>  sig_pcc2addr_cmd_valid      ,
    addr2mstr_cmd_ready       =>  sig_addr2pcc_cmd_ready      ,

    mstr2data_tag             =>  sig_pcc2data_tag            ,
    mstr2data_saddr_lsb       =>  sig_pcc2data_saddr_lsb      ,
    mstr2data_len             =>  sig_pcc2data_len            ,
    mstr2data_strt_strb       =>  sig_pcc2data_strt_strb      ,
    mstr2data_last_strb       =>  sig_pcc2data_last_strb      ,
    mstr2data_drr             =>  sig_pcc2data_drr            ,
    mstr2data_eof             =>  sig_pcc2data_eof            ,
    mstr2data_sequential      =>  sig_pcc2data_sequential     ,
    mstr2data_calc_error      =>  sig_pcc2data_calc_error     ,
    mstr2data_cmd_cmplt       =>  sig_pcc2data_cmd_cmplt      ,
    mstr2data_cmd_valid       =>  sig_pcc2data_cmd_valid      ,
    data2mstr_cmd_ready       =>  sig_data2pcc_cmd_ready      ,
    mstr2data_dre_src_align   =>  sig_pcc2data_dre_src_align  ,
    mstr2data_dre_dest_align  =>  sig_pcc2data_dre_dest_align ,

    calc_error                =>  sig_pcc2all_calc_err        ,

    dre2mstr_cmd_ready        =>  LOGIC_HIGH                  ,
    mstr2dre_cmd_valid        =>  open                        ,
    mstr2dre_tag              =>  open                        ,
    mstr2dre_dre_src_align    =>  open                        ,
    mstr2dre_dre_dest_align   =>  open                        ,
    mstr2dre_btt              =>  open                        ,
    mstr2dre_drr              =>  open                        ,
    mstr2dre_eof              =>  open                        ,
    mstr2dre_cmd_cmplt        =>  open                        ,
    mstr2dre_calc_error       =>  open


    );





  -------------------------------------------------------------------------
  -- Address Controller Logic
  -------------------------------------------------------------------------

   sig_allow_addr_req <= rd_allow_addr_req
     when (sig_doing_read = '1')
     Else wr_allow_addr_req
     When (sig_doing_write = '1')
    Else '0';




  sig_addr2rdc_addr_posted <= sig_addr2data_addr_posted
    When (sig_doing_read = '1')
    Else '0';

  sig_addr2wdc_addr_posted <= sig_addr2data_addr_posted
    When (sig_doing_write = '1')
    Else '0';



  sig_data2addr_stop_req  <=  sig_rdc2addr_stop_req  or
                              sig_wdc2addr_stop_req ;



  sig_addr2rsc_calc_error <= sig_addr2stat_calc_error
    when (sig_doing_read = '1')
    Else '0';


  sig_addr2wsc_calc_error  <=   sig_addr2stat_calc_error
    when (sig_doing_write = '1')
    Else '0';


  sig_addr2rsc_cmd_fifo_empty <= sig_addr2stat_cmd_fifo_empty
    when (sig_doing_read = '1')
    Else '0';


  sig_addr2wsc_cmd_fifo_empty <= sig_addr2stat_cmd_fifo_empty
    when (sig_doing_write = '1')
    Else '0';



  ------------------------------------------------------------
  -- Instance: I_ADDR_CNTL
  --
  -- Description:
  --   Address Controller Block
  --
  ------------------------------------------------------------
   I_ADDR_CNTL : entity axi_master_burst_v1_00_a.axi_master_burst_addr_cntl
   generic map (

     C_ADDR_FIFO_DEPTH            =>  ADDR_CNTL_FIFO_DEPTH        ,
     C_ADDR_WIDTH                 =>  RDWR_ADDR_WIDTH             ,
     C_ADDR_ID                    =>  RDWR_ARID_VALUE             ,
     C_ADDR_ID_WIDTH              =>  RDWR_ARID_WIDTH             ,
     C_TAG_WIDTH                  =>  RDWR_TAG_WIDTH

     )
   port map (

     primary_aclk                 =>  rdwr_aclk                   ,
     mmap_reset                   =>  rdwr_areset                 ,

     doing_read                   =>  sig_doing_read              ,
     doing_write                  =>  sig_doing_write             ,

     addr2axi_aid                 =>  sig_addr2axi_aid            ,
     addr2axi_aaddr               =>  sig_addr2axi_aaddr          ,
     addr2axi_alen                =>  sig_addr2axi_alen           ,
     addr2axi_asize               =>  sig_addr2axi_asize          ,
     addr2axi_aburst              =>  sig_addr2axi_aburst         ,
     addr2axi_aprot               =>  sig_addr2axi_aprot          ,
     addr2axi_arvalid             =>  sig_addr2axi_arvalid        ,
     addr2axi_awvalid             =>  sig_addr2axi_awvalid        ,
     axi2addr_aready              =>  sig_axi2addr_aready         ,

     mstr2addr_tag                =>  sig_pcc2addr_tag            ,
     mstr2addr_addr               =>  sig_pcc2addr_addr           ,
     mstr2addr_len                =>  sig_pcc2addr_len            ,
     mstr2addr_size               =>  sig_pcc2addr_size           ,
     mstr2addr_burst              =>  sig_pcc2addr_burst          ,
     mstr2addr_cmd_cmplt          =>  sig_pcc2addr_cmd_cmplt      ,
     mstr2addr_calc_error         =>  sig_pcc2addr_calc_error     ,
     mstr2addr_cmd_valid          =>  sig_pcc2addr_cmd_valid      ,
     addr2mstr_cmd_ready          =>  sig_addr2pcc_cmd_ready      ,

     addr2rst_stop_cmplt          =>  open                        ,

     allow_addr_req               =>  sig_allow_addr_req          ,
     addr_req_posted              =>  sig_addr_req_posted         ,

     addr2data_addr_posted        =>  sig_addr2data_addr_posted   ,
     data2addr_data_rdy           =>  LOGIC_LOW                   ,
     data2addr_stop_req           =>  sig_data2addr_stop_req      ,

     addr2stat_calc_error         =>  sig_addr2stat_calc_error    ,
     addr2stat_cmd_fifo_empty     =>  sig_addr2stat_cmd_fifo_empty
     );












  -------------------------------------------------------------------------
  -- Read Data Controller Logic
  -------------------------------------------------------------------------





  ------------------------------------------------------------
  -- Instance: I_RD_DATA_CNTL
  --
  -- Description:
  --     Read Data Controller Block
  --
  ------------------------------------------------------------
   I_RD_DATA_CNTL : entity axi_master_burst_v1_00_a.axi_master_burst_rddata_cntl
   generic map (

     C_INCLUDE_DRE             =>  OMIT_DRE                     ,
     C_ALIGN_WIDTH             =>  DRE_ALIGN_WIDTH              ,
     C_SEL_ADDR_WIDTH          =>  SEL_ADDR_WIDTH               ,
     C_DATA_CNTL_FIFO_DEPTH    =>  RD_DATA_CNTL_FIFO_DEPTH      ,
     C_MMAP_DWIDTH             =>  RDWR_MDATA_WIDTH             ,
     C_STREAM_DWIDTH           =>  RDWR_SDATA_WIDTH             ,
     C_TAG_WIDTH               =>  RDWR_TAG_WIDTH               ,
     C_FAMILY                  =>  C_FAMILY

     )
   port map (

     -- Clock and Reset  -----------------------------------
     primary_aclk              =>  rdwr_aclk                    ,
     mmap_reset                =>  rdwr_areset                  ,

     -- Soft Shutdown Interface -----------------------------
     rst2data_stop_request     =>  sig_rst2all_stop_request     ,
     data2addr_stop_req        =>  sig_rdc2addr_stop_req        ,
     data2rst_stop_cmplt       =>  open                         ,

     -- External Address Pipelining Contol support
     mm2s_rd_xfer_cmplt        =>  sig_rd_xfer_cmplt            ,


     -- AXI Read Data Channel I/O  -------------------------------
     mm2s_rdata                =>  sig_axi2rdc_rdata            ,
     mm2s_rresp                =>  sig_axi2rdc_rresp            ,
     mm2s_rlast                =>  sig_axi2rdc_rlast            ,
     mm2s_rvalid               =>  sig_axi2rdc_rvalid           ,
     mm2s_rready               =>  sig_rdc2axi_rready           ,

     -- MM2S DRE Control  -----------------------------------
     mm2s_dre_new_align        =>  open                         ,
     mm2s_dre_use_autodest     =>  open                         ,
     mm2s_dre_src_align        =>  open                         ,
     mm2s_dre_dest_align       =>  open                         ,
     mm2s_dre_flush            =>  open                         ,

     -- AXI Master Stream  -----------------------------------
     mm2s_strm_wvalid          =>  sig_rdc2rdskid_tvalid        ,
     mm2s_strm_wready          =>  sig_rdskid2rdc_tready        ,
     mm2s_strm_wdata           =>  sig_rdc2rdskid_tdata         ,
     mm2s_strm_wstrb           =>  sig_rdc2rdskid_tstrb         ,
     mm2s_strm_wlast           =>  sig_rdc2rdskid_tlast         ,

     -- Command Calculator Interface --------------------------
     mstr2data_tag             =>  sig_pcc2data_tag            ,
     mstr2data_saddr_lsb       =>  sig_pcc2data_saddr_lsb      ,
     mstr2data_len             =>  sig_pcc2data_len            ,
     mstr2data_strt_strb       =>  sig_pcc2data_strt_strb      ,
     mstr2data_last_strb       =>  sig_pcc2data_last_strb      ,
     mstr2data_drr             =>  sig_pcc2data_drr            ,
     mstr2data_eof             =>  sig_pcc2data_eof            ,
     mstr2data_sequential      =>  sig_pcc2data_sequential     ,
     mstr2data_calc_error      =>  sig_pcc2data_calc_error     ,
     mstr2data_cmd_cmplt       =>  sig_pcc2data_cmd_cmplt      ,
     mstr2data_cmd_valid       =>  sig_pcc2rdc_cmd_valid       ,
     data2mstr_cmd_ready       =>  sig_rdc2pcc_cmd_ready       ,
     mstr2data_dre_src_align   =>  sig_pcc2data_dre_src_align  ,
     mstr2data_dre_dest_align  =>  sig_pcc2data_dre_dest_align ,


     -- Address Controller Interface --------------------------
     addr2data_addr_posted     =>  sig_addr2rdc_addr_posted    ,

     -- Data Controller Halted Status
     data2all_dcntlr_halted    =>  open                        ,

     -- Output Stream Skid Buffer Halt control
     data2skid_halt            =>  sig_rdc2skid_halt           ,


     -- Read Status Controller Interface --------------------------
     data2rsc_tag              =>  sig_rdc2rsc_tag             ,
     data2rsc_calc_err         =>  sig_rdc2rsc_calc_err        ,
     data2rsc_okay             =>  sig_rdc2rsc_okay            ,
     data2rsc_decerr           =>  sig_rdc2rsc_decerr          ,
     data2rsc_slverr           =>  sig_rdc2rsc_slverr          ,
     data2rsc_cmd_cmplt        =>  sig_rdc2rsc_cmd_cmplt       ,
     rsc2data_ready            =>  sig_rsc2rdc_ready           ,
     data2rsc_valid            =>  sig_rdc2rsc_valid           ,
     rsc2mstr_halt_pipe        =>  sig_rsc2rdc_halt_pipe

     );




  ------------------------------------------------------------
  -- Instance: I_RD_STATUS_CNTLR
  --
  -- Description:
  -- Read Status Controller Block
  --
  ------------------------------------------------------------
   I_RD_STATUS_CNTLR : entity axi_master_burst_v1_00_a.axi_master_burst_rd_status_cntl
   generic map (

     C_STS_WIDTH            =>  RDWR_STS_WIDTH ,
     C_TAG_WIDTH            =>  RDWR_TAG_WIDTH

     )
   port map (

     primary_aclk           =>  rdwr_aclk                   ,
     mmap_reset             =>  rdwr_areset                 ,

     calc2rsc_calc_error    =>  sig_pcc2all_calc_err        ,

     addr2rsc_calc_error    =>  sig_addr2rsc_calc_error     ,
     addr2rsc_fifo_empty    =>  sig_addr2rsc_cmd_fifo_empty ,

     data2rsc_tag           =>  sig_rdc2rsc_tag             ,
     data2rsc_calc_error    =>  sig_rdc2rsc_calc_err        ,
     data2rsc_okay          =>  sig_rdc2rsc_okay            ,
     data2rsc_decerr        =>  sig_rdc2rsc_decerr          ,
     data2rsc_slverr        =>  sig_rdc2rsc_slverr          ,
     data2rsc_cmd_cmplt     =>  sig_rdc2rsc_cmd_cmplt       ,
     rsc2data_ready         =>  sig_rsc2rdc_ready           ,
     data2rsc_valid         =>  sig_rdc2rsc_valid           ,

     rsc2stat_status        =>  sig_rsc2stat_status         ,
     stat2rsc_status_ready  =>  sig_stat2rsc_status_ready   ,
     rsc2stat_status_valid  =>  sig_rsc2stat_status_valid   ,

     rsc2mstr_halt_pipe     =>  sig_rsc2rdc_halt_pipe

     );









   ------------------------------------------------------------
   -- Instance: I_READ_STREAM_SKID_BUF
   --
   -- Description:
   --   Instance for the Read side Skid Buffer which provides
   -- for registerd Master Stream outputs and supports bi-dir
   -- throttling.
   --
   ------------------------------------------------------------
    I_READ_STREAM_SKID_BUF : entity axi_master_burst_v1_00_a.axi_master_burst_skid_buf
    generic map (

      C_WDATA_WIDTH  =>  RDWR_SDATA_WIDTH

      )
    port map (

      -- System Ports
      aclk           =>  rdwr_aclk             ,
      arst           =>  rdwr_areset           ,

      -- Shutdown control (assert for 1 clk pulse)
      skid_stop      =>  sig_rdc2skid_halt     ,

      -- Slave Side (Stream Data Input)
      s_valid        =>  sig_rdc2rdskid_tvalid  ,
      s_ready        =>  sig_rdskid2rdc_tready  ,
      s_data         =>  sig_rdc2rdskid_tdata   ,
      s_strb         =>  sig_rdc2rdskid_tstrb   ,
      s_last         =>  sig_rdc2rdskid_tlast   ,

      -- Master Side (Stream Data Output
      m_valid        =>  sig_rdskid2strm_tvalid  ,
      m_ready        =>  sig_strm2rdskid_tready  ,
      m_data         =>  sig_rdskid2strm_tdata   ,
      m_strb         =>  sig_rdskid2strm_tstrb   ,
      m_last         =>  sig_rdskid2strm_tlast

      );









  -------------------------------------------------------------------------
  -- Write Data Controller Logic
  -------------------------------------------------------------------------

  sig_wdc_stbs_asserted     <= (others => '0');
  sig_realign2wdc_eop_error <= '0';


  ------------------------------------------------------------
  -- Instance: I_WR_DATA_CNTL
  --
  -- Description:
  --     Write Data Controller Block
  --
  ------------------------------------------------------------
   I_WR_DATA_CNTL : entity axi_master_burst_v1_00_a.axi_master_burst_wrdata_cntl
   generic map (

     C_REALIGNER_INCLUDED   =>  OMIT_DRE                  ,
     C_ENABLE_STORE_FORWARD =>  OMIT_STORE_FORWARD        ,
     C_SF_BYTES_RCVD_WIDTH  =>  WSC_BYTES_RCVD_WIDTH      ,
     C_SEL_ADDR_WIDTH       =>  SEL_ADDR_WIDTH            ,
     C_DATA_CNTL_FIFO_DEPTH =>  WR_DATA_CNTL_FIFO_DEPTH   ,
     C_MMAP_DWIDTH          =>  RDWR_MDATA_WIDTH          ,
     C_STREAM_DWIDTH        =>  RDWR_SDATA_WIDTH          ,
     C_TAG_WIDTH            =>  RDWR_TAG_WIDTH            ,
     C_FAMILY               =>  C_FAMILY

     )
   port map (

     primary_aclk           =>  rdwr_aclk                 ,
     mmap_reset             =>  rdwr_areset               ,

     rst2data_stop_request  =>  sig_rst2all_stop_request  ,
     data2addr_stop_req     =>  sig_wdc2addr_stop_req     ,
     data2rst_stop_cmplt    =>  open                      ,

     wr_xfer_cmplt          =>  sig_wr_xfer_cmplt         ,
     s2mm_ld_nxt_len        =>  open                      ,
     s2mm_wr_len            =>  open                      ,

     data2skid_saddr_lsb    =>  sig_wdc2wrskid_addr_lsb   ,
     data2skid_wdata        =>  sig_wdc2wrskid_wdata      ,
     data2skid_wstrb        =>  sig_wdc2wrskid_wstrb      ,
     data2skid_wlast        =>  sig_wdc2wrskid_wlast      ,
     data2skid_wvalid       =>  sig_wdc2wrskid_wvalid     ,
     skid2data_wready       =>  sig_wrskid2wdc_wready     ,

     s2mm_strm_wvalid       =>  sig_wrskid2wdc_tvalid     ,
     s2mm_strm_wready       =>  sig_wdc2wrskid_tready     ,
     s2mm_strm_wdata        =>  sig_wrskid2wdc_tdata      ,
     s2mm_strm_wstrb        =>  sig_wrskid2wdc_tstrb      ,
     s2mm_strm_wlast        =>  sig_wrskid2wdc_tlast      ,

     s2mm_strm_eop          =>  sig_wrskid2wdc_tlast      ,
     s2mm_stbs_asserted     =>  sig_wdc_stbs_asserted     ,

     realign2wdc_eop_error  =>  sig_realign2wdc_eop_error ,

     mstr2data_tag          =>  sig_pcc2data_tag          ,
     mstr2data_saddr_lsb    =>  sig_pcc2data_saddr_lsb    ,
     mstr2data_len          =>  sig_pcc2data_len          ,
     mstr2data_strt_strb    =>  sig_pcc2data_strt_strb    ,
     mstr2data_last_strb    =>  sig_pcc2data_last_strb    ,
     mstr2data_drr          =>  sig_pcc2data_drr          ,
     mstr2data_eof          =>  sig_pcc2data_eof          ,
     mstr2data_sequential   =>  sig_pcc2data_sequential   ,
     mstr2data_calc_error   =>  sig_pcc2data_calc_error   ,
     mstr2data_cmd_cmplt    =>  sig_pcc2data_cmd_cmplt    ,
     mstr2data_cmd_valid    =>  sig_pcc2wdc_cmd_valid     ,
     data2mstr_cmd_ready    =>  sig_wdc2pcc_cmd_ready     ,

     addr2data_addr_posted  =>  sig_addr2wdc_addr_posted  ,
     data2addr_data_rdy     =>  open                      ,

     data2all_tlast_error   =>  open                      ,
     data2all_dcntlr_halted =>  open                      ,
     data2skid_halt         =>  sig_wdc2skid_halt         ,

     data2wsc_tag           =>  sig_wdc2wsc_tag           ,
     data2wsc_calc_err      =>  sig_wdc2wsc_calc_err      ,
     data2wsc_last_err      =>  sig_wdc2wsc_last_err      ,
     data2wsc_cmd_cmplt     =>  sig_wdc2wsc_cmd_cmplt     ,
     wsc2data_ready         =>  sig_wsc2wdc_ready         ,
     data2wsc_valid         =>  sig_wdc2wsc_valid         ,
     data2wsc_eop           =>  sig_wdc2wsc_eop           ,
     data2wsc_bytes_rcvd    =>  sig_wdc2wsc_bytes_rcvd    ,

     wsc2mstr_halt_pipe     =>  sig_wsc2wdc_halt_pipe

     );











  ------------------------------------------------------------
  -- Instance: I_WR_STATUS_CNTLR
  --
  -- Description:
  -- Write Status Controller Block
  --
  ------------------------------------------------------------
   I_WR_STATUS_CNTLR : entity axi_master_burst_v1_00_a.axi_master_burst_wr_status_cntl
   generic map (

     C_ENABLE_STORE_FORWARD =>  OMIT_STORE_FORWARD          ,
     C_SF_BYTES_RCVD_WIDTH  =>  WSC_BYTES_RCVD_WIDTH        ,
     C_STS_FIFO_DEPTH       =>  WR_STATUS_CNTL_FIFO_DEPTH   ,
     C_STS_WIDTH            =>  RDWR_STS_WIDTH              ,
     C_TAG_WIDTH            =>  RDWR_TAG_WIDTH              ,
     C_FAMILY               =>  C_FAMILY

     )
   port map (

     primary_aclk           =>  rdwr_aclk                   ,
     mmap_reset             =>  rdwr_areset                 ,

     rst2wsc_stop_request   =>  sig_rst2all_stop_request    ,
     wsc2rst_stop_cmplt     =>  open                        ,
     addr2wsc_addr_posted   =>  sig_addr2wdc_addr_posted,

     s2mm_bresp             =>  sig_axi2wsc_bresp           ,
     s2mm_bvalid            =>  sig_axi2wsc_bvalid          ,
     s2mm_bready            =>  sig_wsc2axi_bready          ,

     calc2wsc_calc_error    =>  sig_pcc2all_calc_err        ,

     addr2wsc_calc_error    =>  sig_addr2wsc_calc_error     ,
     addr2wsc_fifo_empty    =>  sig_addr2wsc_cmd_fifo_empty ,

     data2wsc_tag           =>  sig_wdc2wsc_tag             ,
     data2wsc_calc_error    =>  sig_wdc2wsc_calc_err        ,
     data2wsc_last_error    =>  sig_wdc2wsc_last_err        ,
     data2wsc_cmd_cmplt     =>  sig_wdc2wsc_cmd_cmplt       ,
     data2wsc_valid         =>  sig_wdc2wsc_valid           ,
     wsc2data_ready         =>  sig_wsc2wdc_ready           ,
     data2wsc_eop           =>  sig_wdc2wsc_eop             ,
     data2wsc_bytes_rcvd    =>  sig_wdc2wsc_bytes_rcvd      ,

     wsc2stat_status        =>  sig_wsc2stat_status         ,
     stat2wsc_status_ready  =>  sig_stat2wsc_status_ready   ,
     wsc2stat_status_valid  =>  sig_wsc2stat_status_valid   ,

     wsc2mstr_halt_pipe     =>  sig_wsc2wdc_halt_pipe

     );









    ------------------------------------------------------------
    -- Instance: I_WRITE_MMAP_SKID_BUF
    --
    -- Description:
    --   Instance for the S2MM Skid Buffer which provides for
    -- registered outputs and supports bi-dir throttling.
    --
    -- This Module also provides Write Data Bus Mirroring and WSTRB
    -- Demuxing to match a narrow Stream to a wider MMap Write
    -- Channel. By doing this in the skid buffer, the resource
    -- utilization of the skid buffer can be minimized by only
    -- having to buffer/mux the Stream data width, not the MMap
    -- Data width.
    --
    ------------------------------------------------------------
     I_WRITE_MMAP_SKID_BUF : entity axi_master_burst_v1_00_a.axi_master_burst_skid2mm_buf
     generic map (

       C_MDATA_WIDTH    =>  RDWR_MDATA_WIDTH       ,
       C_SDATA_WIDTH    =>  RDWR_SDATA_WIDTH       ,
       C_ADDR_LSB_WIDTH =>  SEL_ADDR_WIDTH

       )
     port map (

       -- System Ports
       ACLK             =>   rdwr_aclk             ,
       ARST             =>   rdwr_areset           ,

       -- Slave Side (Wr Data Controller Input Side )
       S_ADDR_LSB       =>   sig_wdc2wrskid_addr_lsb,
       S_VALID          =>   sig_wdc2wrskid_wvalid  ,
       S_READY          =>   sig_wrskid2wdc_wready  ,
       S_Data           =>   sig_wdc2wrskid_wdata   ,
       S_STRB           =>   sig_wdc2wrskid_wstrb   ,
       S_Last           =>   sig_wdc2wrskid_wlast   ,

       -- Master Side (MMap Write Data Output Side)
       M_VALID          =>   sig_wrskid2axi_wvalid  ,
       M_READY          =>   sig_axi2wrskid_wready  ,
       M_Data           =>   sig_wrskid2axi_wdata   ,
       M_STRB           =>   sig_wrskid2axi_wstrb   ,
       M_Last           =>   sig_wrskid2axi_wlast

       );



  ------------------------------------------------------------
  -- Instance: I_WRITE_STRM_SKID_BUF
  --
  -- Description:
  --   Instance for the Write Stream Input Skid Buffer which
  -- provides for registerd Slave Stream inputs and supports
  -- bi-dir throttling.
  --
  ------------------------------------------------------------
  I_WRITE_STRM_SKID_BUF : entity axi_master_burst_v1_00_a.axi_master_burst_skid_buf
  generic map (

    C_WDATA_WIDTH =>  RDWR_SDATA_WIDTH

    )
  port map (

    -- System Ports
    aclk          =>  rdwr_aclk           ,
    arst          =>  rdwr_areset         ,

    -- Shutdown control (assert for 1 clk pulse)
    skid_stop     =>  sig_wdc2skid_halt   ,

    -- Slave Side (Stream Data Input)
    s_valid       =>  sig_strm2wrskid_tvalid ,
    s_ready       =>  sig_wrskid2strm_tready ,
    s_data        =>  sig_strm2wrskid_tdata  ,
    s_strb        =>  sig_strm2wrskid_tstrb  ,
    s_last        =>  sig_strm2wrskid_tlast  ,

    -- Master Side (Stream Data Output)
    m_valid       =>  sig_wrskid2wdc_tvalid  ,
    m_ready       =>  sig_wdc2wrskid_tready  ,
    m_data        =>  sig_wrskid2wdc_tdata   ,
    m_strb        =>  sig_wrskid2wdc_tstrb   ,
    m_last        =>  sig_wrskid2wdc_tlast

    );







end implementation;
