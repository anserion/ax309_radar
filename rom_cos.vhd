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
-- Description: 512 values of cosin function x \in [0 to 2*pi)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity rom_cos is
    Port ( 
		clk       : in STD_LOGIC;
		en        : in STD_LOGIC;
		addr      : in STD_LOGIC_VECTOR(8 downto 0);
		data      : out STD_LOGIC_VECTOR(7 downto 0)
	 );
end rom_cos;

architecture ax309 of rom_cos is
   type rom_type is array (0 to 511) of std_logic_vector(7 downto 0);
   constant ROM : rom_type:= (
x"64",x"63",x"63",x"63",x"63",x"63",x"63",x"63",x"63",x"63",x"63",x"63",x"62",x"62",x"62",x"62",
x"62",x"61",x"61",x"61",x"61",x"60",x"60",x"60",x"5F",x"5F",x"5E",x"5E",x"5E",x"5D",x"5D",x"5C",
x"5C",x"5B",x"5B",x"5A",x"5A",x"59",x"59",x"58",x"58",x"57",x"57",x"56",x"55",x"55",x"54",x"53",
x"53",x"52",x"51",x"51",x"50",x"4F",x"4E",x"4E",x"4D",x"4C",x"4B",x"4A",x"4A",x"49",x"48",x"47",
x"46",x"45",x"44",x"44",x"43",x"42",x"41",x"40",x"3F",x"3E",x"3D",x"3C",x"3B",x"3A",x"39",x"38",
x"37",x"36",x"35",x"34",x"33",x"32",x"31",x"30",x"2F",x"2E",x"2C",x"2B",x"2A",x"29",x"28",x"27",
x"26",x"25",x"23",x"22",x"21",x"20",x"1F",x"1E",x"1D",x"1B",x"1A",x"19",x"18",x"17",x"15",x"14",
x"13",x"12",x"11",x"0F",x"0E",x"0D",x"0C",x"0B",x"09",x"08",x"07",x"06",x"04",x"03",x"02",x"01",
x"00",x"FF",x"FE",x"FD",x"FC",x"FA",x"F9",x"F8",x"F7",x"F5",x"F4",x"F3",x"F2",x"F1",x"EF",x"EE",
x"ED",x"EC",x"EB",x"E9",x"E8",x"E7",x"E6",x"E5",x"E3",x"E2",x"E1",x"E0",x"DF",x"DE",x"DD",x"DB",
x"DA",x"D9",x"D8",x"D7",x"D6",x"D5",x"D4",x"D2",x"D1",x"D0",x"CF",x"CE",x"CD",x"CC",x"CB",x"CA",
x"C9",x"C8",x"C7",x"C6",x"C5",x"C4",x"C3",x"C2",x"C1",x"C0",x"BF",x"BE",x"BD",x"BC",x"BC",x"BB",
x"BA",x"B9",x"B8",x"B7",x"B6",x"B6",x"B5",x"B4",x"B3",x"B2",x"B2",x"B1",x"B0",x"AF",x"AF",x"AE",
x"AD",x"AD",x"AC",x"AB",x"AB",x"AA",x"A9",x"A9",x"A8",x"A8",x"A7",x"A7",x"A6",x"A6",x"A5",x"A5",
x"A4",x"A4",x"A3",x"A3",x"A2",x"A2",x"A2",x"A1",x"A1",x"A0",x"A0",x"A0",x"9F",x"9F",x"9F",x"9F",
x"9E",x"9E",x"9E",x"9E",x"9E",x"9D",x"9D",x"9D",x"9D",x"9D",x"9D",x"9D",x"9D",x"9D",x"9D",x"9D",
x"9C",x"9D",x"9D",x"9D",x"9D",x"9D",x"9D",x"9D",x"9D",x"9D",x"9D",x"9D",x"9E",x"9E",x"9E",x"9E",
x"9E",x"9F",x"9F",x"9F",x"9F",x"A0",x"A0",x"A0",x"A1",x"A1",x"A2",x"A2",x"A2",x"A3",x"A3",x"A4",
x"A4",x"A5",x"A5",x"A6",x"A6",x"A7",x"A7",x"A8",x"A8",x"A9",x"A9",x"AA",x"AB",x"AB",x"AC",x"AD",
x"AD",x"AE",x"AF",x"AF",x"B0",x"B1",x"B2",x"B2",x"B3",x"B4",x"B5",x"B6",x"B6",x"B7",x"B8",x"B9",
x"BA",x"BB",x"BC",x"BC",x"BD",x"BE",x"BF",x"C0",x"C1",x"C2",x"C3",x"C4",x"C5",x"C6",x"C7",x"C8",
x"C9",x"CA",x"CB",x"CC",x"CD",x"CE",x"CF",x"D0",x"D1",x"D2",x"D4",x"D5",x"D6",x"D7",x"D8",x"D9",
x"DA",x"DB",x"DD",x"DE",x"DF",x"E0",x"E1",x"E2",x"E3",x"E5",x"E6",x"E7",x"E8",x"E9",x"EB",x"EC",
x"ED",x"EE",x"EF",x"F1",x"F2",x"F3",x"F4",x"F5",x"F7",x"F8",x"F9",x"FA",x"FC",x"FD",x"FE",x"FF",
x"00",x"01",x"02",x"03",x"04",x"06",x"07",x"08",x"09",x"0B",x"0C",x"0D",x"0E",x"0F",x"11",x"12",
x"13",x"14",x"15",x"17",x"18",x"19",x"1A",x"1B",x"1D",x"1E",x"1F",x"20",x"21",x"22",x"23",x"25",
x"26",x"27",x"28",x"29",x"2A",x"2B",x"2C",x"2E",x"2F",x"30",x"31",x"32",x"33",x"34",x"35",x"36",
x"37",x"38",x"39",x"3A",x"3B",x"3C",x"3D",x"3E",x"3F",x"40",x"41",x"42",x"43",x"44",x"44",x"45",
x"46",x"47",x"48",x"49",x"4A",x"4A",x"4B",x"4C",x"4D",x"4E",x"4E",x"4F",x"50",x"51",x"51",x"52",
x"53",x"53",x"54",x"55",x"55",x"56",x"57",x"57",x"58",x"58",x"59",x"59",x"5A",x"5A",x"5B",x"5B",
x"5C",x"5C",x"5D",x"5D",x"5E",x"5E",x"5E",x"5F",x"5F",x"60",x"60",x"60",x"61",x"61",x"61",x"61",
x"62",x"62",x"62",x"62",x"62",x"63",x"63",x"63",x"63",x"63",x"63",x"63",x"63",x"63",x"63",x"63"
);
   signal rdata: std_logic_vector(7 downto 0);
begin
	rdata<=ROM(conv_integer(addr));
   process(clk)
   begin
		if rising_edge(clk) then
         if en='1' then
            data<=rdata;
         end if;
		end if;
	end process;
end ax309;