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

entity sonar_driver is
    Port ( 
		clk_1Mhz: in  STD_LOGIC;
      en       : in  STD_LOGIC;
      trig     : out STD_LOGIC;
      echo     : in  STD_LOGIC;
      latency  : out STD_LOGIC_VECTOR(15 downto 0);
      ready    : out STD_LOGIC
	 );
end sonar_driver;

architecture ax309 of sonar_driver is
   signal fsm: natural range 0 to 3 := 0;
   signal cnt: natural range 0 to 63 := 0;
   signal result_reg: std_logic_vector(15 downto 0):=(others=>'0');
   signal ready_reg: std_logic:='0';
   signal trig_reg: std_logic:='0';
begin
   trig<=trig_reg;
   ready<=ready_reg;
   latency<=result_reg;
   process(clk_1Mhz)
   begin
   if rising_edge(clk_1Mhz) then
   case fsm is
   when 0=> if en='1' then
               ready_reg<='0'; result_reg<=(others=>'0');
               trig_reg<='1'; cnt<=0;
               fsm<=1;
            end if;
   when 1=> if cnt=50 then trig_reg<='0'; fsm<=2; else cnt<=cnt+1; end if;
   when 2=> if (en='0')or(echo='1') then fsm<=3; end if;
   when 3=> if (en='0')or(echo='0') then
               ready_reg<='1';
               if en='0' then fsm<=0; end if;
            else result_reg<=result_reg+1;
            end if;
   when others=>null;
   end case;
   end if;
   end process;
end ax309;
