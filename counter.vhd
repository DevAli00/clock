library IEEE;  
use IEEE.STD_LOGIC_1164.ALL;  
use IEEE.NUMERIC_STD.ALL;  

entity counter is  
    Generic (
        MAX_COUNT : integer  -- Valeur maximale du compteur
    );
    Port (
        clock, reset, enable, load_enable : in STD_LOGIC;  -- Signaux d'entrée
        load_value : in integer;  -- Valeur à charger dans le compteur
        counter : out std_logic_vector(3 downto 0);  -- Sortie du compteur (4 bits)
        carry : out STD_LOGIC  -- Signal carry
    );
end counter;

architecture Behavioral of counter is  
    signal counter_internal : integer := 0;  -- Compteur interne
begin
    process (clock, reset)  
    begin
        if reset = '1' then  -- Réinitialisation
            counter_internal <= 0;  
        elsif rising_edge(clock) then  
            if load_enable = '1' then  -- Chargement d'une nouvelle valeur
                counter_internal <= load_value;  
            elsif enable = '1' then  
                if counter_internal = MAX_COUNT then  -- Réinitialisation après MAX_COUNT
                    counter_internal <= 0;  
                else
                    counter_internal <= counter_internal + 1;  -- Incrémentation
                end if;
            end if;
        end if;
    end process;

    counter <= std_logic_vector(to_unsigned(counter_internal, 4));  -- Conversion en vecteur
    carry <= '1' when counter_internal = MAX_COUNT else '0';  -- Signal carry
end Behavioral;
