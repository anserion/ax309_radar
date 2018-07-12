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

entity step_motor_cpu is
    Port ( 
		clk_1kHz : in  std_logic;
      clk_ccw  : in  std_logic;
      clk_cw   : in  std_logic;
      step_motor_pins : out std_logic_vector(3 downto 0);
      alpha : out std_logic_vector(8 downto 0)
	 );
end step_motor_cpu;

architecture ax309 of step_motor_cpu is
   component step_motor_CCW is
    Port (
      clk  : in std_logic;
      en   : in  std_logic;
      value: in std_logic_vector(31 downto 0);
      pins : out std_logic_vector(3 downto 0);
      ready: out std_logic
   );
   end component;

   component step_motor_CW is
    Port (
      clk  : in std_logic;
      en   : in  std_logic;
      value: in std_logic_vector(31 downto 0);
      pins : out std_logic_vector(3 downto 0);
      ready: out std_logic
   );
   end component;

   signal step_motor_ccw_en,step_motor_ccw_ready: std_logic:='0';
   signal step_motor_ccw_value: std_logic_vector(31 downto 0);
   signal step_motor_ccw_pins: std_logic_vector(3 downto 0):=(others=>'0');

   signal step_motor_cw_en,step_motor_cw_ready: std_logic:='0';
   signal step_motor_cw_value: std_logic_vector(31 downto 0);
   signal step_motor_cw_pins: std_logic_vector(3 downto 0):=(others=>'0');

   signal fsm: natural range 0 to 3 := 0;
   signal alpha_reg: std_logic_vector(31 downto 0):=(others=>'0');
   signal tmp: std_logic_vector(31 downto 0):=(others=>'0');
begin
   step_motor_cw_chip: step_motor_cw port map (clk_cw,step_motor_cw_en,step_motor_cw_value,step_motor_cw_pins,step_motor_cw_ready);
   step_motor_ccw_chip: step_motor_ccw port map (clk_ccw,step_motor_ccw_en,step_motor_ccw_value,step_motor_ccw_pins,step_motor_ccw_ready);

   step_motor_ccw_value<=conv_std_logic_vector(540,32);
   step_motor_cw_value<=conv_std_logic_vector(540,32);
   
   alpha<=tmp(22 downto 14);
   process(clk_1kHz)
   begin
   if rising_edge(clk_1kHz) then
   case fsm is
   when 0=>
         if alpha_reg=conv_std_logic_vector(5500,32) then
            fsm<=1;
         else
            alpha_reg<=alpha_reg+1;
         end if;
         step_motor_pins<=step_motor_cw_pins;
         step_motor_cw_en<='1';
         step_motor_ccw_en<='0';
         tmp<=alpha_reg(21 downto 0)*conv_std_logic_vector(760,10);
   when 1=>
         if alpha_reg=0 then
            fsm<=0;
         else
            alpha_reg<=alpha_reg-1;
         end if;
         step_motor_pins<=step_motor_ccw_pins;
         step_motor_ccw_en<='1';
         step_motor_cw_en<='0'; 
         tmp<=alpha_reg(21 downto 0)*conv_std_logic_vector(760,10);
   when others=> null;
   end case;
   end if;
   end process;
end ax309;
