library ieee;
use ieee.std_logic_1164.all;
use work.sha_256_pkg.all;
use ieee.numeric_std.all;

entity tb_sha_256_core is
       generic(
    msg_length : Integer := 32
); 
end tb_sha_256_core;

architecture tb of tb_sha_256_core is

    component miner is
    port(
        clk : in std_logic;
        rst : in std_logic;
        first_data_ready : in std_logic;
        n_blocks : in natural; 
        msg_block_in : in std_logic_vector(0 to (16 * WORD_SIZE)-1);
        final_finished : out std_logic;
        final_data_out : out std_logic_vector((WORD_SIZE * 8)-1 downto 0)
        );
    end component;

    signal clk          : std_logic;
    signal rst          : std_logic;
    signal first_data_ready   : std_logic;
    signal n_blocks     : natural;
    signal msg_block_in : std_logic_vector (0 to (16 * word_size)-1);
    signal final_finished     : std_logic;
    signal final_data_out     : std_logic_vector ((word_size * 8)-1 downto 0);
    signal msg : std_logic_vector(msg_length-1 downto 0):= "01100001011000100110001101100100";

    constant TbPeriod : time := 50 ns; 
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : miner
    port map (clk          => clk,
              rst          => rst,
              first_data_ready   => first_data_ready,
              n_blocks     => n_blocks,
              msg_block_in => msg_block_in,
              final_finished     => final_finished,
              final_data_out     => final_data_out);

    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    clk <= TbClock;

    stimuli : process
    begin
        rst <= '1';
        n_blocks <= 1;
        wait for 250 ns;
        rst <= '0';

        first_data_ready <= '1';
        
        msg_block_in(0 to msg_length-1) <= msg;
        msg_block_in(msg_length) <= '1';
        msg_block_in(msg_length+1 to 446) <= (others => '0');
        msg_block_in(447 to 511) <= std_logic_vector(to_unsigned(msg_length, 65));
        wait for 100 ns;
        
        wait for 22500 ns;

        wait;
    end process;

end tb;