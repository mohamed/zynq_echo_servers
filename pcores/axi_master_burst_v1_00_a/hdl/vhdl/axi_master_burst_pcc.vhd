-------------------------------------------------------------------------------
-- axi_master_burst_pcc.vhd
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
-- Filename:        axi_master_burst_pcc.vhd
--
-- Description:
--    This file implements the AXI Master burst Predictive Command Calculator 
-- (PCC). It has been adapted from the AXI DataMover PCC.
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
-- Date:            $1/19/2011$
--
-- History:
--     DET     1/19/2011     Initial
-- ~~~~~~
--     - Adapted from AXI DataMover v2_00_a axi_datamover_pcc.vhd
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

library axi_master_burst_v1_00_a;
use axi_master_burst_v1_00_a.axi_master_burst_strb_gen;

-------------------------------------------------------------------------------

entity axi_master_burst_pcc is
  generic (

    C_DRE_ALIGN_WIDTH    : Integer range  1 to   3 :=  2;
    C_SEL_ADDR_WIDTH     : Integer range  1 to   8 :=  5;
    C_ADDR_WIDTH         : Integer range 32 to  64 := 32;
    C_STREAM_DWIDTH      : Integer range  8 to 256 := 32;
    C_MAX_BURST_LEN      : Integer range 16 to 256 := 16;
    C_CMD_WIDTH          : Integer                 := 68;
    C_TAG_WIDTH          : Integer range  1 to   8 :=  4;
    C_BTT_USED           : Integer range  8 to  23 := 16;
    C_SUPPORT_INDET_BTT  : Integer range  0 to   1 :=  0

    );
  port (

    -- Clock input
    primary_aclk         : in  std_logic;
       -- Primary synchronization clock for the Master side
       -- interface and internal logic. It is also used
       -- for the User interface synchronization when
       -- C_STSCMD_IS_ASYNC = 0.

    -- Reset input
    mmap_reset           : in  std_logic;
      -- Reset used for the internal master logic




    -- Master Command FIFO/Register Interface -------------------------------

    cmd2mstr_command      : in std_logic_vector(C_CMD_WIDTH-1 downto 0);
       -- The next command value available from the Command FIFO/Register

    cmd2mstr_cmd_valid    : in std_logic;
       -- Handshake bit indicating if the Command FIFO/Register has at leasdt 1 entry

    mst2cmd_cmd_ready     : out  std_logic;
       -- Handshake bit indicating the Command Calculator is ready to accept
       -- another command



    -- Address Channel Controller Interface ---------------------------------

    mstr2addr_tag       : out std_logic_vector(C_TAG_WIDTH-1 downto 0);
       -- The next command tag

    mstr2addr_addr      : out std_logic_vector(C_ADDR_WIDTH-1 downto 0);
       -- The next command address to put on the AXI MMap ADDR

    mstr2addr_len       : out std_logic_vector(7 downto 0);
       -- The next command length to put on the AXI MMap LEN

    mstr2addr_size      : out std_logic_vector(2 downto 0);
       -- The next command size to put on the AXI MMap SIZE

    mstr2addr_burst     : out std_logic_vector(1 downto 0);
       -- The next command burst type to put on the AXI MMap BURST

    mstr2addr_cmd_cmplt : out std_logic;
       -- The indication to the Address Channel that the current
       -- sub-command output is the last one compiled from the
       -- parent command pulled from the Command FIFO

    mstr2addr_calc_error : out std_logic;
       -- Indication if the next command in the calculation pipe
       -- has a calcualtion error

    mstr2addr_cmd_valid : out std_logic;
       -- The next command valid indication to the Address Channel
       -- Controller for the AXI MMap

    addr2mstr_cmd_ready : In std_logic;
       -- Indication from the Address Channel Controller that the
       -- command is being accepted



    -- Data Channel Controller Interface ------------------------------------

    mstr2data_tag        : out std_logic_vector(C_TAG_WIDTH-1 downto 0);
       -- The next command tag

    mstr2data_saddr_lsb  : out std_logic_vector(C_SEL_ADDR_WIDTH-1 downto 0);
       -- The next command start address LSbs to use for the read data
       -- mux (only used if Stream data width is less than the MMap data
       -- width).

    mstr2data_len        : out std_logic_vector(7 downto 0);
       -- The LEN value output to the Address Channel

    mstr2data_strt_strb  : out std_logic_vector((C_STREAM_DWIDTH/8)-1 downto 0);
       -- The starting strobe value to use for the data transfer

    mstr2data_last_strb  : out std_logic_vector((C_STREAM_DWIDTH/8)-1 downto 0);
       -- The endiing (LAST) strobe value to use for the data transfer

    mstr2data_drr        : out std_logic;
       -- The starting tranfer of a sequence of transfers

    mstr2data_eof        : out std_logic;
       -- The endiing tranfer of a sequence of parent transfer commands

    mstr2data_sequential : Out std_logic;
       -- The next sequential tranfer of a sequence of transfers
       -- spawned from a single parent command

    mstr2data_calc_error : out std_logic;
       -- Indication if the next command in the calculation pipe
       -- has a calculation error

    mstr2data_cmd_cmplt  : out std_logic;
       -- The indication to the Data Channel that the current
       -- sub-command output is the last one compiled from the
       -- parent command pulled from the Command FIFO

    mstr2data_cmd_valid  : out std_logic;
       -- The next command valid indication to the Data Channel
       -- Controller for the AXI MMap

    data2mstr_cmd_ready  : In std_logic ;
       -- Indication from the Data Channel Controller that the
       -- command is being accepted on the AXI Address
       -- Channel

    mstr2data_dre_src_align  : Out std_logic_vector(C_DRE_ALIGN_WIDTH-1 downto 0);
       -- The source (input) alignment for the MM2S DRE

    mstr2data_dre_dest_align : Out std_logic_vector(C_DRE_ALIGN_WIDTH-1 downto 0);
       -- The destinstion (output) alignment for the MM2S DRE


    calc_error               : Out std_logic;
       -- Indication from the Command Calculator that a calculation
       -- error has occured.





    -- Special S2MM DRE Controller Interface --------------------------------

    dre2mstr_cmd_ready        : In std_logic ;
       -- Indication from the S2MM DRE Controller that it can
       -- accept another command.

    mstr2dre_cmd_valid        : out std_logic ;
       -- The next command valid indication to the S2MM DRE
       -- Controller.

    mstr2dre_tag              : out std_logic_vector(C_TAG_WIDTH-1 downto 0);
       -- The next command tag

    mstr2dre_dre_src_align    : Out std_logic_vector(C_DRE_ALIGN_WIDTH-1 downto 0) ;
       -- The source (S2MM Stream) alignment for the S2MM DRE

    mstr2dre_dre_dest_align   : Out std_logic_vector(C_DRE_ALIGN_WIDTH-1 downto 0) ;
       -- The destinstion (S2MM MMap) alignment for the S2MM DRE

    mstr2dre_btt              : out std_logic_vector(C_BTT_USED-1 downto 0) ;
       -- The BTT value output to the S2MM DRE. This is needed for
       -- Scatter operations.

    mstr2dre_drr              : out std_logic ;
       -- The starting tranfer of a sequence of transfers

    mstr2dre_eof              : out std_logic ;
       -- The endiing tranfer of a sequence of parent transfer commands

    mstr2dre_cmd_cmplt        : Out std_logic ;
       -- The last child tranfer of a sequence of transfers
       -- spawned from a single parent command

    mstr2dre_calc_error       : out std_logic
       -- Indication if the next command in the calculation pipe
       -- has a calculation error



    );

end entity axi_master_burst_pcc;


architecture implementation of axi_master_burst_pcc is

-- Function declarations  -------------------

  -------------------------------------------------------------------
  -- Function
  --
  -- Function Name: funct_get_dbeat_residue_width
  --
  -- Function Description:
  --  Calculates the number of Least significant bits of the BTT field
  -- that are unused for the LEN calculation
  --
  -------------------------------------------------------------------
  function funct_get_dbeat_residue_width (bytes_per_beat : integer) return integer is

    Variable temp_dbeat_residue_width : Integer := 0; -- 8-bit stream

  begin

    case bytes_per_beat is
-- coverage off      
      when 32 =>
          temp_dbeat_residue_width := 5;
-- coverage on      
      when 16 =>
          temp_dbeat_residue_width := 4;
      when 8 =>
          temp_dbeat_residue_width := 3;
      when 4 =>
          temp_dbeat_residue_width := 2;
-- coverage off      
      when 2 =>
          temp_dbeat_residue_width := 1;
      when others =>  -- assume 1-byte transfers
          temp_dbeat_residue_width := 0;
-- coverage on      
    end case;

    Return (temp_dbeat_residue_width);

  end function funct_get_dbeat_residue_width;




  -------------------------------------------------------------------
  -- Function
  --
  -- Function Name: funct_get_burstcnt_offset
  --
  -- Function Description:
  -- Calculates the bit offset from the residue bits needed to detirmine
  -- the load value for the burst counter.
  --
  -------------------------------------------------------------------
  function funct_get_burst_residue_width (max_burst_len : integer) return integer is


    Variable temp_burst_residue_width : Integer := 0;

  begin

    case max_burst_len is

      when 256 =>
        temp_burst_residue_width := 8;
      when 128 =>
        temp_burst_residue_width := 7;
      when 64 =>
        temp_burst_residue_width := 6;
      when 32 =>
        temp_burst_residue_width := 5;
      when others =>   -- assume 16 dbeats
        temp_burst_residue_width := 4;
    end case;

    Return (temp_burst_residue_width);

  end function funct_get_burst_residue_width;


  -------------------------------------------------------------------
  -- Function
  --
  -- Function Name: func_get_axi_size
  --
  -- Function Description:
  -- Calculates the AXI SIZE Qualifier based on the data width.
  --
  -------------------------------------------------------------------
  function func_get_axi_size (native_dwidth : integer) return std_logic_vector is

    Constant AXI_SIZE_1BYTE    : std_logic_vector(2 downto 0) := "000";
    Constant AXI_SIZE_2BYTE    : std_logic_vector(2 downto 0) := "001";
    Constant AXI_SIZE_4BYTE    : std_logic_vector(2 downto 0) := "010";
    Constant AXI_SIZE_8BYTE    : std_logic_vector(2 downto 0) := "011";
    Constant AXI_SIZE_16BYTE   : std_logic_vector(2 downto 0) := "100";
    Constant AXI_SIZE_32BYTE   : std_logic_vector(2 downto 0) := "101";

    Variable temp_size : std_logic_vector(2 downto 0) := (others => '0');

  begin

     case native_dwidth is
-- coverage off       
       when 8 =>
         temp_size := AXI_SIZE_1BYTE;
       when 16 =>
         temp_size := AXI_SIZE_2BYTE;
-- coverage on       
       when 32 =>
         temp_size := AXI_SIZE_4BYTE;
       when 64 =>
         temp_size := AXI_SIZE_8BYTE;
       when 128 =>
         temp_size := AXI_SIZE_16BYTE;
-- coverage off       
       when others =>
         temp_size := AXI_SIZE_32BYTE;
-- coverage on       
     end case;

     Return (temp_size);


  end function func_get_axi_size;






  -- Constant Declarations  ----------------------------------------

  Constant BASE_CMD_WIDTH    : integer := 32; -- Bit Width of Command LS (no address)
  Constant CMD_BTT_WIDTH     : integer := C_BTT_USED;
  Constant CMD_BTT_LS_INDEX  : integer := 0;
  Constant CMD_BTT_MS_INDEX  : integer := CMD_BTT_WIDTH-1;
  Constant CMD_TYPE_INDEX    : integer := 23;
  Constant CMD_DRR_INDEX     : integer := BASE_CMD_WIDTH-1;
  Constant CMD_EOF_INDEX     : integer := BASE_CMD_WIDTH-2;
  Constant CMD_DSA_WIDTH     : integer := 6;
  Constant CMD_DSA_LS_INDEX  : integer := CMD_TYPE_INDEX+1;
  Constant CMD_DSA_MS_INDEX  : integer := (CMD_DSA_LS_INDEX+CMD_DSA_WIDTH)-1;
  Constant CMD_ADDR_LS_INDEX : integer := BASE_CMD_WIDTH;
  Constant CMD_ADDR_MS_INDEX : integer := (C_ADDR_WIDTH+BASE_CMD_WIDTH)-1;
  Constant CMD_TAG_WIDTH     : integer := C_TAG_WIDTH;
  Constant CMD_TAG_LS_INDEX  : integer := C_ADDR_WIDTH+BASE_CMD_WIDTH;
  Constant CMD_TAG_MS_INDEX  : integer := (CMD_TAG_LS_INDEX+CMD_TAG_WIDTH)-1;


  ----------------------------------------------------------------------------------------
  -- Command calculation constants

  Constant SIZE_TO_USE               : std_logic_vector(2 downto 0) := func_get_axi_size(C_STREAM_DWIDTH);
  Constant BYTES_PER_DBEAT           : integer := C_STREAM_DWIDTH/8;
  Constant DBEATS_PER_BURST          : integer := C_MAX_BURST_LEN;
  Constant BYTES_PER_MAX_BURST       : integer := DBEATS_PER_BURST*BYTES_PER_DBEAT;
  Constant LEN_WIDTH                 : integer  := 8;  -- 8 bits fixed
  Constant MAX_LEN_VALUE             : integer  := DBEATS_PER_BURST-1;
  Constant XFER_LEN_ZERO             : std_logic_vector(LEN_WIDTH-1 downto 0) := (others => '0');
  Constant DBEAT_RESIDUE_WIDTH       : integer  := funct_get_dbeat_residue_width(BYTES_PER_DBEAT);
  Constant BURST_RESIDUE_WIDTH       : integer  := funct_get_burst_residue_width(C_MAX_BURST_LEN);
  Constant BURST_RESIDUE_LS_INDEX    : integer  := DBEAT_RESIDUE_WIDTH;
  Constant BTT_RESIDUE_WIDTH         : integer  := DBEAT_RESIDUE_WIDTH+BURST_RESIDUE_WIDTH;
  Constant BTT_ZEROS                 : std_logic_vector(CMD_BTT_WIDTH-1 downto 0) := (others => '0');
  Constant BTT_RESIDUE_1             : unsigned := TO_UNSIGNED( 1, BTT_RESIDUE_WIDTH);
  Constant BTT_RESIDUE_0             : unsigned := TO_UNSIGNED( 0, BTT_RESIDUE_WIDTH);
  Constant BURST_CNT_LS_INDEX        : integer  := DBEAT_RESIDUE_WIDTH+BURST_RESIDUE_WIDTH;
  Constant BURST_CNTR_WIDTH          : integer  := CMD_BTT_WIDTH - (DBEAT_RESIDUE_WIDTH+BURST_RESIDUE_WIDTH); 
  Constant BRST_CNT_1                : unsigned := TO_UNSIGNED( 1, BURST_CNTR_WIDTH);
  Constant BRST_CNT_0                : unsigned := TO_UNSIGNED( 0, BURST_CNTR_WIDTH);
  Constant BRST_RESIDUE_0            : std_logic_vector(BURST_RESIDUE_WIDTH-1 downto 0) := (others => '0');
  Constant DBEAT_RESIDUE_0           : std_logic_vector(DBEAT_RESIDUE_WIDTH-1 downto 0) := (others => '0');
  Constant ADDR_CNTR_WIDTH           : integer  := 16;  -- Addres Counter slice
  Constant ADDR_MS_SLICE_WIDTH       : integer  := C_ADDR_WIDTH-ADDR_CNTR_WIDTH;
  Constant ADDR_CNTR_MAX_VALUE       : unsigned := TO_UNSIGNED((2**ADDR_CNTR_WIDTH)-1, ADDR_CNTR_WIDTH);
  Constant ADDR_CNTR_ONE             : unsigned := TO_UNSIGNED(1, ADDR_CNTR_WIDTH);
  Constant MBAA_ADDR_SLICE_WIDTH     : integer := BTT_RESIDUE_WIDTH;
  Constant STRBGEN_ADDR_SLICE_WIDTH  : integer := DBEAT_RESIDUE_WIDTH;
  Constant STRBGEN_ADDR_0            : std_logic_vector(STRBGEN_ADDR_SLICE_WIDTH-1 downto 0) := (others => '0');



  -- Type Declarations  --------------------------------------------

  type PCC_SM_STATE_TYPE is (
              INIT,
              WAIT_FOR_CMD,
              CALC_1,
              CALC_2,
              WAIT_ON_XFER_PUSH,
              CHK_IF_DONE,
              ERROR_TRAP
              );





  -- Signal Declarations  --------------------------------------------
  Signal sig_pcc_sm_state                 : PCC_SM_STATE_TYPE := INIT;
  Signal sig_pcc_sm_state_ns              : PCC_SM_STATE_TYPE := INIT;
  signal sig_sm_halt_ns                   : std_logic := '0';
  signal sig_sm_halt_reg                  : std_logic := '0';
  signal sig_sm_ld_xfer_reg_ns            : std_logic := '0';
  signal sig_sm_pop_input_reg_ns          : std_logic := '0';
  signal sig_sm_pop_input_reg             : std_logic := '0';
  signal sig_sm_ld_calc1_reg_ns           : std_logic := '0';
  signal sig_sm_ld_calc1_reg              : std_logic := '0';
  signal sig_sm_ld_calc2_reg_ns           : std_logic := '0';
  signal sig_sm_ld_calc2_reg              : std_logic := '0';
  signal sig_parent_done                  : std_logic := '0';
  signal sig_ld_xfer_reg                  : std_logic := '0';
  signal sig_btt_raw                      : std_logic := '0';
  signal sig_btt_is_zero                  : std_logic := '0';
  signal sig_btt_is_zero_reg              : std_logic := '0';
  signal sig_next_tag                     : std_logic_vector(CMD_TAG_WIDTH-1 downto 0) := (others => '0');
  signal sig_next_addr                    : std_logic_vector(C_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal sig_next_len                     : std_logic_vector(LEN_WIDTH-1 downto 0) := (others => '0');
  signal sig_next_size                    : std_logic_vector(2 downto 0) := (others => '0');
  signal sig_next_burst                   : std_logic_vector(1 downto 0) := (others => '0');
  signal sig_next_strt_strb               : std_logic_vector((C_STREAM_DWIDTH/8)-1 downto 0) := (others => '0');
  signal sig_next_end_strb                : std_logic_vector((C_STREAM_DWIDTH/8)-1 downto 0) := (others => '0');

  ----------------------------------------------------------------------------------------
  -- Burst Buster signals
  signal sig_burst_cnt_slice              : unsigned(BURST_CNTR_WIDTH-1 downto 0) := (others => '0');
  signal sig_last_xfer_valid              : std_logic := '0';
  signal sig_brst_cnt_eq_zero             : std_logic := '0';
  signal sig_brst_cnt_eq_one              : std_logic := '0';
  signal sig_brst_residue_eq_zero         : std_logic := '0';
  signal sig_no_btt_residue               : std_logic := '0';
  signal sig_btt_residue_slice            : Unsigned(BTT_RESIDUE_WIDTH-1 downto 0) := (others => '0');

  -- Input command register
  signal sig_push_input_reg               : std_logic := '0';
  signal sig_pop_input_reg                : std_logic := '0';
  signal sig_input_burst_type_reg         : std_logic := '0';
  signal sig_input_btt_residue_minus1_reg : std_logic_vector(BTT_RESIDUE_WIDTH-1 downto 0) := (others => '0');
  signal sig_input_dsa_reg                : std_logic_vector(CMD_DSA_WIDTH-1 downto 0) := (others => '0');
  signal sig_input_drr_reg                : std_logic := '0';
  signal sig_input_eof_reg                : std_logic := '0';
  signal sig_input_tag_reg                : std_logic_vector(C_TAG_WIDTH-1 downto 0) := (others => '0');
  signal sig_input_reg_empty              : std_logic := '0';
  signal sig_input_reg_full               : std_logic := '0';

  -- Output qualifier Register
  signal sig_ld_output                    : std_logic := '0';
  signal sig_push_xfer_reg                : std_logic := '0';
  signal sig_pop_xfer_reg                 : std_logic := '0';
  signal sig_xfer_addr_reg                : std_logic_vector(C_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal sig_xfer_type_reg                : std_logic := '0';
  signal sig_xfer_len_reg                 : std_logic_vector(LEN_WIDTH-1 downto 0) := (others => '0');
  signal sig_xfer_tag_reg                 : std_logic_vector(C_TAG_WIDTH-1 downto 0) := (others => '0');
  signal sig_xfer_dsa_reg                 : std_logic_vector(CMD_DSA_WIDTH-1 downto 0) := (others => '0');
  signal sig_xfer_drr_reg                 : std_logic := '0';
  signal sig_xfer_eof_reg                 : std_logic := '0';
  signal sig_xfer_strt_strb_reg           : std_logic_vector(BYTES_PER_DBEAT-1 downto 0) := (others => '0');
  signal sig_xfer_end_strb_reg            : std_logic_vector(BYTES_PER_DBEAT-1 downto 0) := (others => '0');
  signal sig_xfer_is_seq_reg              : std_logic := '0';
  signal sig_xfer_cmd_cmplt_reg           : std_logic := '0';
  signal sig_xfer_calc_err_reg            : std_logic := '0';
  signal sig_xfer_reg_empty               : std_logic := '0';
  signal sig_xfer_reg_full                : std_logic := '0';
                                          
  -- Address Counter                      
  signal sig_ld_addr_cntr                 : std_logic := '0';
  signal sig_incr_addr_cntr               : std_logic := '0';
  signal sig_addr_cntr_incr               : Unsigned(ADDR_CNTR_WIDTH-1 downto 0) := (others => '0');
  signal sig_byte_change_minus1           : Unsigned(ADDR_CNTR_WIDTH-1 downto 0) := (others => '0');

  -- misc
  signal sig_xfer_len                     : std_logic_vector(LEN_WIDTH-1 downto 0);
  signal sig_xfer_strt_strb               : std_logic_vector(BYTES_PER_DBEAT-1 downto 0) := (others => '0');
  signal sig_xfer_strt_strb2use           : std_logic_vector(BYTES_PER_DBEAT-1 downto 0) := (others => '0');
  signal sig_xfer_end_strb                : std_logic_vector(BYTES_PER_DBEAT-1 downto 0) := (others => '0');
  signal sig_xfer_end_strb2use            : std_logic_vector(BYTES_PER_DBEAT-1 downto 0) := (others => '0');
  signal sig_xfer_address                 : std_logic_vector(C_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal sig_xfer_size                    : std_logic_vector(2 downto 0) := (others => '0');
  signal sig_cmd_addr_slice               : std_logic_vector(C_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal sig_cmd_btt_slice                : std_logic_vector(CMD_BTT_WIDTH-1 downto 0) := (others => '0');
  signal sig_cmd_type_slice               : std_logic := '0';
  signal sig_cmd_tag_slice                : std_logic_vector(CMD_TAG_WIDTH-1 downto 0) := (others => '0');
  signal sig_cmd_dsa_slice                : std_logic_vector(CMD_DSA_WIDTH-1 downto 0) := (others => '0');
  signal sig_cmd_drr_slice                : std_logic := '0';
  signal sig_cmd_eof_slice                : std_logic := '0';
  signal sig_calc_error_reg               : std_logic := '0';
  signal sig_calc_error_pushed            : std_logic := '0';

 -- PCC2 stuff
  signal sig_finish_addr_offset           : std_logic_vector(STRBGEN_ADDR_SLICE_WIDTH-1 downto 0) := (others => '0');
  signal sig_xfer_len_eq_0                : std_logic := '0';
  signal sig_first_xfer                   : std_logic := '0';
  signal sig_bytes_to_mbaa                : unsigned(ADDR_CNTR_WIDTH-1 downto 0) := (others => '0');
  signal sig_addr_lsh_rollover            : std_logic := '0';
  signal sig_predict_addr_lsh_slv         : std_logic_vector(ADDR_CNTR_WIDTH-1 downto 0) := (others => '0');
  signal sig_predict_addr_lsh             : unsigned(ADDR_CNTR_WIDTH-1 downto 0) := (others => '0');
  signal sig_addr_cntr_lsh                : unsigned(ADDR_CNTR_WIDTH-1 downto 0) := (others => '0');
  signal sig_addr_cntr_lsh_slv            : std_logic_vector(ADDR_CNTR_WIDTH-1 downto 0) := (others => '0');
  signal sig_addr_cntr_msh                : unsigned(ADDR_CNTR_WIDTH-1 downto 0) := (others => '0');
  signal sig_strbgen_addr                 : std_logic_vector(STRBGEN_ADDR_SLICE_WIDTH-1 downto 0) := (others => '0');
  signal sig_strbgen_bytes                : std_logic_vector(STRBGEN_ADDR_SLICE_WIDTH   downto 0) := (others => '0');
  signal sig_ld_btt_cntr                  : std_logic := '0';
  signal sig_decr_btt_cntr                : std_logic := '0';
  signal sig_btt_cntr                     : unsigned(CMD_BTT_WIDTH-1 downto 0) := (others => '0');
  signal sig_cmd2data_valid               : std_logic := '0';
  signal sig_clr_cmd2data_valid           : std_logic := '0';
  signal sig_cmd2addr_valid               : std_logic := '0';
  signal sig_clr_cmd2addr_valid           : std_logic := '0';
  signal sig_btt_lt_b2mbaa                : std_logic := '0';
  signal sig_btt_eq_b2mbaa                : std_logic := '0';
  signal sig_addr_incr_ge_bpdb            : std_logic := '0';

  -- Unaligned start address support
  signal sig_adjusted_addr_incr           : Unsigned(ADDR_CNTR_WIDTH-1 downto 0) := (others => '0');
  signal sig_adjusted_addr_incr_reg       : Unsigned(ADDR_CNTR_WIDTH-1 downto 0) := (others => '0');
  signal sig_start_addr_offset_slice      : Unsigned(DBEAT_RESIDUE_WIDTH-1 downto 0) := (others => '0');
  signal sig_mbaa_addr_cntr_slice         : Unsigned(MBAA_ADDR_SLICE_WIDTH-1 downto 0) := (others => '0');
  signal sig_addr_aligned                 : std_logic := '0';

  -- S2MM DRE Support
  signal sig_cmd2dre_valid                : std_logic := '0';
  signal sig_clr_cmd2dre_valid            : std_logic := '0';
  signal sig_input_xfer_btt               : std_logic_vector(CMD_BTT_WIDTH-1 downto 0) := (others => '0');
  signal sig_xfer_btt_reg                 : std_logic_vector(CMD_BTT_WIDTH-1 downto 0) := (others => '0');
  signal sig_xfer_dre_eof_reg             : std_logic := '0';

  -- Long Timing path breakup intermediate registers
  signal sig_strbgen_addr_reg             : std_logic_vector(STRBGEN_ADDR_SLICE_WIDTH-1 downto 0) := (others => '0');
  signal sig_strbgen_bytes_reg            : std_logic_vector(STRBGEN_ADDR_SLICE_WIDTH   downto 0) := (others => '0');
  signal sig_finish_addr_offset_reg       : std_logic_vector(STRBGEN_ADDR_SLICE_WIDTH-1 downto 0) := (others => '0');
  signal sig_xfer_strt_strb_imreg         : std_logic_vector(BYTES_PER_DBEAT-1 downto 0) := (others => '0');
  signal sig_xfer_end_strb_imreg          : std_logic_vector(BYTES_PER_DBEAT-1 downto 0) := (others => '0');
  signal sig_xfer_len_eq_0_reg            : std_logic := '0';

  signal sig_addr_cntr_incr_imreg         : Unsigned(ADDR_CNTR_WIDTH-1 downto 0) := (others => '0');
  signal sig_predict_addr_lsh_imreg_slv   : std_logic_vector(ADDR_CNTR_WIDTH-1 downto 0) := (others => '0');
  signal sig_predict_addr_lsh_im          : unsigned(ADDR_CNTR_WIDTH-1 downto 0) := (others => '0');
  signal sig_predict_addr_lsh_imreg       : unsigned(ADDR_CNTR_WIDTH-1 downto 0) := (others => '0');
  signal sig_addr_lsh_rollover_im         : std_logic := '0';
  
  
  ----------------------------------------------------------






begin --(architecture implementation)



   -- Assign calculation error output
   calc_error               <= sig_calc_error_reg;

   -- Assign the ready output to the Command FIFO
   mst2cmd_cmd_ready        <= not(sig_sm_halt_reg) and
                               sig_input_reg_empty  and
                               not(sig_calc_error_pushed);

   -- Assign the Address Channel Controller Qualifiers
   mstr2addr_tag            <=  sig_xfer_tag_reg ;
   mstr2addr_addr           <=  sig_xfer_addr_reg;
   mstr2addr_len            <=  sig_xfer_len_reg ;
   mstr2addr_size           <=  sig_xfer_size    ;
   mstr2addr_burst          <=  '0' & sig_xfer_type_reg; -- only fixed or increment supported
   mstr2addr_cmd_valid      <=  sig_cmd2addr_valid;
   mstr2addr_calc_error     <=  sig_xfer_calc_err_reg;
   mstr2addr_cmd_cmplt      <=  sig_xfer_cmd_cmplt_reg;
   

   -- Assign the Data Channel Controller Qualifiers
   mstr2data_tag            <= sig_xfer_tag_reg      ;
   mstr2data_saddr_lsb      <= sig_xfer_addr_reg(C_SEL_ADDR_WIDTH-1 downto 0);
   mstr2data_len            <= sig_xfer_len_reg      ;
   mstr2data_strt_strb      <= sig_xfer_strt_strb_reg;
   mstr2data_last_strb      <= sig_xfer_end_strb_reg ;
   mstr2data_drr            <= sig_xfer_drr_reg      ;
   mstr2data_eof            <= sig_xfer_eof_reg      ;
   mstr2data_sequential     <= sig_xfer_is_seq_reg   ;
   mstr2data_cmd_cmplt      <= sig_xfer_cmd_cmplt_reg;
   mstr2data_cmd_valid      <= sig_cmd2data_valid    ;

   mstr2data_dre_src_align  <= sig_xfer_addr_reg(C_DRE_ALIGN_WIDTH-1 downto 0);  -- Used by MM2S DRE
   mstr2data_dre_dest_align <= sig_xfer_dsa_reg(C_DRE_ALIGN_WIDTH-1 downto 0);   -- Used by MM2S DRE

   mstr2data_calc_error     <= sig_xfer_calc_err_reg ;


   -- Assign the S2MM DRE Controller Qualifiers
   mstr2dre_cmd_valid       <= sig_cmd2dre_valid     ;                            -- Used by S2MM DRE
   mstr2dre_tag             <= sig_xfer_tag_reg      ;                            -- Used by S2MM DRE
   mstr2dre_btt             <= sig_xfer_btt_reg      ;                            -- Used by S2MM DRE
   mstr2dre_dre_src_align   <= sig_xfer_dsa_reg(C_DRE_ALIGN_WIDTH-1 downto 0) ;   -- Used by S2MM DRE
   mstr2dre_dre_dest_align  <= sig_xfer_addr_reg(C_DRE_ALIGN_WIDTH-1 downto 0);   -- Used by S2MM DRE
   mstr2dre_drr             <= sig_xfer_drr_reg      ;                            -- Used by S2MM DRE
   mstr2dre_eof             <= sig_xfer_dre_eof_reg  ;                            -- Used by S2MM DRE
   mstr2dre_cmd_cmplt       <= sig_xfer_cmd_cmplt_reg;                            -- Used by S2MM DRE
   mstr2dre_calc_error      <= sig_xfer_calc_err_reg ;                            -- Used by S2MM DRE



 -- Start internal logic.

  sig_cmd_type_slice        <=  '1';  -- always incrementing (per Interface_X guidelines)

  sig_cmd_addr_slice        <=  cmd2mstr_command(CMD_ADDR_MS_INDEX downto CMD_ADDR_LS_INDEX);
  sig_cmd_tag_slice         <=  cmd2mstr_command(CMD_TAG_MS_INDEX downto CMD_TAG_LS_INDEX);
  sig_cmd_btt_slice         <=  cmd2mstr_command(CMD_BTT_MS_INDEX downto CMD_BTT_LS_INDEX);

  sig_cmd_dsa_slice         <=  cmd2mstr_command(CMD_DSA_MS_INDEX downto CMD_DSA_LS_INDEX);
  sig_cmd_drr_slice         <=  cmd2mstr_command(CMD_DRR_INDEX);
  sig_cmd_eof_slice         <=  cmd2mstr_command(CMD_EOF_INDEX);



  -- Check for a zero length BTT (error condition)
  sig_btt_is_zero  <= '1'
    when  (sig_cmd_btt_slice = BTT_ZEROS)
    Else '0';

  sig_xfer_size <= SIZE_TO_USE;






  -----------------------------------------------------------------
  -- Input xfer register design

  sig_push_input_reg  <=  not(sig_sm_halt_reg) and
                          cmd2mstr_cmd_valid   and
                          sig_input_reg_empty  and
                          not(sig_calc_error_reg);

  sig_pop_input_reg   <= sig_sm_pop_input_reg;



  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: REG_INPUT_QUAL
  --
  -- Process Description:
  --  Implements the input command qualifier holding register
  --
  -------------------------------------------------------------
  REG_INPUT_QUAL : process (primary_aclk)
     begin
       if (primary_aclk'event and primary_aclk = '1') then
          if (mmap_reset            = '1' or
              sig_pop_input_reg     = '1' or
              sig_calc_error_pushed = '1') then

            sig_input_burst_type_reg          <=  '0';
            sig_input_tag_reg                 <=  (others => '0');
            sig_input_dsa_reg                 <=  (others => '0');
            sig_input_drr_reg                 <=  '0';
            sig_input_eof_reg                 <=  '0';

            sig_input_reg_empty               <=  '1';
            sig_input_reg_full                <=  '0';

          elsif (sig_push_input_reg = '1') then

            sig_input_burst_type_reg          <=  sig_cmd_type_slice;
            sig_input_tag_reg                 <=  sig_cmd_tag_slice;
            sig_input_dsa_reg                 <=  sig_cmd_dsa_slice;
            sig_input_drr_reg                 <=  sig_cmd_drr_slice;
            sig_input_eof_reg                 <=  sig_cmd_eof_slice;

            sig_input_reg_empty               <=  '0';
            sig_input_reg_full                <=  '1';

          else
            null; -- Hold current State
          end if;
       end if;
     end process REG_INPUT_QUAL;





----------------------------------------------------------------------
-- Calculation Error Logic


-------------------------------------------------------------
-- Synchronous Process with Sync Reset
--
-- Label: IMP_CALC_ERROR_FLOP
--
-- Process Description:
--   Implements the flop for the Calc Error flag, Once set,
-- the flag cannot be cleared until a reset is issued.
--
-------------------------------------------------------------
IMP_CALC_ERROR_FLOP : process (primary_aclk)
   begin
     if (primary_aclk'event and primary_aclk = '1') then
        if (mmap_reset = '1') then
          sig_calc_error_reg <= '0';
        elsif (sig_push_input_reg = '1' and
               sig_calc_error_reg = '0') then
          sig_calc_error_reg <= sig_btt_is_zero;
        else
          Null;  -- hold the current state
        end if;
     end if;
   end process IMP_CALC_ERROR_FLOP;



-------------------------------------------------------------
-- Synchronous Process with Sync Reset
--
-- Label: IMP_CALC_ERROR_PUSHED
--
-- Process Description:
--   Implements the flop for generating a flag indicating the
-- calculation error flag has been pushed to the addr and data
-- controllers.
--
-------------------------------------------------------------
IMP_CALC_ERROR_PUSHED : process (primary_aclk)
   begin
     if (primary_aclk'event and primary_aclk = '1') then
        if (mmap_reset = '1') then
          sig_calc_error_pushed <= '0';
        elsif (sig_push_xfer_reg = '1' and
               sig_calc_error_pushed = '0') then
          sig_calc_error_pushed <= sig_calc_error_reg;
        else
          Null;  -- hold the current state
        end if;
     end if;
   end process IMP_CALC_ERROR_PUSHED;









---------------------------------------------------------------------
-- Strobe Generator Logic

 sig_xfer_strt_strb2use <=  sig_xfer_strt_strb_imreg
   When (sig_first_xfer = '1')
   Else (others => '1');

 sig_xfer_end_strb2use <= sig_xfer_strt_strb2use
   When (sig_xfer_len_eq_0_reg = '1' and
         sig_first_xfer    = '1')
   else sig_xfer_end_strb_imreg
   When (sig_last_xfer_valid = '1')
   Else (others => '1');


 
 
 
  ----------------------------------------------------------
  -- Intermediate registers for STBGEN Fmax path
 
  
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_IM_STBGEN_REGS
  --
  -- Process Description:
  --  Intermediate registers for Strobegen inputs to break
  -- long timing paths.
  --
  -------------------------------------------------------------
  IMP_IM_STBGEN_REGS : process (primary_aclk)
    begin
      if (primary_aclk'event and primary_aclk = '1') then
         if (mmap_reset = '1') then

           sig_strbgen_addr_reg       <= (others => '0');
           sig_strbgen_bytes_reg      <= (others => '0');
           sig_finish_addr_offset_reg <= (others => '0');
  
         elsif (sig_sm_ld_calc1_reg = '1') then

           sig_strbgen_addr_reg       <= sig_strbgen_addr;
           sig_strbgen_bytes_reg      <= sig_strbgen_bytes;
           sig_finish_addr_offset_reg <= sig_finish_addr_offset;
  
         else
  
           null;  -- hold state
  
         end if; 
      end if;       
    end process IMP_IM_STBGEN_REGS; 
 
 
 
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_IM_STBGEN_OUT_REGS
  --
  -- Process Description:
  --  Intermediate registers for Strobegen outputs to break
  -- long timing paths.
  --
  -------------------------------------------------------------
  IMP_IM_STBGEN_OUT_REGS : process (primary_aclk)
    begin
      if (primary_aclk'event and primary_aclk = '1') then
         if (mmap_reset = '1') then

           sig_xfer_strt_strb_imreg     <= (others => '0');
           sig_xfer_end_strb_imreg      <= (others => '0');
           sig_xfer_len_eq_0_reg        <= '0';
  
         elsif (sig_sm_ld_calc2_reg = '1') then

           sig_xfer_strt_strb_imreg      <= sig_xfer_strt_strb;
           sig_xfer_end_strb_imreg       <= sig_xfer_end_strb;
           sig_xfer_len_eq_0_reg         <= sig_xfer_len_eq_0;
  
         else
  
           null;  -- hold state
  
         end if; 
      end if;       
    end process IMP_IM_STBGEN_OUT_REGS; 
 
 
 
 
 
 
 
 
 
 

 ------------------------------------------------------------
 -- Instance: I_STRT_STRB_GEN
 --
 -- Description:
 --  Strobe generator instance
 --
 ------------------------------------------------------------
 I_STRT_STRB_GEN : entity axi_master_burst_v1_00_a.axi_master_burst_strb_gen
 generic map (

   C_ADDR_MODE       =>  0                          ,  --  0 = normal, 1 = Address only
   C_STRB_WIDTH      =>  BYTES_PER_DBEAT            ,  
   C_OFFSET_WIDTH    =>  STRBGEN_ADDR_SLICE_WIDTH   ,  
   C_NUM_BYTES_WIDTH =>  STRBGEN_ADDR_SLICE_WIDTH+1    

   )
 port map (

   start_addr_offset =>  sig_strbgen_addr_reg       ,  
   num_valid_bytes   =>  sig_strbgen_bytes_reg      ,  
   strb_out          =>  sig_xfer_strt_strb   

   );




 ------------------------------------------------------------
 -- Instance: I_END_STRB_GEN
 --
 -- Description:
 --  Strobe generator instance
 --
 ------------------------------------------------------------
 I_END_STRB_GEN : entity axi_master_burst_v1_00_a.axi_master_burst_strb_gen
 generic map (

   C_ADDR_MODE       =>  1                        ,  -- 0 = normal, 1 = Address only
   C_STRB_WIDTH      =>  BYTES_PER_DBEAT          ,  
   C_OFFSET_WIDTH    =>  STRBGEN_ADDR_SLICE_WIDTH ,  
   C_NUM_BYTES_WIDTH =>  STRBGEN_ADDR_SLICE_WIDTH    

   )
 port map (

   start_addr_offset =>  STRBGEN_ADDR_0             ,  
   num_valid_bytes   =>  sig_finish_addr_offset_reg ,  
   strb_out          =>  sig_xfer_end_strb           

   );








   -----------------------------------------------------------------
   -- Output xfer register design

   sig_push_xfer_reg <= (sig_ld_xfer_reg and sig_xfer_reg_empty);

                        -- Data taking xfer after Addr and DRE
   sig_pop_xfer_reg  <= (sig_clr_cmd2data_valid and not(sig_cmd2addr_valid) and not(sig_cmd2dre_valid))  or
                        -- Addr taking xfer after Data and DRE
                        (sig_clr_cmd2addr_valid and not(sig_cmd2data_valid) and not(sig_cmd2dre_valid))  or 
                        -- DRE taking xfer after Data and ADDR
                        (sig_clr_cmd2dre_valid  and not(sig_cmd2data_valid) and not(sig_cmd2addr_valid)) or  
                        
                        -- data and Addr taking xfer after DRE
                        (sig_clr_cmd2data_valid and sig_clr_cmd2addr_valid and not(sig_cmd2dre_valid))   or 
                        -- Addr and DRE taking xfer after Data
                        (sig_clr_cmd2addr_valid and sig_clr_cmd2dre_valid  and not(sig_cmd2data_valid))  or 
                        -- Data and DRE taking xfer after Addr
                        (sig_clr_cmd2data_valid and sig_clr_cmd2dre_valid  and not(sig_cmd2addr_valid))  or  
                        
                        -- Addr, Data,  and DRE all taking xfer
                        (sig_clr_cmd2data_valid and sig_clr_cmd2addr_valid and sig_clr_cmd2dre_valid);       



   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_OUTPUT_QUAL
   --
   -- Process Description:
   --  Implements the output xfer qualifier holding register
   --
   -------------------------------------------------------------
   REG_OUTPUT_QUAL : process (primary_aclk)
      begin
        if (primary_aclk'event and primary_aclk = '1') then
           if (mmap_reset        = '1' or
              (sig_pop_xfer_reg  = '1' and
               sig_push_xfer_reg = '0')) then

             sig_xfer_addr_reg       <=  (others => '0');
             sig_xfer_type_reg       <=  '0';
             sig_xfer_len_reg        <=  (others => '0');
             sig_xfer_tag_reg        <=  (others => '0');
             sig_xfer_dsa_reg        <=  (others => '0');
             sig_xfer_drr_reg        <=  '0';
             sig_xfer_eof_reg        <=  '0';
             sig_xfer_strt_strb_reg  <=  (others => '0');
             sig_xfer_end_strb_reg   <=  (others => '0');
             sig_xfer_is_seq_reg     <=  '0';
             sig_xfer_cmd_cmplt_reg  <=  '0';
             sig_xfer_calc_err_reg   <=  '0';
             sig_xfer_btt_reg        <=  (others => '0');
             sig_xfer_dre_eof_reg    <=  '0';

             sig_xfer_reg_empty      <=  '1';
             sig_xfer_reg_full       <=  '0';

           elsif (sig_push_xfer_reg = '1') then

             sig_xfer_addr_reg       <=  sig_xfer_address         ;
             sig_xfer_type_reg       <=  sig_input_burst_type_reg ;
             sig_xfer_len_reg        <=  sig_xfer_len             ;
             sig_xfer_tag_reg        <=  sig_input_tag_reg        ;
             sig_xfer_dsa_reg        <=  sig_input_dsa_reg        ;
             sig_xfer_drr_reg        <=  sig_input_drr_reg and
                                         sig_first_xfer           ;
             sig_xfer_eof_reg        <=  sig_input_eof_reg and
                                         sig_last_xfer_valid      ;
             sig_xfer_strt_strb_reg  <=  sig_xfer_strt_strb2use   ;
             sig_xfer_end_strb_reg   <=  sig_xfer_end_strb2use    ;
             sig_xfer_is_seq_reg     <=  not(sig_last_xfer_valid) ;
             sig_xfer_cmd_cmplt_reg  <=  sig_last_xfer_valid or
                                         sig_calc_error_reg       ;
             sig_xfer_calc_err_reg   <=  sig_calc_error_reg       ;
             sig_xfer_btt_reg        <=  sig_input_xfer_btt       ;
             sig_xfer_dre_eof_reg    <=  sig_input_eof_reg        ;

             sig_xfer_reg_empty      <=  '0';
             sig_xfer_reg_full       <=  '1';

           else
             null; -- Hold current State
           end if;
        end if;
      end process REG_OUTPUT_QUAL;





  --------------------------------------------------------------
  -- BTT Counter Logic


  sig_ld_btt_cntr   <= sig_ld_addr_cntr;

  sig_decr_btt_cntr <= sig_incr_addr_cntr;



  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_BTT_CNTR
  --
  -- Process Description:
  -- Bytes to transfer counter implementation.
  --
  -------------------------------------------------------------
  IMP_BTT_CNTR : process (primary_aclk)
     begin
       if (primary_aclk'event and primary_aclk = '1') then
          if (mmap_reset = '1') then

            sig_btt_cntr <= (others => '0');

          elsif (sig_ld_btt_cntr = '1') then

            sig_btt_cntr <= UNSIGNED(sig_cmd_btt_slice);

          Elsif (sig_decr_btt_cntr = '1') Then

            sig_btt_cntr <= sig_btt_cntr-RESIZE(sig_addr_cntr_incr_imreg, CMD_BTT_WIDTH);

          else
            null;  -- hold current state
          end if;
       end if;
     end process IMP_BTT_CNTR;



  -- Convert to logic vector for the S2MM DRE use
  -- The DRE will only use this value prior to the first
  -- decrement of the BTT Counter. Using this saves a separate
  -- BTT register.
  sig_input_xfer_btt <= STD_LOGIC_VECTOR(sig_btt_cntr);


  -- Rip the Burst Count slice from BTT counter value
  sig_burst_cnt_slice <= sig_btt_cntr(CMD_BTT_WIDTH-1 downto BURST_CNT_LS_INDEX);



  sig_brst_cnt_eq_zero <= '1'
    When (sig_burst_cnt_slice = BRST_CNT_0)
    Else '0';

  sig_brst_cnt_eq_one <= '1'
    When (sig_burst_cnt_slice = BRST_CNT_1)
    Else '0';


  -- Rip the BTT residue field from the BTT counter value
  sig_btt_residue_slice   <=  sig_btt_cntr(BTT_RESIDUE_WIDTH-1 downto 0);



  -- Check for transfer length residue of zero prior to subtracting 1
  sig_no_btt_residue <= '1'
     when (sig_btt_residue_slice = BTT_RESIDUE_0)
     Else '0';


  -- Unaligned address compensation
  -- Add the number of starting address offset byte positions to the
  -- final byte change value needed to calculate the AXI LEN field

  sig_start_addr_offset_slice <=  sig_addr_cntr_lsh(DBEAT_RESIDUE_WIDTH-1 downto 0);

  sig_adjusted_addr_incr      <=  sig_addr_cntr_incr +
                                  RESIZE(sig_start_addr_offset_slice, ADDR_CNTR_WIDTH);







  -- adjust the address increment down by 1 byte to compensate
  -- for the LEN requirement of being N-1 data beats

  sig_byte_change_minus1 <=  sig_adjusted_addr_incr_reg-ADDR_CNTR_ONE;



  -- Rip the new transfer length value
  sig_xfer_len <=  STD_LOGIC_VECTOR(
                       RESIZE(
                          sig_byte_change_minus1(BTT_RESIDUE_WIDTH-1 downto
                                                 DBEAT_RESIDUE_WIDTH),
                       LEN_WIDTH)
                   );


  -- Check to see if the new xfer length is zero (1 data beat)
  sig_xfer_len_eq_0 <= '1'
    when (sig_xfer_len = XFER_LEN_ZERO)
    Else '0';



  -- Check for Last transfer condition
  sig_last_xfer_valid  <=  (sig_brst_cnt_eq_one and
                            sig_no_btt_residue  and
                            sig_addr_aligned)   or  -- always the last databeat case

                           ((sig_btt_lt_b2mbaa or sig_btt_eq_b2mbaa) and  -- less than a full burst remaining
                           (sig_brst_cnt_eq_zero and not(sig_no_btt_residue)));




  ------------------------------------------------------------
  -- If Generate
  --
  -- Label: GEN_ADDR_32
  --
  -- If Generate Description:
  -- Implements the Address Counter logic for the 32-bit
  -- address width case. The address counters are split into two
  -- 16-bit sections to improve Fmax convergence.
  --
  --
  ------------------------------------------------------------
  GEN_ADDR_32 : if (C_ADDR_WIDTH = 32) generate


     begin


       -- Populate the transfer address value by concatonating the
       -- address counter segments
       sig_xfer_address <= STD_LOGIC_VECTOR(sig_addr_cntr_msh) &
                           STD_LOGIC_VECTOR(sig_addr_cntr_lsh);


       -- Rip the LS bits of the LS Address Counter for the StrobeGen
       -- starting address offset
       sig_strbgen_addr  <=  STD_LOGIC_VECTOR(sig_addr_cntr_lsh(STRBGEN_ADDR_SLICE_WIDTH-1 downto 0));



       -- Check if the calcualted address increment (in bytes) is greater than the
       -- number of bytes that can be transfered per data beat
       sig_addr_incr_ge_bpdb <= '1'
         When (sig_addr_cntr_incr >= TO_UNSIGNED(BYTES_PER_DBEAT, ADDR_CNTR_WIDTH))
         Else '0';


       -- If the calculated address increment (in bytes) is greater than the
       -- number of bytes that can be transfered per data beat, then clip the
       -- strobegen byte value to the number of bytes per data beat, else use the
       -- increment value.
       sig_strbgen_bytes <=  STD_LOGIC_VECTOR(TO_UNSIGNED(BYTES_PER_DBEAT, STRBGEN_ADDR_SLICE_WIDTH+1))
         when (sig_addr_incr_ge_bpdb = '1')
         else STD_LOGIC_VECTOR(sig_addr_cntr_incr(STRBGEN_ADDR_SLICE_WIDTH downto 0));




       --------------------------------------------------------------------------
       -- Address Counter logic

       sig_ld_addr_cntr   <= sig_push_input_reg;

       -- don't increment address cntr if type is '0' (non-incrementing)
       sig_incr_addr_cntr <= sig_push_xfer_reg and
                             sig_input_burst_type_reg;



       sig_mbaa_addr_cntr_slice <= sig_addr_cntr_lsh(MBAA_ADDR_SLICE_WIDTH-1 downto 0);




       sig_bytes_to_mbaa <=  TO_UNSIGNED(BYTES_PER_MAX_BURST, ADDR_CNTR_WIDTH) -
                             RESIZE(sig_mbaa_addr_cntr_slice,ADDR_CNTR_WIDTH);



       sig_addr_aligned <= '1'
         when (sig_mbaa_addr_cntr_slice = BTT_RESIDUE_0)
         Else '0';




       -- Check to see if the jump to the Max Burst Aligned Address (mbaa) is less
       -- than or equal to the remaining bytes to transfer. If it is, then at least
       -- two tranfers have to be scheduled.
       sig_btt_lt_b2mbaa <= '1'
         when ((RESIZE(sig_btt_residue_slice, ADDR_CNTR_WIDTH) < sig_bytes_to_mbaa) and
               (sig_brst_cnt_eq_zero = '1'))

         Else '0';


       sig_btt_eq_b2mbaa <= '1'
         when ((RESIZE(sig_btt_residue_slice, ADDR_CNTR_WIDTH) = sig_bytes_to_mbaa) and
                (sig_brst_cnt_eq_zero = '1'))
         Else '0';



       -- Select the address counter increment value to use
       sig_addr_cntr_incr <= RESIZE(sig_btt_residue_slice, ADDR_CNTR_WIDTH)
         When (sig_btt_lt_b2mbaa = '1')
         else sig_bytes_to_mbaa
         when (sig_first_xfer = '1')
         else TO_UNSIGNED(BYTES_PER_MAX_BURST, ADDR_CNTR_WIDTH);



       -- calculate the next starting address after the current
       -- xfer completes
       sig_predict_addr_lsh     <=  sig_addr_cntr_lsh + sig_addr_cntr_incr;


       -- Predict next transfer's address offset for the Strobe Generator
       sig_finish_addr_offset   <= STD_LOGIC_VECTOR(sig_predict_addr_lsh(STRBGEN_ADDR_SLICE_WIDTH-1 downto 0));


       sig_addr_cntr_lsh_slv    <= STD_LOGIC_VECTOR(sig_addr_cntr_lsh);



       -- Determine if an address count lsh rollover is going to occur when
       -- jumping to the next starting address by comparing the MS bit of the
       -- current address lsh to the MS bit of the predicted address lsh .
       -- A transition of a '1' to a '0' is a rollover.
       sig_addr_lsh_rollover_im <= '1'
         when (
               (sig_addr_cntr_lsh_slv(ADDR_CNTR_WIDTH-1)    = '1') and
               (sig_predict_addr_lsh_imreg_slv(ADDR_CNTR_WIDTH-1) = '0')
              )
         Else '0';




          
        
             
             
       ----------------------------------------------------------
       -- Intermediate registers for reducing the Address Counter 
       -- Increment timing path
       ----------------------------------------------------------
      

        -- calculate the next starting address after the current
        -- xfer completes using intermediate register values
        sig_predict_addr_lsh_im        <=  sig_addr_cntr_lsh + sig_addr_cntr_incr_imreg;
        
        sig_predict_addr_lsh_imreg_slv <= STD_LOGIC_VECTOR(sig_predict_addr_lsh_imreg);
       
       
       
       -------------------------------------------------------------
       -- Synchronous Process with Sync Reset
       --
       -- Label: IMP_IM_ADDRINC_REG
       --
       -- Process Description:
       --  Intermediate registers for address counter increment to 
       -- break long timing paths.
       --
       -------------------------------------------------------------
       IMP_IM_ADDRINC_REG : process (primary_aclk)
         begin
           if (primary_aclk'event and primary_aclk = '1') then
              if (mmap_reset = '1') then

                sig_addr_cntr_incr_imreg   <= (others => '0');
       
              elsif (sig_sm_ld_calc1_reg = '1') then

                sig_addr_cntr_incr_imreg   <= sig_addr_cntr_incr;
       
              else
       
                null;  -- hold state
       
              end if; 
           end if;       
         end process IMP_IM_ADDRINC_REG; 
      
      
      
       -------------------------------------------------------------
       -- Synchronous Process with Sync Reset
       --
       -- Label: IMP_IM_PREDICT_ADDR_REG
       --
       -- Process Description:
       --  Intermediate register for predicted address to break up
       -- long timing paths.
       --
       -------------------------------------------------------------
       IMP_IM_PREDICT_ADDR_REG : process (primary_aclk)
         begin
           if (primary_aclk'event and primary_aclk = '1') then
              if (mmap_reset = '1') then

                sig_predict_addr_lsh_imreg     <= (others => '0');
       
              elsif (sig_sm_ld_calc2_reg = '1') then

                sig_predict_addr_lsh_imreg     <= sig_predict_addr_lsh_im;
       
              else
       
                null;  -- hold state
       
              end if; 
           end if;       
         end process IMP_IM_PREDICT_ADDR_REG; 
      
      
      
      
      
      
      
           
           
           
           
        
        
        
        

       -------------------------------------------------------------
       -- Synchronous Process with Sync Reset
       --
       -- Label: REG_ADDR_STUFF
       --
       -- Process Description:
       --  Implements a general register for address counter related
       -- things.
       --
       -------------------------------------------------------------
       REG_ADDR_STUFF : process (primary_aclk)
          begin
            if (primary_aclk'event and primary_aclk = '1') then
               if (mmap_reset = '1') then

                 sig_adjusted_addr_incr_reg <= (others => '0');

               else

                 sig_adjusted_addr_incr_reg <= sig_adjusted_addr_incr;

               end if;
            end if;
          end process REG_ADDR_STUFF;




       -------------------------------------------------------------
       -- Synchronous Process with Sync Reset
       --
       -- Label: IMP_LSH_ADDR_CNTR
       --
       -- Process Description:
       -- Least Significant Half Address counter implementation.
       --
       -------------------------------------------------------------
       IMP_LSH_ADDR_CNTR : process (primary_aclk)
          begin
            if (primary_aclk'event and primary_aclk = '1') then
               if (mmap_reset = '1') then

                 sig_addr_cntr_lsh <= (others => '0');

               elsif (sig_ld_addr_cntr = '1') then

                 sig_addr_cntr_lsh <= UNSIGNED(sig_cmd_addr_slice(ADDR_CNTR_WIDTH-1 downto 0));

               Elsif (sig_incr_addr_cntr = '1') Then

                 sig_addr_cntr_lsh <= sig_predict_addr_lsh_imreg;

               else
                 null;  -- hold current state
               end if;
            end if;
          end process IMP_LSH_ADDR_CNTR;




       -------------------------------------------------------------
       -- Synchronous Process with Sync Reset
       --
       -- Label: IMP_MSH_ADDR_CNTR
       --
       -- Process Description:
       -- Least Significant Half Address counter implementation.
       --
       -------------------------------------------------------------
       IMP_MSH_ADDR_CNTR : process (primary_aclk)
          begin
            if (primary_aclk'event and primary_aclk = '1') then
               if (mmap_reset = '1') then

                 sig_addr_cntr_msh <= (others => '0');

               elsif (sig_ld_addr_cntr = '1') then

                 sig_addr_cntr_msh <= UNSIGNED(sig_cmd_addr_slice((2*ADDR_CNTR_WIDTH)-1 downto ADDR_CNTR_WIDTH));

               Elsif (sig_incr_addr_cntr       = '1' and
                      sig_addr_lsh_rollover_im = '1') then

                 sig_addr_cntr_msh <= sig_addr_cntr_msh+ADDR_CNTR_ONE;

               else
                 null;  -- hold current state
               end if;
            end if;
          end process IMP_MSH_ADDR_CNTR;





      -------------------------------------------------------------
      -- Synchronous Process with Sync Reset
      --
      -- Label: IMP_FIRST_XFER_FLOP
      --
      -- Process Description:
      --  Implements the register flop for the first transfer flag.
      --
      -------------------------------------------------------------
      IMP_FIRST_XFER_FLOP : process (primary_aclk)
         begin
           if (primary_aclk'event and primary_aclk = '1') then
              if (mmap_reset         = '1' or
                  sig_incr_addr_cntr = '1') then

                sig_first_xfer <= '0';

              elsif (sig_ld_addr_cntr = '1') then

                sig_first_xfer <= '1';

              else
                null;  -- hold current state
              end if;
           end if;
         end process IMP_FIRST_XFER_FLOP;



     end generate GEN_ADDR_32;









  ------------------------------------------------------------
  -- If Generate
  --
  -- Label: GEN_ADDR_GT_32
  --
  -- If Generate Description:
  -- Implements the Address Counter logic for the case when
  -- the address width is greater than 32 bits.
  --
  ------------------------------------------------------------
  GEN_ADDR_GT_32 : if (C_ADDR_WIDTH > 32) generate


     begin

       -- No support for greater than 32-bit address


     end generate GEN_ADDR_GT_32;







  -- Addr and data Cntlr FIFO interface handshake logic ------------------------------

   sig_clr_cmd2data_valid    <= sig_cmd2data_valid and data2mstr_cmd_ready;

   sig_clr_cmd2addr_valid    <= sig_cmd2addr_valid and addr2mstr_cmd_ready;

   sig_clr_cmd2dre_valid     <= sig_cmd2dre_valid  and dre2mstr_cmd_ready;



   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: CMD2DATA_VALID_FLOP
   --
   -- Process Description:
   --  Implements the set/reset flop for the Command Valid control
   -- to the Data Controller Module.
   --
   -------------------------------------------------------------
   CMD2DATA_VALID_FLOP : process (primary_aclk)
      begin
        if (primary_aclk'event and primary_aclk = '1') then
           if (mmap_reset             = '1' or
               sig_clr_cmd2data_valid = '1') then

             sig_cmd2data_valid <= '0';

           elsif (sig_push_xfer_reg = '1') then

             sig_cmd2data_valid <= '1';

           else
             null; -- hold current state
           end if;
        end if;
      end process CMD2DATA_VALID_FLOP;




   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: CMD2ADDR_VALID_FLOP
   --
   -- Process Description:
   --  Implements the set/reset flop for the Command Valid control
   -- to the Address Controller Module.
   --
   -------------------------------------------------------------
   CMD2ADDR_VALID_FLOP : process (primary_aclk)
      begin
        if (primary_aclk'event and primary_aclk = '1') then
           if (mmap_reset             = '1' or
               sig_clr_cmd2addr_valid = '1') then

             sig_cmd2addr_valid <= '0';

           elsif (sig_push_xfer_reg = '1') then

             sig_cmd2addr_valid <= '1';

           else
             null; -- hold current state
           end if;
        end if;
      end process CMD2ADDR_VALID_FLOP;







   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: CMD2DRE_VALID_FLOP
   --
   -- Process Description:
   --  Implements the set/reset flop for the Command Valid control
   -- to the DRE Module (S2MM DRE Only).
   --
   -- Note that the S2MM DRE only needs to be loaded with a command
   -- for each parent command, not every child command.
   --
   -------------------------------------------------------------
   CMD2DRE_VALID_FLOP : process (primary_aclk)
      begin
        if (primary_aclk'event and primary_aclk = '1') then
           if (mmap_reset            = '1' or
               sig_clr_cmd2dre_valid = '1') then

             sig_cmd2dre_valid <= '0';

           elsif (sig_push_xfer_reg = '1' and
                  sig_first_xfer    = '1') then

             sig_cmd2dre_valid <= '1';

           else
             null; -- hold current state
           end if;
        end if;
      end process CMD2DRE_VALID_FLOP;









  -------------------------------------------------------------------------
  -- PCC State machine Logic





  -------------------------------------------------------------
  -- Combinational Process
  --
  -- Label: PCC_SM_COMBINATIONAL
  --
  -- Process Description:
  -- PCC State Machine combinational implementation
  --
  -------------------------------------------------------------
  PCC_SM_COMBINATIONAL : process (sig_pcc_sm_state     ,
                                  sig_parent_done      ,
                                  sig_push_input_reg   ,
                                  sig_push_xfer_reg    ,
                                  sig_calc_error_pushed)
     begin

       -- SM Defaults
       sig_pcc_sm_state_ns     <=  INIT;
       sig_sm_halt_ns          <=  '0';
       sig_sm_ld_xfer_reg_ns   <=  '0';
       sig_sm_pop_input_reg_ns <=  '0';
       sig_sm_ld_calc1_reg_ns  <=  '0';
       sig_sm_ld_calc2_reg_ns  <=  '0';


       case sig_pcc_sm_state is

         --------------------------------------------
         when INIT =>

           sig_pcc_sm_state_ns  <=  WAIT_FOR_CMD;
           sig_sm_halt_ns       <=  '1';

         --------------------------------------------
         when WAIT_FOR_CMD =>

           If (sig_push_input_reg = '1') Then

             sig_pcc_sm_state_ns     <=  CALC_1;
             sig_sm_ld_calc1_reg_ns  <=  '1';


           else

             sig_pcc_sm_state_ns <=  WAIT_FOR_CMD;

           End if;

         --------------------------------------------
         when CALC_1 =>

           sig_pcc_sm_state_ns     <=  CALC_2;
           sig_sm_ld_calc2_reg_ns  <=  '1';
           

         --------------------------------------------
         when CALC_2 =>

           sig_pcc_sm_state_ns    <=  WAIT_ON_XFER_PUSH;
           sig_sm_ld_xfer_reg_ns  <= '1';


         --------------------------------------------
         when WAIT_ON_XFER_PUSH =>

           if (sig_push_xfer_reg = '1') then

             sig_pcc_sm_state_ns <=  CHK_IF_DONE;

           else  -- wait until output register is loaded

             sig_pcc_sm_state_ns <=  WAIT_ON_XFER_PUSH;


           end if;


         --------------------------------------------
         when CHK_IF_DONE =>

           If (sig_calc_error_pushed = '1') then -- Internal error, go to trap

             sig_pcc_sm_state_ns <=  ERROR_TRAP;
             sig_sm_halt_ns      <=  '1';

           elsif (sig_parent_done = '1') Then  -- done with parent command

             sig_pcc_sm_state_ns     <=  WAIT_FOR_CMD;
             sig_sm_pop_input_reg_ns <= '1';

           else  -- Still breaking up parent command

             sig_pcc_sm_state_ns     <=  CALC_1;
             sig_sm_ld_calc1_reg_ns  <=  '1';

           end if;


         --------------------------------------------
         when ERROR_TRAP =>

           sig_pcc_sm_state_ns <=  ERROR_TRAP;
           sig_sm_halt_ns      <=  '1';

         --------------------------------------------
         when others =>

           sig_pcc_sm_state_ns <=  INIT;

       end case;



     end process PCC_SM_COMBINATIONAL;




  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: PCC_SM_REGISTERED
  --
  -- Process Description:
  -- PCC State Machine registered implementation
  --
  -------------------------------------------------------------
  PCC_SM_REGISTERED : process (primary_aclk)
     begin
       if (primary_aclk'event and primary_aclk = '1') then
          if (mmap_reset = '1') then

            sig_pcc_sm_state     <= INIT;
            sig_sm_halt_reg      <= '1' ;
            sig_sm_pop_input_reg <= '0' ;
            sig_sm_ld_calc1_reg  <= '0' ;
            sig_sm_ld_calc2_reg  <= '0' ;

          else

            sig_pcc_sm_state     <=  sig_pcc_sm_state_ns    ;
            sig_sm_halt_reg      <=  sig_sm_halt_ns         ;
            sig_sm_pop_input_reg <=  sig_sm_pop_input_reg_ns;
            sig_sm_ld_calc1_reg  <=  sig_sm_ld_calc1_reg_ns ;
            sig_sm_ld_calc2_reg  <=  sig_sm_ld_calc2_reg_ns ;

          end if;
       end if;
     end process PCC_SM_REGISTERED;









  ------------------------------------------------------------------
  -- Transfer Register Load Enable logic


  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: LD_XFER_REG_FLOP
  --
  -- Process Description:
  -- Sample and Hold FLOP for signaling a load of the output
  -- xfer register.
  --
  -------------------------------------------------------------
  LD_XFER_REG_FLOP : process (primary_aclk)
     begin
       if (primary_aclk'event and primary_aclk = '1') then
          if (mmap_reset        = '1' or
              sig_push_xfer_reg = '1') then

            sig_ld_xfer_reg <=  '0';

          Elsif (sig_sm_ld_xfer_reg_ns = '1') Then

            sig_ld_xfer_reg <=  '1';

          else

            null;   -- hold current state

          end if;
       end if;
     end process LD_XFER_REG_FLOP;






  ------------------------------------------------------------------
  -- Parent Done flag logic


  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: PARENT_DONE_FLOP
  --
  -- Process Description:
  -- Sample and Hold FLOP for signaling a load of the output
  -- xfer register.
  --
  -------------------------------------------------------------
  PARENT_DONE_FLOP : process (primary_aclk)
     begin
       if (primary_aclk'event and primary_aclk = '1') then
          if (mmap_reset         = '1' or
              sig_push_input_reg = '1') then

            sig_parent_done <=  '0';

          Elsif (sig_push_xfer_reg = '1') Then

            sig_parent_done <=  sig_last_xfer_valid;

          else

            null;   -- hold current state

          end if;
       end if;
     end process PARENT_DONE_FLOP;











end implementation;
