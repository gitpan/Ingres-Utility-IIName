package Ingres::Utility::IIName;

use warnings;
use strict;
use Expect::Simple;
use Data::Dump qw(dump);

=head1 NAME

Ingres::Utility::IIName -  API to IINAME, the Ingres utility for (un)registering services with IIGCN

=head1 VERSION

Version 0.2

=cut

our $VERSION = '0.2';

=head1 SYNOPSIS

List registered INGRES (IIDBMS) services:

    use Ingres::Utility::IIName;

    my $foo = Ingres::Utility::IIName->new();
    
    print $foo->show('INGRES'); # list all INGRES-type servers (iidbms)
    
    while (my @server = $foo->getServer()) {
    	
	print "Server type: $server[0]\tname:$server[1]\tid:$server[2]";

	if (defined($server[3])) {

		print "\t$server[3]";

	}

	print "\n";

    }
    
    		
    
    ...
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.
This module provides an API to the iinamu utility for Ingres RDBMS,
which provides local interaction and control of IIGCN server,
in charge of registering all Ingres services.

Through this interface, it is possible to obtain a list of all
registered services, for later processing (eg. iimonitor), and
also stopping the IIGCN server (extreme caution!).


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Requires Ingres environment variables, such as II_SYSTEM and LD_LIBRARY_PATH.
See Ingres RDBMS documentation.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

Expect::Simple


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 FUNCTIONS

=head2 new

Create a new instance, checking environment prerequisites
and preparing for interfacing with iinamu utility.

=cut

sub new {
	my $class = shift;
	my $this = {};
	$class = ref($class) || $class;
	bless $this, $class;
	if (! defined($ENV{'II_SYSTEM'})) {
		die $class . ": Ingres environment variable II_SYSTEM not set";
	}
	my $iigcn_file = $ENV{'II_SYSTEM'} . '/ingres/bin/iinamu';
	
	if (! -x $iigcn_file) {
		die $class . ": Ingres utility cannot be executed: $iigcn_file";
	}
	$this->{cmd} = $iigcn_file;
	$this->{xpct} = new Expect::Simple {
				Cmd => $iigcn_file,
				Prompt => [ -re => 'IINAMU>\s+' ],
				DisconnectCmd => 'QUIT',
				Verbose => 0,
				Debug => 0,
				Timeout => 10
        } or die $this . ": Module Expect::Simple cannot be instanciated.";
	return $this;
}

=head2 show

Returns the output of SHOW command, and prepares for
parsing the servers sequentially with getServer().
Takes one optional argument for the service

=cut

sub show {
	my $this = shift;
	my $server_type = uc (@_ ? shift : 'INGRES');
	#print $this . ": cmd = $cmd";
	my $obj = $this->{xpct};
	my $cmd = 'SHOW ' . $server_type;
	$obj->send($cmd);
	my $before = $obj->before;
	while ($before =~ /\ \ /) {
		$before =~ s/\ \ /\ /g;
	}
	my @antes = split(/\r\n/,$before);
	if ($#antes > 0) {
		if ($antes[0] eq $cmd) {
			shift @antes;
		}
	}
	$this->{stream} = join($RS,@antes);
	$this->{svrtype} = $server_type;
	return $this->{stream};
}

=head2 getServer

Returns sequentially (call-after-call) each server reported by show() as an array of
3~4 elements.

=cut

sub getServer {
	my $this = shift;
	if (! $this->{stream}) {
		return ();
	}
	if (! $this->{streamPtr}) {
		$this->{streamPtr} = 0;
	}
	my @antes = split($RS,$this->{stream});
	if ($#antes <= $this->{IINAMU_STREAM_PTR}) {
		$this->{streamPtr} = 0;
		return ();
	}
	my $line = $antes[$this->{streamPtr}++];
	return split(/\ /, $line);
}

=head2 stop

Shuts down the IIGCN daemon, making it no longer possible to
stablish new connections to any Ingres service.
After this, a total restart of Ingres will most probably be necessary.

=cut

sub stop {
	my $this = shift;
	my $obj = $this->{IINAMU_XPCT};
	$obj->send( 'STOP');
	my $before = $obj->before;
	while ($before =~ /\ \ /) {
		$before =~ s/\ \ /\ /g;
	}
	my @antes = split(/\r\n/,$before);
	return;
	
}

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-ingres-utility-iiname at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ingres-Utility-IIName>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ingres::Utility::IIName

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ingres-Utility-IIName>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Ingres-Utility-IIName>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ingres-Utility-IIName>

=item * Search CPAN

L<http://search.cpan.org/dist/Ingres-Utility-IIName>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Computer Associates (CA) for licensing Ingres as
open source, and let us hope for Ingres Corp to keep it that way.

=head1 AUTHOR

Joner Cyrre Worm  C<< <FAJCNLXLLXIH at spammotel.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Joner Cyrre Worm C<< <FAJCNLXLLXIH at spammotel.com>. All rights reserved.


Ingres is a registered brand of Ingres Corporation.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1; # End of Ingres::Utility::IIName
