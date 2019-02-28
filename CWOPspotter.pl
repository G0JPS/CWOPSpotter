#!/usr/bin/perl

# CWOPspotter
# G0JPS [2080], Feb 2019

# WHAT IS CWOPSPOTTER?
# The script does two things. It fetches a CWOPs member list from
# the web and stores it in an array. Then it connects to the raw
# feed from the reverse beacon network, and reads the incoming
# spots. Each spot is cleaned up, and compared against the member
# list. If a callsign matches (and it should pick up cases where
# prefixes and suffixes are in use, like G0/K7APO or N1MM/P) it
# will display the time, band, callsign, name, member number, CW
# speed and frequency on the screen.
# The script will run for a pre-set time, then shut down.

# OK, HOW DO I MAKE IT WORK?
# The script is written in Perl, so should run on any system that
# has Perl installed. Perl can be got at http://perl.org
# Some experience with Perl is assumed, like how to add the
# required module (Net::Telnet) from CPAN. If the previous sentence
# makes no sense, you will have problems, and google is your best friend.
# A perl script is a text file, so needs to be made executable (chmod +x).
# Drop the script in a folder, open a terminal window, navigate to
# that folder, and run with 'perl CWOPspotter.pl'
# There are two settings that need to be altered, see below.

# SUPPORT
# This script has been tested on Mac, Linux, and Raspberry Pi.
# Should work on a Windows box, perl is pretty forgiving, but
# I don't have one and never will, so can't test that.
# There may be other snags; I have done very little sanity checking on
# incoming spots, so if RBN spouts garbage (it has been known) then
# the script will start throwing weird errors. Best thing to do is
# kill and restart if that happens.

# CONFIGURATION - IMPORTANT
# Replace the ***** with your callsign in upper case.
my $self = "*****";
# RBN needs to know who it's talking to!

# Time script will run for, in SECONDS
my $runtime = 3600;
# Examples:
# 3600 = 1 hour
# 10800 = 3 hours

use strict;
use warnings;
use DateTime;
use Net::Telnet;		# Needs to be installed. Google CPAN modules.

$self = uc($self);
if ($self eq "*****"){
	die ("Callsign not set in config!\n");
}

my $endtime = $runtime + time();
my $dt = DateTime->now();
my $started = $dt->mdy . " " .$dt->hms . " UTC";
my @fields;
my $spotter;
my $freq;
my $callsign = "";
my $mode = "";
my $speed = 0;
my $time = "";
my $band = "";
my $realcall = "";
my %cwops;
my %cwopsheard;
my $cwopspot = "";
my $currLine = "";
my $list = "";
my $rbn = new Net::Telnet (Host => "telnet.reversebeacon.net",
	Timeout => 10,
	Errmode => "return",
	Port => 7000);

print "\033[2J";
print "\033[0;0H";
print "CWOPspotter : started at $started\n";

sub start_telnet{
	print "Connecting to RBN...\n";
    $rbn->open() or die $rbn->errmsg;
    $rbn->waitfor('/Please enter your call:/') or die $rbn->errmsg;
    $rbn->print("$self\n") or die $rbn->errmsg;
    $rbn->waitfor('/Local users =/') or die $rbn->errmsg;
	$rbn->waitfor('/Current spot rate is/') or die $rbn->errmsg;
    $rbn->waitfor('/>/');
    print "RBN connected\n\n";
}

sub getcwops{ 

	print "Getting member list...\n\n";
	my $content = qx{curl http://hamclubs.info/lists/CWOPS_members.txt};
	if ($content eq "") {
		die "CWOPS: No Web Data\n"
	}

	while ($content =~ /([^\n]+)\n?/g){
		my $line = $1;
		chomp $line;
		my ($exp, $call, $number, $name, $d1) = split / /, $line;
		$cwops{$call}=$name . ", " . $number;
	}
	print "\nDone!\n\n";
}

sub cwop_spotted{
	$cwopspot = "$time on $band: $callsign ($cwops{$realcall}) running $speed wpm on $freq kHz\a\n";
	# And add the call to the heard list with a timestamp
	$cwopsheard{$realcall}=time();
	print $cwopspot;
}

getcwops();

start_telnet();

print "Commence to spotting...\n\n";

while (time() <= $endtime){
	$cwopspot = 0;
	$currLine = $rbn->getline();
	chomp $currLine;
	
	if ($currLine ne "" && $currLine =~ /DX de .+CW.+/){
		$currLine =~ s/DX de //g;
		$currLine =~ s/-#://g;
		$currLine =~ s/^\s+//;
		$currLine =~ s/\s+/,/g;
		@fields = split /,/, $currLine;
		($spotter,$freq, $callsign, $mode, $speed, $time) = @fields[0,1,2,3,6,9];

		if (($mode eq "CW") && ($time =~ /\d{4}Z/)){
			$realcall = $callsign;
			$realcall =~ s/.+\/||\/.+//g;

			if (defined ($cwops{$realcall})){
				unless (exists ($cwopsheard{$realcall})){
					$cwopspot = 1;
				}
			}
			
			if ($cwopspot == 1){
				if (($freq>=1800) && ($freq <=2000)){
					$band = "160m";
				}elsif(($freq>=3500) && ($freq <=3800)){
					$band = "80m";
				}elsif(($freq>=5250) && ($freq<=5405)){
					$band = "60m";
				}elsif(($freq>=7000) && ($freq<=7200)){
					$band = "40m";
				}elsif(($freq>=10100) && ($freq<=10150)){
					$band = "30m";
				}elsif(($freq>=14000) && ($freq<=14350)){
					$band = "20m";
				}elsif(($freq>=18068) && ($freq<=18168)){
					$band = "17m";
				}elsif(($freq>=21000) && ($freq<=21450)){
					$band = "15m";
				}elsif(($freq >=24890) && ($freq <=24990)){
					$band = "12m";
				}elsif(($freq >=28000) && ($freq<=29700)){
					$band = "10m";
				}elsif(($freq>=50000) && ($freq<=52000)){
					$band = "6m";
				}elsif(($freq>=70000) && ($freq<=70500)){
					$band = "4m";
				}elsif(($freq>=144000) && ($freq<=148000)){
					$band = "2m";
				}elsif(($freq>=430000) && ($freq<=440000)){
				    $band = "70cm";
				}
			}
		}
	}

	if ($cwopspot == 1){
		cwop_spotted();
	}
		
	for my $calls (keys %cwopsheard) {
		if ($cwopsheard{$calls} + 900 <= time()){
			delete $cwopsheard{$calls};
		}
	}
}

if ($rbn->break == 1){
	$rbn->print("q\n");
	print "Telnet session closed\n";
}

print "Spotting session finished. 73!\n";

