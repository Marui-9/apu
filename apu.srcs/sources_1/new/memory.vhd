----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/19/2026 08:43:12 AM
-- Design Name: 
-- Module Name: memory - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;

entity memory is
    generic( -- default values for when the instance is not given any
        ADDR_WIDTH : positive := 14; -- not natural because cannot be negative
        INIT_FILE : string := "test1.mem"
    );
    port (
        clk   : in  std_logic;
        en    : in  std_logic;
        we    : in  std_logic_vector(3 downto 0); --one enable per byte
        addr  : in  std_logic_vector(31 downto 0);   -- word address
        wdata : in  std_logic_vector(31 downto 0);
        rdata : out std_logic_vector(31 downto 0)
    );
end memory;
-- to instantiate at the same elvel as core, under a top_soc module
architecture Behavioral of memory is
    constant DEPTH : positive := 2**ADDR_WIDTH;
    type mem_t is array (0 to DEPTH-1) of std_logic_vector(31 downto 0);

impure function load_hex(fname : string) return mem_t is
    file     f : text open read_mode is fname;   -- file opened at func call and closed when done
    variable l : line;                            -- onw text line from file
    variable m : mem_t := (others => (others => '0'));   -- unused words stay zero
begin
    for i in mem_t'range loop    -- one word per file line
        exit when endfile(f);         -- stop if file is shorter than memory
        readline(f, l);        
        hread(l, m(i));     -- parse the read line as hex into 32 bit vector
    end loop;
    return m;      -- the whole array becomes the initial value
end function;


    signal mem : mem_t := load_hex(INIT_FILE);
    signal idx : natural range 0 to DEPTH-1;
begin
    idx <= to_integer(unsigned(addr(ADDR_WIDTH+1 downto 2)));   -- drop byte offset bits 1:0

    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                for b in 0 to 3 loop
                    if we(b) = '1' then
                        mem(idx)(8*b+7 downto 8*b) <= wdata(8*b+7 downto 8*b);
                    end if;
                end loop;
                rdata <= mem(idx);
            end if;
        end if;
    end process;
end Behavioral;
