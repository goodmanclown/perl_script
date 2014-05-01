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
	# replace InfoLog with StackLog and keep the original as comment
	if ($_ =~ m/InfoLog/) {
		# copy the line to another var
      $cmt = $_;

		# comment this line
		$cmt =~ s/InfoLog/\/\/ TW InfoLog/g;

	   # print the line to the output file
		print OUTFILE $cmt;

	   # replace InfoLog to StackLog
		$_ =~ s/InfoLog/StackLog/g;
	}

	print OUTFILE $_;
}

# close input and output file
close (INFILE);

close (OUTFILE);

$INFILE=$file;
$BAKFILE=$file . '.orig';
$OUTFILE="./test.cxx";
#make a copy of the original file first
copy ($INFILE, $BAKFILE) or die "File cannot be copied";

#copy the temp file back to the original one
copy ($OUTFILE, $INFILE) or die "File cannot be copied";
}
