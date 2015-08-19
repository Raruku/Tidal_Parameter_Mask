# Tidal_Parameter_Mask
#Creates Fits files that uses SDSS Petrosian Radius to mask the outer 10xR50 and inter R50 areas.

use strict;
use warnings;
use PGPLOT;
use PDL;
use PDL::Graphics::PGPLOT;
use PDL::Graphics2D;
use PDL::Image2D;
use PDL::IO::FITS;;
use Text::CSV;
use Math::Trig 'pi';
use PDL::IO::Pic;
use PDL::Core;
use PDL::Graphics::IIS;
my $deg2rad = pi/180.;
use PDL::IO::Misc;
use PDL::Transform;
#use Astro::FITS::Header;
#use Astro::FITS::Header::CFITSIO;
$ENV{'PGPLOT_DIR'} = '/usr/local/pgplot';
$ENV{'PGPLOT_DEV'} = '/xs';


open my $SEX, '<', "result_S82.csv" or die "cannot open result_S82.csv: $!"; #open your input file containing all the required input files from SDSS SQL
my $inp = Text::CSV->new({'binary'=>1});
$inp->column_names($inp->getline($SEX));
my $parameter = $inp->getline_hr_all($SEX);

my @nyuID = map {$_->{'col0'}} @{$parameter};
my @A = map {$_->{'R50_r'}} @{$parameter};
my @B = map {$_->{'R50_r'}} @{$parameter};

foreach my $posCount (0 .. scalar @nyuID - 1)
{
	
print "p${nyuID[$posCount]}_S82.fits\n";

#NEW MASK USING SEXTRACTOR
open my $inPositions, '<', "p${nyuID[$posCount]}_S82.aper.csv" or die "cannot open p${nyuID[$posCount]}_S82.aper.csv: $!";

my $input_positions = Text::CSV->new({'binary'=>1});
$input_positions->column_names($input_positions->getline($inPositions));
my $inputs = $input_positions->getline_hr_all($inPositions);

#Make new varibles using the header (column name) for each column
#We will use this later to call certian values
my @N = map {$_->{'NUMBER'}} @{$inputs};
my @X = map {$_->{'X_IMAGE'}} @{$inputs};
my @Y = map {$_->{'Y_IMAGE'}} @{$inputs};

my @THETA = map {$_->{'THETA_IMAGE'}} @{$inputs};

##Open your image from a list
my $image = rfits("p${nyuID[$posCount]}_S82.fits"); #nyuID
##Display a image using the perl
#my $normal = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
##							min, max
#$normal->fits_imag($image,1000,2000);

#Acquiring the dimensions in an image
my @dim = dims($image);
print join(',',@dim),"\n";
#join(',',@dim)
my $size_x = $dim[0];
my $size_y = $dim[1];
print "This image is $size_x x $size_y pixels";
print "\n";


#Naming varibles for stuff
my $e; #eccentricity
my $nx_pix;
my $ny_pix;
my $r_a;
my $r_b;
my $r_10a;
my $r_10b;
my $THETA;
my $K;

#-------------------
#Making a fake image for GALFIT and for visual confirmation
#-----------------
my $x = xvals(float(),$size_x,$size_y)+1;
my $y = yvals(float(),$size_x,$size_y)+1;
my $ellipse = zeroes($size_x,$size_y);
my $ellipse_2 = ones($size_x,$size_y);
my $ellipse_3 = zeroes($size_x,$size_y);
my $ellipse_4 = ones($size_x,$size_y);

foreach my $Count (0 .. scalar @N - 1)
	{
		if ($X[$Count] >= ($size_x/2 - 5) && $Y[$Count] >= ($size_y/2 - 5) && $Y[$Count] <= ($size_y/2 + 5)  ##If statement to find the main galaxy in the center of the image
			&& $X[$Count] <= ($size_x/2 + 5) && $Y[$Count] >= ($size_y/2 - 5) && $Y[$Count] <= ($size_y/2 + 5)  )
		{
		$e = (1-((($B[$Count])**2)/(($A[$Count])**2)))**.5;
		$nx_pix = $X[$Count];
		$ny_pix = $Y[$Count];
		$THETA = $deg2rad * -$THETA[$Count];
		$K=1;
		$r_a = $K*$A[$posCount];
		$r_b = $K*$B[$posCount];
		$r_10a = 10*$K*$A[$posCount];
		$r_10b = 10*$K*$B[$posCount];
		my $new_x = $x - $nx_pix;
		my $new_y = $y - $ny_pix;
	
		my $r_x = $new_x * cos(($THETA)) - $new_y * sin(($THETA));
		my $r_y = $new_x * sin(($THETA)) + $new_y * cos(($THETA));
	
		my $tmp = ($new_x /$r_a)**2 + ($new_y /$r_a)**2;
		$tmp->where($tmp<=1) .= 1;
		$tmp->where($tmp>1) .= 0;
		$ellipse |= $tmp;
	
		my $tmp_2 = ($new_x /$r_a)**2 + ($new_y /$r_a)**2;
		$tmp_2->where($tmp_2<=1) .= 0;
		$tmp_2->where($tmp_2>1) .= 1;
		$ellipse_2 &= $tmp_2;
		
		#10xSDSS Re
		my $tmp_3 = ($new_x /$r_10a)**2 + ($new_y /$r_10a)**2;
		$tmp_3->where($tmp_3<=1) .= 1;
		$tmp_3->where($tmp_3>1) .= 0;
		$ellipse_3 |= $tmp_3;
	
		my $tmp_4 = ($new_x /$r_10a)**2 + ($new_y /$r_10a)**2;
		$tmp_4->where($tmp_4<=1) .= 0;
		$tmp_4->where($tmp_4>1) .= 1;
		$ellipse_4 &= $tmp_4;
		}
	}
	

$ellipse->sethdr($image->hdr);
$ellipse->wfits("R50.${nyuID[$posCount]}_S82_1a.fits"); 
$ellipse_2->sethdr($image->hdr);
$ellipse_2->wfits("R50.${nyuID[$posCount]}_S82_1b.fits"); 

#10xRe
$ellipse_3->sethdr($image->hdr);
$ellipse_3->wfits("10R50.${nyuID[$posCount]}_S82_1a.fits");
$ellipse_4->sethdr($image->hdr);
$ellipse_4->wfits("10R50.${nyuID[$posCount]}_S82_1b.fits");

my $Mimage = $ellipse_2 * $ellipse_3;
$Mimage-> wfits("R50_Mask.p${nyuID[$posCount]}_S82.fits"); #make nyuID R50 mask

#R50 mask x Segmentation mask
my $Seg_image = rfits("p${nyuID[$posCount]}_S82.mask_1b.fits"); # SEG_Object Mask 

#Full mask
my $Full_Mask = $Seg_image * $Mimage;
$Full_Mask-> wfits("Full_Mask.p${nyuID[$posCount]}_S82.fits");

#my $mask_image = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
#$mask_image->fits_imag($Mimage,0,1);

}
print "Finished\n";
