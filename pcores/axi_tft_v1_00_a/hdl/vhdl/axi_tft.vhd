-------------------------------------------------------------------
-- (c) Copyright 1984 - 2012 Xilinx, Inc. All rights reserved.	 --
--		                                						 --
-- This file contains confidential and proprietary information	 --
-- of Xilinx, Inc. and is protected under U.S. and	        	 --
-- international copyright and other intellectual property  	 --
-- laws.							                             --
--								                                 --
-- DISCLAIMER							                         --
-- This disclaimer is not a license and does not grant any	     --
-- rights to the materials distributed herewith. Except as	     --
-- otherwise provided in a valid license issued to you by	     --
-- Xilinx, and to the maximum extent permitted by applicable	 --
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND	     --
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES	 --
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING	 --
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-	     --
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and	     --
-- (2) Xilinx shall not be liable (whether in contract or tort,	 --
-- including negligence, or under any other theory of		     --
-- liability) for any loss or damage of any kind or nature	     --
-- related to, arising under or in connection with these	     --
-- materials, including for any direct, or any indirect,	     --
-- special, incidental, or consequential loss or damage		     --
-- (including loss of data, profits, goodwill, or any type of	 --
-- loss or damage suffered as a result of any action brought	 --
-- by a third party) even if such damage or loss was		     --
-- reasonably foreseeable or Xilinx had been advised of the	     --
-- possibility of the same.					                     --
--								                                 --
-- CRITICAL APPLICATIONS					                     --
-- Xilinx products are not designed or intended to be fail-	     --
-- safe, or for use in any application requiring fail-safe	     --
-- performance, such as life-support or safety devices or	     --
-- systems, Class III medical devices, nuclear facilities,	     --
-- applications related to the deployment of airbags, or any	 --
-- other applications that could lead to death, personal	     --
-- injury, or severe property or environmental damage		     --
-- (individually and collectively, "Critical			         --
-- Applications"). Customer assumes the sole risk and		     --
-- liability of any use of Xilinx products in Critical		     --
-- Applications, subject only to applicable laws and	  	     --
-- regulations governing limitations on product liability.	     --
--								                                 --
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS	     --
-- PART OF THIS FILE AT ALL TIMES. 				                 --
-------------------------------------------------------------------
-- axi_tft.vhd - entity/architecture pair 
-------------------------------------------------------------------------------
-- Filename:      axi_tft.vhd
-- Version:       v1.00.a
-- Description:   Top level design file for AXI TFT controller. It instantiate 
--                AXI maste/slave interface and TFT controller logic. This
--                supports display resolution 640*480 pixels at 25 MHz display
--                clock for 60 Hz TFT refresh rate.
--
-- VHDL-Standard: VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--                  -- axi_tft.vhd
--                      -- axi_master_burst.vhd
--                      -- axi_lite_ipif.vhd
--                      -- tft_controller.v
--                          -- line_buffer.v
--                          -- v_sync.v
--                          -- h_sync.v
--                          -- slave_register.v
--                          -- tft_interface.v
--                              -- iic_init.v
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
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------
-- proc common package of the proc common library is used for different 
-- function declarations
-------------------------------------------------------------------------------
library proc_common_v3_00_a;
use proc_common_v3_00_a.ipif_pkg.INTEGER_ARRAY_TYPE;
use proc_common_v3_00_a.ipif_pkg.SLV64_ARRAY_TYPE;
use proc_common_v3_00_a.ipif_pkg.calc_num_ce;
use proc_common_v3_00_a.family.all;
use proc_common_v3_00_a.family_support.all;

-------------------------------------------------------------------------------
-- axi_lite_ipif_v1_01_a library is used for axi_lite_ipif 
-- component declarations
-------------------------------------------------------------------------------
library axi_lite_ipif_v1_01_a;
use axi_lite_ipif_v1_01_a.axi_lite_ipif;

-------------------------------------------------------------------------------
-- axi_master_burst_v1_00_a library is used for axi_master_burst 
-- component declarations
-------------------------------------------------------------------------------
library axi_master_burst_v1_00_a;
use axi_master_burst_v1_00_a.axi_master_burst;

-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------
-- Definition of Generics:
--   C_FAMILY                 -- Xilinx FPGA family
--
-- -- TFT Controller Generics
------------------------------------
--   C_TFT_INTERFACE          -- Specifies TFT display interface (VGA/DVI)
--   C_I2C_SLAVE_ADDR         -- I2C slave address of chrontel chip  
--   C_DEFAULT_TFT_BASE_ADDR  -- TFT Video memory base address
--
-- --  AXI Master Burst Interface Generics
------------------------------------
--   C_M_AXI_ADDR_WIDTH            -- AXI master: address bus width
--   C_M_AXI_DATA_WIDTH            -- AXI master: data bus width
--
-- --  AXI Slave Single Interface Generics
------------------------------------
--
--
-- Definition of Ports:
-- -- System Interface signals
------------------------------------
--   S_AXI_ACLK              -- PLB main bus clock
--   S_AXI_ARESETN              -- PLB main bus reset
--   M_AXI_ACLK              -- PLB main bus Clock
--   M_AXI_ARESETN              -- PLB main bus Reset
--   MD_ERROR              -- Master detected error status output
--   IP2INTC_Irpt          -- Interrupt to processor
--
-- -- AXI Master Interface signals
------------------------------------
---- MMap Read Address Channel                                              -- AXI4
--    M_AXI_ARREADY               : in  std_logic                          ;-- AXI4
--    M_AXI_ARVALID               : out std_logic                          ;-- AXI4
--    M_AXI_ARADDR                : out std_logic_vector                    -- AXI4
--                                      (C_M_AXI_ADDR_WIDTH-1 downto 0)    ;-- AXI4
--    M_AXI_ARLEN                 : out std_logic_vector(7 downto 0)       ;-- AXI4
--    M_AXI_ARSIZE                : out std_logic_vector(2 downto 0)       ;-- AXI4
--    M_AXI_ARBURST               : out std_logic_vector(1 downto 0)       ;-- AXI4
--    M_AXI_ARPROT                : out std_logic_vector(2 downto 0)       ;-- AXI4
--    M_AXI_ARCACHE               : out std_logic_vector(3 downto 0)       ;-- AXI4
--                                                                          -- AXI4
--    -- MMap Read Data Channel                                             -- AXI4
--    M_AXI_RREADY                : out std_logic                          ;-- AXI4
--    M_AXI_RVALID                : in  std_logic                          ;-- AXI4
--    M_AXI_RDATA                 : in  std_logic_vector                    -- AXI4
--                                      (C_M_AXI_DATA_WIDTH-1 downto 0)    ;-- AXI4
--    M_AXI_RRESP                 : in  std_logic_vector(1 downto 0)       ;-- AXI4
--    M_AXI_RLAST                 : in  std_logic                          ;-- AXI4
---- Write Address Channel                                                  -- AXI4
--    M_AXI_AWREADY               : in  std_logic                          ; -- AXI4
--    M_AXI_AWVALID               : out std_logic                          ; -- AXI4
--    M_AXI_AWADDR                : out std_logic_vector                     -- AXI4
--                                      (C_M_AXI_ADDR_WIDTH-1 downto 0)    ; -- AXI4
--    M_AXI_AWLEN                 : out std_logic_vector(7 downto 0)       ; -- AXI4
--    M_AXI_AWSIZE                : out std_logic_vector(2 downto 0)       ; -- AXI4
--    M_AXI_AWBURST               : out std_logic_vector(1 downto 0)       ; -- AXI4
--    M_AXI_AWPROT                : out std_logic_vector(2 downto 0)       ; -- AXI4
--    M_AXI_AWCACHE               : out std_logic_vector(3 downto 0)       ; -- AXI4
--                                                                           -- AXI4
--    -- Write Data Channel                                                  -- AXI4
--    M_AXI_WREADY                : in  std_logic                          ; -- AXI4
--    M_AXI_WVALID                : out std_logic                          ; -- AXI4
--    M_AXI_WDATA                 : out std_logic_vector                     -- AXI4
--                                      (C_M_AXI_DATA_WIDTH-1 downto 0)    ; -- AXI4
--    M_AXI_WSTRB                 : out std_logic_vector                     -- AXI4
--                                      ((C_M_AXI_DATA_WIDTH/8)-1 downto 0); -- AXI4
--    M_AXI_WLAST                 : out std_logic                          ; -- AXI4
--    -- Write Response Channel                                              -- AXI4
--    M_AXI_BREADY                : out std_logic                          ; -- AXI4
--    M_AXI_BVALID                : in  std_logic                          ; -- AXI4
--    M_AXI_BRESP                 : in  std_logic_vector(1 downto 0)       ; -- AXI4
--
-- -- AXI Slave Interface signals
------------------------------------
-- S_AXI_ACLK            -- AXI Clock
-- S_AXI_ARESETN         -- AXI Reset
-- S_AXI_AWADDR          -- AXI Write address
-- S_AXI_AWVALID         -- Write address valid
-- S_AXI_AWREADY         -- Write address ready
-- S_AXI_WDATA           -- Write data
-- S_AXI_WSTRB           -- Write strobes
-- S_AXI_WVALID          -- Write valid
-- S_AXI_WREADY          -- Write ready
-- S_AXI_BRESP           -- Write response
-- S_AXI_BVALID          -- Write response valid
-- S_AXI_BREADY          -- Response ready
-- S_AXI_ARADDR          -- Read address
-- S_AXI_ARVALID         -- Read address valid
-- S_AXI_ARREADY         -- Read address ready
-- S_AXI_RDATA           -- Read data
-- S_AXI_RRESP           -- Read response
-- S_AXI_RVALID          -- Read valid
-- S_AXI_RREADY          -- Read ready
--
-- TFT Interface Signals
------------------------------------
--   SYS_TFT_Clk           -- TFT input clock
--
-- -- TFT Common Interface Signals
------------------------------------
--   TFT_HSYNC             -- TFT Hsync 
--   TFT_VSYNC             -- TFT Vsync 
--   TFT_DE                -- TFT Data enable
--   TFT_DPS               -- TFT display scan pin  
--
-- -- TFT VGA Interface Signals
------------------------------------
--   TFT_VGA_CLK           -- TFT VGA clock output
--   TFT_VGA_R             -- TFT VGA Red pixel data
--   TFT_VGA_G             -- TFT VGA Green pixel data
--   TFT_VGA_B             -- TFT VGA Blue pixel data
--
-- -- TFT DVI Interface Signals
------------------------------------
--   TFT_DVI_CLK_P         -- TFT DVI differntial clock P output
--   TFT_DVI_CLK_N         -- TFT DVI differntial clock N output
--   TFT_DVI_DATA          -- TFT DVI RGB pixel data
--
-- -- Chrontel I2C Interface Signals
------------------------------------
--   TFT_IIC_SCL_I         -- I2C clock input
--   TFT_IIC_SCL_O         -- I2C clock output
--   TFT_IIC_SCL_T         -- I2C clock tristate cntrol
--   TFT_IIC_SDA_I         -- I2C data input
--   TFT_IIC_SDA_O         -- I2C data output
--   TFT_IIC_SDA_T         -- I2C data tristate cntrol
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------
entity axi_tft is
  generic
  (

    C_FAMILY                : string                    := "virtex5";
    C_INSTANCE              : string                    := "axi_tft_0";
    ------------------------------------------------------------------
    -- TFT Controller generics
    C_TFT_INTERFACE         : integer range 0 to 1      := 1; -- (0:VGA, 1:DVI)
    C_I2C_SLAVE_ADDR        : std_logic_vector          := "1110110";
    C_DEFAULT_TFT_BASE_ADDR : std_logic_vector          := X"F0000000";
    ------------------------------------------------------------------
    -- AXI Master Burst Interface  generics
    C_M_AXI_ADDR_WIDTH      : integer range 32 to 32    := 32;
    C_M_AXI_DATA_WIDTH      : integer range 32 to 128   := 32;
    C_MAX_BURST_LEN         : Integer range 16 to  256 :=  16
    ------------------------------------------------------------------
    -- AXI Slave Interface generics --Need to decide Ravi
    ------------------------------------------------------------------
  );
 port
  (
       -------------------
    -- SYSTEM INTERFACE SIGNALS
       -------------------
    S_AXI_ACLK              : in  std_logic;
    S_AXI_ARESETN           : in  std_logic;
    M_AXI_ACLK              : in  std_logic;
    M_AXI_ARESETN           : in  std_logic;
    MD_ERROR                : out std_logic;
    IP2INTC_Irpt            : out std_logic;
       --------------------------------------
     -- AXI Master Interface signals
       --------------------------------------
-- MMap Read Address Channel                                              -- AXI4
    M_AXI_ARREADY               : in  std_logic                          ;-- AXI4
    M_AXI_ARVALID               : out std_logic                          ;-- AXI4
    M_AXI_ARADDR                : out std_logic_vector                    -- AXI4
                                      (C_M_AXI_ADDR_WIDTH-1 downto 0)    ;-- AXI4
    M_AXI_ARLEN                 : out std_logic_vector(7 downto 0)       ;-- AXI4
    M_AXI_ARSIZE                : out std_logic_vector(2 downto 0)       ;-- AXI4
    M_AXI_ARBURST               : out std_logic_vector(1 downto 0)       ;-- AXI4
    M_AXI_ARPROT                : out std_logic_vector(2 downto 0)       ;-- AXI4
    M_AXI_ARCACHE               : out std_logic_vector(3 downto 0)       ;-- AXI4
                                                                          -- AXI4
-- MMap Read Data Channel                                                 -- AXI4
    M_AXI_RREADY                : out std_logic                          ;-- AXI4
    M_AXI_RVALID                : in  std_logic                          ;-- AXI4
    M_AXI_RDATA                 : in  std_logic_vector                    -- AXI4
                                      (C_M_AXI_DATA_WIDTH-1 downto 0)    ;-- AXI4
    M_AXI_RRESP                 : in  std_logic_vector(1 downto 0)       ;-- AXI4
    M_AXI_RLAST                 : in  std_logic                          ;-- AXI4
-- Write Address Channel                                                  -- AXI4
    M_AXI_AWREADY               : in  std_logic                          ; -- AXI4
    M_AXI_AWVALID               : out std_logic                          ; -- AXI4
    M_AXI_AWADDR                : out std_logic_vector                     -- AXI4
                                      (C_M_AXI_ADDR_WIDTH-1 downto 0)    ; -- AXI4
    M_AXI_AWLEN                 : out std_logic_vector(7 downto 0)       ; -- AXI4
    M_AXI_AWSIZE                : out std_logic_vector(2 downto 0)       ; -- AXI4
    M_AXI_AWBURST               : out std_logic_vector(1 downto 0)       ; -- AXI4
    M_AXI_AWPROT                : out std_logic_vector(2 downto 0)       ; -- AXI4
    M_AXI_AWCACHE               : out std_logic_vector(3 downto 0)       ; -- AXI4
                                                                           -- AXI4
    -- Write Data Channel                                                  -- AXI4
    M_AXI_WREADY                : in  std_logic                          ; -- AXI4
    M_AXI_WVALID                : out std_logic                          ; -- AXI4
    M_AXI_WDATA                 : out std_logic_vector                     -- AXI4
                                      (C_M_AXI_DATA_WIDTH-1 downto 0)    ; -- AXI4
    M_AXI_WSTRB                 : out std_logic_vector                     -- AXI4
                                      ((C_M_AXI_DATA_WIDTH/8)-1 downto 0); -- AXI4
    M_AXI_WLAST                 : out std_logic                          ; -- AXI4
    -- Write Response Channel                                              -- AXI4
    M_AXI_BREADY                : out std_logic                          ; -- AXI4
    M_AXI_BVALID                : in  std_logic                          ; -- AXI4
    M_AXI_BRESP                 : in  std_logic_vector(1 downto 0)       ; -- AXI4
       --------------------------------------
     -- AXI Slave Interface signals
       --------------------------------------
    S_AXI_AWADDR                : in  std_logic_vector
                                  (31 downto 0);
    S_AXI_AWVALID               : in  std_logic;
    S_AXI_AWREADY               : out std_logic;
    S_AXI_WDATA                 : in  std_logic_vector
                                  (31 downto 0);
    S_AXI_WSTRB                 : in  std_logic_vector
                                  (3 downto 0);
    S_AXI_WVALID                : in  std_logic;
    S_AXI_WREADY                : out std_logic;
    S_AXI_BRESP                 : out std_logic_vector(1 downto 0);
    S_AXI_BVALID                : out std_logic;
    S_AXI_BREADY                : in  std_logic;
    S_AXI_ARADDR                : in  std_logic_vector
                                  (31 downto 0);
    S_AXI_ARVALID               : in  std_logic;
    S_AXI_ARREADY               : out std_logic;
    S_AXI_RDATA                 : out std_logic_vector
                                  (31 downto 0);
    S_AXI_RRESP                 : out std_logic_vector(1 downto 0);
    S_AXI_RVALID                : out std_logic;
    S_AXI_RREADY                : in  std_logic;

       ----------------------
    -- TFT INTERFACE SIGNALS
       ----------------------
    SYS_TFT_Clk             : in  std_logic;

    -- TFT Common Interface Signals
    TFT_HSYNC               : out  std_logic;
    TFT_VSYNC               : out  std_logic;
    TFT_DE                  : out  std_logic;
    TFT_DPS                 : out  std_logic;
    
    -- TFT VGA Interface Ports
    TFT_VGA_CLK             : out std_logic;
    TFT_VGA_R               : out std_logic_vector(5 downto 0);
    TFT_VGA_G               : out std_logic_vector(5 downto 0);
    TFT_VGA_B               : out std_logic_vector(5 downto 0);

    -- TFT DVI Interface Ports     
    TFT_DVI_CLK_P           : out  std_logic;
    TFT_DVI_CLK_N           : out  std_logic;
    TFT_DVI_DATA            : out  std_logic_vector(11 downto 0);

       -------------------------------------------
    -- I2C INTERFACE SIGNALS FOR CHRONTEL CH7301C
    -- DVI TRANSMITTER CHIP
       -------------------------------------------
    TFT_IIC_SCL_I           : in  std_logic;    
    TFT_IIC_SCL_O           : out std_logic;
    TFT_IIC_SCL_T           : out std_logic;
    TFT_IIC_SDA_I           : in  std_logic;
    TFT_IIC_SDA_O           : out std_logic;
    TFT_IIC_SDA_T           : out std_logic
  );

-------------------------------------------------------------------------------
-- PSFUTIL Attributes
-------------------------------------------------------------------------------
    ATTRIBUTE SIGIS          : string;
    ATTRIBUTE MAX_FANOUT     : string;

    ATTRIBUTE SIGIS       of S_AXI_ACLK    : signal is "CLK";
    ATTRIBUTE SIGIS       of M_AXI_ACLK    : signal is "CLK";
    ATTRIBUTE SIGIS       of S_AXI_ARESETN : signal is "RST";
    ATTRIBUTE SIGIS       of M_AXI_ARESETN : signal is "RST";
    --ATTRIBUTE SIGIS       of DCR_Clk       : signal is "CLK";
    --ATTRIBUTE SIGIS       of DCR_Rst       : signal is "RST";
    ATTRIBUTE SIGIS       of SYS_TFT_Clk   : signal is "CLK";
    ATTRIBUTE SIGIS       of IP2INTC_Irpt  : signal is "INTR_EDGE_RISING";
                                          
    ATTRIBUTE MAX_FANOUT  of S_AXI_ACLK    : signal is "10000";
    ATTRIBUTE MAX_FANOUT  of S_AXI_ARESETN : signal is "10000";
    ATTRIBUTE MAX_FANOUT  of M_AXI_ACLK    : signal is "10000";
    ATTRIBUTE MAX_FANOUT  of M_AXI_ARESETN : signal is "10000";

end entity axi_tft;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------

architecture imp of axi_tft is

-------------------------------------------------------------------------------
---- constant declaration for webtalk information
-------------------------------------------------------------------------------
  constant C_CORE_GENERATION_INFO : string := C_INSTANCE & ",axi_tft,{"
           & "c_family = "                & C_FAMILY
           & ",c_instance = "              & C_INSTANCE
           & ",c_tft_interface = "         & integer'image(C_TFT_INTERFACE)
           & ",c_m_axi_addr_width = "      & integer'image(C_M_AXI_ADDR_WIDTH)
           & ",c_m_axi_data_width = "      & integer'image(C_M_AXI_DATA_WIDTH) 
           & ",c_max_burst_len = "         & integer'image(C_MAX_BURST_LEN)
           & "}";

  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of imp : architecture is C_CORE_GENERATION_INFO;


  ------------------------------------------
  -- Array of base/high address pairs for each address range
  ------------------------------------------
  constant ZERO_ADDR_PAD  : std_logic_vector(31 downto 0) := (others => '0');
  constant USER_BASEADDR  : std_logic_vector := X"00000000";
  constant USER_HIGHADDR  : std_logic_vector := X"0000000F";

  constant IPIF_ARD_ADDR_RANGE_ARRAY  : SLV64_ARRAY_TYPE  := 
    (
      ZERO_ADDR_PAD & USER_BASEADDR,  -- user logic space base address
      ZERO_ADDR_PAD & USER_HIGHADDR   -- user logic space high address
    );

  ------------------------------------------
  -- Array of desired number of chip enables for each address range
  ------------------------------------------
  constant USER_MST_NUM_REG        : integer            := 4;
  constant USER_NUM_REG            : integer            := USER_MST_NUM_REG;
  constant IPIF_ARD_NUM_CE_ARRAY   : INTEGER_ARRAY_TYPE := 
    (
      0  => 4  -- number of ce for user logic master space
    );


  ------------------------------------------
  -- Inhibit the automatic inculsion of the Conversion Cycle and Burst Length 
  -- Expansion logic
  -- 0 = allow automatic inclusion of the CC and BLE logic
  -- 1 = inhibit automatic inclusion of the CC and BLE logic
  ------------------------------------------
  constant IPIF_INHIBIT_CC_BLE_INCLUSION  : integer     := 0;

  ------------------------------------------
  -- Width of the master address bus (32 only)
  ------------------------------------------
  constant USER_MST_AWIDTH         : integer := C_M_AXI_ADDR_WIDTH;

  ------------------------------------------
  -- TFT Base Address, I2C Slave Address,
  -- DCR base address
  -- Converting std_logic_vector to Integer
  ------------------------------------------
  constant DEFAULT_TFT_BASE_ADDR   : std_logic_vector(0 to 10) 
                                     := C_DEFAULT_TFT_BASE_ADDR(0 to 10);
  constant TFT_BASE_ADDR    : integer 
                              := CONV_INTEGER(DEFAULT_TFT_BASE_ADDR);
  
  constant I2C_SLAVE_ADDR   : integer := CONV_INTEGER(C_I2C_SLAVE_ADDR);
  
  -- Added for generating IO styles
  --constant V2P_IO           : boolean := supported(C_FAMILY, (u_FDDRRSE));
  --constant S3E_IO           : boolean := supported(C_FAMILY, (u_ODDR2));
  --constant V4_IO            : boolean := supported(C_FAMILY, (u_ODDR));
  
  -----------------------------------------------------------------------------
  -- Function: get_io_reg_style
  -- Purpose: Get array size for ARD_ID_ARRAY, ARD_DWIDTH_ARRAY, and 
  --          ARD_NUM_CE_ARRAY
  -----------------------------------------------------------------------------
  --function get_io_reg_style return integer is
  --variable io_reg_style_i : integer;
  --begin

  --    io_reg_style_i := 0;
  --
  --    if (V4_IO = TRUE) then 
  --       io_reg_style_i := 0;
  --    elsif (S3E_IO = TRUE) then 
  --       io_reg_style_i := 1;      
  --    elsif (V2P_IO = TRUE) then 
  --       io_reg_style_i := 2;
  --    else   
  --       io_reg_style_i := 0;         
  --    end if;
  --  
  --    return io_reg_style_i;
  --    
  --end function get_io_reg_style;
  
  function get_ipif_dwidth (axi_width : integer) return integer is
  variable ipif_dwidth : integer;
  begin

      ipif_dwidth := 64;
  
      if (axi_width = 32) then 
         ipif_dwidth := 32;
      else   
         ipif_dwidth := 64;
      end if;
    
      return ipif_dwidth;
      
  end function get_ipif_dwidth;

  constant  IO_REG_STYLE : integer := 0; --get_io_reg_style;
  constant  IPIF_NATIVE_DWIDTH : integer := get_ipif_dwidth(C_M_AXI_DATA_WIDTH);
   
  ------------------------------------------
  -- Signal Declaration 
  ------------------------------------------

  signal bus2ip_clk         : std_logic;
  signal bus2ip_sreset      : std_logic;
  signal bus2ip_mreset      : std_logic;
  signal bus2ip_resetn      : std_logic;
  signal ip2bus_data        : std_logic_vector(0 to 31):=
                              (others  => '0');
  signal ip2bus_error       : std_logic;
  signal ip2bus_wrack       : std_logic;
  signal ip2bus_rdack       : std_logic;
  signal bus2ip_data        : std_logic_vector
                              (0 to 31);
  signal bus2ip_rdce        : std_logic_vector
                              (calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1 downto 0);
  signal bus2ip_wrce        : std_logic_vector
                              (calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1 downto 0);
  signal bus2ip_be          : std_logic_vector(0 to 3);
  
  signal ip2bus_mstrd_req          : std_logic;
  signal ip2bus_mst_addr           : std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
  signal ip2bus_mst_length         : std_logic_vector(11 downto 0);
  signal ip2bus_mst_be             : std_logic_vector
                                     (((IPIF_NATIVE_DWIDTH/8)-1) downto 0);
  signal ip2bus_mst_type           : std_logic;
  signal ip2bus_mst_lock           : std_logic;
  signal ip2bus_mst_reset          : std_logic;
  signal bus2ip_mst_cmdack         : std_logic;
  signal bus2ip_mst_cmplt          : std_logic;
  signal bus2ip_mstrd_d            : std_logic_vector
                                      (0 to IPIF_NATIVE_DWIDTH-1);
  signal temp_bus2ip_mstrd_d       : std_logic_vector
                                      (IPIF_NATIVE_DWIDTH-1 downto 0);
  signal bus2ip_mstrd_eof_n        : std_logic;
  signal bus2ip_mstrd_src_rdy_n    : std_logic;
  signal ip2bus_mstrd_dst_rdy_n    : std_logic;
  signal ip2bus_mstrd_dst_dsc_n    : std_logic;
  signal ip2bus_mstwr_d            : std_logic_vector
                                      (IPIF_NATIVE_DWIDTH-1 downto 0)
                                       := (others => '0');
  signal ip2bus_mstwr_rem          : std_logic_vector
                                      (((IPIF_NATIVE_DWIDTH/8)-1) downto 0)
                                       := (others => '0');
  
  signal bus2ip_mstr_data          : std_logic_vector(0 to 63);
  signal bus2ip_mstrd_d1           : std_logic_vector(0 to 31);
  signal mstr_src_rdy_n            : std_logic;

  ------------------------------------------
  -- Component declaration for verilog user logic
  ------------------------------------------
  component tft_controller is
    generic
    (
      -- TFT Controller parameters
      C_TFT_INTERFACE         : integer  := 1;
      C_I2C_SLAVE_ADDR        : integer;
      C_DEFAULT_TFT_BASE_ADDR : integer;
      C_IOREG_STYLE           : integer  := 1; 
       -- Bus protocol parameters
      C_FAMILY                : string   := "virtex5";
      C_SLV_DWIDTH            : integer  := 32;
      C_MST_AWIDTH            : integer  := 32;
      C_MST_DWIDTH            : integer  := 32;
      C_NUM_REG               : integer  := 4
      -------------------------------------------------------
    );
    port
    (
      -- TFT Interface Ports
      SYS_TFT_Clk                : in  std_logic;
      -- TFT Common Interface Ports
      TFT_HSYNC                  : out std_logic;
      TFT_VSYNC                  : out std_logic;
      TFT_DE                     : out std_logic;
      TFT_DPS                    : out std_logic;

      -- VGA Interface Ports
      TFT_VGA_CLK                : out std_logic;
      TFT_VGA_R                  : out std_logic_vector(5 downto 0);
      TFT_VGA_G                  : out std_logic_vector(5 downto 0);
      TFT_VGA_B                  : out std_logic_vector(5 downto 0);

      -- DVI Interface Ports     
      TFT_DVI_CLK_P              : out std_logic;
      TFT_DVI_CLK_N              : out std_logic;
      TFT_DVI_DATA               : out std_logic_vector(11 downto 0);

      -- I2C interface for Chrontel Chip
      TFT_IIC_SCL_I              : in  std_logic;    
      TFT_IIC_SCL_O              : out std_logic;
      TFT_IIC_SCL_T              : out std_logic;
      TFT_IIC_SDA_I              : in  std_logic;
      TFT_IIC_SDA_O              : out std_logic;
      TFT_IIC_SDA_T              : out std_logic;

      -- Bus protocol ports
      S_AXI_Clk                   : in  std_logic;
      S_AXI_Rst                   : in  std_logic;
      Bus2IP_Data                : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
      Bus2IP_RdCE                : in  std_logic_vector(0 to C_NUM_REG-1);
      Bus2IP_WrCE                : in  std_logic_vector(0 to C_NUM_REG-1);
      Bus2IP_BE                  : in  std_logic_vector(0 to C_SLV_DWIDTH/8-1);
      IP2Bus_Data                : out std_logic_vector(0 to C_SLV_DWIDTH-1);
      IP2Bus_RdAck               : out std_logic;
      IP2Bus_WrAck               : out std_logic;
      IP2Bus_Error               : out std_logic;

      -- Interrupt (Frame complete)
      IP2INTC_Irpt               : out std_logic; 
      
      M_AXI_Clk                   : in  std_logic;
      M_AXI_Rst                   : in  std_logic;
      IP2Bus_MstRd_Req           : out std_logic;
      IP2Bus_Mst_Addr            : out std_logic_vector(0 to C_MST_AWIDTH-1);
      IP2Bus_Mst_BE              : out std_logic_vector(0 to C_MST_DWIDTH/8-1);
      IP2Bus_Mst_Length          : out std_logic_vector(0 to 11);
      IP2Bus_Mst_Type            : out std_logic;
      IP2Bus_Mst_Lock            : out std_logic;
      IP2Bus_Mst_Reset           : out std_logic;
      Bus2IP_Mst_CmdAck          : in  std_logic;
      Bus2IP_Mst_Cmplt           : in  std_logic;
      Bus2IP_MstRd_d             : in  std_logic_vector(0 to C_MST_DWIDTH-1);
      Bus2IP_MstRd_eof_n         : in  std_logic;
      Bus2IP_MstRd_src_rdy_n     : in  std_logic;
      IP2Bus_MstRd_dst_rdy_n     : out std_logic;
      IP2Bus_MstRd_dst_dsc_n     : out std_logic
    );
  end component tft_controller;

begin

  -----------------------------------------------------------------------------
  -- converting Active low reset signal to Active high reset signals for TFT controller
  -----------------------------------------------------------------------------
  M_RESET_TOGGLE: process (M_AXI_ACLK) is
  begin
       if(M_AXI_ACLK'event and M_AXI_ACLK = '1') then
           bus2ip_mreset <= not(M_AXI_ARESETN);
       end if;
  end process M_RESET_TOGGLE;

  -----------------------------------------------------------------------------
  -- Instantiate AXI slave interface. 
  -- Include AXI Slave interface to provide TFT Register access 
  -----------------------------------------------------------------------------
  -- converting Active low reset signal to Active high reset signals for TFT controller
  -----------------------------------------------------------------------------
  S_RESET_TOGGLE: process (bus2ip_clk) is
  begin
       if(bus2ip_clk'event and bus2ip_clk = '1') then
           bus2ip_sreset <= not(bus2ip_resetn);
       end if;
  end process S_RESET_TOGGLE;

  ------------------------------------------
  -- instantiate plbv46_slave_single
  ------------------------------------------
  AXI_LITE_IPIF_I: entity axi_lite_ipif_v1_01_a.axi_lite_ipif
    generic map
    (
      C_S_AXI_DATA_WIDTH         => 32                        ,
      C_S_AXI_ADDR_WIDTH         => 32                        ,
      C_S_AXI_MIN_SIZE           => X"0000000F"               ,
      C_USE_WSTRB                => 0                         ,
      C_DPHASE_TIMEOUT           => 0                         ,
      C_ARD_ADDR_RANGE_ARRAY     => IPIF_ARD_ADDR_RANGE_ARRAY ,
      C_ARD_NUM_CE_ARRAY         => IPIF_ARD_NUM_CE_ARRAY     ,
      C_FAMILY                   => C_FAMILY
    )
    port map
    (

      --System signals
      S_AXI_ACLK           =>      S_AXI_ACLK         , 
      S_AXI_ARESETN        =>      S_AXI_ARESETN      , 
      S_AXI_AWADDR         =>      S_AXI_AWADDR       , 
      S_AXI_AWVALID        =>      S_AXI_AWVALID      , 
      S_AXI_AWREADY        =>      S_AXI_AWREADY      , 
      S_AXI_WDATA          =>      S_AXI_WDATA        , 
      S_AXI_WSTRB          =>      S_AXI_WSTRB        , 
      S_AXI_WVALID         =>      S_AXI_WVALID       , 
      S_AXI_WREADY         =>      S_AXI_WREADY       , 
      S_AXI_BRESP          =>      S_AXI_BRESP        , 
      S_AXI_BVALID         =>      S_AXI_BVALID       , 
      S_AXI_BREADY         =>      S_AXI_BREADY       , 
      S_AXI_ARADDR         =>      S_AXI_ARADDR       , 
      S_AXI_ARVALID        =>      S_AXI_ARVALID      , 
      S_AXI_ARREADY        =>      S_AXI_ARREADY      , 
      S_AXI_RDATA          =>      S_AXI_RDATA        , 
      S_AXI_RRESP          =>      S_AXI_RRESP        , 
      S_AXI_RVALID         =>      S_AXI_RVALID       , 
      S_AXI_RREADY         =>      S_AXI_RREADY       , 
      -- Controls to the IP/IPIF modules
      Bus2IP_Clk            =>      bus2ip_clk        , 
      Bus2IP_Resetn         =>      bus2ip_resetn     ,
      Bus2IP_Addr           =>      open              ,
      Bus2IP_RNW            =>      open              ,
      Bus2IP_BE             =>      bus2ip_be         ,
      Bus2IP_CS             =>      open              ,
      Bus2IP_RdCE           =>      bus2ip_rdce       ,
      Bus2IP_WrCE           =>      bus2ip_wrce       ,
      Bus2IP_Data           =>      bus2ip_data  ,
      IP2Bus_Data           =>      ip2bus_data  ,
      IP2Bus_WrAck          =>      ip2bus_wrack      ,
      IP2Bus_RdAck          =>      ip2bus_rdack      ,
      IP2Bus_Error          =>      ip2bus_error      
    );

  -----------------------------------------------------------------------------
  -- Instantiate axi_master_burst
  -----------------------------------------------------------------------------
  AXI_MASTER_BURST_I: entity axi_master_burst_v1_00_a.axi_master_burst
    generic map
     (
      C_M_AXI_ADDR_WIDTH         => C_M_AXI_ADDR_WIDTH        ,
      C_M_AXI_DATA_WIDTH         => C_M_AXI_DATA_WIDTH        ,
      C_MAX_BURST_LEN            => C_MAX_BURST_LEN           ,
      C_ADDR_PIPE_DEPTH          => 1                         ,
      C_NATIVE_DATA_WIDTH        => IPIF_NATIVE_DWIDTH        ,
      C_LENGTH_WIDTH             => 12                        ,
      C_FAMILY                   => C_FAMILY
      )
    port map
     (
      m_axi_aclk                 => M_AXI_ACLK                ,
      m_axi_aresetn              => M_AXI_ARESETN             ,
      md_error                   => MD_ERROR                  ,
       -- MMap Read Address Channel
      m_axi_arready              => M_AXI_ARREADY             ,
      m_axi_arvalid              => M_AXI_ARVALID             ,
      m_axi_araddr               => M_AXI_ARADDR              ,
      m_axi_arlen                => M_AXI_ARLEN               ,
      m_axi_arsize               => M_AXI_ARSIZE              ,
      m_axi_arburst              => M_AXI_ARBURST             ,
      m_axi_arprot               => M_AXI_ARPROT              ,
      m_axi_arcache              => M_AXI_ARCACHE             ,
      -- MMap Read Data Channel   
      m_axi_rready               => M_AXI_RREADY              ,
      m_axi_rvalid               => M_AXI_RVALID              , 
      m_axi_rdata                => M_AXI_RDATA               , 
      m_axi_rresp                => M_AXI_RRESP               , 
      m_axi_rlast                => M_AXI_RLAST               , 
      -- Write Address Channel
      m_axi_awready              => M_AXI_AWREADY             , 
      m_axi_awvalid              => M_AXI_AWVALID             , 
      m_axi_awaddr               => M_AXI_AWADDR              , 
      m_axi_awlen                => M_AXI_AWLEN               , 
      m_axi_awsize               => M_AXI_AWSIZE              , 
      m_axi_awburst              => M_AXI_AWBURST             , 
      m_axi_awprot               => M_AXI_AWPROT              , 
      m_axi_awcache              => M_AXI_AWCACHE             , 
      -- Write Data Channel
      m_axi_wready               => M_AXI_WREADY              , 
      m_axi_wvalid               => M_AXI_WVALID              , 
      m_axi_wdata                => M_AXI_WDATA               , 
      m_axi_wstrb                => M_AXI_WSTRB               , 
      m_axi_wlast                => M_AXI_WLAST               , 
      -- Write Response Channel 
      m_axi_bready               => M_AXI_BREADY              , 
      m_axi_bvalid               => M_AXI_BVALID              , 
      m_axi_bresp                => M_AXI_BRESP               , 
  
      -- IPIC Request/Qualifiers
      ip2bus_mstrd_req           => ip2bus_mstrd_req          ,
      ip2bus_mstwr_req           => '0'                       ,
      ip2bus_mst_addr            => ip2bus_mst_addr           ,
      ip2bus_mst_length          => ip2bus_mst_length         ,
      ip2bus_mst_be              => ip2bus_mst_be             , 
      ip2bus_mst_type            => ip2bus_mst_type           ,
      ip2bus_mst_lock            => ip2bus_mst_lock           ,
      ip2bus_mst_reset           => ip2bus_mst_reset          ,
      -- IPIC Request Status Reply
      bus2ip_mst_cmdack          => bus2ip_mst_cmdack         ,
      bus2ip_mst_cmplt           => bus2ip_mst_cmplt          ,
      bus2ip_mst_error           => open                      ,
      bus2ip_mst_rearbitrate     => open                      ,
      bus2ip_mst_cmd_timeout     => open                      ,
      -- IPIC Read LocalLink Channel
      bus2ip_mstrd_d             => temp_bus2ip_mstrd_d       ,
      bus2ip_mstrd_rem           => open                      ,
      bus2ip_mstrd_sof_n         => open                      ,
      bus2ip_mstrd_eof_n         => bus2ip_mstrd_eof_n        ,
      bus2ip_mstrd_src_rdy_n     => bus2ip_mstrd_src_rdy_n    ,
      bus2ip_mstrd_src_dsc_n     => open                      ,
      ip2bus_mstrd_dst_rdy_n     => ip2bus_mstrd_dst_rdy_n    ,
      ip2bus_mstrd_dst_dsc_n     => ip2bus_mstrd_dst_dsc_n    ,
      -- IPIC Write LocalLink Channe
      ip2bus_mstwr_d             => ip2bus_mstwr_d            ,
      ip2bus_mstwr_rem           => ip2bus_mstwr_rem          ,
      ip2bus_mstwr_sof_n         => '0'                       ,
      ip2bus_mstwr_eof_n         => '0'                       ,
      ip2bus_mstwr_src_rdy_n     => '0'                       ,
      ip2bus_mstwr_src_dsc_n     => '0'                       ,
      bus2ip_mstwr_dst_rdy_n     => open                      ,
      bus2ip_mstwr_dst_dsc_n     => open
    );

  -----------------------------------------------------------------------------
  -- ENDEANESS correction for master read signals 
  -----------------------------------------------------------------------------
  AXI_DATA_WIDTH_32: if (C_M_AXI_DATA_WIDTH = 32) generate
  begin
    bus2ip_mstrd_d(0 to 31) <= temp_bus2ip_mstrd_d(31 downto 0);
    bus2ip_mstr_data <= (bus2ip_mstrd_d1 & bus2ip_mstrd_d);
    ip2bus_mst_be <= (others => '1');
    RD_DATA_ALIGN: process (M_AXI_ACLK) is
    begin
    if M_AXI_ACLK'event and M_AXI_ACLK = '1' then
        if bus2ip_mreset = '1' then
            bus2ip_mstrd_d1 <= (others => '0');
            mstr_src_rdy_n <= '1';
        else 
            bus2ip_mstrd_d1 <= bus2ip_mstrd_d;
            if (bus2ip_mstrd_src_rdy_n = '0') then
                mstr_src_rdy_n <= not mstr_src_rdy_n;
            else 
                mstr_src_rdy_n <= '1';
            end if;
        end if;
    end if;
    end process RD_DATA_ALIGN;
  end generate AXI_DATA_WIDTH_32;

  AXI_DATA_WIDTH_GT32: if (C_M_AXI_DATA_WIDTH > 32) generate
  begin
    bus2ip_mstrd_d(0 to 63) <= (temp_bus2ip_mstrd_d(31 downto 0) & temp_bus2ip_mstrd_d(63 downto 32));
    bus2ip_mstr_data <= bus2ip_mstrd_d;
    mstr_src_rdy_n <= bus2ip_mstrd_src_rdy_n;
    ip2bus_mst_be <= (others => '1');
  end generate AXI_DATA_WIDTH_GT32;
  
  -----------------------------------------------------------------------------
  -- Instantiate TFT Controller 
  -----------------------------------------------------------------------------
  TFT_CTRL_I: tft_controller
    generic map (
      C_TFT_INTERFACE            => C_TFT_INTERFACE           ,                                        
      C_I2C_SLAVE_ADDR           => I2C_SLAVE_ADDR            ,
      C_DEFAULT_TFT_BASE_ADDR    => TFT_BASE_ADDR             ,  
      C_FAMILY                   => C_FAMILY                  , 
      C_IOREG_STYLE              => IO_REG_STYLE              ,
      C_SLV_DWIDTH               => 32                        ,
      C_MST_AWIDTH               => USER_MST_AWIDTH           ,        
      C_MST_DWIDTH               => 64                        ,
      C_NUM_REG                  => USER_NUM_REG              
     )                                                        
                                                              
    port map                                                  
     (                                                        
      -- TFT SIGNALS OUT TO HW                                
      SYS_TFT_Clk                => SYS_TFT_Clk               ,    
      TFT_HSYNC                  => TFT_HSYNC                 , 
      TFT_VSYNC                  => TFT_VSYNC                 , 
      TFT_DE                     => TFT_DE                    ,    
      TFT_DPS                    => TFT_DPS                   ,   
      TFT_VGA_CLK                => TFT_VGA_CLK               , 
      TFT_VGA_R                  => TFT_VGA_R                 , 
      TFT_VGA_G                  => TFT_VGA_G                 ,   
      TFT_VGA_B                  => TFT_VGA_B                 ,   
      TFT_DVI_CLK_P              => TFT_DVI_CLK_P             , 
      TFT_DVI_CLK_N              => TFT_DVI_CLK_N             , 
      TFT_DVI_DATA               => TFT_DVI_DATA              ,  
                                                              
      -- IIC init state machine for Chrontel CH7301C          
      TFT_IIC_SCL_I              => TFT_IIC_SCL_I             ,
      TFT_IIC_SCL_O              => TFT_IIC_SCL_O             , 
      TFT_IIC_SCL_T              => TFT_IIC_SCL_T             ,
      TFT_IIC_SDA_I              => TFT_IIC_SDA_I             , 
      TFT_IIC_SDA_O              => TFT_IIC_SDA_O             , 
      TFT_IIC_SDA_T              => TFT_IIC_SDA_T             , 
                                                              
      -- PLB slave interface signals        
      S_AXI_Clk                   => bus2ip_clk                ,
      S_AXI_Rst                   => bus2ip_sreset              ,
      Bus2IP_Data                => bus2ip_data               ,
      Bus2IP_RdCE                => bus2ip_rdce               ,
      Bus2IP_WrCE                => bus2ip_wrce               ,
      Bus2IP_BE                  => bus2ip_be                 ,
      IP2Bus_Data                => ip2bus_data               ,
      IP2Bus_RdAck               => ip2bus_rdack              ,
      IP2Bus_WrAck               => ip2bus_wrack              ,
      IP2Bus_Error               => ip2bus_error              ,

      -- Frame Comeplete Interrupt  
      IP2INTC_Irpt               => IP2INTC_Irpt              ,
      
      -- PLB Master interface signals                         
      M_AXI_Clk                   => M_AXI_ACLK                ,
      M_AXI_Rst                   => bus2ip_mreset             ,
      IP2Bus_MstRd_Req           => ip2bus_mstrd_req          ,
      IP2Bus_Mst_Addr            => ip2bus_mst_addr           ,
      IP2Bus_Mst_BE              => open, --ip2bus_mst_be             ,
      IP2Bus_Mst_Length          => ip2bus_mst_length         ,
      IP2Bus_Mst_Type            => ip2bus_mst_type           ,
      IP2Bus_Mst_Lock            => ip2bus_mst_lock           ,
      IP2Bus_Mst_Reset           => ip2bus_mst_reset          ,
      Bus2IP_Mst_CmdAck          => bus2ip_mst_cmdack         ,
      Bus2IP_Mst_Cmplt           => bus2ip_mst_cmplt          ,
      Bus2IP_MstRd_d             => bus2ip_mstr_data, --bus2ip_mstrd_d            ,
      Bus2IP_MstRd_eof_n         => bus2ip_mstrd_eof_n        ,
      Bus2IP_MstRd_src_rdy_n     => mstr_src_rdy_n, --bus2ip_mstrd_src_rdy_n    ,
      IP2Bus_MstRd_dst_rdy_n     => ip2bus_mstrd_dst_rdy_n    ,
      IP2Bus_MstRd_dst_dsc_n     => ip2bus_mstrd_dst_dsc_n    
    );

end imp;
