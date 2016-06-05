perl SBACKGROUND_REPLACER_DR7.pl
perl SBACKGROUND_REPLACER_S82.pl
perl GALFIT_INPUTS.pl
rm galfit.*
perl Tidal_mask_DR7.pl
chmod 755 GALFIT_BATCH_DR7.sh
chmod 755 GALFIT_MBATCH_DR7.sh
perl Tidal_mask_S82.pl
chmod 755 GALFIT_BATCH_S82.sh
chmod 755 GALFIT_MBATCH_S82.sh
./GALFIT_BATCH_DR7.sh
./GALFIT_BATCH_S82.sh
perl Critical_Tidal_Parameter.pl
echo "run NOISE.cl files, then GALFIT_MBATCH.sh files then Tidal_Model_Tc files"
