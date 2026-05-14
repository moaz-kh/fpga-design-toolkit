-- Standard Utility Modules (VHDL-2008)
-- VHDL equivalent of STD_MODULES.v
-- Modules: synchronizer, edge_detector, LED_logic, spi_interface_debounce

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================================
-- synchronizer: Multi-bit clock domain crossing (two-FF)
-- Parameters: WIDTH (default 3)
-- Usage: synchronize signals between clock domains
-- =============================================================================
entity synchronizer is
    generic (
        WIDTH : integer := 3
    );
    port (
        i_clk   : in  std_logic;
        i_rst_n : in  std_logic;
        d_in    : in  std_logic_vector(WIDTH-1 downto 0);
        d_out   : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity synchronizer;

architecture rtl of synchronizer is
    signal q1 : std_logic_vector(WIDTH-1 downto 0);
begin
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' then
                q1    <= (others => '0');
                d_out <= (others => '0');
            else
                q1    <= d_in;
                d_out <= q1;
            end if;
        end if;
    end process;
end architecture rtl;

-- =============================================================================
-- edge_detector: Detect positive and negative edges
-- Generic: sync_sig (0=async input, 1=use synchronizer)
-- Outputs: o_pos_edge, o_neg_edge
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity edge_detector is
    generic (
        sync_sig : integer := 0
    );
    port (
        i_clk      : in  std_logic;
        i_rst_n    : in  std_logic;
        i_sig      : in  std_logic;
        o_pos_edge : out std_logic;
        o_neg_edge : out std_logic
    );
end entity edge_detector;

architecture rtl of edge_detector is
    signal i_sig_sync : std_logic_vector(0 downto 0);
    signal sig_sync   : std_logic;
    signal sig_dly    : std_logic;

    component synchronizer is
        generic (WIDTH : integer := 3);
        port (
            i_clk   : in  std_logic;
            i_rst_n : in  std_logic;
            d_in    : in  std_logic_vector(WIDTH-1 downto 0);
            d_out   : out std_logic_vector(WIDTH-1 downto 0)
        );
    end component;
begin
    i_sig_sync_u : synchronizer
        generic map (WIDTH => 1)
        port map (
            i_clk   => i_clk,
            i_rst_n => i_rst_n,
            d_in(0) => i_sig,
            d_out   => i_sig_sync
        );

    sig_sync <= i_sig_sync(0) when sync_sig = 1 else i_sig;

    o_pos_edge <=  sig_sync and not sig_dly;
    o_neg_edge <= not sig_sync and sig_dly;

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' then
                sig_dly <= '0';
            else
                sig_dly <= sig_sync;
            end if;
        end if;
    end process;
end architecture rtl;

-- =============================================================================
-- LED_logic: Configurable LED blinker
-- Generics: time_count (total on-duration in clk cycles)
--           toggle_count (half-period in clk cycles)
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LED_logic is
    generic (
        sync_sig     : integer := 0;
        time_count   : integer := 50000000;
        toggle_count : integer := 5000000
    );
    port (
        i_clk   : in  std_logic;
        i_rst_n : in  std_logic;
        i_sig   : in  std_logic;
        o_led   : out std_logic
    );
end entity LED_logic;

architecture rtl of LED_logic is
    signal i_sig_sync  : std_logic_vector(0 downto 0);
    signal sig_sync    : std_logic;
    signal sig_posedge : std_logic;
    signal sig_negedge : std_logic;
    signal count       : integer range 0 to time_count   := 0;
    signal tog_count   : integer range 0 to 2*toggle_count := 0;
    signal start_count : std_logic := '0';

    component synchronizer is
        generic (WIDTH : integer := 3);
        port (
            i_clk   : in  std_logic;
            i_rst_n : in  std_logic;
            d_in    : in  std_logic_vector(WIDTH-1 downto 0);
            d_out   : out std_logic_vector(WIDTH-1 downto 0)
        );
    end component;

    component edge_detector is
        generic (sync_sig : integer := 0);
        port (
            i_clk      : in  std_logic;
            i_rst_n    : in  std_logic;
            i_sig      : in  std_logic;
            o_pos_edge : out std_logic;
            o_neg_edge : out std_logic
        );
    end component;
begin
    i_sig_sync_u : synchronizer
        generic map (WIDTH => 1)
        port map (
            i_clk   => i_clk,
            i_rst_n => i_rst_n,
            d_in(0) => i_sig,
            d_out   => i_sig_sync
        );

    sig_sync <= i_sig_sync(0) when sync_sig = 1 else i_sig;

    u_edge : edge_detector
        port map (
            i_clk      => i_clk,
            i_rst_n    => i_rst_n,
            i_sig      => sig_sync,
            o_pos_edge => sig_posedge,
            o_neg_edge => sig_negedge
        );

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' then
                count       <= 0;
                tog_count   <= 0;
                start_count <= '0';
                o_led       <= '0';
            else
                if sig_posedge = '1' then
                    start_count <= '1';
                end if;

                if start_count = '1' then
                    count <= count + 1;

                    if tog_count = 2*toggle_count then
                        tog_count <= 0;
                    else
                        tog_count <= tog_count + 1;
                    end if;

                    if tog_count < toggle_count then
                        o_led <= '1';
                    else
                        o_led <= '0';
                    end if;

                    if count = time_count then
                        count       <= 0;
                        tog_count   <= 0;
                        start_count <= '0';
                        o_led       <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture rtl;

-- =============================================================================
-- spi_interface_debounce: Debounce SPI signals (clk, mosi, cs_n)
-- System clock: 200 MHz, debounce count: 2 cycles
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_interface_debounce is
    generic (
        DEBOUNCE_COUNT : integer := 2
    );
    port (
        i_clk       : in  std_logic;
        i_rst_n     : in  std_logic;
        spi_clk_raw  : in  std_logic;
        spi_mosi_raw : in  std_logic;
        spi_cs_n_raw : in  std_logic;
        spi_clk_db   : out std_logic;
        spi_mosi_db  : out std_logic;
        spi_cs_n_db  : out std_logic
    );
end entity spi_interface_debounce;

architecture rtl of spi_interface_debounce is
    signal spi_clk_sync0,  spi_clk_sync1  : std_logic;
    signal spi_mosi_sync0, spi_mosi_sync1 : std_logic;
    signal spi_cs_n_sync0, spi_cs_n_sync1 : std_logic;

    signal clk_stable_cnt  : unsigned(1 downto 0) := (others => '0');
    signal mosi_stable_cnt : unsigned(1 downto 0) := (others => '0');
    signal cs_n_stable_cnt : unsigned(1 downto 0) := (others => '0');

    signal spi_clk_db_r  : std_logic := '0';
    signal spi_mosi_db_r : std_logic := '0';
    signal spi_cs_n_db_r : std_logic := '1';
begin
    spi_clk_db  <= spi_clk_db_r;
    spi_mosi_db <= spi_mosi_db_r;
    spi_cs_n_db <= spi_cs_n_db_r;

    -- Two-stage synchronizer
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' then
                spi_clk_sync0  <= '0'; spi_clk_sync1  <= '0';
                spi_mosi_sync0 <= '0'; spi_mosi_sync1 <= '0';
                spi_cs_n_sync0 <= '1'; spi_cs_n_sync1 <= '1';
            else
                spi_clk_sync0  <= spi_clk_raw;  spi_clk_sync1  <= spi_clk_sync0;
                spi_mosi_sync0 <= spi_mosi_raw; spi_mosi_sync1 <= spi_mosi_sync0;
                spi_cs_n_sync0 <= spi_cs_n_raw; spi_cs_n_sync1 <= spi_cs_n_sync0;
            end if;
        end if;
    end process;

    -- Debounce: SPI clock
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' then
                clk_stable_cnt <= (others => '0');
                spi_clk_db_r   <= spi_clk_sync1;
            else
                if spi_clk_sync1 = spi_clk_db_r then
                    clk_stable_cnt <= (others => '0');
                else
                    clk_stable_cnt <= clk_stable_cnt + 1;
                    if clk_stable_cnt >= (DEBOUNCE_COUNT - 1) then
                        spi_clk_db_r   <= spi_clk_sync1;
                        clk_stable_cnt <= (others => '0');
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Debounce: SPI MOSI
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' then
                mosi_stable_cnt <= (others => '0');
                spi_mosi_db_r   <= spi_mosi_sync1;
            else
                if spi_mosi_sync1 = spi_mosi_db_r then
                    mosi_stable_cnt <= (others => '0');
                else
                    mosi_stable_cnt <= mosi_stable_cnt + 1;
                    if mosi_stable_cnt >= (DEBOUNCE_COUNT - 1) then
                        spi_mosi_db_r   <= spi_mosi_sync1;
                        mosi_stable_cnt <= (others => '0');
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Debounce: SPI CS_n
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' then
                cs_n_stable_cnt <= (others => '0');
                spi_cs_n_db_r   <= spi_cs_n_sync1;
            else
                if spi_cs_n_sync1 = spi_cs_n_db_r then
                    cs_n_stable_cnt <= (others => '0');
                else
                    cs_n_stable_cnt <= cs_n_stable_cnt + 1;
                    if cs_n_stable_cnt >= (DEBOUNCE_COUNT - 1) then
                        spi_cs_n_db_r   <= spi_cs_n_sync1;
                        cs_n_stable_cnt <= (others => '0');
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
