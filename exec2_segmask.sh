perl SEG_SEX_S82.pl
chmod 755 seg_all_S82.sh
./seg_all_S82.sh
perl SEG_To_CSV.pl
perl SEG_MASK.pl
echo Run Mask_Maker.cl in IRAF, then exec3
