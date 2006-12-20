#!perl -T

use Test::More tests => 5;

BEGIN {
	use_ok( 'Newsletter' );
	use_ok( 'Newsletter::Html' );
	use_ok( 'Newsletter::Html::CSS' );
	use_ok( 'Newsletter::Html::Templ' );
	use_ok( 'Newsletter::Html::Upload' );
}

diag( "Testing Newsletter $Newsletter::VERSION, Perl $], $^X" );
