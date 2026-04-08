# Projet DE0-Nano - Partie 4 (Capteurs Sol + Calculateur cable)

Base: `TP CUTE-CAR_last/TP CUTE-CAR` (version nettoyee)

## Contenu conserve

- `robot_cutecar_de0nano.vhd` (top-level simplifie)
- `robot_cutecar_de0nano.qsf` / `robot_cutecar_de0nano.qpf`
- `nios_system.qsys` (generation HDL a faire dans Quartus/Platform Designer)
- `ip_modules/pll_2freqs.vhd`
- `ip_modules/capteurs_sol.vhd`
- `ip_modules/calculateur_cable.vhd`
- `software/main.c` (validation sur carte)

## Nettoyage realise

- Suppression des modules non utilises pour la Partie 4: PWM moteur, suivi_ligne, rotation, IR, documents TP, anciens projets Qsys `cutecar`, rapports de compilation, `db/`, etc.
- Nettoyage du `.qsf`: uniquement les contraintes de brochage necessaires au design retenu.
- Aucune reference `.qsf` vers des fichiers supprimes.

## Architecture retenue

- `capteurs_sol.vhd` pilote le LTC2308 en 40 MHz (`pll_2freqs`).
- Le calculateur cable est combinatoire:
  - `data_ir[7:0]`
  - `data_jr[7:0]`
  - `op_sel[1:0]`
  - `result[15:0]`
- Cote Qsys, la version retenue est allegee (sans blocs SDRAM/clocks).
- Dans ce projet:
  - `data_ir = data0`
  - `data_jr = data1`
  - `op_sel = MOTOR_LEFT[9:8]`

## Lecture resultat depuis Nios (PIO existants)

Pages SW selectionnees par `{START_ROT, DIR_ROT}`:

- `00` -> `result[7:0]`
- `01` -> `result[15:8]`
- `10` -> `data_ir`
- `11` -> `data_jr`

`FIN_SL` reflete `data_ready` pour le handshake d'acquisition.

## Build Quartus (13.0 SP1)

1. Ouvrir `robot_cutecar_de0nano.qpf`.
2. Verifier que la cible est `EP4CE22F17C6`.
3. Regenerer le systeme Platform Designer si necessaire (`nios_system.qsys`).
4. Compiler le projet.
5. Programmer la DE0-Nano.

## Software

Voir `software/main.c` et `software/README.md`.
