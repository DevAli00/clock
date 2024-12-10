library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reglage is
    Port (
        clock, reset : in STD_LOGIC; -- Entrées pour l'horloge et le reset
        KEY : in STD_LOGIC_VECTOR(1 downto 0); -- Boutons pour ajuster les valeurs
        SW : in STD_LOGIC_VECTOR(9 downto 0); -- Interrupteurs pour sélectionner et activer
        load_seconds_units, load_seconds_tens, load_minutes_units, load_minutes_tens, load_hours_units, load_hours_tens : out integer; -- Sorties des unités et dizaines
        load_enable : out STD_LOGIC -- Signal indiquant si le chargement est activé
    );
end reglage;

architecture Behavioral of reglage is

    type button_state_type is (IDLE, PRESSED, WAIT_RELEASE); -- États du bouton
    signal button_state : button_state_type := IDLE; -- Signal pour suivre l'état actuel du bouton

    -- Signaux internes pour stocker les valeurs de réglage
    signal load_seconds_units_int, load_seconds_tens_int, 
           load_minutes_units_int, load_minutes_tens_int, 
           load_hours_units_int, load_hours_tens_int : integer := 0;

    -- Fonction pour incrémenter une valeur avec une limite donnée
    function increment_value(value : integer; limit : integer) return integer is
    begin
        if value >= limit then
            return 0; -- Réinitialise si la limite est atteinte
        else
            return value + 1; -- Incrémente sinon
        end if;
    end function;

begin
    process(clock, reset)
    begin
        if reset = '1' then
            -- Réinitialise toutes les valeurs et l'état
            load_seconds_units_int <= 0; 
            load_seconds_tens_int <= 0;
            load_minutes_units_int <= 0; 
            load_minutes_tens_int <= 0;
            load_hours_units_int <= 0; 
            load_hours_tens_int <= 0;
            button_state <= IDLE;
        elsif rising_edge(clock) then
            if SW(9) = '1' then -- Active le chargement si SW(9) est activé
                case button_state is
                    when IDLE =>
                        if KEY(0) = '0' then -- Détecte un appui sur le bouton
                            button_state <= PRESSED;
                        end if;

                    when PRESSED =>
                        -- Détection de l'état des interrupteurs pour ajuster les valeurs
                        if SW(0) = '1' then
                            load_seconds_units_int <= increment_value(load_seconds_units_int, 9); -- Incrémente unités de secondes
                        elsif SW(1) = '1' then
                            load_seconds_tens_int <= increment_value(load_seconds_tens_int, 5); -- Incrémente dizaines de secondes
                        elsif SW(2) = '1' then
                            load_minutes_units_int <= increment_value(load_minutes_units_int, 9); -- Incrémente unités de minutes
                        elsif SW(3) = '1' then
                            load_minutes_tens_int <= increment_value(load_minutes_tens_int, 5); -- Incrémente dizaines de minutes
                        elsif SW(4) = '1' then
                            load_hours_units_int <= increment_value(load_hours_units_int, 9); -- Incrémente unités d'heures
                        elsif SW(5) = '1' then
                            load_hours_tens_int <= increment_value(load_hours_tens_int, 2); -- Incrémente dizaines d'heures
                        end if;
                        button_state <= WAIT_RELEASE;

                    when WAIT_RELEASE =>
                        if KEY(0) = '1' then -- Retour à l'état IDLE lorsque le bouton est relâché
                            button_state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- Assignation des sorties
    load_seconds_units <= load_seconds_units_int; 
    load_seconds_tens <= load_seconds_tens_int;
    load_minutes_units <= load_minutes_units_int; 
    load_minutes_tens <= load_minutes_tens_int;
    load_hours_units <= load_hours_units_int; 
    load_hours_tens <= load_hours_tens_int;

    -- Signal de chargement activé
    load_enable <= SW(9);

end Behavioral;

