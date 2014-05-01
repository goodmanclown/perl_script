#! /usr/local/bin/perl
use File::Copy;

$numArgs = $#ARGV + 1;

if ($numArgs > 0) {
	@files = $ARGV[0];
}
else {
	@files = <*.cxx>;
}

foreach $file (@files) {
# repeat the following for each .cxx file

# open input and output file
open (INFILE, $file);

# open output file in overwrite mode
open (OUTFILE, '>./test.cxx');

# read from INFILE 1 line at a time
while (<INFILE>) {
	# replace DebugLog and InfoLog with TrcDebugLog and TrcSipAsLog
	$_ =~ s/DebugLog/TrcDebugLog/g;
	$_ =~ s/InfoLog/TrcSipAsLog/g;
	$_ =~ s/ErrLog/TrcDebugLog/g;
	$_ =~ s/WarningLog/TrcDebugLog/g;
	$_ =~ s/repro\//sipas\//g;

	# print the line to the output file
	print OUTFILE $_;

	# search for the line including Logger.hxx
	if ($_ =~ /Logger.hxx/) {
		# add the SipAsLogger.hxx in the next line
		print OUTFILE "#include \"sipas\/SipAsLogger.hxx\"\n";
	}
}

# close input and output file
close (INFILE);

close (OUTFILE);

$INFILE=$file;
$BAKFILE=$file . '.bak';
$OUTFILE="./test.cxx";
#make a copy of the original file first
copy ($INFILE, $BAKFILE) or die "File cannot be copied";

#copy the temp file back to the original one
copy ($OUTFILE, $INFILE) or die "File cannot be copied";
}
