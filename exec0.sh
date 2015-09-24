perl SDSS_Rename_DR7.pl
wget -i sdss-wget-PSF_DR7.lis
chmod 755 Rename_PSF_DR7.sh
./Rename_PSF_DR7.sh
perl SDSS_Rename_S82.pl
wget -i sdss-wget-PSF_S82.lis
chmod 755 Rename_PSF_S82.sh
./Rename_PSF_S82.sh
