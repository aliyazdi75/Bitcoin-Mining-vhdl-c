library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha_256_pkg.all;

entity sha_256_core is
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
end entity;

architecture sha_256_core_ARCH of sha_256_core is
    signal block_counter : natural := 0;
    signal loop_counter : natural := 0;
    
    signal T1 : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');
    signal T2 : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');
    signal a : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');
    signal b : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');
    signal c : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');
    signal d : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');
    signal e : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');
    signal f : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');
    signal g : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');
    signal h : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');
    
    constant K : K_DATA := (
        X"428a2f98", X"71374491", X"b5c0fbcf", X"e9b5dba5",
        X"3956c25b", X"59f111f1", X"923f82a4", X"ab1c5ed5",
        X"d807aa98", X"12835b01", X"243185be", X"550c7dc3",
        X"72be5d74", X"80deb1fe", X"9bdc06a7", X"c19bf174",
        X"e49b69c1", X"efbe4786", X"0fc19dc6", X"240ca1cc",
        X"2de92c6f", X"4a7484aa", X"5cb0a9dc", X"76f988da",
        X"983e5152", X"a831c66d", X"b00327c8", X"bf597fc7",
        X"c6e00bf3", X"d5a79147", X"06ca6351", X"14292967",
        X"27b70a85", X"2e1b2138", X"4d2c6dfc", X"53380d13",
        X"650a7354", X"766a0abb", X"81c2c92e", X"92722c85",
        X"a2bfe8a1", X"a81a664b", X"c24b8b70", X"c76c51a3",
        X"d192e819", X"d6990624", X"f40e3585", X"106aa070",
        X"19a4c116", X"1e376c08", X"2748774c", X"34b0bcb5",
        X"391c0cb3", X"4ed8aa4a", X"5b9cca4f", X"682e6ff3",
        X"748f82ee", X"78a5636f", X"84c87814", X"8cc70208",
        X"90befffa", X"a4506ceb", X"bef9a3f7", X"c67178f2"
    );
    
    signal W : K_DATA := (
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000"
    );
    
    signal HV : H_DATA;
    signal HV_INITIAL_VALUES : H_DATA := (X"6a09e667", X"bb67ae85", X"3c6ef372",
                                        X"a54ff53a", X"510e527f", X"9b05688c",
                                        X"1f83d9ab", X"5be0cd19");
   
    signal W_INT : K_DATA;
    
    
    type states is ( reset, idle, read, Permutation, Compression1, Compression2, Compression2a, Compression2b, Compression3, DONE );
    signal current_state, next_state: states;

begin

    process(clk, rst)
    begin
        if(rst=RESET_VALUE) then
            current_state <= RESET;
        elsif(clk'event and clk='1') then
            current_state <= next_state;
        end if;
    end process;
    
    process(current_state, rst, n_blocks, block_counter, loop_counter, data_ready)
    begin
        case current_state is
            when reset =>
                if(rst=RESET_VALUE) then
                    next_state <= reset;
                else
                    next_state <= idle;
                end if;
            when IDLE =>
                if(data_ready='1') then
                    next_state <= read;
                else
                    next_state <= idle;
                end if;
            when read =>
                next_state <= Permutation;
            when Permutation =>
                next_state <= Compression1;
            when Compression1 =>
                next_state <= Compression2;
            when Compression2 =>
                if(loop_counter = 64) then
                    next_state <= Compression3;
                else
                    next_state <= Compression2a;
                end if;
            when Compression2a =>
                    next_state <= Compression2b;
            when Compression2b =>
                    next_state <= Compression2;
            when Compression3 =>
                if(block_counter = n_blocks-1) then
                    next_state <= DONE;
                else
                    next_state <= idle;
                end if;
            when DONE =>
                NEXT_STATE <= DONE;
        end case;
    end process;
    
    
    process(clk, rst, current_state)
    variable temp: std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');
    begin
        if(rst=RESET_VALUE) then
            block_counter <= 0;
        elsif(clk'event and clk='1') then
            a <= a;     b <= b;     c <= c;     d <= d;
            e <= e;     f <= f;     g <= g;     h <= h;
            T1 <= T1;   T2 <= T2;
            W <= W;     HV <= HV;
            loop_counter <= loop_counter;
            block_counter <= block_counter;
            case current_state is
                when reset =>
                    HV <= HV_INITIAL_VALUES;
                    loop_counter <= 0;
                    block_counter <= 0;
                when IDLE =>   
                when read =>
                    if(block_counter = 0) then
                        HV <= HV_INITIAL_VALUES;
                    end if;
                when Permutation =>
                    for i in 0 to 63 loop
                        W(i)(31 downto 24) <= W_INT(i)(0)& W_INT(i)(1)& W_INT(i)(2)& W_INT(i)(3)& W_INT(i)(4)& W_INT(i)(5)& W_INT(i)(6)& W_INT(i)(7) ;
                        W(i)(23 downto 16) <= W_INT(i)(15)& W_INT(i)(14)& W_INT(i)(13)& W_INT(i)(12)& W_INT(i)(11)& W_INT(i)(10)& W_INT(i)(9)& W_INT(i)(8) ;
                        W(i)(15 downto 8) <= W_INT(i)(16)& W_INT(i)(17)& W_INT(i)(18)& W_INT(i)(19)& W_INT(i)(20)& W_INT(i)(21)& W_INT(i)(22)& W_INT(i)(23) ;
                        W(i)(7 downto 0) <= W_INT(i)(24)& W_INT(i)(25)& W_INT(i)(26)& W_INT(i)(27)& W_INT(i)(28)& W_INT(i)(29)& W_INT(i)(30)& W_INT(i)(31) ;    
                    end loop;
                when Compression1 =>
                    a <= HV(0);
                    b <= HV(1);
                    c <= HV(2);
                    d <= HV(3);
                    e <= HV(4);
                    f <= HV(5);
                    g <= HV(6);
                    h <= HV(7);
                when Compression2 =>
                    if(loop_counter = 64) then
                        loop_counter <= 0;
                    else
                        temp := std_logic_vector(unsigned(d) + unsigned(c));
                        T2 <= std_logic_vector(unsigned(h) + unsigned(SIGMA1(e)) + unsigned(CH(e, f, g)) + unsigned(K(loop_counter)) + unsigned(W(loop_counter)));
                        T1 <= std_logic_vector(unsigned(SIGMA0(a)) + unsigned(MAJ(a, b, c)) + unsigned(SIGMA2(temp)));
                    end if;
                when Compression2a =>
                    h <= g;
                    g <= f;
                    f <= e;
                    e <= std_logic_vector(unsigned(d) + unsigned(T1));
                    d <= c;
                    c <= b;
                    b <= a;
                    a <=   std_logic_vector(unsigned(T1) + unsigned(T1)+ unsigned(T1)  - unsigned(T2));
                when Compression2b =>
                    loop_counter <= loop_counter + 1; 
                when Compression3 =>
                    HV(0) <= std_logic_vector(unsigned(a) + unsigned(HV(0)));
                    HV(1) <= std_logic_vector(unsigned(b) + unsigned(HV(1)));
                    HV(2) <= std_logic_vector(unsigned(c) + unsigned(HV(2)));
                    HV(3) <= std_logic_vector(unsigned(d) + unsigned(HV(3)));
                    HV(4) <= std_logic_vector(unsigned(e) + unsigned(HV(4)));
                    HV(5) <= std_logic_vector(unsigned(f) + unsigned(HV(5)));
                    HV(6) <= std_logic_vector(unsigned(g) + unsigned(HV(6)));
                    HV(7) <= std_logic_vector(unsigned(h) + unsigned(HV(7)));
                    if(block_counter = n_blocks-1) then
                        block_counter <= 0;
                    else
                        block_counter <= block_counter + 1;
                    end if;
                when DONE =>
            end case;
        end if;
    end process;
    
    expapnsion1:
    for i in 0 to 15 generate
    begin
        W_INT(i) <= msg_block_in((WORD_SIZE * i) to WORD_SIZE * (i+1)-1);
    end generate;
    
    expansion2:
    for i in 16 to 63 generate
    begin
        W_INT(i) <= std_logic_vector(unsigned(S1(W_INT(i-1))) + unsigned(W_INT(i-6)) + unsigned(S0(W_INT(i-12))) + unsigned(W_INT(i-15)));
    end generate;
    
    finished <= '1' when CURRENT_STATE = DONE else
                '0';
                
    next_block <= '1' when CURRENT_STATE = idle else
                               '0';
                
    data_out <= HV(0) & HV(1) & HV(2) & HV(3) & HV(4) & HV(5) & HV(6) & HV(7);
end architecture;