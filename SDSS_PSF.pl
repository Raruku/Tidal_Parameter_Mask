#! /usr/bin/perl
use strict;
use warnings;
use Text::CSV;

#This script generates:
#wget lists for downloading PSFs
#renaming shell script for PSFs
#PSF modifying script for IRAF

open my $PSF_CUT, '>', "PSF_Cut.cl" or die "cannot open PSF_Cut: $!"; #PSF cutout
open my $PSFimages, '>', "Rename_PSF.sh" or die "cannot open Rename_PSF.sh: $!"; #Not IRAF!
open my $psflist, '>', "sdss-wget-PSF.lis" or die "cannot open sdss-wget-PSF.lis: $!"; #wget...

#Data Release 7
#SDSS_Positions_Size.csv can be any SDSS SQL output that contains name/name/ID, x, y, run#, field#, camcol
#It is assumed that you have a pair of CSVs -- one for DR7 and one for S82
my @DataRelease = qw/_DR7 _S82/;
foreach my $DataRelease (@DataRelease) {
	open my $inPositions, '<', "result$DataRelease.csv" or die "cannot open result$DataRelease.csv: $!"; 
	my $input_positions = Text::CSV->new({'binary'=>1});
	$input_positions->column_names($input_positions->getline($inPositions));
	my $position_inputs = $input_positions->getline_hr_all($inPositions);
	#It may be necessary to change target column names. A global find/replace is best, given the large number of hardcoded entries.
	my @nyuID = map {$_->{'col0'}} @{$position_inputs};
	my @px = map {$_->{'imgx'}} @{$position_inputs};
	my @py = map {$_->{'imgy'}} @{$position_inputs};
	my @run = map {$_->{'run'}} @{$position_inputs};
	my @rerun = map {$_->{'rerun'}} @{$position_inputs};
	my @cam = map {$_->{'camcol'}} @{$position_inputs};
	my @field = map {$_->{'field'}} @{$position_inputs};

	my $run0;
	my $field0;

	for (grep {$_->{'col0'}} @{$position_inputs}) { 
		local $, = ' ';

		#PSF cutout and subtraction
		print $PSF_CUT "imcopy psf.$_->{'col0'}$DataRelease.fits[12:42,12:42] cpsf.$_->{'col0'}$DataRelease.fits\n";
		print $PSF_CUT "imarith cpsf.$_->{'col0'}$DataRelease.fits - 1000 scpsf.$_->{'col0'}$DataRelease.fits\n";

		my $runN = $_->{'run'};
		my $fieldN = $_->{'field'};

		if ($DataRelease == "_DR7") {
			#run line padding -- 6 digit field but the run number is 1 to 4 digits. (2-5 zeros of padding)
			if ($runN > 999) {
				$run0 = "00";
			} elsif ($runN > 999) {
				$run0 = "000";
			} elsif ($runN > 9) {
				$run0 = "0000";
			} else {
				$run0 = "00000";
			}

			#field line padding -- 4 digit field but the field number is 1 to 4 digits. (0-3 zeros of padding)
			if ($fieldN > 999) {
				$field0 = "";
			} elsif ($fieldN > 99) {
				$field0 = "0";
			} elsif ($fieldN > 9) {
				$field0 = "00";
			} else {
				$field0 = "000";
			}

			#PSF wget list
			print $psflist "http://das.sdss.org/imaging/$runN/$_->{'rerun'}/objcs/$_->{'camcol'}/psField-00$_->{'run'}-$_->{'camcol'}-0$_->{'field'}.fit\n";
			print "http://das.sdss.org/imaging/$runN/$_->{'rerun'}/objcs/$_->{'camcol'}/psField-$run0$runN-$_->{'camcol'}-$field0$fieldN.fit\n";

			#PSF image
			print $PSFimages 'read_PSF',"psField".'-'.$run0.$runN.'-'.$_->{'camcol'}.'-'.$field0.$fieldN.'.fit','3',$_->{'imgx'},$_->{'imgy'},'psf.'.$_->{'col0'}.$DataRelease.".fits\n";
			print 'read_PSF',"psField".'-'.$run0.$runN.'-'.$_->{'camcol'}.'-'.$field0.$fieldN.'.fit','3',$_->{'imgx'},$_->{'imgy'},'psf.'.$_->{'col0'}.$DataRelease.".fits\n";
		}
		if ($DataRelease == "_S82") {
			#spacing and sizing is hard. This will fail in interesting ways if the naming changes.
			if ($_->{'run'} == 106) {
				$run0 = 100006;
			} else { #run == 206
				$run0 = 200006;
			}

			if (($_->{'field'} < 1000) && ($_->{'field'} >= 100)) { #3 digit field, so 1x 0 for padding
				$field0 = '0';
			} elsif ($_->{'field'} >= 10) { #2 digit field, so 2x padding
				$field0 = '00';
			} elsif ($_->{'field'} < 10) { #1 digit field needs 3x 0 padding
				$field0 = '000';
			} else {
				$field0 = ''; #4 digit fields need no 0s for padding. Also default-ish.
			}

			#PSF wget list
			print $psflist "http://das.sdss.org/imaging/$run0/$_->{'rerun'}/objcs/$_->{'camcol'}/psField-$run0-$_->{'camcol'}-$field0$_->{'field'}.fit\n";
			print "http://das.sdss.org/imaging/$run0/$_->{'rerun'}/objcs/$_->{'camcol'}/psField-$run0-$_->{'camcol'}-$field0$_->{'field'}.fit\n";
			#PSF image
			print $PSFimages 'read_PSF',"psField".'-'.$run0.'-'.$_->{'camcol'}.'-'.$field0.$_->{'field'}.'.'.'fit','3',$_->{'imgx'},$_->{'imgy'},'psf'.'.'.$_->{'col0'}.$DataRelease.'.'."fits\n";
	print 'read_PSF',"psField".'-'.$run0.'-'.$_->{'camcol'}.'-'.$field0.$_->{'field'}.'.'.'fit','3',$_->{'imgx'},$_->{'imgy'},'psf'.'.'.$_->{'col0'}.$DataRelease.'.'."fits\n";
		}
	}
}
print "Files renamed\n";
