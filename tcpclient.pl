#!/usr/bin/perl
#tcpclient.pl [-h] [-v] [-c config file] ip port id action subaction [ ipport / dpc [ssn] ] 

use strict;
use IO::Socket::INET;
use XML::Parser;
use Getopt::Std;

my $usage = "\ntcpclient.pl [-h] [-v] [-c config file] ip port id action subaction [ ipport / dpc [ssn] ]
         -h: help
         -v: print xml message sent and received. default is n
         -c: qc_main / ia_main configuration file.
         ip: ip of qc_main / ia_main
         port: xml listen port of qc_main / ia_main
         id: hi/sb/it/sp/st/qc/ia/all
         action: enable/disable/show/open/close/add
         subaction: debug/alarm/assoc/route
         ipport: ip:port of m3ua associations, comma separated, omit if all associations
         dpc: sccp dpc to be added
         ssn: sccp ssn to be added, comma separated, omit if all ssn\n\n";

#define a pointer to the response tag attributes hash table
my $responsetag;

#define a pointer to the dpcssn tag attributes hash table
my $dpcssntag;

# a hash table to keep dpc ssn configured
my %cfgdpcssn = ();

# if no argument is provided, prompt for it
if ($#ARGV eq -1) {

# first check for input arguments
# loop through the prompt until non-empty ip
   my $check = 0;

	my $ip = '';
   while ($check eq 0) {
	   print "\nip (ip of qc_main / ia_main):";
   	$ip = <STDIN>;
   	chomp $ip;

		if ($ip eq '') {
			print "ip cannot be empty\n";
		}
		else {
			$check = 1;
		}
	}

# loop through the prompt until non-empty port
   $check = 0;

	my $port = '';
   while ($check eq 0) {
   	print "\nport (xml listen port of qc_main / ia_main):";
   	$port = <STDIN>;
   	chomp $port;
		
		if ($port eq '') {
			print "port cannot be empty\n";
		}
		else {
			$check = 1;
		}
	}

# creating object interface of IO::Socket::INET modules which internally creates
# socket, binds and connects to the TCP server running on the specific port.
   my $socket = new IO::Socket::INET (
      PeerHost => $ip,
      PeerPort => $port,
      Proto => 'tcp',
   ) or die "ERROR in Socket Creation : $!\n\n"; # print the error 

   print "\nConnected to $ip:$port\n";

# define config file
	my $config = '';

# loop through the prompts until user quit
   my $continue = 'y';

   while ($continue eq 'y')
   {
      my $check = 0;

# by default, verbose is off
		my $verbose = 'n';
   	while ($check eq 0) {
	   	print "\nverbose (y/n):";
  	 		my $newverbose = <STDIN>;
   		chomp $newverbose;

# only allow y or n or empty, i.e., default to n
			if ($newverbose ne '' && $newverbose ne 'y' && $newverbose ne 'n') {
				print "only y or n is allowed\n";
			}
			else {
# set verbose if not default to n
				$verbose = $newverbose if ($newverbose ne '');

				$check = 1;
			}
		}

# loop through the prompt until correct id
      $check = 0;

		my $id = '';
      while ($check eq 0) {

         print "\nid (hi/sb/it/sp/st/qc/ia/all):";
         $id = <STDIN>;
         chomp $id;
         $id = lc $id;

# invoke subroutine to validate $id
			$check = validateId($id);
      }

# loop through the prompt until correct action
      $check = 0;

		my $action = '';
      while ($check eq 0) {

         print "\naction (enable/disable/show/open/close/add):";
         $action = <STDIN>;
         chomp $action;
         $action = lc $action;

# invoke subroutine to validate $action
			$check = validateAction($action, $id);
      }

# loop through the prompt until correct subaction
      $check = 0;

		my $subaction = '';
      while ($check eq 0) {

         print "\nsubaction (debug/alarm/assoc/route):";
         $subaction = <STDIN>;
         chomp $subaction;
         $subaction = lc $subaction;

# invoke subroutine to validate $subaction
			$check = validateSubaction($subaction, $action);
      }

		my $ipport = '';
      if ($subaction eq 'assoc') {
         print "\nipport (ip:port of m3ua associations (optional)):";
         $ipport = <STDIN>;
         chomp $ipport;
      }

# a hash table to keep dpc ssn entered
		my %dpcssn = ();
      if ($subaction eq 'route') {

# prompt for config file first
			$check = 0;
      	while ($check eq 0) {

         	print "\nconfig file ($config):";
         	my $newconfig = <STDIN>;
         	chomp $newconfig;

# set the config to input if not empty
				$config = $newconfig if ($newconfig ne '');

 				if ($config eq '') {
					print "config file name cannot be empty\n";
				}
				else {
# check if file exists
					if (-e $config) {
# parse the input config file to set the dpcssn hash table for current config
						$check = parsedpcssnconfig($config);
					}
					else {
						print "$config does not exist\n";
						$check = 0;
					}
				}
      	}

			my $dpcmore = 'y';
			while ($dpcmore eq 'y') {

				# loop through the prompt until non-empty dpc
   			$check = 0;

				my $dpc = '';
  				while ($check eq 0) {
         		print "\ndpc (sccp dpc to be added):";

	         	$dpc = <STDIN>;
  		       	chomp $dpc;

					if ($dpc eq '') {
						print "\ndpc cannot be empty\n";
					}
					else {
						$check = 1;
					}
				}

         	print "\nssn (sccp ssn to be added (optional):";
         	my $ssn = <STDIN>;
         	chomp $ssn;

				$dpcssn{ $dpc } = $ssn;

				print "\n\nmore? (y/n):";
				$dpcmore = <STDIN>;
				chomp $dpcmore;

			}  # while ($dpcmore eq 'y') {
      }  # if ($subaction eq 'route') {

# print all input parameters and ask for confirmation

		print "\nverbose:   $verbose\n";
		print "id:        $id\n";
		print "action:    $action\n";
		print "subaction: $subaction\n";

		print "ipport:    $ipport\n" if ($subaction eq 'assoc');

 		if ($subaction eq 'route') {
			print "config:    $config\n";

			while (my ($key, $value) = each(%dpcssn)) {
				print "dpc:       $key\n";
				print "ssn:       $value\n";
			}
		}
		
		my $paracorrect = 'n';

		print "\nparameters correct? (y/n):";
		$paracorrect = <STDIN>;
		chomp $paracorrect;

# send the data in xml format over tcp
		if ($paracorrect eq 'y') {
      	tcpconnect($socket, $verbose, $id, $action, $subaction, $ipport, %dpcssn); 

# get the response tag value
			if ($responsetag) {
				my $response = $responsetag->{ '_str' };
				chomp $response;

				if ($response =~ /success/) {
					if ($subaction eq 'route') {
# update the cfg xml file with the new dpcssn 
						my $key = '';
						my $value = '';

# replace or add entries to the cfg
						$cfgdpcssn{ $key } = $value while (($key, $value) = each(%dpcssn));

						updatedpcssnconfig($config, \%cfgdpcssn);
					}
					else {
						if (($subaction eq 'assoc') && ($action ne 'show')) {
# issue the show command again to get the status
      					tcpconnect($socket, $verbose, $id, 'show', $subaction, $ipport, %dpcssn); 
						}
					}
				}
			}
		}

      print "\n\n";

      print "continue? (y/n):";
      $continue = <STDIN>;
      chomp $continue;

   } 	# while ($continue eq 'y')

# close the socket
   $socket->close();

} 	# if ($#ARGV eq -1) {
else
{

# first check for input arguments
# by default, verbose is off
	my $verbose = 'n';

# read from command line inputs

# define a hash table to keep the command line options
	my %options = ();

# get the command line flags defined
	getopts("vhc:", \%options);

# -h is defined
	die $usage if defined $options{h};

# -v is defined
	$verbose = 'y' if defined $options{v};

# -c is defined
	my $config = $options{c} if defined $options{c};

   if ($#ARGV < 4) { die $usage; }

	my $index = 0;

   my $ip = $ARGV[$index];
	$index = $index+1;

   my $port = $ARGV[$index];
	$index++;

# convert all to lowercase
   my $id = lc $ARGV[$index];
	$index++;

   my $action = lc $ARGV[$index];
	$index++;

   my $subaction = lc $ARGV[$index];
	$index++;

   print "\n";

# validate $id and exit if failed
	my $check = validateId($id);

 	die $usage if ($check eq 0); # print usage if validate failed

# validate $action and exit if failed
	$check = validateAction($action, $id);

 	die $usage if ($check eq 0); # print usage if validate failed
	
# validate $action and exit if failed
	$check = validateSubaction($subaction, $action);

 	die $usage if ($check eq 0); # print usage if validate failed
	
	my $ipport = ''; 
	my %dpcssn = ();
   if ($#ARGV >= $index) { 

# get ipport if subaction is assoc
		if ($subaction eq 'assoc') {
			$ipport = $ARGV[$index] 
		}
		else {
# get dpcssn if subaction is route
			if ($subaction eq 'route') {

# if add route, config file must be specified
				if ($config eq '') {
					print "config file must be specified\n";
					die $usage;
				}
				else {
# check if file exists
					if (-e $config) {
# parse the input config file to set the dpcssn hash table for current config
						$check = parsedpcssnconfig($config);
					}
					else {
						print "$config does not exist\n";
						die $usage;
					}
				}

				my $dpc = $ARGV[$index];
				$index++;

# see if ssn is defined
				my $ssn = '';
				$ssn = $ARGV[$index] if ($#ARGV >= $index); # comma separated

				$dpcssn{ $dpc } = $ssn;
			}
		}
	}

# check to make sure dpc ssn is not empty for add route
	if ($subaction eq 'route') {

# check size of %dpcssn
		my $size = keys %dpcssn;

# dpcssn list cannot be empty
		die "dpc must be configured\n\n$usage" if ($size eq 0);	
	}

# set up connection

# creating object interface of IO::Socket::INET modules which internally creates
# socket, binds and connects to the TCP server running on the specific port.
   my $socket = new IO::Socket::INET (
      PeerHost => $ip,
      PeerPort => $port,
      Proto => 'tcp',
   ) or die "ERROR in Socket Creation : $!\n"; # print the error 

   print "\nConnected to $ip:$port\n";

# send the data in xml format over tcp
   tcpconnect($socket, $verbose, $id, $action, $subaction, $ipport, %dpcssn);

# get the response tag value
 	if ($responsetag) {

		my $response = $responsetag->{ '_str' };
		chomp $response;

		if ($response =~ /success/) {
			if ($subaction eq 'route') {

# update the cfg xml file with the new dpcssn 
				my $key = '';
				my $value = '';
# replace or add entries to the cfg
				$cfgdpcssn{ $key } = $value while (($key, $value) = each(%dpcssn));

				updatedpcssnconfig($config, \%cfgdpcssn);
			}
			else {
				if (($subaction eq 'assoc') && ($action ne 'show')) {
# issue the show command again to get the status
      			tcpconnect($socket, $verbose, $id, 'show', $subaction, $ipport, %dpcssn); 
				}
			}
		}
	}

# close the socket
   $socket->close();

} # else


#
# @param $_[0] - $socket
# @param $_[1] - $verbose
# @param $_[2] - $id
# @param $_[3] - $action
# @param $_[4] - $subaction
# @param $_[5] - $ipport
# @param $_[6] - %dpcssn
# 
sub tcpconnect($$$$$$%)
{
# get all the arguments from the argument array
	my ( $socket, $verbose, $id, $action, $subaction, $ipport, %dpcssn ) = @_;

# flush after every write
   $| = 1; # if set to no-zero, forces a flush right away, and after every write or print 

	my $data = '';
   $data = "<?xml version=\'1.0\' encoding=\'ISO-8859-1\'?>\n<!DOCTYPE rpcmsg SYSTEM \'\'>\n\n<rpcmsg>\n<entid>$id</entid>\n<action>$action</action>\n<subaction>$subaction</subaction>\n<ipport>$ipport</ipport>\n";

# check size of %dpcssn
	my $size = keys %dpcssn;
	
	if ($size ne 0) {

# dpcssn list is not empty

# add each key value pair into the xml 
		my $key = '';
		my $value = '';
		$data .= "<dpcssn dpc=\"$key\">$value</dpcssn>\n" while (($key, $value) = each(%dpcssn));
	}

	$data .= "</rpcmsg>";

   print "\n\nSent to Server : \n$data\n\n" if ($verbose eq 'y');

# write on the socket to server.

   print $socket $data;
# we can also send the data through IO::Socket::INET module,
# $socket->send($data);


# read the socket data sent by server.
#$data = <$socket>;
# we can also read from socket through recv()  in IO::Socket::INET
   $socket->recv($data,1024);
   print "Received from Server : \n$data\n" if ($verbose eq 'y');
	

# create a XML object to parse rpc xml msg
	my $rpcxml = new XML::Parser( Handlers => { Start => \&rpchdl_start, End => \&rpchdl_end, Char => \&rpchdl_char, Default => \&rpchdl_def, } );

# parse the input string
	$rpcxml->parse($data);

} 	# sub tcpconnect 

#
# @param $_[0] - $id to be checked 
# 
# @return 1 - if found, 0 - if not found
#
sub validateId($) 
{
	my $id = $_[0];

# declare arrays for id
	my @ids = ( 'hi', 'sb', 'it', 'sp', 'st', 'qc', 'ia', 'all' );

# check and make sure input id is correct
   my $found = 0;
   foreach (@ids) {
   	if ($id eq $_) {
      	$found = 1;
         last;
      }
   }

   if ($found == 0) {
   	print "invalid id $id\n\n";
		return 0;
   } 
	else {
   	return 1;
   }
} 	# sub validateId 


#
# @param $_[0] - $action to be checked 
# @param $_[1] - $id to be checked 
# 
# @return 1 - if found, 0 - if not found
#
sub validateAction($$)
{

	my ( $action, $id ) = @_;

   my @actions = ( 'enable', 'disable', 'show', 'open', 'close', 'add' );

# check and make sure input action is correct
   my $found = 0;
   foreach (@actions) {
      if ($action eq $_) {
         $found = 1;
         last;
      }
   }

   if ($found == 0) {
      print "invalid action $action\n\n";
		return 0;
   }
	else {
# if id is not it, action cannot be show or open or close
		if (($id ne 'it') && (($action eq 'show') || ($action eq 'open') || ($action eq 'close'))) { 
      	print "$action is valid for it only\n\n";
			return 0;
		}
		else {
			if (($id ne 'sp') && ($action eq 'add')) { 
      		print "$action is valid for sp only\n\n";
				return 0;
			}
			else {
				return 1;
			}
		}
	}
} 	# sub validateAction 


#
# @param $_[0] - $subaction to be checked 
# @param $_[1] - $action to be checked 
# 
# @return 1 - if found, 0 - if not found
#
sub validateSubaction($$)
{

	my ( $subaction, $action ) = @_;

   my @subactions = ( 'debug', 'alarm', 'assoc', 'route' );

# check and make sure input subaction is correct
   my $found = 0;
   foreach (@subactions) {
      if ($subaction eq $_) {
         $found = 1;
         last;
      }
   }

   if ($found == 0) {
      print "invalid subaction $subaction\n\n";
		return 0;
   }
	else {

# if subactions is assoc, action must be enabe or disable show or open or close
		if (($subaction eq 'assoc') && ($action eq 'add')) { 
      	print "$subaction is not valid for $action\n\n";
			return 0;
		}
		else {
# if subactions is route, action must be add
			if (($subaction eq 'route') && ($action ne 'add')) { 
      		print "$subaction is not valid for $action\n\n";
				return 0;
			}
			else {
				return 1;
			}
		}
	}
} 	# sub validateSubaction 


# XML Parser Handlers
#
# @param $expat - expat object
# @param $elem - name of the element
# @param %attrs - a hash containing all attributes of this element 
#
sub rpchdl_start($$%)
{
	my ( $expat, $elem, %attrs ) = @_;

# get the response tag only
	return unless $elem eq 'response';

# initialize the value of this tag, key is _str
	$attrs{ '_str' } = '';

# get a pointer to the attributes hash table
	$responsetag  = \%attrs;

} 	# sub rpchdl_start


#
# @param $expat - expat object
# @param $elem - name of the element
#
sub rpchdl_end($$)
{
	my ( $expat, $elem ) = @_;
	
# handle the response tag only
	return unless $elem eq 'response' && $responsetag;

# get the response tag value
	my $response = $responsetag->{ '_str' };

# remove the last ',' if any
	$response =~ s/,$//;

   print "\nCommand response: $response\n\n";

} 	# sub rpchdl_end


#
# @param $expat - expat object
# @param $str - character of content of element
#
sub rpchdl_char($$)
{
	my ( $expat, $str ) = @_;

# make sure responsetag is set
	return unless $responsetag;

# append the character
	$responsetag->{ '_str' } .= $str;

} 	# sub rpchdl_char


sub rpchdl_def
{
# do nothing for now
} 	# sub hdl_default


#
# @param $config - config file name
# @return 1 if parsing ok
#
sub parsedpcssnconfig($)
{
	my $config = $_[0];

# create a XML object to parse cfg xml 
	my $cfgxml = new XML::Parser( Handlers => { Start => \&cfghdl_start, End => \&cfghdl_end, Char => \&cfghdl_char, Default => \&cfghdl_def, } );

# parse the input string
	$cfgxml->parsefile($config);

	return 1;
}


# XML Parser Handlers
#
# @param $expat - expat object
# @param $elem - name of the element
# @param %attrs - a hash containing all attributes of this element 
#
sub cfghdl_start($$%)
{
	my ( $expat, $elem, %attrs ) = @_;

# get the dpc ssn only
	return unless lc $elem eq 'dpcssn';

# initialize the value of this tag, key is _str
	$attrs{ '_str' } = '';

# get a pointer to the attributes hash table
	$dpcssntag  = \%attrs;

} 	# sub cfghdl_start


#
# @param $expat - expat object
# @param $elem - name of the element
#
sub cfghdl_end($$)
{
	my ( $expat, $elem ) = @_;
	
# handle the dpcssn tag only
	return unless lc $elem eq 'dpcssn' && $dpcssntag;

# get the dpc value
 	my $dpc = $dpcssntag->{ 'dpc' };

# get the ssn value
	my $ssn = $dpcssntag->{ '_str' };

# store the pair
	$cfgdpcssn{ $dpc } = $ssn;

#  print "\ndpc:$dpc, ssn=$ssn\n";

} 	# sub cfghdl_end


#
# @param $expat - expat object
# @param $str - character of content of element
#
sub cfghdl_char($$)
{
	my ( $expat, $str ) = @_;

# make sure dpcssntag is set
	return unless $dpcssntag;

# append the character
	$dpcssntag->{ '_str' } .= $str;

} 	# sub cfghdl_char


sub cfghdl_def
{
# do nothing for now
} 	# sub hdl_default


#
# @param $config - config file name
# @param $cfgdpcsn - a reference to %cfgdocssn
#
sub updatedpcssnconfig($$)
{
	use File::Copy;

	my ($config, $cfgdpcssnref) = @_;

# open the config file to read
	open(INFILE, $config);

# open the new config file
	my $newconfig = $config . ".new";

# open the new config file to write
	open(OUTFILE, ">$newconfig");

	my $startexe = 0;
	my $skipdpcssn = 0;

# read line in the file
	while (<INFILE>) {
# search for the line with <config> 
		$startexe = 1 if ($_ =~ /<config>/);

# no need to take action until <config> is found to by pass the comments
		if ($startexe eq 1) {

# search for 1st line having dpcssn
			if ($_ =~ /<DpcSsn/) {

				if ($skipdpcssn eq 0) {
# now we have the 1st line that has dpcssn 
# update the new dpcssn config for each dpc ssn entry in the hashtable
				
					my $key = '';
					my $value = '';
 					while (($key, $value) = each(%$cfgdpcssnref)) {
						my $dpcssntag = "\t<DpcSsn dpc=\"$key\">$value</DpcSsn>\n";

# print the line to the output file
						print OUTFILE $dpcssntag;
					}

# set the flag to skip subsequent dpcssn tag
					$skipdpcssn = 1;
				}  # if ($skipdpcssn eq 0) {
# skip all lines having dpcssn

				next;
			} 	# if ($_ =~ /<DpcSsn/) {
		}  # if ($startexe eq 1) {
		
# print the line to the output file
		print OUTFILE $_;	
	}  # while (<INFILE>) {

	close (INFILE);
	close (OUTFILE);

# copy and backup the files
	my $infile = $config;
	my $bakfile = $config . '.bak';

	copy ($infile, $bakfile);
	copy ($newconfig, $infile);

# delete the outfile
	unlink $newconfig;
}
