-------------------------------------------------------------------------------
-- axi_master_burst.vhd
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
-- Filename:        axi_master_burst.vhd
--
-- Description:
--
-- AXI Master interface utilizing Xilinx LocalLink interface for User Logic
-- Side (IPIC) data transfer interface
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
--                  |        |--  axi_master_burst_fifo.vhd
--                  |               |-- proc_common_v3_00_a.srl_fifo_f
--                  |--  axi_master_burst_rddata_cntl.vhd
--                  |        |--  axi_master_burst_rdmux.vhd
--                  |        |--  axi_master_burst_fifo.vhd
--                  |               |-- proc_common_v3_00_a.srl_fifo_f
--                  |--  axi_master_burst_wrdata_cntl.vhd
--                  |        |--  axi_master_burst_strb_gen
--                  |        |--  axi_master_burst_fifo.vhd
--                  |               |-- proc_common_v3_00_a.srl_fifo_f
--                  |--  axi_master_burst_rd_status_cntl.vhd
--                  |--  axi_master_burst_wr_status_cntl.vhd
--                  |        |--  axi_master_burst_fifo.vhd
--                  |               |-- proc_common_v3_00_a.srl_fifo_f
--                  |--  axi_master_burst_skid_buf.vhd
--                  |--  axi_master_burst_skid2mm_buf.vhd
--
--
-------------------------------------------------------------------------------
-- Author:          DET
-- Revision:        $Revision: 1.0 $
-- Date:            $$
--
-- History:
--   DET   01/18/2011       Version 1_00_a
--
--     DET     2/10/2011     Initial for EDK 13.1
-- ~~~~~~
--    -- Per CR593346
--     - Connected md_error output to the axi_master_burst_cmd_status rw_error
--       output.
-- ^^^^^^
--
--     DET     2/17/2011     Initial for 13.2
-- ~~~~~~
--    -- Per CR593967
--     - Added the port rdwr2llink_int_err to the Cmd/Status Module.
--       This output is now used to initiate a Locallink discontinue
--       when an internal error is detected.
-- ^^^^^^
--
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x"
--      reset signals:                          "rst", "rst_n"
--      generics:                               "C_*"
--      user defined types:                     "*_TYPE"
--      state machine next state:               "*_ns"
--      state machine current state:            "*_cs"
--      combinatorial signals:                  "*_com"
--      pipelined or register delay signals:    "*_d#"
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce"
--      internal version of output port         "*_i"
--      device pins:                            "*_pin"
--      ports:                                  - Names begin with Uppercase
--      processes:                              "*_PROCESS"
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



library axi_master_burst_v1_00_a;
Use axi_master_burst_v1_00_a.axi_master_burst_reset       ;
Use axi_master_burst_v1_00_a.axi_master_burst_cmd_status  ;
Use axi_master_burst_v1_00_a.axi_master_burst_rd_wr_cntlr ;
Use axi_master_burst_v1_00_a.axi_master_burst_rd_llink    ;
Use axi_master_burst_v1_00_a.axi_master_burst_wr_llink    ;


-------------------------------------------------------------------------------

entity axi_master_burst is
  generic (



    ----------------------------------------------------------------------------
    -- AXI4 Related Parameters
    ----------------------------------------------------------------------------
    C_M_AXI_ADDR_WIDTH         : integer range 32 to 32    := 32;
        -- DataMover Master AXI Memory Map Address Width (bits)

    C_M_AXI_DATA_WIDTH         : integer range 32 to 256   := 32;
        -- DataMover Master AXI Memory Map Data Width (bits)

    C_MAX_BURST_LEN     : Integer range 16 to  256 :=  16;
       -- Specifies the max number of databeats to use for each AXI MMap
       -- transfer by the AXI Master Burst

    C_ADDR_PIPE_DEPTH   : Integer range 1 to  14 :=  1;
       -- Specifies the address pipeline depth for the AXI Master Burst
       -- when submitting transfer requests to the AXI4 Read and Write
       -- Address Channels.



    ----------------------------------------------------------------------------
    -- IPIC Related Parameters
    ----------------------------------------------------------------------------
    C_NATIVE_DATA_WIDTH : INTEGER range 32 to 128 := 32;
        --  Set this equal to desired data bus width needed by IPIC
        --  LocalLink Data Channels.

    C_LENGTH_WIDTH      : INTEGER range 12 to 20 := 12;
        -- Set this to the desired bit width for the ip2bus_mst_length
        -- input port required to specify the maximimum transfer byte
        -- count needed for any one command by the User logic.
        -- 12 bits =    4095 bytes max per command
        -- 13 bits =    8191 bytes max per command
        -- 14 bits =   16383 bytes max per command
        -- 15 bits =   32767 bytes max per command
        -- 16 bits =   65535 bytes max per command
        -- 17 bits =  131071 bytes max per command
        -- 18 bits =  262143 bytes max per command
        -- 19 bits =  524287 bytes max per command
        -- 20 bits = 1048575 bytes max per command


    ----------------------------------------------------------------------------
    -- Target FPGA Family Parameter
    ----------------------------------------------------------------------------
    C_FAMILY                   : string := "virtex6"
        -- Target FPGA Device Family

    );
  port (

    ----------------------------------------------------------------------------
    -- Primary Clock
    ----------------------------------------------------------------------------
    m_axi_aclk                  : in  std_logic                         ;-- AXI4

    ----------------------------------------------------------------------------
    -- Primary Reset Input (active low)
    ----------------------------------------------------------------------------
    m_axi_aresetn               : in  std_logic                         ;-- AXI4



    -----------------------------------------------------------------------
    -- Master Detected Error output
    -----------------------------------------------------------------------
    md_error                    : out  std_logic                        ;-- Error output discrete




    ----------------------------------------------------------------------------
    -- AXI4 Master Read Channel
    ----------------------------------------------------------------------------
    -- MMap Read Address Channel                                          -- AXI4
    m_axi_arready               : in  std_logic                          ;-- AXI4
    m_axi_arvalid               : out std_logic                          ;-- AXI4
    m_axi_araddr                : out std_logic_vector                    -- AXI4
                                      (C_M_AXI_ADDR_WIDTH-1 downto 0)    ;-- AXI4
    m_axi_arlen                 : out std_logic_vector(7 downto 0)       ;-- AXI4
    m_axi_arsize                : out std_logic_vector(2 downto 0)       ;-- AXI4
    m_axi_arburst               : out std_logic_vector(1 downto 0)       ;-- AXI4
    m_axi_arprot                : out std_logic_vector(2 downto 0)       ;-- AXI4
    m_axi_arcache               : out std_logic_vector(3 downto 0)       ;-- AXI4
                                                                          -- AXI4
    -- MMap Read Data Channel                                             -- AXI4
    m_axi_rready                : out std_logic                          ;-- AXI4
    m_axi_rvalid                : in  std_logic                          ;-- AXI4
    m_axi_rdata                 : in  std_logic_vector                    -- AXI4
                                      (C_M_AXI_DATA_WIDTH-1 downto 0)    ;-- AXI4
    m_axi_rresp                 : in  std_logic_vector(1 downto 0)       ;-- AXI4
    m_axi_rlast                 : in  std_logic                          ;-- AXI4



    -----------------------------------------------------------------------------
    -- AXI4 Master Write Channel
    -----------------------------------------------------------------------------
    -- Write Address Channel                                               -- AXI4
    m_axi_awready               : in  std_logic                          ; -- AXI4
    m_axi_awvalid               : out std_logic                          ; -- AXI4
    m_axi_awaddr                : out std_logic_vector                     -- AXI4
                                      (C_M_AXI_ADDR_WIDTH-1 downto 0)    ; -- AXI4
    m_axi_awlen                 : out std_logic_vector(7 downto 0)       ; -- AXI4
    m_axi_awsize                : out std_logic_vector(2 downto 0)       ; -- AXI4
    m_axi_awburst               : out std_logic_vector(1 downto 0)       ; -- AXI4
    m_axi_awprot                : out std_logic_vector(2 downto 0)       ; -- AXI4
    m_axi_awcache               : out std_logic_vector(3 downto 0)       ; -- AXI4
                                                                           -- AXI4
    -- Write Data Channel                                                  -- AXI4
    m_axi_wready                : in  std_logic                          ; -- AXI4
    m_axi_wvalid                : out std_logic                          ; -- AXI4
    m_axi_wdata                 : out std_logic_vector                     -- AXI4
                                      (C_M_AXI_DATA_WIDTH-1 downto 0)    ; -- AXI4
    m_axi_wstrb                 : out std_logic_vector                     -- AXI4
                                      ((C_M_AXI_DATA_WIDTH/8)-1 downto 0); -- AXI4
    m_axi_wlast                 : out std_logic                          ; -- AXI4
                                                                           -- AXI4
    -- Write Response Channel                                              -- AXI4
    m_axi_bready                : out std_logic                          ; -- AXI4
    m_axi_bvalid                : in  std_logic                          ; -- AXI4
    m_axi_bresp                 : in  std_logic_vector(1 downto 0)       ; -- AXI4





    -----------------------------------------------------------------------------------------
    -- IPIC Request/Qualifiers
    -----------------------------------------------------------------------------------------
    ip2bus_mstrd_req           : In  std_logic                                           ;-- IPIC CMD
    ip2bus_mstwr_req           : In  std_logic                                           ;-- IPIC CMD
    ip2bus_mst_addr            : in  std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0)     ;-- IPIC CMD
    ip2bus_mst_length          : in  std_logic_vector(C_LENGTH_WIDTH-1 downto 0)         ;-- IPIC CMD
    ip2bus_mst_be              : in  std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);-- IPIC CMD
    ip2bus_mst_type            : in  std_logic                                           ;-- IPIC CMD
    ip2bus_mst_lock            : In  std_logic                                           ;-- IPIC CMD
    ip2bus_mst_reset           : In  std_logic                                           ;-- IPIC CMD


    -----------------------------------------------------------------------------------------
    -- IPIC Request Status Reply
    -----------------------------------------------------------------------------------------
    bus2ip_mst_cmdack          : Out std_logic                                           ;-- IPIC Stat
    bus2ip_mst_cmplt           : Out std_logic                                           ;-- IPIC Stat
    bus2ip_mst_error           : Out std_logic                                           ;-- IPIC Stat
    bus2ip_mst_rearbitrate     : Out std_logic                                           ;-- IPIC Stat
    bus2ip_mst_cmd_timeout     : out std_logic                                           ;-- IPIC Stat


    -----------------------------------------------------------------------------------------
    -- IPIC Read LocalLink Channel
    -----------------------------------------------------------------------------------------
    bus2ip_mstrd_d             : out std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 )   ;-- IPIC RD LLink
    bus2ip_mstrd_rem           : out std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);-- IPIC RD LLink
    bus2ip_mstrd_sof_n         : Out std_logic                                           ;-- IPIC RD LLink
    bus2ip_mstrd_eof_n         : Out std_logic                                           ;-- IPIC RD LLink
    bus2ip_mstrd_src_rdy_n     : Out std_logic                                           ;-- IPIC RD LLink
    bus2ip_mstrd_src_dsc_n     : Out std_logic                                           ;-- IPIC RD LLink

    ip2bus_mstrd_dst_rdy_n     : In  std_logic                                           ;-- IPIC RD LLink
    ip2bus_mstrd_dst_dsc_n     : In  std_logic                                           ;-- IPIC RD LLink


    -----------------------------------------------------------------------------------------
    -- IPIC Write LocalLink Channel
    -----------------------------------------------------------------------------------------
    ip2bus_mstwr_d             : In  std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0)    ;-- IPIC WR LLink
    ip2bus_mstwr_rem           : In  std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);-- IPIC WR LLink
    ip2bus_mstwr_sof_n         : In  std_logic                                           ;-- IPIC WR LLink
    ip2bus_mstwr_eof_n         : In  std_logic                                           ;-- IPIC WR LLink
    ip2bus_mstwr_src_rdy_n     : In  std_logic                                           ;-- IPIC WR LLink
    ip2bus_mstwr_src_dsc_n     : In  std_logic                                           ;-- IPIC WR LLink

    bus2ip_mstwr_dst_rdy_n     : Out std_logic                                           ;-- IPIC WR LLink
    bus2ip_mstwr_dst_dsc_n     : Out std_logic                                            -- IPIC WR LLink

    );

end entity axi_master_burst;


architecture implementation of axi_master_burst is



  -- Constants

   Constant LOGIC_LOW            : std_logic := '0';
   Constant LOGIC_HIGH           : std_logic := '1';

   Constant LLINK_DWIDTH         : integer := C_NATIVE_DATA_WIDTH;

   Constant LENGTH_WIDTH         : integer := C_LENGTH_WIDTH;
   Constant PCC_CMD_WIDTH        : integer := 68; -- in bits
   Constant STATUS_WIDTH         : integer :=  8; -- in bits

   Constant RDWR_ID_WIDTH        : integer :=  4; -- in bits
   Constant RDWR_ID              : integer :=  0; -- in bits

   Constant RDWR_MAX_BURST_LEN   : integer := C_MAX_BURST_LEN; -- in data beats
   Constant RDWR_BTT_USED        : integer := LENGTH_WIDTH;
   Constant RDWR_ADDR_PIPE_DEPTH : integer := C_ADDR_PIPE_DEPTH;









  -- Signal Declarations

   signal sig_ipic_reset               : std_logic := '0';
   signal sig_rst2cmd_stat_reset       : std_logic := '0';
   signal sig_rst2rdwr_cntlr_reset     : std_logic := '0';
   signal sig_rst2llink_reset          : std_logic := '0';

   signal sig_rw_error                 : std_logic := '0';
   signal sig_rdwr2llink_int_err       : std_logic := '0';



   signal sig_ip2bus_mstrd_req         : std_logic := '0';
   signal sig_ip2bus_mstwr_req         : std_logic := '0';
   signal sig_ip2bus_mst_addr          : std_logic_vector(0 to C_M_AXI_ADDR_WIDTH-1) := (others => '0');
   signal sig_ip2bus_mst_length        : std_logic_vector(0 to LENGTH_WIDTH-1) := (others => '0');
   signal sig_ip2bus_mst_be            : std_logic_vector(0 to (C_NATIVE_DATA_WIDTH/8)-1) := (others => '0');
   signal sig_ip2bus_mst_type          : std_logic := '0';
   signal sig_ip2bus_mst_lock          : std_logic := '0';

   signal sig_bus2ip_mst_cmdack        : std_logic := '0';
   signal sig_bus2ip_mst_cmplt         : std_logic := '0';
   signal sig_bus2ip_mst_error         : std_logic := '0';
   signal sig_bus2ip_mst_rearbitrate   : std_logic := '0';
   signal sig_bus2ip_mst_cmd_timeout   : std_logic := '0';

   signal sig_llink2cmd_rd_busy        : std_logic := '0';
   signal sig_llink2cmd_wr_busy        : std_logic := '0';

   signal sig_pcc2cmd_cmd_ready        : std_logic := '0';
   signal sig_cmd2pcc_cmd_valid        : std_logic := '0';
   signal sig_cmd2pcc_command          : std_logic_vector(PCC_CMD_WIDTH-1 downto 0) := (others => '0');

   signal sig_cmd2all_doing_read       : std_logic := '0';
   signal sig_cmd2all_doing_write      : std_logic := '0';

   signal sig_stat2rsc_status_ready    : std_logic := '0';
   signal sig_rsc2stat_status_valid    : std_logic := '0';
   signal sig_rsc2stat_status          : std_logic_vector(STATUS_WIDTH-1 downto 0) := (others => '0');

   signal sig_stat2wsc_status_ready    : std_logic := '0';
   signal sig_wsc2stat_status_valid    : std_logic := '0';
   signal sig_wsc2stat_status          : std_logic_vector(STATUS_WIDTH-1 downto 0) := (others => '0');

   signal sig_llink2rd_allow_addr_req  : std_logic := '0';
   signal sig_rd2llink_addr_req_posted : std_logic := '0';
   signal sig_rd2llink_xfer_cmplt      : std_logic := '0';

   signal sig_llink2wr_allow_addr_req  : std_logic := '0';
   signal sig_wr2llink_addr_req_posted : std_logic := '0';
   signal sig_wr2llink_xfer_cmplt      : std_logic := '0';

   signal sig_rd2llink_strm_tdata      : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
   signal sig_rd2llink_strm_tstrb      : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
   signal sig_rd2llink_strm_tlast      : std_logic := '0';
   signal sig_rd2llink_strm_tvalid     : std_logic := '0';
   signal sig_llink2rd_strm_tready     : std_logic := '0';

   signal sig_llink2wr_strm_tdata      : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
   signal sig_llink2wr_strm_tstrb      : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
   signal sig_llink2wr_strm_tlast      : std_logic := '0';
   signal sig_llink2wr_strm_tvalid     : std_logic := '0';
   signal sig_llink2wr_strm_tready     : std_logic := '0';

   signal sig_rd_llink_enable          : std_logic := '0';
   signal sig_wr_llink_enable          : std_logic := '0';

   signal sig_md_error                 : std_logic := '0';


    -----------------------------------------------------------------------------------------
    -- IPIC Read LocalLink Channel (Little Endian bit ordering)
    -----------------------------------------------------------------------------------------
    -- signal sig_bus2ip_mstrd_d             : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 )   ;-- IPIC RD LLink
    -- signal sig_bus2ip_mstrd_rem           : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);-- IPIC RD LLink
    -- signal sig_bus2ip_mstrd_sof_n         : std_logic                                           ;-- IPIC RD LLink
    -- signal sig_bus2ip_mstrd_eof_n         : std_logic                                           ;-- IPIC RD LLink
    -- signal sig_bus2ip_mstrd_src_rdy_n     : std_logic                                           ;-- IPIC RD LLink
    -- signal sig_bus2ip_mstrd_src_dsc_n     : std_logic                                           ;-- IPIC RD LLink
    --
    -- signal sig_ip2bus_mstrd_dst_rdy_n     : std_logic                                           ;-- IPIC RD LLink
    -- signal sig_ip2bus_mstrd_dst_dsc_n     : std_logic                                           ;-- IPIC RD LLink

    -----------------------------------------------------------------------------------------
    -- IPIC Read LocalLink Channel (Big Endian bit ordering)
    -----------------------------------------------------------------------------------------
    signal sig_bus2ip_mstrd_d             : std_logic_vector(0 to C_NATIVE_DATA_WIDTH-1)        ;-- IPIC RD LLink
    signal sig_bus2ip_mstrd_rem           : std_logic_vector(0 to (C_NATIVE_DATA_WIDTH/8)-1)    ;-- IPIC RD LLink
    signal sig_bus2ip_mstrd_sof_n         : std_logic                                           ;-- IPIC RD LLink
    signal sig_bus2ip_mstrd_eof_n         : std_logic                                           ;-- IPIC RD LLink
    signal sig_bus2ip_mstrd_src_rdy_n     : std_logic                                           ;-- IPIC RD LLink
    signal sig_bus2ip_mstrd_src_dsc_n     : std_logic                                           ;-- IPIC RD LLink

    signal sig_ip2bus_mstrd_dst_rdy_n     : std_logic                                           ;-- IPIC RD LLink
    signal sig_ip2bus_mstrd_dst_dsc_n     : std_logic                                           ;-- IPIC RD LLink



    -----------------------------------------------------------------------------------------
    -- IPIC Write LocalLink Channel  (Little Endian bit ordering)
    -----------------------------------------------------------------------------------------
    -- signal sig_ip2bus_mstwr_d             : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0)    ;-- IPIC WR LLink
    -- signal sig_ip2bus_mstwr_rem           : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);-- IPIC WR LLink
    -- signal sig_ip2bus_mstwr_sof_n         : std_logic                                           ;-- IPIC WR LLink
    -- signal sig_ip2bus_mstwr_eof_n         : std_logic                                           ;-- IPIC WR LLink
    -- signal sig_ip2bus_mstwr_src_rdy_n     : std_logic                                           ;-- IPIC WR LLink
    -- signal sig_ip2bus_mstwr_src_dsc_n     : std_logic                                           ;-- IPIC WR LLink
    --
    -- signal sig_bus2ip_mstwr_dst_rdy_n     : std_logic                                           ;-- IPIC WR LLink
    -- signal sig_bus2ip_mstwr_dst_dsc_n     : std_logic                                           ;-- IPIC WR LLink


    -----------------------------------------------------------------------------------------
    -- IPIC Write LocalLink Channel  (Big Endian bit ordering)
    -----------------------------------------------------------------------------------------
    signal sig_ip2bus_mstwr_d             : std_logic_vector(0 to C_NATIVE_DATA_WIDTH-1)        ;-- IPIC WR LLink
    signal sig_ip2bus_mstwr_rem           : std_logic_vector(0 to (C_NATIVE_DATA_WIDTH/8)-1)    ;-- IPIC WR LLink
    signal sig_ip2bus_mstwr_sof_n         : std_logic                                           ;-- IPIC WR LLink
    signal sig_ip2bus_mstwr_eof_n         : std_logic                                           ;-- IPIC WR LLink
    signal sig_ip2bus_mstwr_src_rdy_n     : std_logic                                           ;-- IPIC WR LLink
    signal sig_ip2bus_mstwr_src_dsc_n     : std_logic                                           ;-- IPIC WR LLink

    signal sig_bus2ip_mstwr_dst_rdy_n     : std_logic                                           ;-- IPIC WR LLink
    signal sig_bus2ip_mstwr_dst_dsc_n     : std_logic                                           ;-- IPIC WR LLink








begin --(architecture implementation)

  -- Master detected Error output discrete
  -- md_error                  <= sig_md_error      ;
  md_error                  <= sig_rw_error      ;



  -- Assign IPIC Command Inputs
  -- Note that this also changes the bit ordering
  -- from Little Endian to big endian for vectors.
  sig_ip2bus_mstrd_req      <= ip2bus_mstrd_req  ;
  sig_ip2bus_mstwr_req      <= ip2bus_mstwr_req  ;
  sig_ip2bus_mst_addr       <= ip2bus_mst_addr   ;
  sig_ip2bus_mst_length     <= ip2bus_mst_length ;
  sig_ip2bus_mst_be         <= ip2bus_mst_be     ;
  sig_ip2bus_mst_type       <= ip2bus_mst_type   ;
  sig_ip2bus_mst_lock       <= ip2bus_mst_lock   ;
  sig_ipic_reset            <= ip2bus_mst_reset  ;


  -- Assign IPIC Status Outputs

  bus2ip_mst_cmdack         <= sig_bus2ip_mst_cmdack      ;
  bus2ip_mst_cmplt          <= sig_bus2ip_mst_cmplt       ;
  bus2ip_mst_error          <= sig_bus2ip_mst_error       ;
  bus2ip_mst_rearbitrate    <= sig_bus2ip_mst_rearbitrate ;
  bus2ip_mst_cmd_timeout    <= sig_bus2ip_mst_cmd_timeout ;


  -- Assign Read LocalLink Ports
  -- Note that this also changes the bit ordering
  -- from Little Endian to big endian for vectors.
  bus2ip_mstrd_d              <=  sig_bus2ip_mstrd_d         ;
  bus2ip_mstrd_rem            <=  sig_bus2ip_mstrd_rem       ;
  bus2ip_mstrd_sof_n          <=  sig_bus2ip_mstrd_sof_n     ;
  bus2ip_mstrd_eof_n          <=  sig_bus2ip_mstrd_eof_n     ;
  bus2ip_mstrd_src_rdy_n      <=  sig_bus2ip_mstrd_src_rdy_n ;
  bus2ip_mstrd_src_dsc_n      <=  sig_bus2ip_mstrd_src_dsc_n ;

  sig_ip2bus_mstrd_dst_rdy_n  <=  ip2bus_mstrd_dst_rdy_n     ;
  sig_ip2bus_mstrd_dst_dsc_n  <=  ip2bus_mstrd_dst_dsc_n     ;


  -- Assign Write LocalLink Ports
  -- Note that this also changes the bit ordering
  -- from Little Endian to big endian for vectors.
  sig_ip2bus_mstwr_d          <= ip2bus_mstwr_d             ;
  sig_ip2bus_mstwr_rem        <= ip2bus_mstwr_rem           ;
  sig_ip2bus_mstwr_sof_n      <= ip2bus_mstwr_sof_n         ;
  sig_ip2bus_mstwr_eof_n      <= ip2bus_mstwr_eof_n         ;
  sig_ip2bus_mstwr_src_rdy_n  <= ip2bus_mstwr_src_rdy_n     ;
  sig_ip2bus_mstwr_src_dsc_n  <= ip2bus_mstwr_src_dsc_n     ;

  bus2ip_mstwr_dst_rdy_n      <= sig_bus2ip_mstwr_dst_rdy_n ;
  bus2ip_mstwr_dst_dsc_n      <= sig_bus2ip_mstwr_dst_dsc_n ;







  ------------------------------------------------------------
  -- Instance: I_RESET_MODULE
  --
  -- Description:
  --   Reset Module instance.
  --
  ------------------------------------------------------------
  I_RESET_MODULE : entity axi_master_burst_v1_00_a.axi_master_burst_reset
  port map (

    -- Clock Input
    axi_aclk               => m_axi_aclk     ,

    -- Reset Input (active low)
    axi_aresetn            => m_axi_aresetn  ,


    -- IPIC Reset Input
    ip2bus_mst_reset       => sig_ipic_reset ,




    -- HW Reset to internal reset groups --------------------------
    rst2cmd_reset_out      => sig_rst2cmd_stat_reset    ,
    rst2rdwr_reset_out     => sig_rst2rdwr_cntlr_reset  ,
    rst2llink_reset_out    => sig_rst2llink_reset

    );





   ------------------------------------------------------------
   -- Instance: I_CMD_STATUS_MODULE
   --
   -- Description:
   --  Instance of the Command and Status Module
   --
   ------------------------------------------------------------
   I_CMD_STATUS_MODULE : entity axi_master_burst_v1_00_a.axi_master_burst_cmd_status
   generic map (

     C_ADDR_WIDTH            =>   C_M_AXI_ADDR_WIDTH ,
     C_NATIVE_DWIDTH         =>   C_NATIVE_DATA_WIDTH,
     C_CMD_WIDTH             =>   PCC_CMD_WIDTH      ,
     C_CMD_BTT_USED_WIDTH    =>   LENGTH_WIDTH       ,
     C_STS_WIDTH             =>   STATUS_WIDTH       ,
     C_FAMILY                =>   C_FAMILY

     )
   port map (

     -- Clock inputs
     axi_aclk                =>  m_axi_aclk                 ,

     -- Reset inputs
     axi_reset               =>  sig_rst2cmd_stat_reset     ,

     -- RW_ERROR Output Discrete
     rw_error                =>  sig_rw_error               ,

     -- Internal error Output Discrete to LocalLink backends
     -- (Asserted until Pertinent LocalLink IF is not busy)
     rdwr2llink_int_err      =>  sig_rdwr2llink_int_err     ,

-- IPIC Request/Qualifiers
     ip2bus_mstrd_req        =>  sig_ip2bus_mstrd_req       ,
     ip2bus_mstwr_req        =>  sig_ip2bus_mstwr_req       ,
     ip2bus_mst_addr         =>  sig_ip2bus_mst_addr        ,
     ip2bus_mst_length       =>  sig_ip2bus_mst_length      ,
     ip2bus_mst_be           =>  sig_ip2bus_mst_be          ,
     ip2bus_mst_type         =>  sig_ip2bus_mst_type        ,
     ip2bus_mst_lock         =>  sig_ip2bus_mst_lock        ,
     ip2bus_mst_reset        =>  LOGIC_LOW                  ,


     -- IPIC Request Status Reply
     bus2ip_mst_cmdack       =>  sig_bus2ip_mst_cmdack      ,
     bus2ip_mst_cmplt        =>  sig_bus2ip_mst_cmplt       ,
     bus2ip_mst_error        =>  sig_bus2ip_mst_error       ,
     bus2ip_mst_rearbitrate  =>  sig_bus2ip_mst_rearbitrate ,
     bus2ip_mst_cmd_timeout  =>  sig_bus2ip_mst_cmd_timeout ,


     -- IPIC LocalLink Busy Flag
     mstrd_llink_busy        =>  sig_llink2cmd_rd_busy      ,
     mstwr_llink_busy        =>  sig_llink2cmd_wr_busy      ,


     -- PCC Command Interface
     pcc2cmd_cmd_ready       =>  sig_pcc2cmd_cmd_ready      ,
     cmd2pcc_cmd_valid       =>  sig_cmd2pcc_cmd_valid      ,
     cmd2pcc_command         =>  sig_cmd2pcc_command        ,



     -- Read/Write Command Indicator Interface
     cmd2all_doing_read      =>  sig_cmd2all_doing_read     ,
     cmd2all_doing_write     =>  sig_cmd2all_doing_write    ,


     -- Read Status Controller Interface
     stat2rsc_status_ready   =>  sig_stat2rsc_status_ready  ,
     rsc2stat_status_valid   =>  sig_rsc2stat_status_valid  ,
     rsc2stat_status         =>  sig_rsc2stat_status        ,


     -- Write Status Controller Interface
     stat2wsc_status_ready   =>  sig_stat2wsc_status_ready  ,
     wsc2stat_status_valid   =>  sig_wsc2stat_status_valid  ,
     wsc2stat_status         =>  sig_wsc2stat_status

     );







     ------------------------------------------------------------
     -- Instance: I_RD_WR_CNTRL_MODULE
     --
     -- Description:
     --   Instance of the Read and Write Controller Module
     --
     ------------------------------------------------------------
     I_RD_WR_CNTRL_MODULE : entity axi_master_burst_v1_00_a.axi_master_burst_rd_wr_cntlr
     generic map (

       C_RDWR_ID_WIDTH          => RDWR_ID_WIDTH        ,
       C_RDWR_ARID              => RDWR_ID              ,
       C_RDWR_ADDR_WIDTH        => C_M_AXI_ADDR_WIDTH   ,
       C_RDWR_MDATA_WIDTH       => C_M_AXI_DATA_WIDTH   ,
       C_RDWR_SDATA_WIDTH       => C_NATIVE_DATA_WIDTH  ,
       C_RDWR_MAX_BURST_LEN     => RDWR_MAX_BURST_LEN   ,
       C_RDWR_BTT_USED          => RDWR_BTT_USED        ,
       C_RDWR_ADDR_PIPE_DEPTH   => RDWR_ADDR_PIPE_DEPTH ,
       C_RDWR_PCC_CMD_WIDTH     => PCC_CMD_WIDTH        ,
       C_RDWR_STATUS_WIDTH      => STATUS_WIDTH         ,
       C_FAMILY                 => C_FAMILY

       )
     port map (

       -- RDWR Primary Clock input
       rdwr_aclk               => m_axi_aclk                    ,

       -- RDWR Primary Reset input
       rdwr_areset             => sig_rst2rdwr_cntlr_reset      ,

       -- RDWR Master detected Error Output Discrete
       rdwr_md_error           => sig_md_error                   ,


       -- Command/Status Module PCC Command Interface (AXI Stream Like)
       cmd2rdwr_cmd_valid      => sig_cmd2pcc_cmd_valid         ,
       rdwr2cmd_cmd_ready      => sig_pcc2cmd_cmd_ready         ,
       cmd2rdwr_cmd_data       => sig_cmd2pcc_command           ,

       -- Command/Status Module Type Interface
       cmd2rdwr_doing_read     => sig_cmd2all_doing_read        ,
       cmd2rdwr_doing_write    => sig_cmd2all_doing_write       ,

       -- Command/Status Module Read Status Ports (AXI Stream Like)
       stat2rsc_status_ready   => sig_stat2rsc_status_ready     ,
       rsc2stat_status_valid   => sig_rsc2stat_status_valid     ,
       rsc2stat_status         => sig_rsc2stat_status           ,


       -- Command/Status Module Write Status Ports (AXI Stream Like)
       stat2wsc_status_ready   => sig_stat2wsc_status_ready     ,
       wsc2stat_status_valid   => sig_wsc2stat_status_valid     ,
       wsc2stat_status         => sig_wsc2stat_status           ,


       -- Read Address Posting Contols/Status
       rd_allow_addr_req       => sig_llink2rd_allow_addr_req   ,
       rd_addr_req_posted      => sig_rd2llink_addr_req_posted  ,
       rd_xfer_cmplt           => sig_rd2llink_xfer_cmplt       ,

       -- Write Address Posting Contols/Status
       wr_allow_addr_req       => sig_llink2wr_allow_addr_req   ,
       wr_addr_req_posted      => sig_wr2llink_addr_req_posted  ,
       wr_xfer_cmplt           => sig_wr2llink_xfer_cmplt       ,



       -- LocalLink Enable Outputs (1 clock pulse)
       rd_llink_enable        => sig_rd_llink_enable            ,
       wr_llink_enable        => sig_wr_llink_enable            ,



       -- AXI Read Address Channel I/O
       rd_arid                 => open                          ,
       rd_araddr               => m_axi_araddr                  ,
       rd_arlen                => m_axi_arlen                   ,
       rd_arsize               => m_axi_arsize                  ,
       rd_arburst              => m_axi_arburst                 ,
       rd_arprot               => m_axi_arprot                  ,
       rd_arcache              => m_axi_arcache                 ,
       rd_arvalid              => m_axi_arvalid                 ,
       rd_arready              => m_axi_arready                 ,

       -- AXI Read Data Channel I/O
       rd_rdata                => m_axi_rdata                   ,
       rd_rresp                => m_axi_rresp                   ,
       rd_rlast                => m_axi_rlast                   ,
       rd_rvalid               => m_axi_rvalid                  ,
       rd_rready               => m_axi_rready                  ,

       -- AXI Read Master Stream Channel I/O
       rd_strm_tdata           => sig_rd2llink_strm_tdata       ,
       rd_strm_tstrb           => sig_rd2llink_strm_tstrb       ,
       rd_strm_tlast           => sig_rd2llink_strm_tlast       ,
       rd_strm_tvalid          => sig_rd2llink_strm_tvalid      ,
       rd_strm_tready          => sig_llink2rd_strm_tready      ,


       -- AXI Write Address Channel I/O
       wr_awid                 => open                          ,
       wr_awaddr               => m_axi_awaddr                  ,
       wr_awlen                => m_axi_awlen                   ,
       wr_awsize               => m_axi_awsize                  ,
       wr_awburst              => m_axi_awburst                 ,
       wr_awprot               => m_axi_awprot                  ,
       wr_awcache              => m_axi_awcache                 ,
       wr_awvalid              => m_axi_awvalid                 ,
       wr_awready              => m_axi_awready                 ,

       -- RDWR AXI Write Data Channel I/O
       wr_wdata                => m_axi_wdata                   ,
       wr_wstrb                => m_axi_wstrb                   ,
       wr_wlast                => m_axi_wlast                   ,
       wr_wvalid               => m_axi_wvalid                  ,
       wr_wready               => m_axi_wready                  ,


       -- RDWR AXI Write response Channel I/O
       wr_bresp                => m_axi_bresp                   ,
       wr_bvalid               => m_axi_bvalid                  ,
       wr_bready               => m_axi_bready                  ,

       -- RDWR AXI Slave Stream Channel I/O
       wr_strm_tdata           => sig_llink2wr_strm_tdata       ,
       wr_strm_tstrb           => sig_llink2wr_strm_tstrb       ,
       wr_strm_tlast           => sig_llink2wr_strm_tlast       ,
       wr_strm_tvalid          => sig_llink2wr_strm_tvalid      ,
       wr_strm_tready          => sig_llink2wr_strm_tready


       );












    ------------------------------------------------------------
    -- Instance: I_RD_LLINK_ADAPTER
    --
    -- Description:
    --   Instance for the Read AXI Stream to Read LocalLink Adapter
    --
    ------------------------------------------------------------
    I_RD_LLINK_ADAPTER : entity axi_master_burst_v1_00_a.axi_master_burst_rd_llink
    generic map (

      C_NATIVE_DWIDTH => C_NATIVE_DATA_WIDTH

      )
    port map (

      -- Read LocalLink Clock input
      rdllink_aclk               =>  m_axi_aclk                   ,

      -- Read LocalLink Reset input
      rdllink_areset             =>  sig_rst2llink_reset          ,

      -- Read Cntlr Internal Error Indication
      rdllink_rd_error           =>  sig_rdwr2llink_int_err       ,

      -- LocalLink Enable Control (1 Clock wide pulse)
      rdllink_llink_enable       =>  sig_rd_llink_enable          ,

      -- IPIC LocalLink Busy Flag
      rdllink_llink_busy         =>  sig_llink2cmd_rd_busy        ,


      -- Read Address Posting Contols/Status
      rdllink_allow_addr_req     =>  sig_llink2rd_allow_addr_req  ,
      rdllink_addr_req_posted    =>  sig_rd2llink_addr_req_posted ,
      rdllink_xfer_cmplt         =>  sig_rd2llink_xfer_cmplt      ,


      -- Read AXI Slave Master Channel
      rdllink_strm_tdata         =>  sig_rd2llink_strm_tdata      ,
      rdllink_strm_tstrb         =>  sig_rd2llink_strm_tstrb      ,
      rdllink_strm_tlast         =>  sig_rd2llink_strm_tlast      ,
      rdllink_strm_tvalid        =>  sig_rd2llink_strm_tvalid     ,
      rdllink_strm_tready        =>  sig_llink2rd_strm_tready     ,

      -- IPIC Read LocalLink Channel
      bus2ip_mstrd_d             =>  sig_bus2ip_mstrd_d           ,
      bus2ip_mstrd_rem           =>  sig_bus2ip_mstrd_rem         ,
      bus2ip_mstrd_sof_n         =>  sig_bus2ip_mstrd_sof_n       ,
      bus2ip_mstrd_eof_n         =>  sig_bus2ip_mstrd_eof_n       ,
      bus2ip_mstrd_src_rdy_n     =>  sig_bus2ip_mstrd_src_rdy_n   ,
      bus2ip_mstrd_src_dsc_n     =>  sig_bus2ip_mstrd_src_dsc_n   ,

      ip2bus_mstrd_dst_rdy_n     =>  sig_ip2bus_mstrd_dst_rdy_n   ,
      ip2bus_mstrd_dst_dsc_n     =>  sig_ip2bus_mstrd_dst_dsc_n


      );












    ------------------------------------------------------------
    -- Instance: I_WR_LLINK_ADAPTER
    --
    -- Description:
    --   Instance for the Write LocalLink to AXI Stream Adapter
    --
    ------------------------------------------------------------
    I_WR_LLINK_ADAPTER : entity axi_master_burst_v1_00_a.axi_master_burst_wr_llink
    generic map (

      C_NATIVE_DWIDTH => C_NATIVE_DATA_WIDTH

      )
    port map (

      -- Write LocalLink Clock input
      wrllink_aclk               =>  m_axi_aclk                   ,

      -- Write LocalLink Reset input
      wrllink_areset             =>  sig_rst2llink_reset          ,

      -- RDWR Cntlr Internal Error Indication
      wrllink_wr_error           =>  sig_rdwr2llink_int_err       ,

      -- LocalLink Enable Control (1 Clock wide pulse)
      wrllink_llink_enable       =>  sig_wr_llink_enable          ,

      -- IPIC LocalLink Busy Flag
      wrllink_llink_busy         =>  sig_llink2cmd_wr_busy        ,


      -- Write Address Posting Contols/Status
      wrllink_allow_addr_req     =>  sig_llink2wr_allow_addr_req  ,
      wrllink_addr_req_posted    =>  sig_wr2llink_addr_req_posted ,
      wrllink_xfer_cmplt         =>  sig_wr2llink_xfer_cmplt      ,


      -- Write AXI Slave Master Channel
      wrllink_strm_tdata         =>  sig_llink2wr_strm_tdata      ,
      wrllink_strm_tstrb         =>  sig_llink2wr_strm_tstrb      ,
      wrllink_strm_tlast         =>  sig_llink2wr_strm_tlast      ,
      wrllink_strm_tvalid        =>  sig_llink2wr_strm_tvalid     ,
      wrllink_strm_tready        =>  sig_llink2wr_strm_tready     ,

      -- IPIC Write LocalLink Channel
      ip2bus_mstwr_d             =>  sig_ip2bus_mstwr_d           ,
      ip2bus_mstwr_rem           =>  sig_ip2bus_mstwr_rem         ,
      ip2bus_mstwr_sof_n         =>  sig_ip2bus_mstwr_sof_n       ,
      ip2bus_mstwr_eof_n         =>  sig_ip2bus_mstwr_eof_n       ,
      ip2bus_mstwr_src_rdy_n     =>  sig_ip2bus_mstwr_src_rdy_n   ,
      ip2bus_mstwr_src_dsc_n     =>  sig_ip2bus_mstwr_src_dsc_n   ,

      bus2ip_mstwr_dst_rdy_n     =>  sig_bus2ip_mstwr_dst_rdy_n   ,
      bus2ip_mstwr_dst_dsc_n     =>  sig_bus2ip_mstwr_dst_dsc_n


      );









end implementation;
