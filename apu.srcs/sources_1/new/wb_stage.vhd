library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pipeline_pkg.all;
use work.config_pkg.all;
use work.core_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity wb_stage is
    port (
        mem_wb_reg : in  mem_wb_t;
        dmem_rdata : in  std_logic_vector(XLEN-1 downto 0);
        --
        wb_data : out unsigned(XLEN-1 downto 0)
    );
end wb_stage;

architecture Behavioral of wb_stage is
    signal shifted: std_logic_vector(XLEN-1 downto 0);
    signal load_data : unsigned(XLEN-1 downto 0);
begin
    -- 1. move the addressed byte/halfword down to bit 0 (little-endian)
    with mem_wb_reg.ex_result(1 downto 0) select shifted <=
        dmem_rdata                             when "00",
        x"00"     &  dmem_rdata(31 downto 8)    when "01",
        x"0000"   & dmem_rdata(31 downto 16)   when "10",
        x"000000" & dmem_rdata(31 downto 24)   when others;

    -- 2. extend by size and signedness
    with mem_wb_reg.mem_size select load_data <=
        unsigned(resize(signed(shifted(7 downto 0)),   XLEN)) when FUNCT3_LOAD_LB,
        unsigned(resize(signed(shifted(15 downto 0)), XLEN)) when FUNCT3_LOAD_LH,
        resize(unsigned(shifted(7 downto 0)),  XLEN)         when FUNCT3_LOAD_LBU,
        resize(unsigned(shifted(15 downto 0)), XLEN)         when FUNCT3_LOAD_LHU,
        unsigned(shifted)                                    when others;   -- LW

    -- 3. WB mux
    wb_data <= load_data when mem_wb_reg.wb.wb_sel = WB_MEM else mem_wb_reg.ex_result;
end Behavioral;
