#! /usr/bin/perl
use strict;
use warnings;
use Text::CSV;
use PDL;

# This script generates the GALFIT input files and scripts to mass execute them for the postamp and model images.
# Note that the model run will require additional inputs later in the the script if you want it to execute properly.

my @galaxy_fits = qw/a aa/; #model fits we are checking (Free sersic, and double free sersic w/ fixed position)
my @DataRelease = qw/DR7 S82/;

foreach my $DataRelease (@DataRelease) {
	open my $inGalPositions, '<', "result_$DataRelease.csv" or die "cannot open result_$DataRelease.csv: $!";
	my $positions = Text::CSV->new({'binary'=>1});
	$positions->column_names($positions->getline($inGalPositions));
	my $position = $positions->getline_hr_all($inGalPositions);
	my @nyuID = map {$_->{'col0'}} @{$position};
	my @ZPR = map {$_->{'Zero_point_r'}} @{$position};
	if ($DataRelease == "S82") {
		my @bkg = map {$_->{'global_background_r'}+1000} @{$position};
	} else {
		my @bkg = map {$_->{'global_background_r'}} @{$position};
	}

open my $galfit_batch, '>', "GALFIT_BATCH_$DataRelease.sh" or die "cannot open GALFIT_BATCH_$DataRelease.sh: $!";
open my $mgalfit_batch, '>', "GALFIT_MBATCH_$DataRelease.sh" or die "cannot open GALFIT_BATCH_$DataRelease.sh: $!";
#system("/usr/bin/perl $dir/BACKGROUND_REPLACER_$DataRelease.pl");
foreach my $galCount (0 .. scalar @nyuID - 1) {
	if (-e "background.p${nyuID[$galCount]}_$DataRelease.fits") {
		my $Good_values = rfits("background.p$nyuID[$galCount]_$DataRelease.fits");
		my $average = sprintf("%.3f",(avg($Good_values)));
		print $average,"\n";
		print "background.p${nyuID[$galCount]}_$DataRelease.fits\n";	
		open my $inPositions, '<', "p$nyuID[$galCount]_$DataRelease.galfit_input.csv" or die "cannot open p$nyuID[$galCount]_$DataRelease.galfit_input.csv: $!";
		my $input_positions = Text::CSV->new({'binary'=>1});
		$input_positions->column_names($input_positions->getline($inPositions));
		my $position_inputs = $input_positions->getline_hr_all($inPositions);

		foreach my $galaxy_fits (@galaxy_fits) { #iterate over all fit types
			print $galfit_batch "galfit p$nyuID[$galCount]_$DataRelease.galfit_$galaxy_fits\n";
			print $galfit_batch "mv galfit.01 p$nyuID[$galCount]_$DataRelease.galfit_$galaxy_fits.out\n";
			print $mgalfit_batch "galfit mp$nyuID[$galCount]_$DataRelease.galfit_$galaxy_fits\n";
			print $mgalfit_batch "mv galfit.01 mp$nyuID[$galCount]_$DataRelease.galfit_$galaxy_fits.out\n";
			}

		my @N = map {$_->{'NUMBER'}} @{$position_inputs}; #mag
		my @mag = map {$_->{'MAG'}} @{$position_inputs}; #mag
		my @Re = map {$_->{'Re'}} @{$position_inputs}; #RE
		my @px = map {$_->{'X'}} @{$position_inputs}; 
		my @py = map {$_->{'Y'}} @{$position_inputs};
		my @X = map {$_->{'sizex'}} @{$position_inputs};
		my @Y = map {$_->{'sizey'}} @{$position_inputs};
		my @THETA_IMAGE = map {$_->{'THETA'}} @{$position_inputs};
		my @ba = map {$_->{'ba'}} @{$position_inputs};
		my @fit = map {$_->{'fit'}} @{$position_inputs};
		my @type = map {$_->{'type'}} @{$position_inputs};

		foreach my $posCount (0 .. scalar @N - 1) {

			open my $galfita, '>', "p$nyuID[$galCount]_$DataRelease.galfit_a" or die "cannot open p$nyuID[$galCount]_$DataRelease.galfit_a $!"; #GALFIT Normal Galaxy (n=anything)
			open my $mgalfita, '>', "mp$nyuID[$galCount]_$DataRelease.galfit_a" or die "cannot open mp$nyuID[$galCount]_$DataRelease.galfit_a $!"; #GALFIT Normal Galaxy model (n=anything)

			open my $galfitaa, '>', "p$nyuID[$galCount]_$DataRelease.galfit_aa" or die "cannot open p$nyuID[$galCount]_$DataRelease.galfit_aa $!"; #GALFIT 2 component Normal Galaxy (n=1 disk, n=4 bulge)
			open my $mgalfitaa, '>', "mp$nyuID[$galCount]_$DataRelease.galfit_aa" or die "cannot open mp$nyuID[$galCount]_$DataRelease.galfit_aa $!"; #GALFIT 2 component Normal Galaxy model (n=1 disk, n=4 bulge)

print $galfita  <<___end___;
================================================================================
# IMAGE and GALFIT CONTROL PARAMETERS
A) MASKED.p$nyuID[$galCount]_$DataRelease.fits      # Input data image (FITS file)
B) p$nyuID[$galCount]_$DataRelease.model_a.fits      # Output data image block
C) #                   # Sigma image name (made from data if blank or "none") 
D) scpsf.$nyuID[$galCount]_$DataRelease.fits           # Input PSF image and (optional) diffusion kernel
E) 1                  # PSF fine sampling factor relative to data 
F) FMASK.p$nyuID[$galCount]_$DataRelease.fits      # Bad pixel mask (FITS image or ASCII coord list)
G) none                # File with parameter constraints (ASCII file) 
H) 1 $X[$posCount]  1 $Y[$posCount]       # Image region to fit (xmin xmax ymin ymax)
I) 100 100           # Size of the convolution box (x y)
J) $ZPR[$galCount]          # Magnitude photometric zeropoint 
K) 0.3961 0.3961       # Plate scale (dx dy)   [arcsec per pixel]
O) regular             # Display type (regular, curses, both)
P) 0                   # Choose: 0=optimize, 1=model, 2=imgblock, 3=subcomps

# INITIAL FITTING PARAMETERS
#
#   For component type, the allowed functions are: 
#       sersic, expdisk, edgedisk, devauc, king, nuker, psf, 
#       gaussian, moffat, ferrer, and sky. 
#  
#   Hidden parameters will only appear when they're specified:
#       Bn (n=integer, Bending Modes).
#       C0 (diskyness/boxyness), 
#       Fn (n=integer, Azimuthal Fourier Modes).
#       R0-R10 (coordinate rotation, for creating spiral structures).
#       To, Ti, T0-T10 (truncation function).
# 
# ------------------------------------------------------------------------------
#   par)    par value(s)    fit toggle(s)    # parameter description 
# ------------------------------------------------------------------------------
___end___


my $hack = "bmodel.p$nyuID[$galCount]_$DataRelease"+"_a.fits"; #this is what happens when someone comes up with bad variable name ideas.

print $mgalfita  <<___end___;
================================================================================
# IMAGE and GALFIT CONTROL PARAMETERS
A) $hack      # Input data image (FITS file)
B) mp$nyuID[$galCount]_$DataRelease.model_a.fits      # Output data image block
C) #                   # Sigma image name (made from data if blank or "none") 
D) scpsf.$nyuID[$galCount]_$DataRelease.fits           # Input PSF image and (optional) diffusion kernel
E) 1                  # PSF fine sampling factor relative to data 
F) FMASK.p$nyuID[$galCount]_$DataRelease.fits      # Bad pixel mask (FITS image or ASCII coord list)
G) none                # File with parameter constraints (ASCII file) 
H) 1 $X[$posCount]  1 $Y[$posCount]       # Image region to fit (xmin xmax ymin ymax)
I) 100 100           # Size of the convolution box (x y)
J) $ZPR[$galCount]          # Magnitude photometric zeropoint 
K) 0.3961 0.3961       # Plate scale (dx dy)   [arcsec per pixel]
O) regular             # Display type (regular, curses, both)
P) 0                   # Choose: 0=optimize, 1=model, 2=imgblock, 3=subcomps

# INITIAL FITTING PARAMETERS
#
#   For component type, the allowed functions are: 
#       sersic, expdisk, edgedisk, devauc, king, nuker, psf, 
#       gaussian, moffat, ferrer, and sky. 
#  
#   Hidden parameters will only appear when they're specified:
#       Bn (n=integer, Bending Modes).
#       C0 (diskyness/boxyness), 
#       Fn (n=integer, Azimuthal Fourier Modes).
#       R0-R10 (coordinate rotation, for creating spiral structures).
#       To, Ti, T0-T10 (truncation function).
# 
# ------------------------------------------------------------------------------
#   par)    par value(s)    fit toggle(s)    # parameter description 
# ------------------------------------------------------------------------------
___end___


print $galfitaa  <<___end___;
================================================================================
# IMAGE and GALFIT CONTROL PARAMETERS
A) MASKED.p$nyuID[$galCount]_$DataRelease.fits      # Input data image (FITS file)
B) p$nyuID[$galCount]_$DataRelease.model_aa.fits      # Output data image block
C) #                   # Sigma image name (made from data if blank or "none") 
D) scpsf.$nyuID[$galCount]_$DataRelease.fits           # Input PSF image and (optional) diffusion kernel
E) 1                  # PSF fine sampling factor relative to data 
F) FMASK.p$nyuID[$galCount]_$DataRelease.fits      # Bad pixel mask (FITS image or ASCII coord list)
G) none                # File with parameter constraints (ASCII file) 
H) 1 $X[$posCount]  1 $Y[$posCount]       # Image region to fit (xmin xmax ymin ymax)
I) 100 100           # Size of the convolution box (x y)
J) $ZPR[$galCount]          # Magnitude photometric zeropoint 
K) 0.3961 0.3961       # Plate scale (dx dy)   [arcsec per pixel]
O) regular             # Display type (regular, curses, both)
P) 0                   # Choose: 0=optimize, 1=model, 2=imgblock, 3=subcomps

# INITIAL FITTING PARAMETERS
#
#   For component type, the allowed functions are: 
#       sersic, expdisk, edgedisk, devauc, king, nuker, psf, 
#       gaussian, moffat, ferrer, and sky. 
#  
#   Hidden parameters will only appear when they're specified:
#       Bn (n=integer, Bending Modes).
#       C0 (diskyness/boxyness), 
#       Fn (n=integer, Azimuthal Fourier Modes).
#       R0-R10 (coordinate rotation, for creating spiral structures).
#       To, Ti, T0-T10 (truncation function).
# 
# ------------------------------------------------------------------------------
#   par)    par value(s)    fit toggle(s)    # parameter description 
# ------------------------------------------------------------------------------
___end___

$hack = "bmodel.p$nyuID[$galCount]_$DataRelease"+"_aa.fits"; #again this is what happens when someone comes up with bad variable name ideas.

print $mgalfitaa  <<___end___;
================================================================================
# IMAGE and GALFIT CONTROL PARAMETERS
A) $hack      # Input data image (FITS file)
B) mp$nyuID[$galCount]_$DataRelease.model_aa.fits      # Output data image block
C) #                   # Sigma image name (made from data if blank or "none") 
D) scpsf.$nyuID[$galCount]_$DataRelease.fits           # Input PSF image and (optional) diffusion kernel
E) 1                  # PSF fine sampling factor relative to data 
F) FMASK.p$nyuID[$galCount]_$DataRelease.fits      # Bad pixel mask (FITS image or ASCII coord list)
G) none                # File with parameter constraints (ASCII file) 
H) 1 $X[$posCount]  1 $Y[$posCount]       # Image region to fit (xmin xmax ymin ymax)
I) 100 100           # Size of the convolution box (x y)
J) $ZPR[$galCount]          # Magnitude photometric zeropoint 
K) 0.3961 0.3961       # Plate scale (dx dy)   [arcsec per pixel]
O) regular             # Display type (regular, curses, both)
P) 0                   # Choose: 0=optimize, 1=model, 2=imgblock, 3=subcomps

# INITIAL FITTING PARAMETERS
#
#   For component type, the allowed functions are: 
#       sersic, expdisk, edgedisk, devauc, king, nuker, psf, 
#       gaussian, moffat, ferrer, and sky. 
#  
#   Hidden parameters will only appear when they're specified:
#       Bn (n=integer, Bending Modes).
#       C0 (diskyness/boxyness), 
#       Fn (n=integer, Azimuthal Fourier Modes).
#       R0-R10 (coordinate rotation, for creating spiral structures).
#       To, Ti, T0-T10 (truncation function).
# 
# ------------------------------------------------------------------------------
#   par)    par value(s)    fit toggle(s)    # parameter description 
# ------------------------------------------------------------------------------
___end___


foreach my $posCount (0 .. scalar @N - 1) {
print $galfita  <<___end___;
# Component number: $N[$posCount]
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 1 1  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 2.5000      1          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)

___end___

print $mgalfita  <<___end___;
# Component number: $N[$posCount]
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 1 1  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 2.5000      1          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)

___end___


print $galfitaa  <<___end___;
# Component number: $N[$posCount], exp fit
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 0 0  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 1.0000      1          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)
___end___

print $galfitaa  <<___end___;
# Component number: $N[$posCount], de Vaucouleurs fit
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 0 0  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 4.0000      1          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)
___end___

print $mgalfitaa  <<___end___;
# Component number: $N[$posCount], exp fit
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 0 0  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 1.0000      1          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)
___end___

print $mgalfitaa  <<___end___;
# Component number: $N[$posCount], de Vaucouleurs fit
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 0 0  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 4.0000      1          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)
___end___

}
print $galfita <<___end___;
# Component number: Sky
 0) sky                    #  Component type
 1) $average        0          #  Sky background at center of fitting region [ADUs]
 2) 0		    	0       #  dsky/dx (sky gradient in x)     [ADUs/pix]
 3) 0		    	0       #  dsky/dy (sky gradient in y)     [ADUs/pix]
 Z) 0                      #  Skip this model in output image?  (yes=1, no=0)
================================================================================

___end___

print $mgalfita <<___end___;
# Component number: Sky
 0) sky                    #  Component type
 1) $average        0          #  Sky background at center of fitting region [ADUs]
 2) 0		    	0       #  dsky/dx (sky gradient in x)     [ADUs/pix]
 3) 0		    	0       #  dsky/dy (sky gradient in y)     [ADUs/pix]
 Z) 0                      #  Skip this model in output image?  (yes=1, no=0)
================================================================================

___end___


print $galfitaa <<___end___;
# Component number: Sky
 0) sky                    #  Component type
 1) $average        0          #  Sky background at center of fitting region [ADUs]
 2) 0		    	0       #  dsky/dx (sky gradient in x)     [ADUs/pix]
 3) 0		    	0       #  dsky/dy (sky gradient in y)     [ADUs/pix]
 Z) 0                      #  Skip this model in output image?  (yes=1, no=0)
================================================================================
___end___

print $mgalfitaa <<___end___;
# Component number: Sky
 0) sky                    #  Component type
 1) $average        0          #  Sky background at center of fitting region [ADUs]
 2) 0		    	0       #  dsky/dx (sky gradient in x)     [ADUs/pix]
 3) 0		    	0       #  dsky/dy (sky gradient in y)     [ADUs/pix]
 Z) 0                      #  Skip this model in output image?  (yes=1, no=0)
================================================================================
___end___
		}
	}
#system ("rm $dir/galfit.* ");
#print "Finished p$nyuID[$galCount].fits\n";	
	}
}

print "Done";
