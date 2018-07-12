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
-- Description:simple step motor driver
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity step_motor_stop is
    Port (
      en   : in  std_logic;
      pins : out std_logic_vector(3 downto 0)
   );
end step_motor_stop;

architecture ax309 of step_motor_stop is
begin
   pins<=(others=>'0') when en='1';
end ax309;

------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity step_motor_CCW is
    Port (
      clk  : in std_logic;
      en   : in  std_logic;
      value: in std_logic_vector(31 downto 0);
      pins : out std_logic_vector(3 downto 0);
      ready: out std_logic
   );
end step_motor_CCW;

architecture ax309 of step_motor_CCW is
signal ready_reg: std_logic:='0';
signal i: std_logic_vector(31 downto 0):=(others=>'0');
signal fsm: natural range 0 to 3 := 0;
begin
   ready<=ready_reg;
   process(clk)
   begin
      if rising_edge(clk) then
         if en='1' then
            case fsm is
            when 0=>
               pins<="0011";
               fsm<=1;
            when 1=>
               pins<="0110";
               fsm<=2;
            when 2=>
               pins<="1100";
               fsm<=3;
            when 3=>
               if i = value then
                  pins<="0000";
                  ready_reg<='1';
               else
                  pins<="1001";
                  ready_reg<='0';
                  i<=i+1;
                  fsm<=0;                  
               end if;
            when others => null;
            end case;
         else
            ready_reg<='0';
            pins<="0000";
            i<=(others=>'0');
            fsm<=0;
         end if;
      end if;
   end process;
end ax309;

------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity step_motor_CW is
    Port (
      clk  : in std_logic;
      en   : in  std_logic;
      value: in std_logic_vector(31 downto 0);
      pins : out std_logic_vector(3 downto 0);
      ready: out std_logic
   );
end step_motor_CW;

architecture ax309 of step_motor_CW is
signal ready_reg: std_logic:='0';
signal i: std_logic_vector(31 downto 0):=(others=>'0');
signal fsm: natural range 0 to 3 := 0;
begin
   ready<=ready_reg;
   process(clk)
   begin
      if rising_edge(clk) then
         if en='1' then
            case fsm is
            when 0=>
               pins<="1001";
               fsm<=1;
            when 1=>
               pins<="1100";
               fsm<=2;
            when 2=>
               pins<="0110";
               fsm<=3;
            when 3=>
               if i = value then
                  pins<="0000";
                  ready_reg<='1';
               else
                  pins<="1001";
                  ready_reg<='0';
                  i<=i+1;
                  fsm<=0;                  
               end if;
            when others => null;
            end case;
         else
            ready_reg<='0';
            pins<="0000";
            i<=(others=>'0');
            fsm<=0;
         end if;
      end if;
   end process;
end ax309;
