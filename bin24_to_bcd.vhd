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
-- Description: generate 8-digits bcd code from 24-bit binary number
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity bin24_to_bcd is
    Port ( 
		clk   : in  STD_LOGIC;
      en    : in std_logic;
      bin   : in std_logic_vector(23 downto 0);
      bcd   : out std_logic_vector(31 downto 0);
      ready : out std_logic
    );
end bin24_to_bcd;

architecture ax309 of bin24_to_bcd is
signal N: natural range 0 to 2**24-1;
signal K: natural range 0 to 9;
signal bin_reg: std_logic_vector(23 downto 0);
signal fsm: natural range 0 to 31:=0;
signal ready_reg: std_logic:='0';
begin
   ready<=ready_reg;
   process(clk)
   begin
      if rising_edge(clk) then
         if en='1' then
            case fsm is
            when 0=> 
                     N<=10000000; k<=1;
                     bin_reg<=bin;
                     fsm<=1;
            when 1=>
                     if bin_reg>=N then
                        fsm<=2;
                     else
                        N<=N-10000000;
                        k<=k-1;
                     end if;
            when 2=>
                     bcd(31 downto 28)<=conv_std_logic_vector(k,4);
                     fsm<=3;

            when 3=>
                     bin_reg<=bin_reg-N;
                     N<=9000000; k<=9;
                     fsm<=4;
            when 4=>
                     if bin_reg>=N then
                        fsm<=5;
                     else
                        N<=N-1000000;
                        k<=k-1;
                     end if;
            when 5=>
                     bcd(27 downto 24)<=conv_std_logic_vector(k,4);
                     fsm<=6;

            when 6=>
                     bin_reg<=bin_reg-N;
                     N<=900000; k<=9;
                     fsm<=7;
            when 7=>
                     if bin_reg>=N then
                        fsm<=8;
                     else
                        N<=N-100000;
                        k<=k-1;
                     end if;
            when 8=>
                     bcd(23 downto 20)<=conv_std_logic_vector(k,4);
                     fsm<=9;

            when 9=>
                     bin_reg<=bin_reg-N;
                     N<=90000; k<=9;
                     fsm<=10;
            when 10=>
                     if bin_reg>=N then
                        fsm<=11;
                     else
                        N<=N-10000;
                        k<=k-1;
                     end if;
            when 11=>
                     bcd(19 downto 16)<=conv_std_logic_vector(k,4);
                     fsm<=12;
                     
            when 12=>
                     bin_reg<=bin_reg-N;
                     N<=9000; k<=9;
                     fsm<=13;
            when 13=>
                     if bin_reg>=N then
                        fsm<=14;
                     else
                        N<=N-1000;
                        k<=k-1;
                     end if;
            when 14=>
                     bcd(15 downto 12)<=conv_std_logic_vector(k,4);
                     fsm<=15;

            when 15=>
                     bin_reg<=bin_reg-N;
                     N<=900; k<=9;
                     fsm<=16;
            when 16=>
                     if bin_reg>=N then
                        fsm<=17;
                     else
                        N<=N-100;
                        k<=k-1;
                     end if;
            when 17=>
                     bcd(11 downto 8)<=conv_std_logic_vector(k,4);
                     fsm<=18;

            when 18=>
                     bin_reg<=bin_reg-N;
                     N<=90; k<=9;
                     fsm<=19;
            when 19=>
                     if bin_reg>=N then
                        fsm<=20;
                     else
                        N<=N-10;
                        k<=k-1;
                     end if;
            when 20=>
                     bcd(7 downto 4)<=conv_std_logic_vector(k,4);
                     fsm<=21;
                     
            when 21=>
                     bin_reg<=bin_reg-N;
                     fsm<=22;
            when 22=>
                     bcd(3 downto 0)<=bin_reg(3 downto 0);
                     ready_reg<='1';
            when others=> null;
            end case;
         else
            ready_reg<='0';
            fsm<=0;
         end if;
      end if;
   end process;
end ax309;
