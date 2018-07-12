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
-- Description: delay counter
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity delay_module is
    Port ( 
		clk   : in  STD_LOGIC;
      en    : in  STD_LOGIC;
      value : in STD_LOGIC_VECTOR(31 downto 0);
      outpin: out STD_LOGIC
	 );
end delay_module;

architecture ax309 of delay_module is
   signal trig: std_logic:='0';
   signal fsm: natural range 0 to 1 := 0;
   signal cnt: std_logic_vector(31 downto 0):=(others=>'0');
begin
   outpin<=trig;
   process(clk)
   begin
		if rising_edge(clk) then
         case fsm is
         when 0=>
            if en='1' then
               trig<='1'; cnt<=(others=>'0');
               fsm<=1;
            end if;
         when 1=>
            if cnt=value then
               trig<='0';
               if en='0' then fsm<=0; end if;
            else
               cnt<=cnt+1;
            end if; 
         when others => null;
         end case;
		end if;
	end process;
end ax309;
