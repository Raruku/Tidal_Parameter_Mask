perl SDSS_PSF.pl
wget -i sdss-wget-PSF.lis
chmod 755 Rename_PSF.sh
./Rename_PSF.sh
echo "run PSF_Cut.cl in IRAF"
