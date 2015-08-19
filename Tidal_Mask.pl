# Tidal_Parameter_Mask
Creates Fits files that uses SDSS Petrosian Radius to mask the outer 10xR50 and inter R50 areas.
use strict;
use warnings;
use PGPLOT;
use PDL;
use PDL::Graphics::PGPLOT;
use PDL::Graphics2D;
use PDL::Image2D;
$ENV{'PGPLOT_DIR'} = '/usr/local/pgplot';
$ENV{'PGPLOT_DEV'} = '/xs';
use Text::CSV;
use PDL::Image2D;

my $Fit = "a";

#open my $inPositions, '<', "Tlist_1$Fit.csv" or die "cannot open Tlist_1$Fit.csv: $!";
open my $inPositions, '<', "Tlist_All_1$Fit.csv" or die "cannot open Tlist_All_1$Fit.csv: $!";


#c and d
#open my $inPositions, '<', "Tlist_non_all.csv" or die "cannot open Tlist_non_all.csv: $!";

my $input_positions = Text::CSV->new({'binary'=>1});
$input_positions->column_names($input_positions->getline($inPositions));
my $position_inputs = $input_positions->getline_hr_all($inPositions);

my @nyuID = map {$_->{'ID'}} @{$position_inputs};
my @model = map {$_->{'Model'}} @{$position_inputs};
my @background = map {$_->{'background'}} @{$position_inputs};
my @pixel = map {$_->{'pixel_scale'}} @{$position_inputs};
my @type = map {$_->{'type'}} @{$position_inputs};
my @z_type = map {$_->{'z_type'}} @{$position_inputs};

open my $maker, '>', "Model_Maker_1$Fit.cl";
open my $galfit, '>', "galfit_1$Fit.cl";
open my $mgalfit, '>', "Mgalfit_1$Fit.cl";
open my $T_plot, '>', "T_plot_1$Fit.csv" or die "cannot open T_plot_1$Fit.csv $!";
print $T_plot "ID,Tp,Tp_Area,MTp,MTp_Area,Tp_scaled,MTp_scaled,Total_pixel,Good_pixel,FIT,type,z_type\n";
open my $residual, '>', "imexam_residual_1$Fit.cl";


foreach my $posCount (0 .. scalar @nyuID - 1)
{
my $A =$model[$posCount];


#SCIENCE IMAGES
#my $Gimage = rfits("gCFVnyu19424.model_1$A.fits[1]"); #normal
#my $Mimage = rfits("gCFVnyu19424.model_1$A.fits[2]");
#
#my $Mask_1a = rfits("unmask.gCFVnyu19424_1a.fits");
#my $Mask_1b = rfits("unmask.gCFVnyu19424_1b.fits"); #normal
#my $R50_1a = rfits("R50.gCFVnyu19424_1a.fits"); #normal
#my $R50_1b = rfits("R50.gCFVnyu19424_1b.fits"); #normal
#my $R50_10_1a = rfits("10R50.gCFVnyu19424_1a.fits"); #normal
#my $R50_10_1b = rfits("10R50.gCFVnyu19424_1b.fits"); #normal

print "$nyuID[$posCount]\n";
#Auto
my $Gimage = rfits("gCFV$nyuID[$posCount].model_1$A.fits[1]"); #normal
my $Mimage = rfits("gCFV$nyuID[$posCount].model_1$A.fits[2]");

print $maker "imarith gCFV$nyuID[$posCount].model_1$A.fits[2] - $background[$posCount] model.gCFV$nyuID[$posCount]_1$A.fits\n";
print $maker "mknoise model.gCFV$nyuID[$posCount]_1$A.fits\n";
print $maker "imarith model.gCFV$nyuID[$posCount]_1$A.fits + background.gCFV$nyuID[$posCount].fits bmodel.gCFV$nyuID[$posCount]_1$A.fits\n";
print $maker "imarith bmodel.gCFV$nyuID[$posCount]_1$A.fits + unmask.gCFV$nyuID[$posCount]_1b.fits bmodel.gCFV$nyuID[$posCount]_1$A.fits\n";

print $galfit "galfit gCFV$nyuID[$posCount].galfit_1$A\n";
print $galfit "mv galfit.01 gCFV$nyuID[$posCount].galfit_1$A.out\n";
print $mgalfit "galfit gCFV$nyuID[$posCount].mgalfit_1$A\n";
print $mgalfit "mv galfit.01 gCFV$nyuID[$posCount].mgalfit_1$A.out\n";

print $residual "displ gCFV$nyuID[$posCount].fits 1\n";
print $residual "displ residual.gCFV$nyuID[$posCount]_1$A.fits 2\n";
print $residual "imexam\n";

my @dim = dims($Gimage);
#print join(',',@dim),"\n";
#join(',',@dim)
my $size_x = $dim[0];
my $size_y = $dim[1];
my $Area = $size_x*$size_y;

my $Mask_1a = rfits("unmask.gCFV$nyuID[$posCount]_1a.fits");
my $Mask_1b = rfits("unmask.gCFV$nyuID[$posCount]_1b.fits"); #normal
my $R50_1a = rfits("R50.gCFV$nyuID[$posCount]_1a.fits"); #normal
my $R50_1b = rfits("R50.gCFV$nyuID[$posCount]_1b.fits"); #normal
my $R50_10_1a = rfits("10R50.gCFV$nyuID[$posCount]_1a.fits"); #normal
my $R50_10_1b = rfits("10R50.gCFV$nyuID[$posCount]_1b.fits"); #normal


my $full_mask = $Mask_1b * $R50_1b * $R50_10_1a;
#$full_mask->where($full_mask <= 1 ) .= 1;
#$full_mask->wfits("fullmask.gCFVnyu19424.fits");
$full_mask->wfits("fullmask.gCFVnyu[$posCount].fits");

my $residual = ($Gimage - $Mimage) * $Mask_1b;
#$residual->where($residual <= 1 ) .= 1;
#$residual -> wfits("residual.gCFVnyu19424_1$A.fits"); #normal
$residual -> wfits("residual.gCFV$nyuID[$posCount]_1$A.fits"); #normal

my $Tresidual = ($Gimage - $Mimage) * $full_mask;
#$residual->where($residual <= -1 ) .= 0;
#$Tresidual -> wfits("Tidal_mask.gCFVnyu19424_1$A.fits"); #normal
$Tresidual -> wfits("Tidal_mask.gCFV$nyuID[$posCount]_1$A.fits"); #normal


my $elem = nelem(($Gimage)->where($Mask_1b));
print "$elem\n";

my $elem_mask = nelem(($Gimage)->where($full_mask));
print "$elem\n";

my $Tp = sprintf("%.5f",(avg(abs((($Gimage/($Mimage)) - 1)->where($Mask_1b)))));
my $Tpa = sprintf("%.7f",($Tp/$elem));
my $Ts = sprintf("%.5f",($Tp * $pixel[$posCount]**2 / 0.282**2));
my $FFlux_percent = ((($Gimage-($Mimage)))->where($Mask_1b));
print "The tidal parameter using GALFIT from van Dokkum et al. 2005 Tp  = ", $Tp,' ',$Tpa,' ',$Ts,"\n"; 



#*$pixel[$posCount]/0.282

my $Tp_mask = sprintf("%.5f",((avg(abs((($Gimage/($Mimage)) - 1))->where($full_mask)))));
my $Tpma = sprintf("%.7f",($Tp_mask/$elem_mask));
my $Ts_mask = sprintf("%.5f",($Tp_mask * $pixel[$posCount]**2 / 0.282**2 ));
print "The tidal parameter using GALFIT from van Dokkum et al. 2005 Tp (masked)  = ", $Tp_mask,' ',$Tpma,' ',$Ts_mask,"\n"; 


##Tidal image of galaxy
my $T_image = (($Gimage - $Mimage)/($Mimage))* $Mask_1b;
#->where($full_mask)
#$T_image->where($T_image <= -1 ) .= 0;
#$T_image -> wfits("Timage.gCFVnyu19424_1$A.fits"); #normal
$T_image -> wfits("Timage.gCFV$nyuID[$posCount]_1$A.fits"); #normal

my $T = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
$T->fits_imag($T_image,-0.1, 0.1);

my $Tr = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
$Tr->fits_imag($Tresidual,-0.1, 0.1);


#histograms
my $nd = $T_image->getndims;
#print "$nd\n";
my $min = min($T_image);
print "T_image min = $min\n";
my $max = max($T_image);
print "T_image max = $max\n";
my $average = avg($T_image);
print "T_image avg = $average\n";
my $med = median($T_image);
print "T_image medium = $med\n", "\n";


#histograms
my $ndr = $Tresidual->getndims;
#print "$nd\n";
my $minr = min($Tresidual);
print "Tmask min = $minr\n";
my $maxr = max($Tresidual);
print "Tmask max = $maxr\n";
my $averager = avg($Tresidual);
print "Tmask avg = $averager\n";
my $medr = median($Tresidual);
print "Tmask medium = $medr\n", "\n";

my $hist_Win = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
$hist_Win->bin(hist($T_image->clump(-1)));

my $hist_Win_m = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
$hist_Win_m->bin(hist($Tresidual->clump(-1)));
print $T_plot "$nyuID[$posCount],$Tp,$Tpa,$Tp_mask,$Tpma,Tp_corrected,Tp_masked_corrected,$elem,$elem_mask,$A,$type[$posCount],$z_type[$posCount]\n";
}

