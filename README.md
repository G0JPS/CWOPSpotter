# CWOPSpotter
# G0JPS [2080], Feb 2019

# WHAT IS CWOPSPOTTER?
The script does two things. It fetches a CWOPs member list from
the web and stores it in an array. Then it connects to the raw
feed from the reverse beacon network, and reads the incoming
spots. Each spot is cleaned up, and compared against the member
list. If a callsign matches (and it should pick up cases where
prefixes and suffixes are in use, like G0/K7APO or N1MM/P) it
will display the time, band, callsign, name, member number, CW
speed and frequency on the screen.
The script will run for a pre-set time, then shut down.

# OK, HOW DO I MAKE IT WORK?
The script is written in Perl, so should run on any system that
has Perl installed. Perl can be got at http://perl.org
Some experience with Perl is assumed, like how to add the
required module (Net::Telnet) from CPAN. If the previous sentence
makes no sense, you will have problems, and google is your best friend.
A perl script is a text file, so needs to be made executable (chmod +x).
Drop the script in a folder, open a terminal window, navigate to
that folder, and run with 'perl CWOPspotter.pl'
There are two settings that need to be altered, see below.

# SUPPORT
This script has been tested on Mac, Linux, and Raspberry Pi.
Should work on a Windows box, perl is pretty forgiving, but
I don't have one and never will, so can't test that.
There may be other snags; I have done very little sanity checking on
incoming spots, so if RBN spouts garbage (it has been known) then
the script will start throwing weird errors. Best thing to do is
kill and restart if that happens.
