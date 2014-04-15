-------------------------------------------------------------------------------
-- axi_master_burst_reset.vhd
-------------------------------------------------------------------------------
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
-- Filename:        axi_master_burst_reset.vhd
--
-- Description:     
--                  
-- This VHDL file implements the reset module for the AXI Master lite.                 
--                  
--                  
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              axi_master_burst_reset.vhd
--
-------------------------------------------------------------------------------
-- Author:          DET
-- Revision:        $Revision: 1.0 $
-- Date:            $1/26/2011$
--
-- History:
--
--     DET     1/26/2011     Initial
-- ~~~~~~
--     - Adapted from AXI Master Lite reset module
-- ^^^^^^
--
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;




-------------------------------------------------------------------------------

entity axi_master_burst_reset is
  port (
    
    -----------------------------------------------------------------------
    -- Clock Input
    -----------------------------------------------------------------------
    axi_aclk            : in  std_logic ;
    
    -----------------------------------------------------------------------
    -- Reset Input (active low) 
    -----------------------------------------------------------------------
    axi_aresetn         : in  std_logic ;

    
    
    -----------------------------------------------------------------------
    -- IPIC Reset Input 
    -----------------------------------------------------------------------
    ip2bus_mst_reset    : In  std_logic ; 
     
    
    
    -----------------------------------------------------------------------
    -- Command Status Module Reset Output 
    -----------------------------------------------------------------------
    rst2cmd_reset_out   : out  std_logic ; 
    
    -----------------------------------------------------------------------
    -- Read Write controller Module Reset Output 
    -----------------------------------------------------------------------
    rst2rdwr_reset_out  : out  std_logic ; 
    
    -----------------------------------------------------------------------
    -- LocalLink Modules Reset Output 
    -----------------------------------------------------------------------
    rst2llink_reset_out : out  std_logic  
    
    
    );

end entity axi_master_burst_reset;


architecture implementation of axi_master_burst_reset is

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------

  
-------------------------------------------------------------------------------
-- Signal / Type Declarations
-------------------------------------------------------------------------------
  signal sig_axi_por_reg1            : std_logic := '0';
  signal sig_axi_por_reg2            : std_logic := '0';
  signal sig_axi_por_reg3            : std_logic := '0';
  signal sig_axi_por_reg4            : std_logic := '0';
  signal sig_axi_por_reg5            : std_logic := '0';
  signal sig_axi_por_reg6            : std_logic := '0';
  signal sig_axi_por_reg7            : std_logic := '0';
  signal sig_axi_por_reg8            : std_logic := '0';
  signal sig_axi_por2rst             : std_logic := '0';
  signal sig_axi_por2rst_out         : std_logic := '0';
  
  
  signal sig_axi_reset               : std_logic := '0';
  signal sig_ipic_reset              : std_logic := '0';
  signal sig_combined_reset          : std_logic := '0';
  signal sig_cmd_reset_reg           : std_logic := '0';
  signal sig_rdwr_reset_reg          : std_logic := '0';
  signal sig_llink_reset_reg         : std_logic := '0';
  
 
   
-------------------------------------------------------------------------------
-- Register duplication attribute assignments to control fanout
-- on reset signals
-------------------------------------------------------------------------------

 Attribute KEEP : string; -- declaration
 Attribute EQUIVALENT_REGISTER_REMOVAL : string; -- declaration
 
 Attribute KEEP of sig_cmd_reset_reg     : signal is "TRUE";
 Attribute KEEP of sig_rdwr_reset_reg    : signal is "TRUE";
 Attribute KEEP of sig_llink_reset_reg   : signal is "TRUE";
 
 Attribute EQUIVALENT_REGISTER_REMOVAL of sig_cmd_reset_reg   : signal is "no";
 Attribute EQUIVALENT_REGISTER_REMOVAL of sig_rdwr_reset_reg  : signal is "no";
 Attribute EQUIVALENT_REGISTER_REMOVAL of sig_llink_reset_reg : signal is "no";


  
                      

begin --(architecture implementation)

  
  -- Assign the output ports
  rst2cmd_reset_out   <= sig_cmd_reset_reg  ;
  rst2rdwr_reset_out  <= sig_rdwr_reset_reg ;
  rst2llink_reset_out <= sig_llink_reset_reg;
  
  
  
   
  -- Generate an active high combined reset from the 
  -- axi reset input and the IPIC reset input
  sig_axi_reset          <= not(axi_aresetn);
  sig_ipic_reset         <= ip2bus_mst_reset;
  sig_combined_reset     <= sig_axi_reset or sig_ipic_reset;     
  
  
  
  
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_CMD_RST_REG
  --
  -- Process Description:
  --   Implements the register for the command/status module
  -- reset output.
  --
  -------------------------------------------------------------
  IMP_CMD_RST_REG : process (axi_aclk)
    begin
      if (axi_aclk'event and axi_aclk = '1') then
         if (sig_axi_por2rst_out = '1') then
  
           sig_cmd_reset_reg <= '1';
  
         else
 
           sig_cmd_reset_reg <= sig_combined_reset;
  
         end if; 
      end if;       
    end process IMP_CMD_RST_REG; 
  

   
   

  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_RDWR_RST_REG
  --
  -- Process Description:
  --   Implements the register for the read/write controller 
  -- module reset output.
  --
  -------------------------------------------------------------
  IMP_RDWR_RST_REG : process (axi_aclk)
    begin
      if (axi_aclk'event and axi_aclk = '1') then
         if (sig_axi_por2rst_out = '1') then
  
           sig_rdwr_reset_reg <= '1';
  
         else
 
           sig_rdwr_reset_reg <= sig_combined_reset;
  
         end if; 
      end if;       
    end process IMP_RDWR_RST_REG; 
  

   
   

  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: IMP_LLINK_RST_REG
  --
  -- Process Description:
  --   Implements the register for the LocalLink Modules 
  -- reset output.
  --
  -------------------------------------------------------------
  IMP_LLINK_RST_REG : process (axi_aclk)
    begin
      if (axi_aclk'event and axi_aclk = '1') then
         if (sig_axi_por2rst_out = '1') then
  
           sig_llink_reset_reg <= '1';
  
         else
 
           sig_llink_reset_reg <= sig_combined_reset;
  
         end if; 
      end if;       
    end process IMP_LLINK_RST_REG; 
  








---------------------------------------------------------------
-- Start Power On Reset (POR) Logic
---------------------------------------------------------------
  
  
                      
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: AXI_POR_REG
  --
  -- Process Description:
  --    This process generates an 8-clock wide pulse that 
  --  only occurs immediately after FPGA initialization. This  
  --  pulse is used to initialize reset logic synchronous to
  --  the Main axi_aclk Clock until the Bus Reset occurs.
  --
  -------------------------------------------------------------
  AXI_POR_REG : process (axi_aclk)
    begin
      if (axi_aclk'event and axi_aclk = '1') then
        sig_axi_por_reg1    <= '1';
        sig_axi_por_reg2    <= sig_axi_por_reg1;
        sig_axi_por_reg3    <= sig_axi_por_reg2;
        sig_axi_por_reg4    <= sig_axi_por_reg3;
        sig_axi_por_reg5    <= sig_axi_por_reg4;
        sig_axi_por_reg6    <= sig_axi_por_reg5;
        sig_axi_por_reg7    <= sig_axi_por_reg6;
        sig_axi_por_reg8    <= sig_axi_por_reg7;

        sig_axi_por2rst_out <= sig_axi_por2rst ;
        
      end if;       
    end process AXI_POR_REG; 
                     
                       
  
                      
  sig_axi_por2rst <=   not(sig_axi_por_reg1 and                  
                           sig_axi_por_reg2 and
                           sig_axi_por_reg3 and
                           sig_axi_por_reg4 and
                           sig_axi_por_reg5 and
                           sig_axi_por_reg6 and
                           sig_axi_por_reg7 and
                           sig_axi_por_reg8 );
                      
 
 
 
---------------------------------------------------------------
-- End of Power On Reset (POR) Logic
---------------------------------------------------------------
  
 
  
   





end implementation;
