#! usr/bin/perl
use strict;
use warnings;
use PDL;
use PDL::Image2D;
use Text::CSV;
 
#Prints nyuID, run type, Tp, Tm, Tc to a CSV
#Displays graphs of all galaxies' deviations
#Creates check file to display regular/model/residual/tidal images of each galaxy

my @galaxy_fits = qw/a aa/; #model fits we are checking
my @DataRelease = qw/_DR7 _S82/;
foreach my $DataRelease (@DataRelease) {
open my $inPositions, '<', "result$DataRelease.csv" or die "cannot open result$DataRelease.csv: $!";
my $input_positions = Text::CSV->new({'binary'=>1});
$input_positions->column_names($input_positions->getline($inPositions));
my $position_inputs = $input_positions->getline_hr_all($inPositions);

my @nyuID = map {$_->{'col0'}} @{$position_inputs};

open my $T_plot, '>', "Tc$DataRelease.csv" or die "cannot open Tc$DataRelease.csv $!"; # Tp table
print $T_plot "ID,Fit_Type,Tp,Tm,Tc\n";
#open my $displ, '>', "displ$DataRelease.cl" or die "cannot open displ.cl $!"; #Galaxy image check

foreach my $posCount (0 .. scalar @nyuID - 1) {
foreach my $galaxy_fits (@galaxy_fits) { #iterate over all fit types
if ((-e "mp${nyuID[$posCount]}$DataRelease.model_$galaxy_fits.fits") && (-e "p${nyuID[$posCount]}$DataRelease.model_$galaxy_fits.fits")) { #Successful modelling?
print "p${nyuID[$posCount]}$DataRelease.fits\n";

my $Good_values = rfits("background.p${nyuID[$posCount]}$DataRelease.fits");
my $average = avg($Good_values);
print $average,"\n";

#SCIENCE IMAGES
my $Gimage = rfits("p${nyuID[$posCount]}$DataRelease.model_$galaxy_fits.fits[1]"); #normal
my $Mimage = rfits("p${nyuID[$posCount]}$DataRelease.model_$galaxy_fits.fits[2]");
my $Mask_1a = rfits("FMASK.p${nyuID[$posCount]}$DataRelease.fits");#GALFIT MASK
my $Mask_1b = rfits("FMASK_b.p${nyuID[$posCount]}$DataRelease.fits"); #normal image mask
my $TMask = rfits("tmask_1a.p${nyuID[$posCount]}$DataRelease.fits"); #normal image mask

#residual images
my $residual = $Gimage - $Mimage * $Mask_1b;
#$residual->where($residual <= -1 ) .= 0;
$residual -> wfits("residual.p${nyuID[$posCount]}$DataRelease"."_$galaxy_fits.fits"); #residual image

#full mask
my $full_mask = $Mask_1b * $TMask;
$full_mask -> wfits("fullmask.p${nyuID[$posCount]}$DataRelease.fits"); #normal

#GALFIT MODEL IMAGE

#model images
my $Gimage_1 = rfits("mp${nyuID[$posCount]}$DataRelease.model_$galaxy_fits.fits[1]"); #normal
my $Mimage_1 = rfits("mp${nyuID[$posCount]}$DataRelease.model_$galaxy_fits.fits[2]");

#residual images
my $residual_M = $Gimage_1 - $Mimage_1 * $Mask_1b;
#$residual_M->where($residual <= -1 ) .= 0;
$residual_M -> wfits("residual.mp${nyuID[$posCount]}$DataRelease"."_$galaxy_fits.fits"); #residual image

#-------------------------
#T-Van Dokkum with GALFIT
#-------------------------
#Science frame calculations with random good sky values 
my $Tp = avg(abs((($Gimage/($Mimage)) - 1)->where($full_mask)));
print "The tidal parameter using GALFIT from van Dokkum et al. 2005 Tp  = ", $Tp, "\n"; 

#Tal's model parameter
my $Tm = avg(abs((($Gimage_1/($Mimage_1)) - 1)->where($full_mask)));
print "The tidal parameter using GALFIT from van Dokkum et al. 2005 Tm  = ", $Tm, "\n"; 

#Critical tidal parameter
my $Tc = (($Tp)**2 -($Tm)**2 );
if ($Tc < 0)
{
	$Tc = 0; #assumes that Tc = 0 is preferably to undefined.
}
$Tc = (sprintf("%.6f",(($Tc)**0.5)));
print "The critical tidal parameter for ${nyuID[$posCount]}$DataRelease is $Tc\n";

print $T_plot "${nyuID[$posCount]},$galaxy_fits,$Tp$DataRelease,$Tm$DataRelease,$Tc$DataRelease\n";

##Tidal image of galaxy
my $T_image = (($Gimage - $Mimage)/($Mimage) * $full_mask);
#$T_image->where($full_mask <= -1 ) .= 0;
$T_image -> wfits("Timage.p${nyuID[$posCount]}$DataRelease"."_$galaxy_fits.fits"); #normal

##Tidal image of galaxy
my $T_image_1 = (($Gimage_1 - $Mimage_1)/($Mimage_1) * $full_mask);
#$T_image->where($full_mask <= -1 ) .= 0;
$T_image_1 -> wfits("Timage.mp${nyuID[$posCount]}$DataRelease"."_$galaxy_fits.fits"); #normal
			}
		}
	}
}
