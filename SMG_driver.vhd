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
-- Description: 7 segments 6 digit LCD panel driver
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity SMG_driver is
    Port ( 
		clk    : in  STD_LOGIC;
      en     : in  STD_LOGIC;
      bcd_num: in STD_LOGIC_VECTOR(23 downto 0);
      mask   : in STD_LOGIC_VECTOR(5 downto 0);
      SEG    : out STD_LOGIC_VECTOR(7 downto 0);
      DIG    : out STD_LOGIC_VECTOR(5 downto 0)
	 );
end SMG_driver;

architecture ax309 of SMG_driver is
   signal fsm: natural range 0 to 15 := 0;
   signal bcd_code: std_logic_vector(3 downto 0);
   signal DP_reg: std_logic:='0';
   signal DIG_reg: STD_LOGIC_VECTOR(5 downto 0);
   signal SEG_reg: STD_LOGIC_VECTOR(6 downto 0);
begin
   SEG<=DP_reg & SEG_reg;
   DIG<=DIG_reg;
   process(clk)
   begin
		if rising_edge(clk) and (en='1') then
         case fsm is
         when 0=> fsm<=1;
         when 1=>
            bcd_code<=bcd_num(3 downto 0);
            fsm<=2;
         when 2=>
            DP_reg<=mask(0);
            DIG_reg<="111110";
            fsm<=3;
         when 3=>
            bcd_code<=bcd_num(7 downto 4);
            fsm<=4;
         when 4=>   
            DP_reg<=mask(1);
            DIG_reg<="111101";
            fsm<=5;
         when 5=>
            bcd_code<=bcd_num(11 downto 8);
            fsm<=6;
         when 6=>
            DP_reg<=mask(2);
            DIG_reg<="111011";
            fsm<=7;
         when 7=>
            bcd_code<=bcd_num(15 downto 12);
            fsm<=8;
         when 8=>
            DP_reg<=mask(3);
            DIG_reg<="110111";
            fsm<=9;
         when 9=>
            bcd_code<=bcd_num(19 downto 16);
            fsm<=10;
         when 10=>
            DP_reg<=mask(4);
            DIG_reg<="101111";
            fsm<=11;
         when 11=>
            bcd_code<=bcd_num(23 downto 20);
            fsm<=12;
         when 12=>
            DP_reg<=mask(5);
            DIG_reg<="011111";
            fsm<=0;
         when others => null;
         end case;
         
         case bcd_code is
         when "0000" => SEG_reg<="1000000";
         when "0001" => SEG_reg<="1111001";
         when "0010" => SEG_reg<="0100100";
         when "0011" => SEG_reg<="0110000";
         when "0100" => SEG_reg<="0011001";
         when "0101" => SEG_reg<="0010010";
         when "0110" => SEG_reg<="0000010";
         when "0111" => SEG_reg<="1111000";
         when "1000" => SEG_reg<="0000000";
         when "1001" => SEG_reg<="0010000";
         when others => SEG_reg<="1111111";
         end case;
		end if;
	end process;
end ax309;
