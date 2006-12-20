use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME                => 'Newsletter',
    AUTHOR              => 'Dominik Hochreiter <dominik@soft.uni-linz.ac.at>',
    VERSION_FROM        => 'lib/Newsletter.pm',
    ABSTRACT_FROM       => 'lib/Newsletter.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'MIME::Explode' => '0.38',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Newsletter-*' },
#    PL_FILES 		=> {'cgi/My.PL' => 'My'},
);

do "cgi/My.PL";


# pre-install handler; 
#sub MY::preinstall  {  }


# post-install handler; 
#sub MY::postinstall { 
#	return <<'MAKE_';
#
#perl cgi/My.PL
#
#MAKE_
#} 


