LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY calcul_position IS
    PORT(
        vect_capt : IN  std_logic_vector(6 downto 0);
        pos_ligne : OUT integer range -6 to 6
    );
END calcul_position;

ARCHITECTURE combinatoire OF calcul_position IS
BEGIN

process(vect_capt)

    variable PPU : integer := 0;
    variable PDU : integer := 0;

begin

    -- recherche du premier 1 (PPU)
    if vect_capt(0) = '1' then
        PPU := 0;
    elsif vect_capt(1) = '1' then
        PPU := 1;
    elsif vect_capt(2) = '1' then
        PPU := 2;
    elsif vect_capt(3) = '1' then
        PPU := 3;
    elsif vect_capt(4) = '1' then
        PPU := 4;
    elsif vect_capt(5) = '1' then
        PPU := 5;
    elsif vect_capt(6) = '1' then
        PPU := 6;
    else
        PPU := 0; -- cas aucun capteur actif
    end if;

    -- recherche du dernier 1 (PDU)
    if vect_capt(6) = '1' then
        PDU := 6;
    elsif vect_capt(5) = '1' then
        PDU := 5;
    elsif vect_capt(4) = '1' then
        PDU := 4;
    elsif vect_capt(3) = '1' then
        PDU := 3;
    elsif vect_capt(2) = '1' then
        PDU := 2;
    elsif vect_capt(1) = '1' then
        PDU := 1;
    elsif vect_capt(0) = '1' then
        PDU := 0;
    else
        PDU := 0;
    end if;

    -- calcul position
    pos_ligne <= PPU + PDU - 6;

end process;

END combinatoire;