library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Définition de l'entité top
entity top is
    port (
        MAX10_CLK1_50 : in std_logic;                -- Horloge de base à 50 MHz
        KEY           : in std_logic_vector(1 downto 0); -- Boutons
        SW            : in std_logic_vector(9 downto 0); -- Switches (SW(0) pour reset)
        LEDR          : out std_logic_vector(9 downto 0);
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0) -- Afficheur pour unité des secondes
    );
end top;

architecture Behavioral of top is
    -- Signaux internes
    signal clk_1Hz, reset, limit : std_logic;
    signal enable_seconds_units, enable_seconds_tens, enable_minutes_units, enable_minutes_tens, enable_hours_units, enable_hours_tens : std_logic;
    signal counter_seconds_units, counter_seconds_tens, counter_minutes_units, counter_minutes_tens, counter_hours_units, counter_hours_tens : std_logic_vector(3 downto 0);
    signal carry_seconds_units, carry_seconds_tens, carry_minutes_units, carry_minutes_tens, carry_hours_units, carry_hours_tens : std_logic;

	 -- Internal Signals for Chrono
	signal clk_1ms, limit_chrono : std_logic; -- 1 ms clock and limit signal for the chrono
	signal enable_mseconds_units, enable_mseconds_tens, enable_seconds_units_chrono, enable_seconds_tens_chrono, enable_minutes_units_chrono, enable_minutes_tens_chrono : std_logic; -- Enable signals for chrono counters
	signal counter_mseconds_units_chrono, counter_mseconds_tens_chrono, counter_seconds_units_chrono, counter_seconds_tens_chrono, counter_minutes_units_chrono, counter_minutes_tens_chrono : std_logic_vector(3 downto 0); -- Counter values
	signal carry_mseconds_units_chrono, carry_mseconds_tens_chrono, carry_seconds_units_chrono, carry_seconds_tens_chrono, carry_minutes_units_chrono, carry_minutes_tens_chrono : std_logic; -- Carry signals for cascading counters

	 
    -- Signaux pour le reglage
    signal load_seconds_units_val, load_seconds_tens_val, load_minutes_units_val, load_minutes_tens_val, load_hours_units_val, load_hours_tens_val : integer;
    signal load_enable_signal, mode_reglage : std_logic;

    -- Signaux pour l'alarme
    signal alarme_seconds_units, alarme_seconds_tens, alarme_minutes_units, alarme_minutes_tens, alarme_hours_units, alarme_hours_tens : std_logic_vector(3 downto 0);
    signal alarme_enable_signal, mode_alarme : std_logic;
	 signal alarme_triggered : std_logic := '0';
	 
	 -- Mode Selection Signals
    signal mode_chrono : std_logic;
	 signal chrono_start_stop : std_logic := '0';
	 signal key0_prev_state   : std_logic := '1';

    -- Signaux pour sélectionner les sorties des afficheurs 7 segments
    signal display_seconds_units, display_seconds_tens, display_minutes_units, display_minutes_tens, display_hours_units, display_hours_tens : std_logic_vector(3 downto 0);

    -- Déclaration des composants
    component seg7_lut is
        port(
            digit: in std_logic_vector(3 downto 0);
            hex: out std_logic_vector(6 downto 0)
        );
    end component;

    component clock_divider is
        port (
            clock_in  : in std_logic;      -- horloge d'entrée
            reset     : in std_logic;      -- réinitialisation asynchrone
            clock_out : out std_logic       -- horloge de sortie
        );
    end component;
	 
	 component clk_ms is
		port (
        clock_in  : in std_logic;  -- Input clock (e.g., 50 MHz)
        reset     : in std_logic;  -- Reset signal
		  clock_out : out std_logic  -- Output clock (1 ms pulse)
			);
	 end component;

    component counter is
        Generic (
            MAX_COUNT : integer  -- Valeur maximale du compteur
        );
        Port (
            clock, reset, enable, load_enable : in STD_LOGIC;
            load_value : in integer;  -- Valeur à charger
            counter : out std_logic_vector(3 downto 0); -- Valeur actuelle du compteur
            carry : out STD_LOGIC                  -- Débordement (1 quand le compteur atteint la valeur maximale)
        );
    end component;

    -- Ajout du composant reglage
    component reglage is
        Port (
            clock, reset : in STD_LOGIC;
            KEY : in STD_LOGIC_VECTOR(1 downto 0);
            SW : in STD_LOGIC_VECTOR(9 downto 0);
            load_seconds_units, load_seconds_tens, load_minutes_units, load_minutes_tens, load_hours_units, load_hours_tens : out integer;
            load_enable : out STD_LOGIC
        );
    end component;

    -- Déclaration du composant alarme
    component alarme is
        Port (
            clock, reset : in STD_LOGIC;
            KEY : in STD_LOGIC_VECTOR(1 downto 0);
            SW : in STD_LOGIC_VECTOR(9 downto 0);
            alarme_seconds_units, alarme_seconds_tens, alarme_minutes_units, alarme_minutes_tens, alarme_hours_units, alarme_hours_tens : out STD_LOGIC_VECTOR(3 downto 0);
            alarme_enable : out STD_LOGIC
        );
    end component;
	 
	
	 

begin

    -- Signaux d'activation pour les compteurs
    enable_minutes_units <= '1' when carry_seconds_units = '1' and counter_seconds_tens = "0101" else '0';
    enable_minutes_tens <= '1' when enable_minutes_units = '1' and counter_minutes_units = "1001" else '0';
    enable_hours_units <= '1' when enable_minutes_tens = '1' and counter_minutes_tens = "0101" else '0';
    enable_hours_tens <= '1' when enable_hours_units = '1' and counter_hours_units = "1001" else '0';
    limit <= '1' when counter_hours_tens = "0010" and counter_hours_units = "0100" else '0';
	 
	 -- Signaux d'activation pour le chrono
	-- Enable signals for cascading Chrono counters
	enable_seconds_units_chrono <= '1' when carry_mseconds_units_chrono = '1' and counter_mseconds_tens_chrono = "1001" else '0';
	enable_seconds_tens_chrono  <= '1' when enable_seconds_units_chrono = '1' and counter_seconds_units_chrono = "1001" else '0';
	enable_minutes_units_chrono <= '1' when enable_seconds_tens_chrono = '1' and counter_seconds_tens_chrono = "0101" else '0';
	enable_minutes_tens_chrono  <= '1' when enable_minutes_units_chrono = '1' and counter_minutes_units_chrono = "1001" else '0';
	limit_chrono <= '1' when counter_minutes_tens_chrono = "0101" and counter_minutes_units_chrono = "1001" else '0';



    reset <= not KEY(1);
    mode_reglage <= SW(9);
    mode_alarme <= SW(8);
	 mode_chrono <= SW(7);

    -- Instanciation du diviseur d'horloge
    divider: clock_divider
        port map (
            clock_in => MAX10_CLK1_50,
            reset => reset,
            clock_out => clk_1Hz
        );
		  
	dividerms: clk_ms
    port map (
        clock_in => MAX10_CLK1_50,
        reset    => reset,
        clock_out => clk_1ms
    );

		

    -- Instanciation du module de réglage
    reglage_inst: reglage
        port map (
            clock => MAX10_CLK1_50,
            reset => reset,
            KEY => KEY,
            SW => SW,
            load_seconds_units => load_seconds_units_val,
            load_seconds_tens => load_seconds_tens_val,
            load_minutes_units => load_minutes_units_val,
            load_minutes_tens => load_minutes_tens_val,
            load_hours_units => load_hours_units_val,
            load_hours_tens => load_hours_tens_val,
            load_enable => load_enable_signal
        );
		  

    -- Instanciation du module d'alarme
    alarme_inst: alarme
        port map (
            clock => MAX10_CLK1_50,
            reset => reset,
            KEY => KEY,
            SW => SW,
            alarme_seconds_units => alarme_seconds_units,
            alarme_seconds_tens => alarme_seconds_tens,
            alarme_minutes_units => alarme_minutes_units,
            alarme_minutes_tens => alarme_minutes_tens,
            alarme_hours_units => alarme_hours_units,
            alarme_hours_tens => alarme_hours_tens,
            alarme_enable => alarme_enable_signal
        );

		  
		
	 -- Instanciation des compteurs chrono  
		  
    milliseconds_units_chrono: counter
     generic map (MAX_COUNT => 9) -- Max count is 9 (0–9)
     port map (
        clock       => clk_1ms,
        reset       => reset or limit_chrono,
        enable      => not (mode_reglage or mode_alarme) and SW(0),
        load_enable => '0', 
        load_value  => load_seconds_units_val,
        counter     => counter_mseconds_units_chrono,
        carry       => carry_mseconds_units_chrono
    );

   milliseconds_tens_chrono: counter
    generic map (MAX_COUNT => 9) -- Max count is 9 (0–9)
    port map (
        clock       => clk_1ms,
        reset       => reset or limit_chrono,
        enable      => not (mode_reglage or mode_alarme ) and carry_mseconds_units_chrono,
        load_enable => load_enable_signal,
        load_value  => load_seconds_tens_val,
        counter     => counter_mseconds_tens_chrono,
        carry       => carry_mseconds_tens_chrono
    );

  seconds_units_chrono: counter
    generic map (MAX_COUNT => 9) -- Max count is 9 (0–9)
    port map (
        clock       => clk_1ms,
        reset       => reset or limit_chrono,
        enable      => not (mode_reglage or mode_alarme) and enable_seconds_units_chrono,
        load_enable => '0',
        load_value  => load_seconds_units_val,
        counter     => counter_seconds_units_chrono,
        carry       => carry_seconds_units_chrono
    );

  seconds_tens_chrono: counter
    generic map (MAX_COUNT => 5) -- Max count is 5 (0–5)
    port map (
        clock       => clk_1ms,
        reset       => reset or limit_chrono,
        enable      => not (mode_reglage or mode_alarme) and enable_seconds_tens_chrono,
        load_enable => '0',
        load_value  => load_seconds_tens_val,
        counter     => counter_seconds_tens_chrono,
        carry       => carry_seconds_tens_chrono
    );

  minutes_units_chrono: counter
    generic map (MAX_COUNT => 9) -- Max count is 9 (0–9)
    port map (
        clock       => clk_1ms,
        reset       => reset or limit_chrono,
        enable      => not (mode_reglage or mode_alarme) and enable_minutes_units_chrono,
        load_enable => '0',
        load_value  => load_minutes_units_val,
        counter     => counter_minutes_units_chrono,
        carry       => carry_minutes_units_chrono
    );

  minutes_tens_chrono: counter
    generic map (MAX_COUNT => 5) -- Max count is 5 (0–5)
    port map (
        clock       => clk_1ms,
        reset       => reset or limit_chrono,
        enable      => not (mode_reglage or mode_alarme) and enable_minutes_tens_chrono,
        load_enable => '0',
        load_value  => load_minutes_tens_val,
        counter     => counter_minutes_tens_chrono,
        carry       => carry_minutes_tens_chrono
    );


		  

		  
	 
	 -- Instanciation des compteurs horloge/alarme
    seconds_units: counter
        generic map (MAX_COUNT => 9) -- 9 en décimal
        port map (
            clock => clk_1Hz,
            reset => reset or limit,
            enable => not (mode_reglage),
            load_enable => load_enable_signal,  -- Charge si actif
            load_value => load_seconds_units_val,
            counter => counter_seconds_units,
            carry => carry_seconds_units
        );

    seconds_tens: counter
        generic map (MAX_COUNT => 5) -- 5 en décimal
        port map (
            clock => clk_1Hz,
            reset => reset or limit,
            enable => not (mode_reglage) and carry_seconds_units,
            load_enable => load_enable_signal,  -- Charge si actif
            load_value => load_seconds_tens_val,
            counter => counter_seconds_tens,
            carry => carry_seconds_tens
        );

    minutes_units: counter
        generic map (MAX_COUNT => 9) -- 9 en décimal
        port map (
            clock => clk_1Hz,
            reset => reset or limit,
            enable => not (mode_reglage) and enable_minutes_units,
            load_enable => load_enable_signal,  -- Charge si actif
            load_value => load_minutes_units_val,
            counter => counter_minutes_units,
            carry => carry_minutes_units
        );

    minutes_tens: counter
        generic map (MAX_COUNT => 5) -- 5 en décimal
        port map (
            clock => clk_1Hz,
            reset => reset or limit,
            enable => not (mode_reglage) and enable_minutes_tens,
            load_enable => load_enable_signal,  -- Charge si actif
            load_value => load_minutes_tens_val,
            counter => counter_minutes_tens,
            carry => carry_minutes_tens
        );

    hours_units: counter
        generic map (MAX_COUNT => 9) -- 9 en décimal
        port map (
            clock => clk_1Hz,
            reset => reset or limit,
            enable => not (mode_reglage) and enable_hours_units,
            load_enable => load_enable_signal,  -- Charge si actif
            load_value => load_hours_units_val,
            counter => counter_hours_units,
            carry => carry_hours_units
        );

    hours_tens: counter
        generic map (MAX_COUNT => 2) -- 2 en décimal (pour format 24 heures)
        port map (
            clock => clk_1Hz,
            reset => reset or limit,
            enable => not (mode_reglage) and enable_hours_tens,
            load_enable => load_enable_signal,  -- Charge si actif
            load_value => load_hours_tens_val,
            counter => counter_hours_tens,
            carry => carry_hours_tens
        );

    -- Process pour gérer LEDR(8)
    process(KEY)
    begin
        if KEY(0) = '0' and ( mode_reglage = '0' or mode_alarme = '0' ) then
            alarme_triggered <= '0';
        elsif (counter_seconds_units = alarme_seconds_units and
               counter_seconds_tens = alarme_seconds_tens and
               counter_minutes_units = alarme_minutes_units and
               counter_minutes_tens = alarme_minutes_tens and
               counter_hours_units = alarme_hours_units and
               counter_hours_tens = alarme_hours_tens and
               alarme_enable_signal = '1') then
            alarme_triggered <= '1';
        end if;
    end process;
	 
	 
	-- Process to toggle chrono on KEY0 press
	process(KEY)
	begin
        
	end process;

    -- Gestion de la LED Alarme
    process(mode_alarme, alarme_triggered, alarme_enable_signal)
    begin
        if (alarme_enable_signal = '1' and mode_alarme = '1') or (alarme_enable_signal = '1' and alarme_triggered = '1') then
            LEDR(8) <= '1';
        else
            LEDR(8) <= '0';
        end if;
    end process;
	 
	 -- Gestion de la LED Chrono
	process(mode_chrono, chrono_start_stop)
	begin
    if mode_chrono = '1' and chrono_start_stop = '1' then
        LEDR(7) <= '1'; -- Indicate chrono is active
    else
        LEDR(7) <= '0'; -- Indicate chrono is inactive
    end if;
	end process;

    -- Sélection des sorties en fonction de l'état du switch 8
    process(mode_alarme,mode_chrono)
    begin
        if mode_alarme = '1' then
            display_seconds_units <= alarme_seconds_units;
            display_seconds_tens <= alarme_seconds_tens;
            display_minutes_units <= alarme_minutes_units;
            display_minutes_tens <= alarme_minutes_tens;
            display_hours_units <= alarme_hours_units;
            display_hours_tens <= alarme_hours_tens;
				
			elsif mode_chrono = '1' then
				display_seconds_units <= counter_mseconds_units_chrono;
				display_seconds_tens <= counter_mseconds_tens_chrono;
				display_minutes_units <= counter_seconds_units_chrono;
				display_minutes_tens <= counter_seconds_tens_chrono;
				display_hours_units <= counter_minutes_units_chrono;
				display_hours_tens <= counter_minutes_tens_chrono;

				
        else
            display_seconds_units <= counter_seconds_units;
            display_seconds_tens <= counter_seconds_tens;
            display_minutes_units <= counter_minutes_units;
            display_minutes_tens <= counter_minutes_tens;
            display_hours_units <= counter_hours_units;
            display_hours_tens <= counter_hours_tens;
        end if;
    end process;

    -- Instanciation des convertisseurs 7 segments
    seg7_lut_units_sec: seg7_lut
        port map (
            digit => display_seconds_units,
            hex => HEX0
        );

    seg7_lut_tens_sec: seg7_lut
        port map (
            digit => display_seconds_tens,
            hex => HEX1
        );

    seg7_lut_units_min: seg7_lut
        port map (
            digit => display_minutes_units,
            hex => HEX2
        );

    seg7_lut_tens_min: seg7_lut
        port map (
            digit => display_minutes_tens,
            hex => HEX3
        );

    seg7_lut_units_hr: seg7_lut
        port map (
            digit => display_hours_units,
            hex => HEX4
        );

    seg7_lut_tens_hr: seg7_lut
        port map (
            digit => display_hours_tens,
            hex => HEX5
        );
end Behavioral;
