#! /usr/bin/perl
use strict;
use warnings;
use Text::CSV;
use Cwd qw(cwd);
#use String::Scanf;
use Statistics::OLS;
use PDL;
use PDL::Constants qw(PI);
use PDL::Fit::Polynomial qw(fitpoly1d);

# This script is used to take SDSS x and y outputs and use them as inputs.
# for cutting out postage stamps. Stripe 82 sizes are applied to DR7 images.

open my $inPositions_S82, '<', "result_S82.csv" or die "cannot open result_S82.csv: $!"; #Change the input to your input file with the galaxy coordinates
open my $DR7, '>', "S82_DR7_Sizes.csv" or die "cannot open S82_DR7_Sizes.csv: $!"; #Required for SDSS DR7 Cutouts
print $DR7 "nyuID_S82,X,Y\n";

my $input_positions_S82 = Text::CSV->new({'binary'=>1});
$input_positions_S82->column_names($input_positions_S82->getline($inPositions_S82));
my $position_inputs_S82 = $input_positions_S82->getline_hr_all($inPositions_S82);

my @nyuID_S82 = map {$_->{'col0'}} @{$position_inputs_S82};
my @px_S82 = map {$_->{'imgx'}} @{$position_inputs_S82};
my @py_S82 = map {$_->{'imgy'}} @{$position_inputs_S82};
my @run_S82 = map {$_->{'run'}} @{$position_inputs_S82};
my @rerun_S82 = map {$_->{'rerun'}} @{$position_inputs_S82};
my @cam_S82 = map {$_->{'camcol'}} @{$position_inputs_S82};
my @field_S82 = map {$_->{'field'}} @{$position_inputs_S82};

open my $inPositions, '<', "result_DR7.csv" or die "cannot open result_DR7.csv: $!"; 
my $input_positions = Text::CSV->new({'binary'=>1});
$input_positions->column_names($input_positions->getline($inPositions));
my $position_inputs = $input_positions->getline_hr_all($inPositions);

my @nyuID_DR7 = map {$_->{'col0'}} @{$position_inputs};
my @px_DR7 = map {$_->{'imgx'}} @{$position_inputs};
my @py_DR7 = map {$_->{'imgy'}} @{$position_inputs};
my @run_DR7 = map {$_->{'run'}} @{$position_inputs};
my @rerun_DR7 = map {$_->{'rerun'}} @{$position_inputs};
my @cam_DR7 = map {$_->{'camcol'}} @{$position_inputs};
my @field_DR7 = map {$_->{'field'}} @{$position_inputs};

open my $coutouts, '>', "Galaxy_cutouts.cl" or die "cannot open Galaxy_cutouts.cl: $!";

my $run0_DR7;
my $field0_DR7;
my $run0_S82;
my $field0_S82;
my $runN;
my $fieldN;
my $camN;

foreach my $posCount (0 .. scalar @nyuID_S82 - 1) {
	#Getting DR7 image filename
		foreach my $posDR7 (0 .. scalar @nyuID_DR7 - 1) {
			if ($nyuID_S82[$posCount] == $nyuID_DR7[$posDR7]) {
					$runN = $run_DR7[$posDR7];
					$fieldN = $field_DR7[$posDR7];
					$camN = $cam_DR7[$posDR7];
				}
			}

	#run line padding -- 6 digit field but the run number is 1 to 4 digits. (2-5 zeros of padding)
	if ($runN > 999) {
		$run0_DR7 = "00";
	} elsif ($runN > 999) {
		$run0_DR7 = "000";
	} elsif ($runN > 9) {
		$run0_DR7 = "0000";
	} else {
		$run0_DR7 = "00000";
	}

	#field line padding -- 4 digit field but the field number is 1 to 4 digits. (0-3 zeros of padding)
	if ($fieldN > 999) {
		$field0_DR7 = "";
	} elsif ($fieldN > 99) {
		$field0_DR7 = "0";
	} elsif ($fieldN > 9) {
		$field0_DR7 = "00";
	} else {
		$field0_DR7 = "000";
	}

	#Object name string
	my $fpC_DR7 = 'fpC-'.$run0_DR7.$runN.'-r'.$camN.'-'.$field0_DR7.$fieldN.'.fit';

	#Getting S82 image filename
	#spacing and sizing is hard. This will fail in interesting ways if the naming changes.
	if ($run_S82[$posCount] == 106) {
		$run0_S82 = 100006;
	} else { #run == 206
		$run0_S82 = 200006;
	}

	if (($field_S82[$posCount] < 1000) && ($field_S82[$posCount] >= 100)) { #3 digit field, so 1x 0 for padding
		$field0_S82 = '0';
	} elsif ($field_S82[$posCount] >= 10) { #2 digit field, so 2x padding
		$field0_S82 = '00';
	} elsif ($field_S82[$posCount] < 10) { #1 digit field needs 3x 0 padding
		$field0_S82 = '000';
	} else {
		$field0_S82 = ''; #4 digit fields need no 0s for padding. Also default-ish.
	}
	#example:
	#run 3704, rerun 301, camcol 3, field 91
	#http://data.sdss3.org/sas/dr9/boss/photoObj/frames/301/3704/3/frame-g-003704-3-0091.fits.bz2

	#Object name string
	my $fpC_S82 = 'fpC-'.$run0_S82.'-r'.$cam_S82[$posCount].'-'.$field0_S82.$_->{'field'}.'.fit';

	open my $instars, '<', "$nyuID_S82[$posCount].aper.csv" or die "cannot open $nyuID_S82[$posCount].aper.csv $!";
	
	my $input_stars = Text::CSV->new({'binary'=>1});
	$input_stars->column_names($input_stars->getline($instars));
	my $galaxy_inputs = $input_stars->getline_hr_all($instars);
	
	#We need to define a set of parameters to make the correct postage stamps
	#These next eight parameters should be usin only 
	#if you dont the position of your galaxies, use the follow eight lines to fine your galaxies
	#in the sextractor catalog with ten pixels in both the X and Y position.
	
	
	#If you do know the exact locations of your galaxies in the SEXtractor catalog
	#then use the 
	
	my @Xp_image; # this will find the galaxies using the x-pixel coordinates of the parent
	my @Yp_image; # this will find the galaxies using the y coordinates of the parent
	my @Xc_image; # this will find the galaxies using the x-pixel coordinates of the companion
	my @Yc_image; # this will find the galaxies using the y coordinates of the companion
	
	#parent cutout
	my $Xp_cutout;	
	my $Yp_cutout;
	#imcopy cutout
	my $Xg_p_cutmin;
	my $Xg_p_cutmax;
	my $Yg_p_cutmin;
	my $Yg_p_cutmax;
	#Distance parameters
	my $Distance_X; #Xp - Xc
	my $Distance_Y;	#Yp - Yc
	my $total_X; #Xp + Xc
	my $total_Y; #Yp + Yc
	
	#total cutout size
	my $Xb;	
	my $Yb;
	my $center;
	my @a_p; # semi-major axis parent galaxies.
	my @a_c; # semi-major axis companion galaxies.
	my @E_p; # ellipticity of parent galaxies.
	my @E_c; # ellipticity of companion galaxies.
	my @theta_p;
	my @theta_c;
	my @Kron_p;
	my @Kron_c;
	
	#This parameters will deal with the cutout size of the box about the center
	my $Xcenter_cutmin;
	my $Xcenter_cutmax;
	my $Ycenter_cutmin;
	my $Ycenter_cutmax;
	my $X_checker;
	my $Y_checker;
	
	
	#First we need to locate the individual galaxies in the SEXtractor
	#output.
	
	
		@Xp_image = map{$_->{'X_IMAGE'}} grep {$_->{'X_IMAGE'} > ($px_S82[$posCount] - 5) && $_->{'X_IMAGE'} < ($px_S82[$posCount] + 5) && $_->{'Y_IMAGE'} > ($py_S82[$posCount] - 5) && $_->{'Y_IMAGE'} < ($py_S82[$posCount] + 5) } @{$galaxy_inputs};
		@Yp_image = map{$_->{'Y_IMAGE'}} grep {$_->{'X_IMAGE'} > ($px_S82[$posCount] - 5) && $_->{'X_IMAGE'} < ($px_S82[$posCount] + 5) && $_->{'Y_IMAGE'} > ($py_S82[$posCount] - 5) && $_->{'Y_IMAGE'} < ($py_S82[$posCount] + 5) } @{$galaxy_inputs};
		@a_p = map{$_->{'A_IMAGE'}} grep {$_->{'X_IMAGE'} > ($px_S82[$posCount] - 5) && $_->{'X_IMAGE'} < ($px_S82[$posCount] + 5) && $_->{'Y_IMAGE'} > ($py_S82[$posCount] - 5) && $_->{'Y_IMAGE'} < ($py_S82[$posCount] + 5) } @{$galaxy_inputs};
		@Kron_p = map{$_->{'KRON_RADIUS'}} grep {$_->{'X_IMAGE'} > ($px_S82[$posCount] - 5) && $_->{'X_IMAGE'} < ($px_S82[$posCount] + 5) && $_->{'Y_IMAGE'} > ($py_S82[$posCount] - 5) && $_->{'Y_IMAGE'} < ($py_S82[$posCount] + 5) } @{$galaxy_inputs};
		@E_p = map{$_->{'ELLIPTICITY'}} grep {$_->{'X_IMAGE'} > ($px_S82[$posCount] - 5) && $_->{'X_IMAGE'} < ($px_S82[$posCount] + 5) && $_->{'Y_IMAGE'} > ($py_S82[$posCount] - 5) && $_->{'Y_IMAGE'} < ($py_S82[$posCount] + 5) } @{$galaxy_inputs};
		@theta_p = map{$_->{'THETA_IMAGE'}} grep {$_->{'X_IMAGE'} > ($px_S82[$posCount] - 5) && $_->{'X_IMAGE'} < ($px_S82[$posCount] + 5) && $_->{'Y_IMAGE'} > ($py_S82[$posCount] - 5) && $_->{'Y_IMAGE'} < ($py_S82[$posCount] + 5) } @{$galaxy_inputs};
		
		#Correct GALAPAGOS equation would be 2.5x, not 5x
		$Xp_cutout = 5 * $a_p[0] * $Kron_p[0] * ( (abs(sin((PI/180) * $theta_p[0]))) + (1 - $E_p[0]) * (abs(cos((PI/180) * $theta_p[0]))) );
		$Yp_cutout = 5 * $a_p[0] * $Kron_p[0] * ( (abs(cos((PI/180) * $theta_p[0]))) + (1 - $E_p[0]) * (abs(sin((PI/180) * $theta_p[0]))) );

		my $Xp = sprintf("%.0f", $Xp_image[0]);
		my $Yp = sprintf("%.0f", $Yp_image[0]);
		
		#new algorithm time
		my $Xp_cut = sprintf("%.0f", $Xp_cutout/2);
		my $Yp_cut = sprintf("%.0f", $Yp_cutout/2);
		
		print "$Xp_cut $Yp_cut\n";
		
		print "The parent galaxy is located at $Xp,$Yp\n";
	
		if ($Xp_cut > $Yp_cut)
		{
			$Yp_cut = $Xp_cut;
		$Xg_p_cutmin = sprintf("%.0f",$Xp - $Xp_cut);
		$Xg_p_cutmax = sprintf("%.0f",$Xp + $Xp_cut);
		$Yg_p_cutmin = sprintf("%.0f",$Yp - $Yp_cut);
		$Yg_p_cutmax = sprintf("%.0f",$Yp + $Yp_cut);
		print "Cutout Size $Xp_cut\n";
			if ( $Xg_p_cutmin >= 0 && $Xg_p_cutmax <= 2048 && $Yg_p_cutmin >= 0 && $Yg_p_cutmax <= 1489)
			{	
			print $coutouts "imcopy $nyuID_S82[$posCount]_S82.fits[$Xg_p_cutmin:$Xg_p_cutmax,$Yg_p_cutmin:$Yg_p_cutmax] p$nyuID_S82[$posCount]_S82.fits\n";
			print "imcopy $nyuID_S82[$posCount]_S82.fits[$Xg_p_cutmin:$Xg_p_cutmax,$Yg_p_cutmin:$Yg_p_cutmax] p$nyuID_S82[$posCount]_S82.fits\n";
			print $DR7 "$nyuID_S82[$posCount],$Xp_cut,$Yp_cut\n";
			}
		}
		
		else
		{
			$Xp_cut = $Yp_cut;
		$Xg_p_cutmin = sprintf("%.0f",$Xp - $Xp_cut);
		$Xg_p_cutmax = sprintf("%.0f",$Xp + $Xp_cut);
		$Yg_p_cutmin = sprintf("%.0f",$Yp - $Yp_cut);
		$Yg_p_cutmax = sprintf("%.0f",$Yp + $Yp_cut);
		print "Cutout Size $Xp_cut\n";
			if ( $Xg_p_cutmin >= 0 && $Xg_p_cutmax <= 2048 && $Yg_p_cutmin >= 0 && $Yg_p_cutmax <= 1489)
			{	
			print $coutouts "imcopy $nyuID_S82[$posCount]_S82.fits[$Xg_p_cutmin:$Xg_p_cutmax,$Yg_p_cutmin:$Yg_p_cutmax] p$nyuID_S82[$posCount]_S82.fits\n";
			print "imcopy $nyuID_S82[$posCount]_S82.fits[$Xg_p_cutmin:$Xg_p_cutmax,$Yg_p_cutmin:$Yg_p_cutmax] p$nyuID_S82[$posCount]_S82.fits\n";
			print $DR7 "$nyuID_S82[$posCount],$Xp_cut,$Yp_cut\n";
			}
		}
			
#	Sorting the min and max values to make the correct box size that will be used for center.
	my @Xvalues = sort{$a <=> $b} ($Xg_p_cutmin,$Xg_p_cutmax);
	my @Yvalues = sort{$a <=> $b} ($Yg_p_cutmin,$Yg_p_cutmax);


#	the largest box size for both galaxies using the GALAPGOS cutout 
	my $Length_X_image = sprintf("%.0f",(abs($Xvalues[0] - $Xvalues[1])));
	my $Length_Y_image = sprintf("%.0f",(abs($Yvalues[0] - $Yvalues[1])));

	my $Box_Xmin;
	my $Box_Xmax;
	my $Box_Ymin;
	my $Box_Ymax;
	
	print "$posCount\n";
	
}
print "Finished!\n";
