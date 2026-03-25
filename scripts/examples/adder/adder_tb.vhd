-- Testbench for 8-bit VHDL Adder
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_tb is
end entity adder_tb;

architecture sim of adder_tb is

    signal a    : std_logic_vector(7 downto 0) := (others => '0');
    signal b    : std_logic_vector(7 downto 0) := (others => '0');
    signal cin  : std_logic := '0';
    signal sum  : std_logic_vector(7 downto 0);
    signal cout : std_logic;

    component adder is
        port (
            a    : in  std_logic_vector(7 downto 0);
            b    : in  std_logic_vector(7 downto 0);
            cin  : in  std_logic;
            sum  : out std_logic_vector(7 downto 0);
            cout : out std_logic
        );
    end component;

begin

    dut : adder port map (a => a, b => b, cin => cin, sum => sum, cout => cout);

    stim : process
        variable expected   : unsigned(8 downto 0);
        variable fail_count : integer := 0;

        procedure check(name : in string) is
        begin
            wait for 10 ns;
            expected := ('0' & unsigned(a)) + ('0' & unsigned(b)) + ("00000000" & cin);
            if (cout & sum) /= std_logic_vector(expected) then
                report "FAIL [" & name & "]" severity warning;
                fail_count := fail_count + 1;
            else
                report "PASS [" & name & "]";
            end if;
        end procedure;

    begin
        report "=== 8-bit Adder Testbench ===";

        -- Zero cases
        a <= x"00"; b <= x"00"; cin <= '0'; check("zero+zero");
        a <= x"00"; b <= x"00"; cin <= '1'; check("zero+zero+cin");

        -- Basic addition
        a <= x"0F"; b <= x"01"; cin <= '0'; check("basic add");
        a <= x"0F"; b <= x"01"; cin <= '1'; check("basic add+cin");

        -- Carry out
        a <= x"F0"; b <= x"20"; cin <= '0'; check("carry out");

        -- Carry propagation (0xFF + 1 ripples through all bits)
        a <= x"FF"; b <= x"01"; cin <= '0'; check("carry propagate");

        -- Max values with carry in
        a <= x"FF"; b <= x"FF"; cin <= '1'; check("max+max+cin");

        -- Identity (a + 0 = a)
        a <= x"A5"; b <= x"00"; cin <= '0'; check("identity");

        -- Signed overflow boundary (0x7F + 1 = 0x80)
        a <= x"7F"; b <= x"01"; cin <= '0'; check("signed overflow");

        -- MSB carry (0x80 + 0x80)
        a <= x"80"; b <= x"80"; cin <= '0'; check("msb carry");

        report "=== Done: " & integer'image(fail_count) & " failure(s) ===";
        if fail_count = 0 then
            report "ALL TESTS PASSED";
        else
            report "SOME TESTS FAILED" severity failure;
        end if;
        wait;
    end process;

end architecture sim;
