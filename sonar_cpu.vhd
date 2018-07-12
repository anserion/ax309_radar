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

----------------------------------------------------------------------------------
-- Engineer: Andrey S. Ionisyan <anserion@gmail.com>
-- 
-- Description: sonar HC-SR04 supervisor
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity sonar_cpu is
    Port ( 
		clk : in std_logic;
      mem_rw_en   : out std_logic;
      mem_rw_ready: in std_logic;
      mem_wr_en   : out std_logic;
      mem_addr    : out std_logic_vector(23 downto 0);
      mem_wr_data : out std_logic_vector(15 downto 0);
      mem_rd_data : in std_logic_vector(15 downto 0);
      dist1 : in std_logic_vector(15 downto 0);
      dist2 : in std_logic_vector(15 downto 0);
      alpha : in std_logic_vector(8 downto 0)
	 );
end sonar_cpu;

architecture ax309 of sonar_cpu is
   component rom_sin is
    Port ( 
		clk       : in STD_LOGIC;
		en        : in STD_LOGIC;
		addr      : in STD_LOGIC_VECTOR(8 downto 0);
		data      : out STD_LOGIC_VECTOR(7 downto 0)
	 );
   end component;

   component rom_cos is
    Port ( 
		clk       : in STD_LOGIC;
		en        : in STD_LOGIC;
		addr      : in STD_LOGIC_VECTOR(8 downto 0);
		data      : out STD_LOGIC_VECTOR(7 downto 0)
	 );
   end component;
   
   signal mem_addr_reg: std_logic_vector(23 downto 0):=(others=>'0');
   signal fsm: natural range 0 to 255 := 0;
   
   signal clear_cnt: std_logic_vector(31 downto 0):=(others=>'0');
   
   signal fade_x,fade_y: std_logic_vector(9 downto 0):=(others=>'0');
   signal pixel: std_logic_vector(15 downto 0):=(others=>'0');
   
   signal angle: std_logic_vector(8 downto 0):=(others=>'0');
   signal cos_arg,sin_arg: std_logic_vector(8 downto 0):=(others=>'0');
   signal cos_value,sin_value: std_logic_vector(7 downto 0):=(others=>'0');
   
   signal c1_x,c1_y: std_logic_vector(9 downto 0):=(others=>'0');
   signal c2_x,c2_y: std_logic_vector(9 downto 0):=(others=>'0');
   signal c3_x,c3_y: std_logic_vector(9 downto 0):=(others=>'0');
   signal c4_x,c4_y: std_logic_vector(9 downto 0):=(others=>'0');
   signal c5_x,c5_y: std_logic_vector(9 downto 0):=(others=>'0');
   
   signal hor_x,hor_y: std_logic_vector(9 downto 0):=(others=>'0');
   signal vert_x,vert_y: std_logic_vector(9 downto 0):=(others=>'0');
   
   signal sonar1_tmpX,sonar1_tmpY: std_logic_vector(15 downto 0):=(others=>'0');
   signal sonar2_tmpX,sonar2_tmpY: std_logic_vector(15 downto 0):=(others=>'0');
   signal sonar1_x,sonar1_y: std_logic_vector(9 downto 0):=(others=>'0');
   signal sonar2_x,sonar2_y: std_logic_vector(9 downto 0):=(others=>'0');

begin
   rom_cos_chip: rom_cos port map(clk,'1',cos_arg,cos_value);
   rom_sin_chip: rom_sin port map(clk,'1',sin_arg,sin_value);
   
   mem_addr<=mem_addr_reg;
   process(clk)
   begin
   if rising_edge(clk) then
   case fsm is
   when 0=>
      if clear_cnt=conv_std_logic_vector(8000000,32) then
         mem_addr_reg<=(others=>'0');
         mem_rw_en<='0';
         clear_cnt<=(others=>'0');
         fsm<=1;
      else
         clear_cnt<=clear_cnt+1;
         fsm<=41;
      end if;
      
   --clear display
   when 1=>
      if mem_addr_reg=conv_std_logic_vector(272*1024,24) then fsm<=10;
      else mem_addr_reg<=mem_addr_reg+1;
         mem_wr_data<=conv_std_logic_vector(0,16);
         mem_wr_en<='1';
         mem_rw_en<='1';
         fsm<=2;
      end if;
   when 2=>
      if mem_rw_ready='1' then
         mem_rw_en<='0';
         fsm<=1;
      end if;

   -- fade effect
   when 3=>
      fade_x<=(others=>'0');
      fade_y<=(others=>'0');
      mem_rw_en<='0';
      fsm<=4;
   when 4=>
      if fade_y=conv_std_logic_vector(272,10) then fsm<=10;
      else fsm<=5;
      end if;
   when 5=>
      if fade_x=conv_std_logic_vector(479,10) then
         fade_x<=(others=>'0'); fade_y<=fade_y+1;
         fsm<=4;
      else
         fade_x<=fade_x+1;
         fsm<=6;
      end if;
   when 6=>
      mem_addr_reg<="0000" & fade_y & fade_x;
      mem_wr_en<='0';
      mem_rw_en<='1';
      fsm<=7;
   when 7=>
      if mem_rw_ready='1' then
         mem_rw_en<='0';
         pixel<=mem_rd_data;
         fsm<=8;
      end if;
   when 8=>
      mem_addr_reg<="0000" & fade_y & fade_x;
      if pixel=conv_std_logic_vector(0,16) then mem_wr_data<=(others=>'0');
      else mem_wr_data<=pixel-conv_std_logic_vector(1,16);
      end if;
      mem_wr_en<='1';
      mem_rw_en<='1';
      fsm<=9;
   when 9=>
      if mem_rw_ready='1' then
         mem_rw_en<='0';
         fsm<=5;
      end if;
      
   -- draw circle's with 25,50,100,125 radiuses
   when 10=> 
      angle<=conv_std_logic_vector(0,9);
      mem_rw_en<='0';
      fsm<=11;
   when 11=>
      if angle=conv_std_logic_vector(511,9) then fsm<=31;
      else angle<=angle+1; fsm<=12;
      end if;
   when 12=>
      cos_arg<=angle;
      sin_arg<=angle;
      fsm<=13;

   when 13=>
      c4_x<=cos_value(7)&cos_value(7)&cos_value+240;
      c4_y<=sin_value(7)&sin_value(7)&sin_value+136;
      fsm<=14;
   when 14=>
      mem_addr_reg<="0000" & c4_y & c4_x;
      mem_wr_data<=conv_std_logic_vector(180*256,16);
      mem_wr_en<='1';
      mem_rw_en<='1';
      fsm<=15;
   when 15=>
      if mem_rw_ready='1' then
         mem_rw_en<='0';
         fsm<=16;
      end if;
--------------------------------------
   when 16=>
      c2_x<=cos_value(7)&cos_value(7)&cos_value(7)&cos_value(7 downto 1)+240;
      c2_y<=sin_value(7)&sin_value(7)&sin_value(7)&sin_value(7 downto 1)+136;
      fsm<=17;
   when 17=>
      mem_addr_reg<="0000" & c2_y & c2_x;
      mem_wr_data<=conv_std_logic_vector(180*256,16);
      mem_wr_en<='1';
      mem_rw_en<='1';
      fsm<=18;
   when 18=>
      if mem_rw_ready='1' then
         mem_rw_en<='0';
         fsm<=19;
      end if;

   when 19=>
      c1_x<=cos_value(7)&cos_value(7)&cos_value(7)&cos_value(7)&cos_value(7 downto 2)+240;
      c1_y<=sin_value(7)&sin_value(7)&sin_value(7)&sin_value(7)&sin_value(7 downto 2)+136;
      fsm<=20;
   when 20=>
      mem_addr_reg<="0000" & c1_y & c1_x;
      mem_wr_data<=conv_std_logic_vector(180*256,16);
      mem_wr_en<='1';
      mem_rw_en<='1';
      fsm<=21;
   when 21=>
      if mem_rw_ready='1' then
         mem_rw_en<='0';
         fsm<=22;
      end if;

   when 22=>
      c3_x<=(c1_x+c2_x)-240;
      c3_y<=(c1_y+c2_y)-136;
      fsm<=23;
   when 23=>
      mem_addr_reg<="0000" & c3_y & c3_x;
      mem_wr_data<=conv_std_logic_vector(180*256,16);
      mem_wr_en<='1';
      mem_rw_en<='1';
      fsm<=24;
   when 24=>
      if mem_rw_ready='1' then
         mem_rw_en<='0';
         fsm<=25;
      end if;

   when 25=>
      c5_x<=(c1_x+c4_x)-240;
      c5_y<=(c1_y+c4_y)-136;
      fsm<=26;
   when 26=>
      mem_addr_reg<="0000" & c5_y & c5_x;
      mem_wr_data<=conv_std_logic_vector(180*256,16);
      mem_wr_en<='1';
      mem_rw_en<='1';
      fsm<=27;
   when 27=>
      if mem_rw_ready='1' then
         mem_rw_en<='0';
         fsm<=11;
      end if;

   -----------------------------------------------------------
   -- horisontal lines y=136 +/- k*25, x=[0,479]
   when 31=>
      hor_x<=(others=>'0');
      hor_y<=conv_std_logic_vector(11,10);
      mem_rw_en<='0';
      fsm<=32;
   when 32=>
      if hor_y=conv_std_logic_vector(286,10) then fsm<=36;
      else fsm<=33;
      end if;
   when 33=>
      if hor_x=conv_std_logic_vector(479,10) then
         hor_x<=(others=>'0'); hor_y<=hor_y+25;
         fsm<=32;
      else
         hor_x<=hor_x+1;
         fsm<=34;
      end if;
   when 34=>
      mem_addr_reg<="0000" & hor_y & hor_x;
      mem_wr_data<=conv_std_logic_vector(180*256,16);
      mem_wr_en<='1';
      mem_rw_en<='1';
      fsm<=35;
   when 35=>
      if mem_rw_ready='1' then
         mem_rw_en<='0';
         fsm<=33;
      end if;

   -----------------------------------------------------------
   -- vertical lines x=240 +/- k*25, y=[0,271]
   when 36=>
      vert_x<=conv_std_logic_vector(15,10);
      vert_y<=(others=>'0');
      mem_rw_en<='0';
      fsm<=37;
   when 37=>
      if vert_x=conv_std_logic_vector(490,10) then fsm<=41;
      else fsm<=38;
      end if;
   when 38=>
      if vert_y=conv_std_logic_vector(271,10) then
         vert_y<=(others=>'0'); vert_x<=vert_x+25;
         fsm<=37;
      else
         vert_y<=vert_y+1;
         fsm<=39;
      end if;
   when 39=>
      mem_addr_reg<="0000" & vert_y & vert_x;
      mem_wr_data<=conv_std_logic_vector(180*256,16);   
      mem_wr_en<='1';
      mem_rw_en<='1';
      fsm<=40;
   when 40=>
      if mem_rw_ready='1' then
         mem_rw_en<='0';
         fsm<=38;
      end if;
      
   -----------------------------------------------------------
   -- sonar draw
   when 41=> 
      cos_arg<=alpha;
      sin_arg<=alpha;
      mem_rw_en<='0';
      fsm<=42;
   when 42=> -- ROM wait
      fsm<=43;
   when 43=>
      if cos_value(7)='0' then
         sonar1_tmpX<=dist1(7 downto 0)*cos_value;
         sonar2_tmpX<=dist2(7 downto 0)*cos_value;
      else
         sonar1_tmpX<=dist1(7 downto 0)*(conv_std_logic_vector(1,8)-cos_value);
         sonar2_tmpX<=dist2(7 downto 0)*(conv_std_logic_vector(1,8)-cos_value);
      end if;
      if sin_value(7)='0' then
         sonar1_tmpY<=dist1(7 downto 0)*sin_value;
         sonar2_tmpY<=dist2(7 downto 0)*sin_value;
      else
         sonar1_tmpY<=dist1(7 downto 0)*(conv_std_logic_vector(1,8)-sin_value);
         sonar2_tmpY<=dist2(7 downto 0)*(conv_std_logic_vector(1,8)-sin_value);
      end if;
      fsm<=44;
   when 44=>
      if cos_value(7)='0' then
         sonar1_x<=conv_std_logic_vector(240,10)+("0"&sonar1_tmpX(15 downto 7));
         sonar2_x<=conv_std_logic_vector(240,10)-("0"&sonar2_tmpX(15 downto 7));
      else
         sonar1_x<=conv_std_logic_vector(240,10)-("0"&sonar1_tmpX(15 downto 7));
         sonar2_x<=conv_std_logic_vector(240,10)+("0"&sonar2_tmpX(15 downto 7));
      end if;
      if sin_value(7)='0' then
         sonar1_y<=conv_std_logic_vector(136,10)+("0"&sonar1_tmpY(15 downto 7));
         sonar2_y<=conv_std_logic_vector(136,10)-("0"&sonar2_tmpY(15 downto 7));
      else
         sonar1_y<=conv_std_logic_vector(136,10)-("0"&sonar1_tmpY(15 downto 7));
         sonar2_y<=conv_std_logic_vector(136,10)+("0"&sonar2_tmpY(15 downto 7));
      end if;
      fsm<=45;
   when 45=>
      mem_addr_reg<="0000" & sonar1_y & sonar1_x;
      mem_wr_data<=conv_std_logic_vector(65535,16);
      mem_wr_en<='1';
      mem_rw_en<='1';
      fsm<=46;
   when 46=>
      if mem_rw_ready='1' then
         mem_rw_en<='0';
         fsm<=47;
      end if;
   when 47=>
      mem_addr_reg<="0000" & sonar2_y & sonar2_x;
      mem_wr_data<=conv_std_logic_vector(65535,16);
      mem_wr_en<='1';
      mem_rw_en<='1';
      fsm<=48;
   when 48=>
      if mem_rw_ready='1' then
         mem_rw_en<='0';
         fsm<=0;
      end if;
   
   when others=>null;
   end case;
   end if;
   end process;
end ax309;
