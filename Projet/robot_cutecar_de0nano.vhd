LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY robot_cutecar_de0nano IS
    PORT (
        KEY : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        CLOCK_50 : IN STD_LOGIC;

        LED : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);

        MTR_Sleep_n : OUT STD_LOGIC;
        VCC3P3_PWRON_n : OUT STD_LOGIC;

        LTC_ADC_CONVST : OUT STD_LOGIC;
        LTC_ADC_SCK : OUT STD_LOGIC;
        LTC_ADC_SDI : OUT STD_LOGIC;
        LTC_ADC_SDO : IN STD_LOGIC
    );
END robot_cutecar_de0nano;

ARCHITECTURE rtl OF robot_cutecar_de0nano IS

    COMPONENT nios_system
        PORT (
            clk_clk : IN STD_LOGIC;
            reset_reset_n : IN STD_LOGIC;
            led_export : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            sw_export : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            motorleft_export : OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
            motorright_export : OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
            start_sl_export_export : OUT STD_LOGIC;
            start_rot_export_export : OUT STD_LOGIC;
            dir_rot_export_export : OUT STD_LOGIC;
            fin_sl_export_export : IN STD_LOGIC;
            fin_rot_export_export : IN STD_LOGIC
        );
    END COMPONENT;

    SIGNAL led_from_nios : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sw_to_nios : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL motorleft_nios : STD_LOGIC_VECTOR(13 DOWNTO 0);
    SIGNAL motorright_nios : STD_LOGIC_VECTOR(13 DOWNTO 0);

    SIGNAL start_sl_sig : STD_LOGIC;
    SIGNAL start_rot_sig : STD_LOGIC;
    SIGNAL dir_rot_sig : STD_LOGIC;
    SIGNAL fin_sl_sig : STD_LOGIC;
    SIGNAL fin_rot_sig : STD_LOGIC;

    SIGNAL clk_40m : STD_LOGIC;

    SIGNAL start_sl_sync0 : STD_LOGIC;
    SIGNAL start_sl_sync1 : STD_LOGIC;

    SIGNAL data_ready : STD_LOGIC;
    SIGNAL data0 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL data1 : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL op_sel_sync0 : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL op_sel_sync1 : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL calc_result : STD_LOGIC_VECTOR(15 DOWNTO 0);

    SIGNAL data_ready_sync0 : STD_LOGIC;
    SIGNAL data_ready_sync1 : STD_LOGIC;

    SIGNAL calc_result_meta : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL calc_result_sync : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL data0_meta : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL data0_sync : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL data1_meta : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL data1_sync : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL page_sel : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN

    MTR_Sleep_n <= '1';
    VCC3P3_PWRON_n <= '0';

    LED <= led_from_nios;

    -- Lecture resultat/operandes via SW[7:0], page selectionnee par {start_rot, dir_rot}.
    page_sel <= start_rot_sig & dir_rot_sig;
    WITH page_sel SELECT
        sw_to_nios <= calc_result_sync(7 DOWNTO 0) WHEN "00",
                      calc_result_sync(15 DOWNTO 8) WHEN "01",
                      data0_sync WHEN "10",
                      data1_sync WHEN OTHERS;

    -- Handshake acquisition vers Nios.
    fin_sl_sig <= data_ready_sync1;
    fin_rot_sig <= data_ready_sync1;

    PLL_inst : ENTITY work.pll_2freqs
        PORT MAP (
            areset => NOT KEY(0),
            inclk0 => CLOCK_50,
            c0 => clk_40m,
            c1 => OPEN
        );

    NiosII : nios_system
        PORT MAP (
            clk_clk => CLOCK_50,
            reset_reset_n => KEY(0),
            led_export => led_from_nios,
            sw_export => sw_to_nios,
            motorleft_export => motorleft_nios,
            motorright_export => motorright_nios,
            start_sl_export_export => start_sl_sig,
            start_rot_export_export => start_rot_sig,
            dir_rot_export_export => dir_rot_sig,
            fin_sl_export_export => fin_sl_sig,
            fin_rot_export_export => fin_rot_sig
        );

    -- CDC: commande d'acquisition 50 -> 40 MHz.
    PROCESS (clk_40m, KEY(0))
    BEGIN
        IF KEY(0) = '0' THEN
            start_sl_sync0 <= '0';
            start_sl_sync1 <= '0';
            op_sel_sync0 <= (OTHERS => '0');
            op_sel_sync1 <= (OTHERS => '0');
        ELSIF rising_edge(clk_40m) THEN
            start_sl_sync0 <= start_sl_sig;
            start_sl_sync1 <= start_sl_sync0;
            op_sel_sync0 <= motorleft_nios(9 DOWNTO 8);
            op_sel_sync1 <= op_sel_sync0;
        END IF;
    END PROCESS;

    capteurs_inst : ENTITY work.capteurs_sol
        PORT MAP (
            clk => clk_40m,
            reset_n => KEY(0),
            data_capture => start_sl_sync1,
            data_readyr => data_ready,
            data0r => data0,
            data1r => data1,
            data2r => OPEN,
            data3r => OPEN,
            data4r => OPEN,
            data5r => OPEN,
            data6r => OPEN,
            ADC_CONVSTr => LTC_ADC_CONVST,
            ADC_SCK => LTC_ADC_SCK,
            ADC_SDIr => LTC_ADC_SDI,
            ADC_SDO => LTC_ADC_SDO
        );

    calc_inst : ENTITY work.calculateur_cable
        PORT MAP (
            data_ir => data0,
            data_jr => data1,
            op_sel => op_sel_sync1,
            result => calc_result
        );

    -- CDC: donnees capteurs/resultat 40 -> 50 MHz.
    PROCESS (CLOCK_50, KEY(0))
    BEGIN
        IF KEY(0) = '0' THEN
            data_ready_sync0 <= '0';
            data_ready_sync1 <= '0';
            calc_result_meta <= (OTHERS => '0');
            calc_result_sync <= (OTHERS => '0');
            data0_meta <= (OTHERS => '0');
            data0_sync <= (OTHERS => '0');
            data1_meta <= (OTHERS => '0');
            data1_sync <= (OTHERS => '0');
        ELSIF rising_edge(CLOCK_50) THEN
            data_ready_sync0 <= data_ready;
            data_ready_sync1 <= data_ready_sync0;

            calc_result_meta <= calc_result;
            calc_result_sync <= calc_result_meta;

            data0_meta <= data0;
            data0_sync <= data0_meta;

            data1_meta <= data1;
            data1_sync <= data1_meta;
        END IF;
    END PROCESS;

END rtl;
