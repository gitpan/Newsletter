#!perl -w

use strict;
my $INSTALL_PATH = '/tmp';
my $INSTALL_QUASTION = 'y';
my $INSTALL_FILE = 'newsletter.cgi';


print "Newsletter website Installer ($INSTALL_FILE)\n";
print "Install? [$INSTALL_QUASTION]:";

my $inp = <STDIN>;
if( $inp =~/y/i || $inp =~ /^\n$/ ) {
	while(1) {
		print "Install path? [$INSTALL_PATH]:";
		$inp = <STDIN>;
		chomp $inp;
		if( $inp ) {
			$INSTALL_PATH = $inp;
		}
		print "Confirm path? [$INSTALL_PATH] [$INSTALL_QUASTION]:";
		$inp = <STDIN>;
		if( ($inp =~/y/i || $inp =~ /\n/) && $inp !~/n/i) {
			print "I am going to install ($INSTALL_FILE) ...\n";
			
			if( -d $INSTALL_PATH ) {
				
				print qx "cp cgi/$INSTALL_FILE $INSTALL_PATH 2>&1 ";
				print "TODO: Change settings in [$INSTALL_PATH/$INSTALL_FILE]\n";

			} else {
				print "Error: [$INSTALL_PATH] does not exists!\n";
			}

			last;
		} else {
			print "Stop install?:";
			if( <STDIN> =~/y/i ) {
				last;
			}
		}
	}
} else {
	print "$INSTALL_FILE not installed\n";
}

