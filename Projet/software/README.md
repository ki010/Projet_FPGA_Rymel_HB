# Validation logicielle (Partie 4)

`main.c` realise la sequence suivante:

1. Initialisation des PIO (trigger, mode lecture, LEDs).
2. Ecriture du seuil capteurs dans `MOTOR_LEFT[7:0]`.
3. Acquisition:
   - `START_SL=1`
   - attente de `FIN_SL=1`
   - `START_SL=0`
   - attente du retour `FIN_SL=0`
4. Lecture resultats:
   - `DIR_ROT=0` -> lecture `vect_capt` sur `SW[6:0]`
   - `DIR_ROT=1` -> lecture `pos_code` sur `SW[3:0]`
5. Verification coherence:
   - recalcul logiciel de position a partir de `vect_capt`
   - comparaison `pos_hw == pos_sw`
   - verification du drapeau ligne perdue (`FIN_ROT`)
6. Affichage LED:
   - coherent: `LED[6:0]=vect_capt`
   - erreur: `LED[7]=1`
