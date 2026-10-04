----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/02/2026 07:57:46 AM
-- Design Name: 
-- Module Name: alu - Behavioral
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
use work.core_pkg.ALL;
use work.config_pkg.all;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity alu is
    Port (
    --inputs
    op : in ALU_OP;
    R : in unsigned(XLEN-1 downto 0);
    S : in unsigned(XLEN-1 downto 0);
    --outputs
    F : out unsigned(XLEN-1 downto 0)
    );
end alu;

architecture Behavioral of alu is
begin
    process(op, r, s)
        variable shamt: natural range 0 to XLEN-1;

    begin
        F <= (others => '0');
        
        case op is 
            when ALU_ADD =>
                F <= R + S;
            when ALU_SUB =>
                F <= R - S;
            when ALU_AND =>
                F <= R and S;
            when ALU_OR =>
                F <= R or S;
            when ALU_XOR =>
                F <= R xor S;
            when ALU_SLL =>
                --R is rs1, S is rs2 SLL shifts rs1 bits left by the amount in lower 5 bits of rs2
                shamt := to_integer(S(SHAMT_W-1 downto 0));
                F <= R sll shamt;
            when ALU_SRL =>
                shamt := to_integer(S(SHAMT_W-1 downto 0));
                F <= R srl shamt;
            when ALU_SRA =>
               shamt := to_integer(S(SHAMT_W-1 downto 0));
                F <= unsigned(shift_right(signed(R), shamt));
            when ALU_SLT =>
                F <= to_unsigned(1, XLEN) when signed(r) < signed (s) else (others => '0');
            when ALU_SLTU => 
                F <= to_unsigned(1, XLEN) when r < s else (others => '0');
                --F <= x"00000001" when unsigned(r) < unsigned (s) else x"00000000";
            --when others =>    
         end case;
    end process;
    

end Behavioral;