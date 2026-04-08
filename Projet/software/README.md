# Validation logicielle (Partie 4)

`main.c` valide le bloc calculateur cable (`data_ir`, `data_jr`, `op_sel`, `result`).

## Mapping PIO utilise

- `START_SL` : declenche l'acquisition ADC.
- `FIN_SL` : `data_ready` (acquisition terminee).
- `MOTOR_LEFT[9:8]` : `op_sel`.
- `SW[7:0]` : donnees lues selon la page `{START_ROT, DIR_ROT}` :
  - `00` -> `result[7:0]`
  - `01` -> `result[15:8]`
  - `10` -> `data_ir`
  - `11` -> `data_jr`

## Sequence de test

1. Initialiser les PIO (trigger bas, page 0).
2. Pour `op_sel = 0..3`:
   - ecrire `op_sel` dans `MOTOR_LEFT[9:8]`
   - lancer acquisition (`START_SL=1`) et attendre `FIN_SL=1`
   - lire `result` (2 octets) + `data_ir` + `data_jr`
   - recalculer en software et comparer au resultat hardware
3. Affichage LEDs:
   - OK: LED = octet bas du resultat
   - KO: LED7=1
