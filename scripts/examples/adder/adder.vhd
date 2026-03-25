-- 8-bit Ripple Carry Adder with Carry Out
-- Auto-generated VHDL example for digital design project
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
    port (
        a    : in  std_logic_vector(7 downto 0);
        b    : in  std_logic_vector(7 downto 0);
        cin  : in  std_logic;
        sum  : out std_logic_vector(7 downto 0);
        cout : out std_logic
    );
end entity adder;

architecture rtl of adder is
    signal result : unsigned(8 downto 0);
begin
    result <= ('0' & unsigned(a)) + ('0' & unsigned(b)) + ("00000000" & cin);
    sum    <= std_logic_vector(result(7 downto 0));
    cout   <= result(8);
end architecture rtl;
