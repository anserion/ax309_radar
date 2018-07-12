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
-- Description: calculate ticks of input signal
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity pulsein_module is
    Port ( 
      clk_1Mhz: in  STD_LOGIC;
      input   : in  STD_LOGIC;
      value   : in  STD_LOGIC;
      result  : out STD_LOGIC_VECTOR(31 downto 0);
      ready   : out STD_LOGIC
	 );
end pulsein_module;

architecture ax309 of pulsein_module is
   signal fsm: natural range 0 to 1 := 0;
   signal ready_reg: std_logic:='0';
   signal cnt: std_logic_vector(31 downto 0):=(others=>'0');
begin
   ready<=ready_reg;
   result<=cnt;
   process(clk_1Mhz)
   begin
		if rising_edge(clk_1Mhz) then
         case fsm is
         when 0=>
            if input=value then
               ready_reg<='0';
               cnt<=(others=>'0');
               fsm<=1;
            end if;
         when 1=>
            if input=not(value) then
               ready_reg<='1';
               fsm<=0;
            else
               cnt<=cnt+1;
            end if;
         when others => null;
         end case;
		end if;
	end process;
end ax309;
