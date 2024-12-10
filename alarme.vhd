library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alarme is
    Port (
        clock, reset : in STD_LOGIC; -- Entrées pour l'horloge et le reset
        KEY : in STD_LOGIC_VECTOR(1 downto 0); -- Boutons pour ajuster les valeurs
        SW : in STD_LOGIC_VECTOR(9 downto 0); -- Interrupteurs pour sélectionner et activer
        alarme_seconds_units, alarme_seconds_tens, alarme_minutes_units, alarme_minutes_tens, alarme_hours_units, alarme_hours_tens : out STD_LOGIC_VECTOR(3 downto 0); -- Sorties des unités et dizaines
        alarme_enable : out STD_LOGIC -- Signal indiquant si l'alarme est activée
    );
end alarme;

architecture Behavioral of alarme is
    type button_state_type is (IDLE, PRESSED, WAIT_RELEASE); -- États du bouton
    signal button_state : button_state_type; -- Signal pour suivre l'état actuel du bouton

    -- Signaux internes pour stocker les valeurs de l'alarme
    signal alarme_seconds_units_int, alarme_seconds_tens_int, alarme_minutes_units_int, alarme_minutes_tens_int, alarme_hours_units_int, alarme_hours_tens_int : integer := 0;

    -- Signal pour activer ou désactiver l'alarme
    signal alarme_signal : STD_LOGIC := '0';

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
            alarme_seconds_units_int <= 0; alarme_seconds_tens_int <= 0;
            alarme_minutes_units_int <= 0; alarme_minutes_tens_int <= 0;
            alarme_hours_units_int <= 0; alarme_hours_tens_int <= 0;
            button_state <= IDLE; alarme_signal <= '0';
        elsif rising_edge(clock) then
            if SW(8) = '1' then -- Active la configuration de l'alarme si SW(8) est activé
                case button_state is
                    when IDLE =>
                        if KEY(0) = '0' then -- Détecte un appui sur le bouton
                            button_state <= PRESSED;
                        end if;

                    when PRESSED =>
                        if SW(0) = '1' then
                            alarme_seconds_units_int <= increment_value(alarme_seconds_units_int, 9); -- Incrémente unités de secondes
                        elsif SW(1) = '1' then
                            alarme_seconds_tens_int <= increment_value(alarme_seconds_tens_int, 5); -- Incrémente dizaines de secondes
                        elsif SW(2) = '1' then
                            alarme_minutes_units_int <= increment_value(alarme_minutes_units_int, 9); -- Incrémente unités de minutes
                        elsif SW(3) = '1' then
                            alarme_minutes_tens_int <= increment_value(alarme_minutes_tens_int, 5); -- Incrémente dizaines de minutes
                        elsif SW(4) = '1' then
                            alarme_hours_units_int <= increment_value(alarme_hours_units_int, 9); -- Incrémente unités d'heures
                        elsif SW(5) = '1' then
                            alarme_hours_tens_int <= increment_value(alarme_hours_tens_int, 2); -- Incrémente dizaines d'heures
                        else
                            alarme_signal <= not alarme_signal; -- Inverse l'état du signal d'alarme si aucun interrupteur n'est actif
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
	alarme_seconds_units <= std_logic_vector(to_unsigned(alarme_seconds_units_int, 4)); alarme_seconds_tens <= std_logic_vector(to_unsigned(alarme_seconds_tens_int, 4));
	alarme_minutes_units <= std_logic_vector(to_unsigned(alarme_minutes_units_int, 4)); alarme_minutes_tens <= std_logic_vector(to_unsigned(alarme_minutes_tens_int, 4));
	alarme_hours_units <= std_logic_vector(to_unsigned(alarme_hours_units_int, 4)); alarme_hours_tens <= std_logic_vector(to_unsigned(alarme_hours_tens_int, 4));
	alarme_enable <= alarme_signal;

end Behavioral;
