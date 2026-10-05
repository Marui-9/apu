----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/23/2026 05:18:06 AM
-- Design Name: 
-- Module Name: alu_tb - Behavioral
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
library work;
use work.core_pkg.all;
use work.config_pkg.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
entity alu_tb is
end entity alu_tb;


architecture test of alu_tb is
    signal op_s   : ALU_OP;
    signal R_s    : unsigned(XLEN-1 downto 0);
    signal S_s    : unsigned(XLEN-1 downto 0);
    signal F_s    : unsigned(XLEN-1 downto 0);
    
begin
    
    dut: entity work.alu -- reminder: ports on the left, signals on the right
        port map(
            op => op_s,
            r => r_s,
            s => S_s,
            f => F_s
        );
        
    stimulus: process
        begin
            --type ALU_OP is (ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR, ALU_SLL, ALU_SRL, ALU_SRA, ALU_SLT, ALU_SLTU);
            --alu add no wraparound
            op_s <= ALU_ADD;
            R_s <= x"00000007"; --    0111
            S_s <= x"00000014"; -- 01 0100
            wait for 10ns;
            assert F_s = x"0000001b" report "failed add" severity error;
            --alu add with wraparound
            op_s <= ALU_ADD;
            R_s <= x"7FFFFFFF"; 
            S_s <= x"00000001"; 
            wait for 10ns;
            assert F_s = x"80000000" report "failed add wrap" severity error;
            -- overflow to 0
            op_s <= ALU_ADD;
            R_s <= x"FFFFFFFF"; 
            S_s <= x"00000001";
            wait for 10ns;
            assert F_s = x"00000000" report "failed add overflow" severity error;
            -------------------------------------------------------sub
            op_s <= ALU_SUB;
            R_s <= x"00000000";
            S_s <= x"00000001"; 
            wait for 10ns;
            assert F_s = x"FFFFFFFF" report "failed sub wrap" severity error;
            -- sub
            op_s <= ALU_SUB;
            R_s <= x"00000002";
            S_s <= x"00000002"; 
            wait for 10ns;
            assert F_s = x"00000000" report "failed sub 0" severity error;
            -- ------------------------------------------------------and 0 mask
            op_s <= ALU_AND;
            R_s <= x"00000002";
            S_s <= x"00000000"; 
            wait for 10ns;
            assert F_s = x"00000000" report "failed and 0 mask" severity error;
            -- and 1 mask
            op_s <= ALU_AND;
            R_s <= x"FFFFFFFF";
            S_s <= x"00000002"; 
            wait for 10ns;
            assert F_s = x"00000002" report "failed and 1 mask" severity error;
            ---------------------------------------------------------- or 0 mask
            op_s <= ALU_OR;
            R_s <= x"00000002";
            S_s <= x"00000000"; 
            wait for 10ns;
            assert F_s = x"00000002" report "failed or 0 mask" severity error;
            -- or 1 mask
            op_s <= ALU_OR;
            R_s <= x"FFFFFFFF";
            S_s <= x"00000002"; 
            wait for 10ns;
            assert F_s = x"FFFFFFFF" report "failed or 1 mask" severity error;
            --------------------------------------------------------------xor
             op_s <= ALU_XOR;
            R_s <= x"0000000A";
            S_s <= x"00000006"; 
            wait for 10ns;
            assert F_s = x"0000000C" report "failed xor" severity error;
            -------------------------------sll, sra, srl,
             op_s <= ALU_SLL;
            R_s <= x"0000000A";
            S_s <= x"00000000"; 
            wait for 10ns;
            assert F_s = x"0000000A" report "failed shift left by 0" severity error;
             op_s <= ALU_SRA;
            R_s <= x"0000000A";
            S_s <= x"00000000"; 
            wait for 10ns;
            assert F_s = x"0000000A" report "failed shift right a by 0" severity error;
            
            
             op_s <= ALU_SLL;
            R_s <= x"00000001";
            S_s <= x"0000001F"; 
            wait for 10ns;
            assert F_s = x"80000000" report "failed shift left by 31" severity error;
             op_s <= ALU_SLL;
            R_s <= x"FFFFFFFF";
            S_s <= x"00000010"; --16
            wait for 10ns;
            assert F_s = x"FFFF0000" report "failed shift left by not filling with 0s" severity error;
            -----------------------------------------------------------------SRL
             op_s <= ALU_SRL;
            R_s <= x"0000000A";
            S_s <= x"00000000"; 
            wait for 10ns;
            assert F_s = x"0000000A" report "failed shift right" severity error;
             op_s <= ALU_SRL;
            R_s <= x"0000000A";
            S_s <= x"00000000"; 
            wait for 10ns;
            assert F_s = x"0000000A" report "failed shift right by 0" severity error;
             op_s <= ALU_SRL;
            R_s <= x"80000000";
            S_s <= x"00000001"; 
            wait for 10ns;
            assert F_s = x"40000000" report "failed shift right with 8000_0000" severity error;
             op_s <= ALU_SRL;
            R_s <= x"80000001";
            S_s <= x"00000020"; 
            wait for 10ns;
            assert F_s = x"80000001" report "failed shift right with amount > 31" severity error;
            
            -------------------------------------------------------------- slt, sltu by 0 and 32
             op_s <= ALU_SLT; -- signed!
            R_s <= x"8000000A";
            S_s <= x"00000000"; 
            wait for 10ns;
            assert F_s = x"00000001" report "failed slt" severity error;
             op_s <= ALU_SLT; 
            R_s <= x"0000000A";
            S_s <= x"8000000F"; 
            wait for 10ns;
            assert F_s = x"00000000" report "failed slt 2" severity error;
             op_s <= ALU_SLT; 
            R_s <= x"80000000";
            S_s <= x"00000001"; 
            wait for 10ns;
            assert F_s = x"00000001" report "failed slt discriminator 0x80000000 vs 1" severity error;
            ---------------------------------------------------------------sltu
            op_s <= ALU_SLTU;
            R_s  <= x"00000001";
            S_s  <= x"00000002";
            wait for 10 ns;
            assert F_s = x"00000001" report "SLTU failed: 1 <u 2 should be 1" severity error;

            -- equal operands: not-less-than, must be 0 (catches <= vs <)
            op_s <= ALU_SLTU;
            R_s  <= x"00000005";
            S_s  <= x"00000005";
            wait for 10 ns;
            assert F_s = x"00000000" report "SLTU failed: 5 <u 5 should be 0" severity error;

            -- the signed/unsigned discriminator: 0x80000000 vs 1
            -- unsigned, 0x80000000 is huge, so NOT less than 1 -> 0
            op_s <= ALU_SLTU;
            R_s  <= x"80000000";
            S_s  <= x"00000001";
            wait for 10 ns;
            assert F_s = x"00000000" report "SLTU failed: 0x80000000 <u 1 should be 0" severity error;

            -- reverse direction: 1 <u 0x80000000 -> 1
            op_s <= ALU_SLTU;
            R_s  <= x"00000001";
            S_s  <= x"80000000";
            wait for 10 ns;
            assert F_s = x"00000001" report "SLTU failed: 1 <u 0x80000000 should be 1" severity error;
            
            ------------------------------------------------------SRA: sign-fills from the left on negatives
            -- most-negative value, shift 1: sign bit propagates
            op_s <= ALU_SRA;
            R_s  <= x"80000000";
            S_s  <= x"00000001";
            wait for 10 ns;
            assert F_s = x"C0000000" report "SRA failed: 0x80000000 >>a 1 should be 0xC0000000 (sign fill)" severity error;

            -- most-negative, shift 31: fills to all ones
            op_s <= ALU_SRA;
            R_s  <= x"80000000";
            S_s  <= x"0000001F";
            wait for 10 ns;
            assert F_s = x"FFFFFFFF" report "SRA failed: 0x80000000 >>a 31 should be 0xFFFFFFFF" severity error;

            -- positive operand behaves like logical shift (no sign fill)
            op_s <= ALU_SRA;
            R_s  <= x"0000000A";
            S_s  <= x"00000001";
            wait for 10 ns;
            assert F_s = x"00000005" report "SRA failed: +10 >>a 1 should be 0x00000005" severity error;

            -- shift by 0: unchanged
            op_s <= ALU_SRA;
            R_s  <= x"80000000";
            S_s  <= x"00000000";
            wait for 10 ns;
            assert F_s = x"80000000" report "SRA failed: 0x80000000 >>a 0 should be unchanged" severity error;
            -------- same input twice in a row
            -- negative even value (-4), shift 1 -> -2
            op_s <= ALU_SRA;
            R_s  <= x"FFFFFFFC";
            S_s  <= x"00000001";
            wait for 10 ns;
            assert F_s = x"FFFFFFFE" report "SRA failed: -4 >>a 1 should be 0xFFFFFFFE (-2)" severity error;-- negative even value (-4), shift 1 -> -2
 
            ------------------------------------------------- sweep of ops with the same inputs
            
            op_s <= ALU_ADD;  R_s <= x"D5F4B3B2"; S_s <= x"0000000E";
            wait for 10 ns;
            assert F_s = x"D5F4B3C0" report "sweep ADD"  severity error;

            op_s <= ALU_SUB;  R_s <= x"D5F4B3B2"; S_s <= x"0000000E";
            wait for 10 ns;
            assert F_s = x"D5F4B3A4" report "sweep SUB"  severity error;

            op_s <= ALU_AND;  R_s <= x"D5F4B3B2"; S_s <= x"0000000E";
            wait for 10 ns;
            assert F_s = x"00000002" report "sweep AND"  severity error;

            op_s <= ALU_OR;   R_s <= x"D5F4B3B2"; S_s <= x"0000000E";
            wait for 10 ns;
            assert F_s = x"D5F4B3BE" report "sweep OR"   severity error;

            op_s <= ALU_XOR;  R_s <= x"D5F4B3B2"; S_s <= x"0000000E";
            wait for 10 ns;
            assert F_s = x"D5F4B3BC" report "sweep XOR"  severity error;

            op_s <= ALU_SLL;  R_s <= x"D5F4B3B2"; S_s <= x"0000000E";
            wait for 10 ns;
            assert F_s = x"2CEC8000" report "sweep SLL"  severity error;

            op_s <= ALU_SRL;  R_s <= x"D5F4B3B2"; S_s <= x"0000000E";
            wait for 10 ns;
            assert F_s = x"000357D2" report "sweep SRL"  severity error;

            op_s <= ALU_SRA;  R_s <= x"D5F4B3B2"; S_s <= x"0000000E";
            wait for 10 ns;
            assert F_s = x"FFFF57D2" report "sweep SRA"  severity error;

            op_s <= ALU_SLT;  R_s <= x"D5F4B3B2"; S_s <= x"0000000E";
            wait for 10 ns;
            assert F_s = x"00000001" report "sweep SLT"  severity error;

            op_s <= ALU_SLTU; R_s <= x"D5F4B3B2"; S_s <= x"0000000E";
            wait for 10 ns;
            assert F_s = x"00000000" report "sweep SLTU" severity error;
            
        wait;
    end process stimulus;
    
end architecture test;


    


