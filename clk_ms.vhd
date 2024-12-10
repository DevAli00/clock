library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_ms is
    port (
        clock_in  : in std_logic;      -- horloge d'entrée
        reset     : in std_logic;      -- réinitialisation asynchrone
        clock_out : out std_logic       -- horloge de sortie
    );
end clk_ms;

architecture one of clk_ms is

    signal count: integer := 0;
    signal Hz : std_logic := '0';

begin

    process(clock_in, reset)
    begin
        if (reset = '1') then
            count <= 1;
            Hz <= '0';
        elsif rising_edge(clock_in) then
            count <= count + 1;
            if (count = 1) then
                Hz <= '0';
            elsif (count = 500000) then
                count <= 1;
                Hz <= not Hz;
            end if;
        end if;
        clock_out <= Hz;
    end process;

end one;