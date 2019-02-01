library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sha_256_pkg is
    constant WORD_SIZE : natural := 32;
    
    type K_DATA is array (0 to 63) of std_logic_vector(WORD_SIZE-1 downto 0);
    type M_DATA is array (0 to 15) of std_logic_vector(WORD_SIZE-1 downto 0);
    type H_DATA is array (0 to 7) of std_logic_vector(WORD_SIZE-1 downto 0);
    
    function ROT (a : std_logic_vector(WORD_SIZE-1 downto 0); n : natural)
                    return std_logic_vector;
    function SHF (a : std_logic_vector(WORD_SIZE-1 downto 0); n : natural)
                    return std_logic_vector;
    function CH (x : std_logic_vector(WORD_SIZE-1 downto 0);
                    y : std_logic_vector(WORD_SIZE-1 downto 0);
                    z : std_logic_vector(WORD_SIZE-1 downto 0))
                    return std_logic_vector;
    function MAJ (x : std_logic_vector(WORD_SIZE-1 downto 0);
                    y : std_logic_vector(WORD_SIZE-1 downto 0);
                    z : std_logic_vector(WORD_SIZE-1 downto 0))
                    return std_logic_vector;
                    
    function SIGMA0 (x : std_logic_vector(WORD_SIZE-1 downto 0))
                    return std_logic_vector;
    function SIGMA1 (x : std_logic_vector(WORD_SIZE-1 downto 0))
                    return std_logic_vector;
    function SIGMA2 (x : std_logic_vector(WORD_SIZE-1 downto 0))
                    return std_logic_vector;
                    
    function S0 (x : std_logic_vector(WORD_SIZE-1 downto 0))
                    return std_logic_vector;
                                       
    function S1 (x : std_logic_vector(WORD_SIZE-1 downto 0))
                    return std_logic_vector;
              

                    
end package;

package body sha_256_pkg is
    function ROT (a : std_logic_vector(WORD_SIZE-1 downto 0); n : natural)
                    return std_logic_vector is
    begin
        return (std_logic_vector(shift_right(unsigned(a), n))) or std_logic_vector((shift_left(unsigned(a), (WORD_SIZE-n))));
    end function;
    
    function SHF (a : std_logic_vector(WORD_SIZE-1 downto 0); n : natural)
                    return std_logic_vector is
    begin
        return std_logic_vector(shift_right(unsigned(a), n));
    end function;
    
    function CH (x : std_logic_vector(WORD_SIZE-1 downto 0);
                    y : std_logic_vector(WORD_SIZE-1 downto 0);
                    z : std_logic_vector(WORD_SIZE-1 downto 0))
                    return std_logic_vector is
    begin
        return (x and y) xor (not(y) and z) xor (not(x) and z);
    end function;
    
    function MAJ (x : std_logic_vector(WORD_SIZE-1 downto 0);
                    y : std_logic_vector(WORD_SIZE-1 downto 0);
                    z : std_logic_vector(WORD_SIZE-1 downto 0))
                    return std_logic_vector is
    begin
        return (x and z) xor (x and y) xor (y and z);
    end function;
    
    function SIGMA0 (x : std_logic_vector(WORD_SIZE-1 downto 0))
                    return std_logic_vector is
    begin
        return ROT(x, 2) xor ROT(x, 13) xor ROT(x, 22) xor SHF(x, 7);
    end function;
    
    function SIGMA1 (x : std_logic_vector(WORD_SIZE-1 downto 0))
                    return std_logic_vector is
    begin
        return ROT(x, 6) xor ROT(x, 11) xor ROT(x, 25);
    end function;
    
    function SIGMA2 (x : std_logic_vector(WORD_SIZE-1 downto 0))
                        return std_logic_vector is
        begin
            return ROT(x, 2) xor ROT(x, 3) xor ROT(x, 15) xor SHF(x, 5);
        end function;
       
    function S0 (x : std_logic_vector(WORD_SIZE-1 downto 0))
                                return std_logic_vector is
        begin
            return ROT(x, 17) xor ROT(x, 14) xor SHF(x, 12);
        end function;
    
    function S1 (x : std_logic_vector(WORD_SIZE-1 downto 0))
                                return std_logic_vector is
        begin
            return ROT(x, 9) xor ROT(x, 19) xor SHF(x, 9);
        end function;       
    
end package body;