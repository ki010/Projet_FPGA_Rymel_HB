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

        DRAM_CLK : OUT STD_LOGIC;
        DRAM_CKE : OUT STD_LOGIC;
        DRAM_ADDR : OUT STD_LOGIC_VECTOR(12 DOWNTO 0);
        DRAM_BA : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        DRAM_CS_N : OUT STD_LOGIC;
        DRAM_CAS_N : OUT STD_LOGIC;
        DRAM_RAS_N : OUT STD_LOGIC;
        DRAM_WE_N : OUT STD_LOGIC;
        DRAM_DQ : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        DRAM_DQM : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

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
            sdram_wire_addr : OUT STD_LOGIC_VECTOR(12 DOWNTO 0);
            sdram_wire_ba : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            sdram_wire_cas_n : OUT STD_LOGIC;
            sdram_wire_cke : OUT STD_LOGIC;
            sdram_wire_cs_n : OUT STD_LOGIC;
            sdram_wire_dq : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            sdram_wire_dqm : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            sdram_wire_ras_n : OUT STD_LOGIC;
            sdram_wire_we_n : OUT STD_LOGIC;
            sdram_clk_clk : OUT STD_LOGIC;
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
    SIGNAL start_sl_sync0 : STD_LOGIC;
    SIGNAL start_sl_sync1 : STD_LOGIC;

    SIGNAL clk_40m : STD_LOGIC;

    SIGNAL data_ready : STD_LOGIC;
    SIGNAL data0 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL data1 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL data2 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL data3 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL data4 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL data5 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL data6 : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL niveau_seuil : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL vect_capt : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL pos_ligne : INTEGER RANGE -6 TO 6;
    SIGNAL pos_code : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL data_ready_sync0 : STD_LOGIC;
    SIGNAL data_ready_sync1 : STD_LOGIC;
    SIGNAL vect_capt_meta : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL vect_capt_sync : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL pos_code_meta : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL pos_code_sync : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN

    MTR_Sleep_n <= '1';
    VCC3P3_PWRON_n <= '0';

    LED <= led_from_nios;

    -- Seuil configurable par logiciel via MOTOR_LEFT[7:0], valeur par defaut 0x70.
    niveau_seuil <= x"70" WHEN motorleft_nios(7 DOWNTO 0) = x"00" ELSE motorleft_nios(7 DOWNTO 0);

    -- Position codee sur 4 bits: 0..12 <=> -6..+6.
    pos_code <= STD_LOGIC_VECTOR(to_unsigned(pos_ligne + 6, 4));

    -- dir_rot = 0 -> SW[6:0] = vect_capt, SW[7] = data_ready
    -- dir_rot = 1 -> SW[3:0] = pos_code, SW[7] = data_ready
    sw_to_nios <= data_ready_sync1 & vect_capt_sync WHEN dir_rot_sig = '0' ELSE
                  data_ready_sync1 & "000" & pos_code_sync;

    fin_sl_sig <= data_ready_sync1;
    fin_rot_sig <= '1' WHEN vect_capt_sync = "0000000" ELSE '0';

    PROCESS (clk_40m, KEY(0))
    BEGIN
        IF KEY(0) = '0' THEN
            start_sl_sync0 <= '0';
            start_sl_sync1 <= '0';
        ELSIF rising_edge(clk_40m) THEN
            start_sl_sync0 <= start_sl_sig;
            start_sl_sync1 <= start_sl_sync0;
        END IF;
    END PROCESS;

    PROCESS (CLOCK_50, KEY(0))
    BEGIN
        IF KEY(0) = '0' THEN
            data_ready_sync0 <= '0';
            data_ready_sync1 <= '0';
            vect_capt_meta <= (OTHERS => '0');
            vect_capt_sync <= (OTHERS => '0');
            pos_code_meta <= (OTHERS => '0');
            pos_code_sync <= (OTHERS => '0');
        ELSIF rising_edge(CLOCK_50) THEN
            data_ready_sync0 <= data_ready;
            data_ready_sync1 <= data_ready_sync0;
            vect_capt_meta <= vect_capt;
            vect_capt_sync <= vect_capt_meta;
            pos_code_meta <= pos_code;
            pos_code_sync <= pos_code_meta;
        END IF;
    END PROCESS;

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
            sdram_wire_addr => DRAM_ADDR,
            sdram_wire_ba => DRAM_BA,
            sdram_wire_cas_n => DRAM_CAS_N,
            sdram_wire_cke => DRAM_CKE,
            sdram_wire_cs_n => DRAM_CS_N,
            sdram_wire_dq => DRAM_DQ,
            sdram_wire_dqm => DRAM_DQM,
            sdram_wire_ras_n => DRAM_RAS_N,
            sdram_wire_we_n => DRAM_WE_N,
            sdram_clk_clk => DRAM_CLK,
            motorleft_export => motorleft_nios,
            motorright_export => motorright_nios,
            start_sl_export_export => start_sl_sig,
            start_rot_export_export => start_rot_sig,
            dir_rot_export_export => dir_rot_sig,
            fin_sl_export_export => fin_sl_sig,
            fin_rot_export_export => fin_rot_sig
        );

    capteurs_inst : ENTITY work.capteurs_sol
        PORT MAP (
            clk => clk_40m,
            reset_n => KEY(0),
            data_capture => start_sl_sync1,
            data_readyr => data_ready,
            data0r => data0,
            data1r => data1,
            data2r => data2,
            data3r => data3,
            data4r => data4,
            data5r => data5,
            data6r => data6,
            ADC_CONVSTr => LTC_ADC_CONVST,
            ADC_SCK => LTC_ADC_SCK,
            ADC_SDIr => LTC_ADC_SDI,
            ADC_SDO => LTC_ADC_SDO
        );

    vect_capt(0) <= '1' WHEN unsigned(data0) > unsigned(niveau_seuil) ELSE '0';
    vect_capt(1) <= '1' WHEN unsigned(data1) > unsigned(niveau_seuil) ELSE '0';
    vect_capt(2) <= '1' WHEN unsigned(data2) > unsigned(niveau_seuil) ELSE '0';
    vect_capt(3) <= '1' WHEN unsigned(data3) > unsigned(niveau_seuil) ELSE '0';
    vect_capt(4) <= '1' WHEN unsigned(data4) > unsigned(niveau_seuil) ELSE '0';
    vect_capt(5) <= '1' WHEN unsigned(data5) > unsigned(niveau_seuil) ELSE '0';
    vect_capt(6) <= '1' WHEN unsigned(data6) > unsigned(niveau_seuil) ELSE '0';

    pos_inst : ENTITY work.calcul_position
        PORT MAP (
            vect_capt => vect_capt,
            pos_ligne => pos_ligne
        );

END rtl;
