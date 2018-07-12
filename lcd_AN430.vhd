------------------------------------------------------------------
--Copyright 2017 Andrey S. Ionisyan (anserion@gmail.com)
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

----------------------------------------------------------------------------------
-- Engineer: Andrey S. Ionisyan <anserion@gmail.com>
-- 
-- Description: Controller 480x272 LCD AN430 (TM043NBH02 panel)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity lcd_AN430 is
    Port (
      en      : in std_logic;
		clk     : in  STD_LOGIC;
		red     : out STD_LOGIC_VECTOR(7 downto 0);
		green   : out STD_LOGIC_VECTOR(7 downto 0);
		blue    : out STD_LOGIC_VECTOR(7 downto 0);
		hsync   : out STD_LOGIC;
		vsync   : out STD_LOGIC;
		de      : out STD_LOGIC;
		x       : out STD_LOGIC_VECTOR(9 downto 0);
		y       : out STD_LOGIC_VECTOR(9 downto 0);
      dirty_x : out STD_LOGIC_VECTOR(9 downto 0);
      dirty_y : out STD_LOGIC_VECTOR(9 downto 0);
      pixel   : in STD_LOGIC_VECTOR(23 downto 0);
		char_x    : out STD_LOGIC_VECTOR(6 downto 0);
		char_y	 : out STD_LOGIC_VECTOR(4 downto 0);
		char_code : in  STD_LOGIC_VECTOR(7 downto 0)
	 );
end lcd_AN430;

architecture ax309 of lcd_AN430 is
   component rom_vgafont
   Port ( 
		clk       : in STD_LOGIC;
		en        : in STD_LOGIC;
		addr      : in STD_LOGIC_VECTOR(11 downto 0);
		data      : out STD_LOGIC_VECTOR(7 downto 0)
	 );
   end component;

   component counter_xy
   generic (
      n: natural range 1 to 10:=10;
      x_min: natural range 0 to 1023:=0;
      y_min: natural range 0 to 1023:=0;
      x_max: natural range 0 to 1023:=479;
      y_max: natural range 0 to 1023:=271
   );
   Port ( 
		clk   : in  STD_LOGIC;
      en    : in std_logic;
      reset : in std_logic;
      x     : out std_logic_vector (n-1 downto 0);
      y     : out std_logic_vector (n-1 downto 0)
	 );
   end component;

   -- Timing constants
   constant hStartSync : natural := 43;
   constant hStartWin  : natural := hStartSync+30;
   constant hEndWin    : natural := hStartWin+480;
   constant hEndSync   : natural := hStartSync+525;
   constant hMaxCount  : natural := 600;
	
   constant vStartSync : natural := 12;
   constant vStartWin  : natural := vStartSync+3;
   constant vEndWin    : natural := vStartWin+272;
   constant vEndSync   : natural := vStartSync+280;
   constant vMaxCount  : natural := 300;
	
   signal hCounter   : std_logic_vector(9 downto 0) := (others => '0');
   signal vCounter   : std_logic_vector(9 downto 0) := (others => '0');
	signal reg_x      : std_logic_vector(9 downto 0) := (others => '0');
   signal next_x      : std_logic_vector(9 downto 0) := (others => '0');
	signal reg_y      : std_logic_vector(9 downto 0) := (others => '0');
   signal reg_hSync  : std_logic := '1';
   signal reg_vSync  : std_logic := '1';
   signal hWin_de: std_logic := '1';
   signal vWin_de: std_logic := '1';
	signal reg_de     : std_logic := '1';
	signal char_line  : std_logic_vector(7 downto 0);
   
begin
   next_x<=reg_x+2;
   char_x<=next_x(9 downto 3);
   char_y<=reg_y(8 downto 4);
   
   rom_vgafont_chip: rom_vgafont
   port map(
      clk => clk,
      en  => en,
      addr => char_code & reg_y(3 downto 0),
      data => char_line
   );

   counter_xy_chip: counter_xy
   generic map(
      x_max => hMaxCount,
      y_max => vMaxCount
   )
   Port map( 
		clk   => clk,
      en    => en,
      reset => not(en),
      x     => hCounter,
      y     => vCounter
	 );

   counter_out_xy_chip: counter_xy
   Port map( 
		clk   => clk,
      en    => reg_de,
      reset => not(en),
      x     => reg_x,
      y     => reg_y
	 );
   
   hSync<=reg_hSync;
   vSync<=reg_vSync;
	x <= reg_x;
	y <= reg_y;
   dirty_x<=hCounter;
   dirty_y<=vCounter;
   de<=reg_de;
   reg_de<=en and not(hWin_de or vWin_de);
	
   process(clk)
   begin
		if rising_edge(clk) then
       if en='1' then
			if reg_de = '1' then
				if char_line(7-conv_integer(reg_x(2 downto 0)))='1' then
					blue  <= (others=>'1');
					green <= (others=>'1');
					red   <= (others=>'1');
				else
					blue  <= pixel(23 downto 16);
					green <= pixel(15 downto 8);
					red   <= pixel(7 downto 0);
				end if;
			else
				red   <= (others => '0');
				green <= (others => '0');
				blue  <= (others => '0');
			end if;
	
			if vCounter=vStartSync then reg_vSync <= '0';
         elsif vCounter=vEndSync then reg_vSync <= '1';
         end if;

         if reg_vSync='0' then
            if hCounter=hStartSync then reg_hSync <= '0';
            elsif hCounter=hEndSync then reg_hSync <= '1';
            end if;
         else reg_hSync <= '1';
         end if;

			if vCounter=vStartWin then vWin_de <= '0';
         elsif vCounter=vEndWin then vWin_de <= '1';
         end if;

         if vWin_de='0' then
            if hCounter=hStartWin then hWin_de <= '0';
            elsif hCounter=hEndWin then hWin_de <= '1';
            end if;
         else hWin_de <= '1';
         end if;
       else
         reg_hsync<='1'; reg_vsync<='1';
         hWin_de<='1'; vWin_de<='1';
       end if;
		end if;
	end process;
end ax309;