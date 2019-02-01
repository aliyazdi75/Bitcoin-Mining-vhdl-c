library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha_256_pkg.all;

entity miner is
    port(
        clk : in std_logic;
        rst : in std_logic;
        first_data_ready : in std_logic;
        n_blocks : in natural; 
        msg_block_in : in std_logic_vector(0 to (16 * WORD_SIZE)-1);
        final_finished : out std_logic;
        final_data_out : out std_logic_vector((WORD_SIZE * 8)-1 downto 0)
        );
end miner;

architecture Behavioral of miner is
    component sha_256_core is
        generic(
            RESET_VALUE : std_logic := '0'  
        );
        port(
            clk : in std_logic;
            rst : in std_logic;
            data_ready : in std_logic;
            n_blocks : in natural; 
            msg_block_in : in std_logic_vector(0 to (16 * WORD_SIZE)-1);
            finished : out std_logic;
            next_block: out std_logic;
            data_out : out std_logic_vector((WORD_SIZE * 8)-1 downto 0) --SHA-256 results in a 256-bit hash value
        );
    end component;
    signal finished, next_block,  data_ready, rst_sha : std_logic;
    signal n_blocks_sha : natural;
    signal block_header : std_logic_vector(671 downto 0);
    type state is (s0, s1, s2_1, s2_2, s2_3, s2_4, s2_4_1, s3, s3_1, s4, S4_1, s5);
    signal curState, nextState: state;
    signal version : std_logic_vector(31 downto 0):= x"02000000";
    signal prev_block : std_logic_vector(287 downto 0):= x"17975b97c18ed1f7e255adf297599b55330edab87803c817010000000202020200000000";
    signal data_out : std_logic_vector((WORD_SIZE * 8)-1 downto 0);
    signal timestamp : std_logic_vector(31 downto 0):= x"358b0553";
    signal diff : std_logic_vector(31 downto 0):= x"5350f119";
    signal nonce_4_char : std_logic_vector(31 downto 0);
    signal hash : std_logic_vector(255 downto 0);
    signal msg : std_logic_vector(511 downto 0);
    signal target : std_logic_vector(255 downto 0);
    
begin
    
    
    dut : sha_256_core
    port map (clk          => clk,
              rst          => rst_sha,
              data_ready   => data_ready,
              n_blocks     => n_blocks_sha,
              msg_block_in => msg,
              finished     => finished,
              next_block => next_block,
              data_out     => data_out);
              
   SEQ: process(clk,rst)
          begin
             if (rst='1') then
                curState <= S0;
             elsif rising_edge(clk) then
                curState <= nextState;
             end if;
          end process;  

   COMB: process(curState, clk)
       variable nonce : INTEGER;
       begin
          case curState is
             when S0 =>
                data_ready <= '0';
                nonce := 0;
                rst_sha <= '0';
                n_blocks_sha <= n_blocks;
                hash <= x"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
                target <= x"0000101010101010101010101010101010101010101010101010101010101010";
                msg <= msg_block_in;
                if first_data_ready = '1' then
                   rst_sha <= '1';
                   data_ready <= '1';
                   nextState <= S1;
                end if;
             when S1 =>
                if finished = '1' then
                   nonce_4_char <= std_logic_vector(to_unsigned(nonce, nonce_4_char'length));
                   block_header <= version & prev_block & data_out & timestamp & diff & nonce_4_char;
                   data_ready <= '0';
                   rst_sha <= '0';
                   nextState <= S2_1;
                end if;
             when S2_1 =>
                if hash > target then
                   nonce_4_char <= std_logic_vector(to_unsigned(nonce, nonce_4_char'length));
                   block_header <= version & prev_block & data_out & timestamp & diff & nonce_4_char;
                   msg <= (others => '0') ;
                   msg <= block_header(511 downto 0);
                   n_blocks_sha <= 2;
                   data_ready <= '1';
                   rst_sha <= '1';
                   nextState <= S2_2;
                else
                   nextState <= S5;
                end if;
             when S2_2 => nextState <= S2_3;
             when S2_3 => nextState <= S2_4;
             when S2_4 =>
                if next_block = '1' then
                   msg <= (others => '0') ;
                   msg(159 downto 0) <=  block_header(671 downto 512);
                   msg(160) <= '1';
                   msg(511 downto 447) <=  std_logic_vector(to_unsigned(672, 65));
                   rst_sha <= '1';
                   nextState <= S2_4_1;
                end if;
             when S2_4_1 =>
                  nextState <= S3;
             when S3 =>
                if finished = '1' then
                   msg <= (others => '0') ;
                   msg(255 downto 0) <= data_out;
                   msg(256) <= '1';
                   msg(511 downto 447) <=  std_logic_vector(to_unsigned(256, 65));
                   rst_sha <= '0';
                   n_blocks_sha <= 1;
                   data_ready <= '1';
                   nextState <= S3_1;
                end if;
             when S3_1 =>
                  n_blocks_sha <= 1;
                  data_ready <= '1';
                  rst_sha <= '1';
                  nextState <= S4;
            when S4 =>
               if finished = '1' then
                  rst_sha <= '0';
                  data_ready <= '0';
                  hash <= data_out;
                  nonce := nonce + 1;
                  nextState <= S4_1;
               end if;
            when S4_1 =>
                  nextState <= S2_1;
            when S5 =>
                  final_finished <= '1';
                  final_data_out <= data_out;
          end case;
   end process;  

end Behavioral;
