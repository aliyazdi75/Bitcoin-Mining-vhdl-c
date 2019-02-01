library ieee;
use ieee.std_logic_1164.all;
use work.sha_256_pkg.all;

entity tb_sha_256_core is
end tb_sha_256_core;

architecture tb of tb_sha_256_core is

    component sha_256_core
        port (clk          : in std_logic;
              rst          : in std_logic;
              data_ready   : in std_logic;
              n_blocks     : in natural;
              msg_block_in : in std_logic_vector (0 to (16 * word_size)-1);
              finished     : out std_logic;
              data_out     : out std_logic_vector ((word_size * 8)-1 downto 0));
    end component;

    signal clk          : std_logic;
    signal rst          : std_logic;
    signal data_ready   : std_logic;
    signal n_blocks     : natural;
    signal msg_block_in : std_logic_vector (0 to (16 * word_size)-1);
    signal finished     : std_logic;
    signal data_out     : std_logic_vector ((word_size * 8)-1 downto 0);

    constant TbPeriod : time := 50 ns; 
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : sha_256_core
    port map (clk          => clk,
              rst          => rst,
              data_ready   => data_ready,
              n_blocks     => n_blocks,
              msg_block_in => msg_block_in,
              finished     => finished,
              data_out     => data_out);

    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    clk <= TbClock;

    stimuli : process
    begin
        rst <= '1';
        n_blocks <= 1;
        wait for 250 ns;

        data_ready <= '1';
        msg_block_in <= "01000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001010000010100000101000001";
        wait for 100 ns;
        
        data_ready <= '0';
        wait for 22500 ns;

        TbSimEnded <= '1';
        wait;
    end process;

end tb;