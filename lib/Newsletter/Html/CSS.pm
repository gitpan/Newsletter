package Newsletter::Html::CSS;

use warnings;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT $CSS);

@ISA = qw(Exporter);
@EXPORT = qw( $CSS );


$CSS = qq~
<style type="text/css">
<!--
body {
        font-family:verdana,tahoma;
        color:#666666;
        font-size:10px;
}

h1 {
        font-size:18px;
        font-weight:bold;
        color: #cc9900;
}

h2 {
        font-size:15px;
        font-weight:bold;
        color: #cc9900;

}

h3 {
        font-size:10px;
        font-weight:bold;
        color: #cc9900;
}

table {
        font-size:10px;
        border-width:0px;
        border-style:solid;
        border-color:white;
}

input {
        border:1px solid #cc9900;
}

select {
        border:1px solid #cc9900;
}

textarea {
	border:1px solid #cc9900;
}

button {
         border:1px solid #cc9900;
}

hr {
        border:1px solid #cc9900;
}

pre {
}


a:link { text-decoration:none; font-size:10px; }
a:visited { text-decoration:none;  font-size:10px; }
a:focus { text-decoration:underline; font-size:10px; }
a:hover { text-decoration:none; }
a:active { text-decoration:underline; }



a:link { color:#a07800; letter-spacing:1.2px; }
a:visited { color:#a07800; letter-spacing:1.2px; }
a:hover { color:#cc8600; letter-spacing:1.2px; }


.nlSelect {
	width:300px;
}

.nlInput {
	width:300px;
}

.nlSelectShort {
        width:150px;
}

.nlInputShort {
        width:150px;
}


.nlSelectLarge {
        width:500px;
}

.nlInputLarge {
        width:500px;
}



.nlTdLighter {
	background:#f6f6f6;	
}

.nlTdDarker {
	background:#eaeaea;
}


.previewTdEmail {
	background:white;
	border-width:1px;
        border-style:solid;
        border-color:gray;
}




-->
</style>
~;



=head1 NAME

Newsletter::Html::CSS - Newsletter CSS!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

CSS for the newsletter module

Perhaps a little code snippet.

    use Newsletter::Html::CSS;

    my $foo = Newsletter::Html::CSS->new();
    ...

=head1 EXPORT

=head1 AUTHOR

Dominik Hochreiter, C<< <dominik at soft.uni-linz.ac.at> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-newsletter-html-css at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Newsletter>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Newsletter

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Newsletter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Newsletter>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Newsletter>

=item * Search CPAN

L<http://search.cpan.org/dist/Newsletter>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dominik Hochreiter, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Newsletter::Html::CSS
