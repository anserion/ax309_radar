------------------------------------------------------------------
--Copyright 2018 Andrey S. Ionisyan (anserion@gmail.com)
--Licensed under the Apache License, Version 2.0 (the "License");
--you may not use this file except in compliance with the License.
--You may obtain a copy of the License at
--    http://www.apache.org/licenses/LICENSE-2.0
--Unless required by applicable law or agreed to in writing, software
--distributed under the License is distributed on an "AS IS" BASIS,
--WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--See the License for the specific language governing permissions and
--limitations under the License.
------------------------------------------------------------------

------------------------------------------------------------------------------
-- Engineer: Andrey S. Ionisyan <anserion@gmail.com>
-- 
-- Description:
-- Top level for the simple radar lego-station (Alinx AX309 board).
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity radar_top is
   Port (
      clk50_ucf: in STD_LOGIC;
      
      trig1    : out STD_LOGIC;
      trig2    : out std_logic;
      echo1    : in STD_LOGIC;
      echo2    : in std_logic;

      step_motor_pins: out STD_LOGIC_VECTOR(3 downto 0);
      
      led      : out  STD_LOGIC_VECTOR(3 downto 0);
      key      : in  STD_LOGIC_VECTOR(3 downto 0);

      SMG_seg  : out STD_LOGIC_VECTOR(7 downto 0);
      SMG_dig  : out STD_LOGIC_VECTOR(5 downto 0);

      lcd_red      : out   STD_LOGIC_VECTOR(7 downto 0);
      lcd_green    : out   STD_LOGIC_VECTOR(7 downto 0);
      lcd_blue     : out   STD_LOGIC_VECTOR(7 downto 0);
      lcd_hsync    : out   STD_LOGIC;
      lcd_vsync    : out   STD_LOGIC;
      lcd_dclk     : out   STD_LOGIC;

      Sdram_CLK_ucf: out STD_LOGIC; 
      Sdram_CKE_ucf: out STD_LOGIC;
      Sdram_NCS_ucf: out STD_LOGIC;
      Sdram_NWE_ucf: out STD_LOGIC;
      Sdram_NCAS_ucf: out STD_LOGIC;
      Sdram_NRAS_ucf: out STD_LOGIC;
      Sdram_DQM_ucf: out STD_LOGIC_VECTOR(1 downto 0);
      Sdram_BA_ucf: out STD_LOGIC_VECTOR(1 downto 0);
      Sdram_A_ucf: out STD_LOGIC_VECTOR(12 downto 0);
      Sdram_DB_ucf: inout STD_LOGIC_VECTOR(15 downto 0)
	);
end radar_top;

architecture ax309 of radar_top is
   component clk_core
   port(
      CLK50_ucf: in std_logic;
      CLK100: out std_logic;
      CLK16: out std_logic;      
      CLK4: out std_logic
   );
   end component;

   component vram_scanline
   port (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
   );
   end component;

   component freq_div_module is
    Port ( 
		clk   : in  STD_LOGIC;
      en    : in  STD_LOGIC;
      value : in  STD_LOGIC_VECTOR(31 downto 0);
      result: out STD_LOGIC
	 );
   end component;

   component bin24_to_bcd is
    Port ( 
		clk   : in  STD_LOGIC;
      en    : in std_logic;
      bin   : in std_logic_vector(23 downto 0);
      bcd   : out std_logic_vector(31 downto 0);
      ready : out std_logic
	 );
   end component;

   component SMG_driver is
    Port ( 
		clk    : in  STD_LOGIC;
      en     : in  STD_LOGIC;
      bcd_num: in STD_LOGIC_VECTOR(23 downto 0);
      mask   : in STD_LOGIC_VECTOR(5 downto 0);
      SEG    : out STD_LOGIC_VECTOR(7 downto 0);
      DIG    : out STD_LOGIC_VECTOR(5 downto 0)
	 );
   end component;

   component sdram_controller
	generic (
				--memory frequency in MHz
				sdram_frequency	: integer := 100
				);
	port (
			--ready operation
			ready						: out std_logic;
			--clk
			clk						: in std_logic;
			--read interface
			rd_req					: in std_logic;
			rd_adr					: in std_logic_vector(23 downto 0);
			rd_data					: out std_logic_vector(15 downto 0);
			rd_valid					: out std_logic;
			--write interface
			wr_req					: in std_logic;
			wr_adr					: in std_logic_vector(23 downto 0);
			wr_data					: in std_logic_vector(15 downto 0);
			--SDRAM interface
			sdram_wren_n			: out std_logic := '1';
			sdram_cas_n				: out std_logic := '1';
			sdram_ras_n				: out std_logic := '1';
			sdram_a					: out std_logic_vector(12 downto 0);
			sdram_ba					: out std_logic_vector(1 downto 0);
			sdram_dqm				: out std_logic_vector(1 downto 0);
			sdram_dq					: inout std_logic_vector(15 downto 0);
			sdram_clk_n				: out std_logic
			);
   end component;
   signal sdram_clk : std_logic;
   signal sdram_ready,sdram_rd_req,sdram_rd_valid,sdram_wr_req:std_logic:='0';
   signal sdram_rd_addr,sdram_wr_addr:std_logic_vector(23 downto 0);
   signal sdram_rd_data,sdram_wr_data:std_logic_vector(15 downto 0);

   component sdram_supervisor is
   Port ( 
      clk : in std_logic;
      en  : in std_logic;
      lcd_en    : in std_logic;
      cpu_en    : in std_logic;

      sdram_rd_req   : out std_logic; 
      sdram_rd_valid : in std_logic;
      sdram_wr_req   : out std_logic;
      sdram_rd_addr  : out std_logic_vector(23 downto 0);
      sdram_wr_addr  : out std_logic_vector(23 downto 0);
      sdram_rd_data  : in std_logic_vector(15 downto 0);
      sdram_wr_data  : out std_logic_vector(15 downto 0);

      lcd_width : in std_logic_vector(9 downto 0);
      lcd_y     : in std_logic_vector(9 downto 0);
      lcd_vsync : in std_logic;
      lcd_wr_en : out std_logic;
      lcd_wr_addr: out std_logic_vector(9 downto 0);
      lcd_wr_data: out std_logic_vector(15 downto 0);
      
      cpu_wr_en  : in std_logic;
      cpu_addr   : in std_logic_vector(23 downto 0);
      cpu_wr_data: in std_logic_vector(15 downto 0);
      cpu_rd_data: out std_logic_vector(15 downto 0);
      
      ready      : out std_logic
	);
   end component;

   component lcd_AN430
    Port ( 
      en      : in std_logic;
      clk     : in  STD_LOGIC;
      red     : out STD_LOGIC_VECTOR(7 downto 0);
      green   : out STD_LOGIC_VECTOR(7 downto 0);
      blue    : out STD_LOGIC_VECTOR(7 downto 0);
      hsync   : out STD_LOGIC;
      vsync   : out STD_LOGIC;
      de	     : out STD_LOGIC;
      x       : out STD_LOGIC_VECTOR(9 downto 0);
      y       : out STD_LOGIC_VECTOR(9 downto 0);
      dirty_x : out STD_LOGIC_VECTOR(9 downto 0);
      dirty_y : out STD_LOGIC_VECTOR(9 downto 0);
      pixel   : in STD_LOGIC_VECTOR(23 downto 0);
      char_x    : out STD_LOGIC_VECTOR(6 downto 0);
      char_y	 : out STD_LOGIC_VECTOR(4 downto 0);
      char_code : in  STD_LOGIC_VECTOR(7 downto 0)
    );
   end component;

   component step_motor_cpu is
    Port ( 
		clk_1kHz : in  std_logic;
      clk_ccw  : in  std_logic;
      clk_cw   : in  std_logic;
      step_motor_pins : out std_logic_vector(3 downto 0);
      alpha : out std_logic_vector(8 downto 0)
	 );
   end component;

   component sonar_driver is
    Port ( 
		clk_1Mhz: in  STD_LOGIC;
      en       : in  STD_LOGIC;
      trig     : out STD_LOGIC;
      echo     : in  STD_LOGIC;
      latency  : out STD_LOGIC_VECTOR(15 downto 0);
      ready    : out STD_LOGIC
	 );
   end component;

   component sonar_cpu is
    Port ( 
		clk      : in  STD_LOGIC;
      mem_rw_en   : out std_logic;
      mem_rw_ready: in std_logic;
      mem_wr_en   : out std_logic;
      mem_addr    : out std_logic_vector(23 downto 0);
      mem_wr_data : out std_logic_vector(15 downto 0);
      mem_rd_data : in std_logic_vector(15 downto 0);
      dist1 : in STD_LOGIC_VECTOR(15 downto 0);
      dist2 : in STD_LOGIC_VECTOR(15 downto 0);
      alpha : in STD_LOGIC_VECTOR(8 downto 0)
	 );
   end component;
   
   signal clk16: std_logic:='0';
   signal clk4: std_logic:='0';
   signal clk100: std_logic:='0';
   signal clk_1Mhz: std_logic:='0';
   signal clk_1Khz: std_logic:='0';
   signal clk_200hz: std_logic:='0';
   signal clk_100hz: std_logic:='0';
   signal clk_50hz: std_logic:='0';
   signal clk_1hz: std_logic:='0';

   signal alpha: std_logic_vector(8 downto 0):=(others=>'0');
   
   signal sonar1_ready,sonar2_ready:std_logic:='0';
   signal sonar1_latency,sonar2_latency: std_logic_vector(15 downto 0):=(others=>'0');

   signal sonar1_dist: std_logic_vector(15 downto 0):=(others=>'0');
   signal sonar2_dist: std_logic_vector(15 downto 0):=(others=>'0');
   
   signal bcd1_en,bcd1_ready: std_logic:='0';
   signal bcd_num1: std_logic_vector(31 downto 0):=(others=>'0');

   signal bcd2_en,bcd2_ready: std_logic:='0';
   signal bcd_num2: std_logic_vector(31 downto 0):=(others=>'0');

   signal bcd_num: std_logic_vector(23 downto 0):=(others=>'0');

   signal lcd_clk   : std_logic;
   signal lcd_en    : std_logic := '1';
   signal lcd_de    : std_logic :='0';
   signal lcd_reg_hsync: STD_LOGIC :='1';
   signal lcd_reg_vsync: STD_LOGIC :='1';
   signal lcd_x     : std_logic_vector(9 downto 0) := (others => '0');
   signal lcd_y     : std_logic_vector(9 downto 0) := (others => '0');
   signal lcd_dirty_x: std_logic_vector(9 downto 0) := (others => '0');
   signal lcd_dirty_y: std_logic_vector(9 downto 0) := (others => '0');	
   signal lcd_pixel : std_logic_vector(23 downto 0) := (others => '0');	
   signal lcd_char_x: std_logic_vector(6 downto 0) := (others => '0');
   signal lcd_char_y: std_logic_vector(4 downto 0) := (others => '0');
   signal lcd_char  : std_logic_vector(7 downto 0);
   signal lcd_scanline_wea   : std_logic_vector(0 downto 0);
   signal lcd_scanline_wr_addr: std_logic_vector(9 downto 0);
   signal lcd_scanline_wr_data: std_logic_vector(15 downto 0);
   signal pixel_16bpp : std_logic_vector(15 downto 0) := (others => '0');	
   
   signal cpu_wr_en,cpu_sdram_rw_en,cpu_sdram_rw_ready: std_logic:='0';
   signal cpu_addr: std_logic_vector(23 downto 0):=(others=>'0');
   signal cpu_wr_data: std_logic_vector(15 downto 0):=(others=>'0');
   signal cpu_rd_data: std_logic_vector(15 downto 0):=(others=>'0');

begin
   clocking_chip: clk_core port map (CLK50_ucf, clk100, clk16, clk4);
   freq_1Mhz_chip: freq_div_module port map(clk16,'1',conv_std_logic_vector(8,32),clk_1Mhz);
   freq_1Khz_chip: freq_div_module port map(clk16,'1',conv_std_logic_vector(8000,32),clk_1Khz);
   freq_200Hz_chip: freq_div_module port map(clk4,'1',conv_std_logic_vector(10000,32),clk_200hz);
   freq_100Hz_chip: freq_div_module port map(clk4,'1',conv_std_logic_vector(20000,32),clk_100hz);
   freq_50Hz_chip: freq_div_module port map(clk4,'1',conv_std_logic_vector(40000,32),clk_50hz);

   sdram_clk<=clk100;
   lcd_clk<=clk4;
   lcd_dclk<=lcd_clk;

-------------------------------------------------------------   
   sdram_CKE_ucf<='1'; --sdram chip clock always turn on
   sdram_NCS_ucf<='0'; --sdram chip always selected (zero active level)
   SDRAM_chip: sdram_controller generic map (100)
                   port map (
                             sdram_ready, sdram_clk,
                             sdram_rd_req, sdram_rd_addr, sdram_rd_data, sdram_rd_valid,
                             sdram_wr_req, sdram_wr_addr, sdram_wr_data,
                             sdram_nwe_ucf, sdram_ncas_ucf, sdram_nras_ucf,
                             sdram_a_ucf, sdram_ba_ucf, sdram_dqm_ucf, sdram_db_ucf,
                             sdram_clk_ucf
                             );

   sdram_supervisor_chip: sdram_supervisor
   Port map( 
      clk => sdram_clk,
      en  => sdram_ready,
      lcd_en => lcd_en,
      cpu_en => cpu_sdram_rw_en,

      sdram_rd_req   => sdram_rd_req,
      sdram_rd_valid => sdram_rd_valid,
      sdram_wr_req   => sdram_wr_req,
      sdram_rd_addr  => sdram_rd_addr,
      sdram_wr_addr  => sdram_wr_addr,
      sdram_rd_data  => sdram_rd_data,
      sdram_wr_data  => sdram_wr_data,

      lcd_width   => conv_std_logic_vector(480,10),
      lcd_y       => lcd_y,
      lcd_vsync   => lcd_reg_vsync,
      lcd_wr_en   => lcd_scanline_wea(0),
      lcd_wr_addr => lcd_scanline_wr_addr,
      lcd_wr_data => lcd_scanline_wr_data,
      
      cpu_wr_en   => cpu_wr_en,
      cpu_addr    => cpu_addr,
      cpu_wr_data => cpu_wr_data,
      cpu_rd_data => cpu_rd_data,
      ready => cpu_sdram_rw_ready
	);

   lcd_scanline : vram_scanline
   PORT MAP (
    clka  => sdram_clk,
    wea   => lcd_scanline_wea,
    addra => lcd_scanline_wr_addr,
    dina  => lcd_scanline_wr_data,
    clkb  => lcd_clk,
    addrb => lcd_x,
    doutb => pixel_16bpp(15 downto 0)
   );

   lcd_pixel(23 downto 16)<=(others=>'0');
   lcd_pixel(15 downto 0)<=pixel_16bpp;
   lcd_hsync<=lcd_reg_hsync;
   lcd_vsync<=lcd_reg_vsync;
   lcd_AN430_chip: lcd_AN430 PORT MAP(
      en    => lcd_en,
		clk   => lcd_clk,
		red   => lcd_red,
		green => lcd_green,
		blue  => lcd_blue,
		hsync => lcd_reg_hsync,
		vsync => lcd_reg_vsync,
		de	   => lcd_de,
		x     => lcd_x,
		y     => lcd_y,
      dirty_x=>lcd_dirty_x,
      dirty_y=>lcd_dirty_y,
      pixel => lcd_pixel,
		char_x=> lcd_char_x,
		char_y=> lcd_char_y,
		char_code  => lcd_char
      );
-------------------------------------------------------------------

   sonar1_chip: sonar_driver port map(clk_1Mhz,clk_50Hz,trig1,echo1,sonar1_latency,sonar1_ready);
   sonar2_chip: sonar_driver port map(clk_1Mhz,clk_50Hz,trig2,echo2,sonar2_latency,sonar2_ready);

   sonar1_dist<="000000"&sonar1_latency(15 downto 6) when sonar1_ready='1';
   sonar2_dist<="000000"&sonar2_latency(15 downto 6) when sonar2_ready='1';

   sonar_cpu_chip: sonar_cpu port map(
      clk4,
      cpu_sdram_rw_en,cpu_sdram_rw_ready,
      cpu_wr_en,cpu_addr,cpu_wr_data,cpu_rd_data,
      sonar1_dist,sonar2_dist,alpha
   );

   bcd1_en<='1' when sonar1_ready='1' else '0';
   bcd2_en<='1' when sonar2_ready='1' else '0';
   bin24_to_bcd_chip1: bin24_to_bcd port map(clk_1Mhz,bcd1_en,"00000000"&sonar1_dist,bcd_num1,bcd1_ready);
   bin24_to_bcd_chip2: bin24_to_bcd port map(clk_1Mhz,bcd2_en,"00000000"&sonar2_dist,bcd_num2,bcd2_ready);
   bcd_num<=bcd_num1(11 downto 0) & bcd_num2(11 downto 0) when (bcd1_ready='1') and (bcd2_ready='1');
   smg_LCD: SMG_driver port map(clk_1Khz,'1',bcd_num,"110111",SMG_seg,SMG_dig);

   step_motor_cpu_chip: step_motor_cpu port map(
      clk_1Khz,clk_200Hz,clk_200Hz,step_motor_pins,alpha
   );

   led<=not(key);
end ax309;
