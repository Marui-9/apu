----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/19/2026 04:34:37 PM
-- Design Name: 
-- Module Name: tb_soc - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use work.config_pkg.all;
use work.core_pkg.all;
use work.pipeline_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_soc is
end tb_soc;

architecture sim of tb_soc is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    -- "0x" followed by the low 4*digits bits of v in lowercase hex, like spike prints
    function hex(v : std_logic_vector; digits : positive) return string is
        constant HEXCHARS : string(1 to 16) := "0123456789abcdef";
        variable u : unsigned(4*digits-1 downto 0) := resize(unsigned(v), 4*digits);
        variable s : string(1 to digits+2) := (others => '0');
    begin
        s(1 to 2) := "0x";
        for i in 0 to digits-1 loop
            s(digits+2-i) := HEXCHARS(to_integer(u(4*i+3 downto 4*i)) + 1);
        end loop;
        return s;
    end function;
begin
    clk <= not clk after 5 ns;  -- 100 mhz
    rst <= '1', '0' after 22 ns;   -- held for 2 edges, released between edges

    dut : entity work.soc
        generic map ( INIT_FILE => "test1.mem" )
        port map ( clk => clk, rst => rst );

    -- commit trace: one line per instruction leaving WB, in the same format as
    -- "spike --log-commits", written to trace.txt in the xsim run directory.
    -- must come after dut: external names can only point at already elaborated objects
    trace : process(clk)
        alias mem_wb  is << signal .tb_soc.dut.instance_core.mem_wb_reg : mem_wb_t >>;
        alias ex_mem  is << signal .tb_soc.dut.instance_core.ex_mem_reg : ex_mem_t >>;
        alias wb_data is << signal .tb_soc.dut.instance_core.wb_data : unsigned(XLEN-1 downto 0) >>;
        file f : text open write_mode is "trace.txt";
        variable l : line;
        variable rd : natural;
        variable done : boolean := false;
        -- load/store seen in MEM, printed when the same instruction reaches WB one edge later
        variable pend_valid : boolean := false;
        variable pend_pc    : unsigned(XLEN-1 downto 0);
        variable pend_store : boolean;
        variable pend_addr  : unsigned(XLEN-1 downto 0);
        variable pend_data  : unsigned(XLEN-1 downto 0);
        variable pend_size  : funct3_t;
    begin
        if rising_edge(clk) and not done then
            -- values read here are from before the edge: mem_wb is the instruction in WB this cycle
            if mem_wb.valid = '1' then
                write(l, string'("core   0: 3 ") & hex(std_logic_vector(mem_wb.cur_pc), 8)
                         & " (" & hex(mem_wb.inst, 8) & ")");
                if mem_wb.wb.regwrite = '1' and mem_wb.rd /= "00000" then   -- spike omits x0 writes
                    rd := to_integer(unsigned(mem_wb.rd));
                    if rd < 10 then
                        write(l, " x" & integer'image(rd) & "  " & hex(std_logic_vector(wb_data), 8));
                    else
                        write(l, " x" & integer'image(rd) & " " & hex(std_logic_vector(wb_data), 8));
                    end if;
                end if;
                if pend_valid and pend_pc = mem_wb.cur_pc then
                    write(l, " mem " & hex(std_logic_vector(pend_addr), 8));
                    if pend_store then  -- spike prints store data with the width of the access
                        case pend_size(1 downto 0) is
                            when "00"   => write(l, " " & hex(std_logic_vector(pend_data), 2));
                            when "01"   => write(l, " " & hex(std_logic_vector(pend_data), 4));
                            when others => write(l, " " & hex(std_logic_vector(pend_data), 8));
                        end case;
                    end if;
                end if;
                writeline(f, l);
                -- jal x0, 0 jumps to itself: the program has finished
                if mem_wb.inst = x"0000006f" then
                    done := true;
                    file_close(f);
                    report "trace: halt loop reached, trace.txt closed";
                    std.env.stop;
                end if;
            end if;
            -- what is in MEM now reaches WB at the next edge (EX/MEM -> MEM/WB never stalls)
            pend_valid := ex_mem.valid = '1' and (ex_mem.mem.memread = '1' or ex_mem.mem.memwrite = '1');
            pend_pc    := ex_mem.cur_pc;
            pend_store := ex_mem.mem.memwrite = '1';
            pend_addr  := ex_mem.ex_result;
            pend_data  := ex_mem.store_data;
            pend_size  := ex_mem.mem.mem_size;
        end if;
    end process;

    timeout : process
    begin
        wait for 100 us;
        report "timeout: halt loop never reached" severity failure;
    end process;
end sim;
