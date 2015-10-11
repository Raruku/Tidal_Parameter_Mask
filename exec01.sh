perl SDSS_PSF.pl
wget -i sdss-wget-PSF.lis
chmod 755 Rename_PSF.sh
./Rename_PSF.sh
perl SDSS_SEX.pl
chmod +x aper_all.sh
./aper_all.sh
perl APER_To_CSV.pl
perl Single_SDSS_S82_Postage_Stamp.pl
echo "Run Galaxy_cutouts.cl in IRAF"
echo "Run PSF_Cut.cl in IRAF"
