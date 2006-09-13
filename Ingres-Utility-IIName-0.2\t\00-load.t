#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Ingres::Utility::IIName' );
}

diag( "Testing Ingres::Utility::IIName $Ingres::Utility::IIName::VERSION, Perl $], $^X" );
