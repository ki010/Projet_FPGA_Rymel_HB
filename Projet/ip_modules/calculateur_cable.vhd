LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY calculateur_cable IS
    PORT (
        data_ir : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        data_jr : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        op_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        result : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END calculateur_cable;

ARCHITECTURE combinatoire OF calculateur_cable IS
BEGIN

    PROCESS (data_ir, data_jr, op_sel)
        VARIABLE tmp : UNSIGNED(15 DOWNTO 0);
    BEGIN
        CASE op_sel IS
            WHEN "00" =>
                tmp := resize(unsigned(data_ir), 16) + resize(unsigned(data_jr), 16);
            WHEN "01" =>
                -- Soustraction en arithmetique non signee (modulo 2^16 si negatif).
                tmp := resize(unsigned(data_ir), 16) - resize(unsigned(data_jr), 16);
            WHEN "10" =>
                tmp := shift_left(resize(unsigned(data_ir), 16), 1);
            WHEN OTHERS =>
                tmp := shift_right(resize(unsigned(data_ir), 16), 1);
        END CASE;

        result <= STD_LOGIC_VECTOR(tmp);
    END PROCESS;

END combinatoire;
