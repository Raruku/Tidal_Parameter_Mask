#! /usr/bin/perl
use strict;
use warnings;
use PDL;
use PDL::Image2D;
use Text::CSV;
 
 #Creates tidal images for all galaxy images/models.

my @galaxy_fits = qw/a aa/; #model fits we are checking
my @DataRelease = qw/DR7 S82/;
open my $NOISE, '>', "NOISE.cl" or die "cannot open NOISE.cl $!"; # Poisson noise addition

foreach my $DataRelease (@DataRelease) {
open my $inPositions, '<', "result_$DataRelease.csv" or die "cannot open result_$DataRelease.csv: $!";
my $input_positions = Text::CSV->new({'binary'=>1});
$input_positions->column_names($input_positions->getline($inPositions));
my $position_inputs = $input_positions->getline_hr_all($inPositions);

my @nyuID = map {$_->{'col0'}} @{$position_inputs};
foreach my $galaxy_fits (@galaxy_fits) { #iterate over all fit types

foreach my $posCount (0 .. scalar @nyuID - 1) {
if (-e "p${nyuID[$posCount]}_$DataRelease.model_$galaxy_fits.fits") { #Does the output image actually exist?
print "p${nyuID[$posCount]}_$DataRelease.model_$galaxy_fits.fits\n";

my $Good_values = rfits("background.p${nyuID[$posCount]}_$DataRelease.fits");
my $average = avg($Good_values);
print $average,"\n";

#SCIENCE IMAGES
my $Gimage = rfits("p${nyuID[$posCount]}_$DataRelease.model_$galaxy_fits.fits[1]"); #normal
my $Mimage = rfits("p${nyuID[$posCount]}_$DataRelease.model_$galaxy_fits.fits[2]");
my $Mask_1a = rfits("FMASK.p${nyuID[$posCount]}_$DataRelease.fits");#GALFIT MASK
my $Mask_1b = rfits("FMASK_b.p${nyuID[$posCount]}_$DataRelease.fits"); #normal image mask
my $TMask = rfits("tmask_1a.p${nyuID[$posCount]}_$DataRelease.fits"); #normal image mask

#residual images
my $residual = $Gimage - $Mimage * $Mask_1b;
#$residual->where($residual <= -1 ) .= 0;
$residual -> wfits("residual.p${nyuID[$posCount]}_$DataRelease"."_$galaxy_fits.fits"); #residual image

#full mask
my $full_mask = $Mask_1b * $TMask;
$full_mask -> wfits("fullmask.p${nyuID[$posCount]}_$DataRelease.fits"); #normal


#model images
my $MODEL_IMAGE;
$MODEL_IMAGE = $Mimage - $average;
$MODEL_IMAGE->wfits("model.p${nyuID[$posCount]}_$DataRelease"."_$galaxy_fits.fits");
print $NOISE "mknoise model.p${nyuID[$posCount]}_$DataRelease"."_$galaxy_fits.fits\n";
print $NOISE "imarith model.p${nyuID[$posCount]}_$DataRelease"."_$galaxy_fits.fits + background.p${nyuID[$posCount]}_$DataRelease.fits bmodel.p${nyuID[$posCount]}_$DataRelease"."_$galaxy_fits.fits\n";

#-------------------------
#T-Van Dokkum with GALFIT
#-------------------------
#	Science frame calculations with random good sky values 
my $Tp = avg(abs((($Gimage/($Mimage)) - 1)->where($full_mask)));
print "The tidal parameter using GALFIT from van Dokkum et al. 2005 Tp  = ", $Tp, "\n"; 

#Tidal image of galaxy
my $T_image = (($Gimage - $Mimage)/($Mimage) * $full_mask);
#$T_image->where($full_mask <= -1 ) .= 0;
$T_image -> wfits("Timage.p${nyuID[$posCount]}_$DataRelease"."_$galaxy_fits.fits"); #normal
print "${nyuID[$posCount]}_$DataRelease,$galaxy_fits,$Tp\n";
#print $T_plot "${nyuID[$posCount]}_$DataRelease,$Tp\n";
}
}
}
}
print"\n";
print "Run NOISE.cl in IRAF\n";
print "Run GALFIT_MBATCH.sh in a terminal\n";


