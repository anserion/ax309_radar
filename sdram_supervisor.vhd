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
-- Description: sdram supervisor.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sdram_supervisor is
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
end sdram_supervisor;

architecture ax309 of sdram_supervisor is
   signal fsm: natural range 0 to 31 := 0;
   signal sdram_x : std_logic_vector(9 downto 0) := (others => '0');
   signal sdram_y : std_logic_vector(9 downto 0) := (others => '0');
   signal lcd_parity: std_logic:='0';
   signal cpu_ready: std_logic:='1';
begin
   process(clk)
   begin
      if rising_edge(clk) and en='1' then
         case fsm is
         when 0=> fsm<=1; --reserved
         when 1=> fsm<=2; --reserved
         when 2=> fsm<=3; --reserved
         --------------------------------
         -- SDRAM to LCD device section
         --------------------------------
         when 3 => 
            if lcd_en='1' and lcd_vsync='0' and lcd_y(0)=lcd_parity
            then
               sdram_x<=(others=>'0');
               sdram_y<=lcd_y;
               sdram_rd_req<='1';
               sdram_wr_req<='0';
               lcd_wr_en<='1';
               lcd_parity<=not(lcd_parity);
               fsm<=4;
            else 
               sdram_rd_req<='0';
               sdram_wr_req<='0';
               fsm <= 16;
            end if;
         when 4 =>
            if sdram_x/=lcd_width
            then
               sdram_x<=sdram_x+1;
               sdram_rd_addr <= "00" & "00" & sdram_y & sdram_x;
               fsm<=5;
            else
               sdram_rd_req<='0';
               sdram_wr_req<='0';
               lcd_wr_en<='0';
               fsm<=16;
            end if;
         when 5 =>
            if sdram_rd_valid='1' then
               lcd_wr_addr<=sdram_x;
               lcd_wr_data<=sdram_rd_data;
               fsm<=4;
            end if;
         --------------------------------
         -- end of SDRAM to LCD section
         --------------------------------            

         --------------------------------
         -- low priority CPU to SDRAM section
         --------------------------------            
         when 16 =>
         if cpu_en='0' then
            ready<='1';
            cpu_ready<='1';
            fsm<=0;
         else
            if cpu_ready='1' then
               cpu_ready<='0';
               if cpu_wr_en='0' then
                  sdram_rd_req<='1';
                  sdram_wr_req<='0';
                  sdram_rd_addr <= cpu_addr;
                  ready<='0';
                  fsm <= 17;
               else 
                  sdram_rd_req<='0';
                  sdram_wr_req<='1';
                  sdram_wr_addr <= cpu_addr;
                  sdram_wr_data <= cpu_wr_data;
                  ready<='0';
                  fsm <= 18;
               end if;
            else fsm<=0;
            end if;
         end if;
         when 17 =>
            if sdram_rd_valid='1' then
               cpu_rd_data<=sdram_rd_data;
               ready<='1';
               fsm<=0;
            end if;
         when 18 => fsm<=19;
         when 19 => fsm<=20;
         when 20=> ready<='1'; fsm<=0;
         when others => null;
         end case;
      end if;
   end process;
end;

