package Newsletter::Html::Upload;

use warnings;

use strict;

sub fileUpload {
        my ($self, $cgiParamName ) = @_;

	my $file = $self->{'cgi'}->param( $cgiParamName );

	return "No File !" if(!$file);

	my $saveFile = $file;
	$saveFile =~s/^.*\\([\w\d_\- \(\)]+\.[\w]+)$/$1/g;
        $saveFile =~s/ /_/g;

	my $savePath = $self->{'uploadPath'}.'/'.$saveFile;

	open (FILE, '>'.$savePath) or die "Error processing file: $savePath, $!\n";
        binmode FILE;
	
        $self->_lowRead( \$file, \*FILE );

        close FILE;

	# return file+path on server
	return $saveFile;
}


sub _lowRead {
        my ($self, $file, $FILE_HANLDE) = @_;
        my $data;
        while(read $$file, $data, 32768) { #1 #1024
                print $FILE_HANLDE $data;
        }
}



=head1 NAME

Newsletter::Html::Upload - Fileupload!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Attchments and embedded files inside of the mails

Perhaps a little code snippet.

    use Newsletter::Html::Upload;

    my $foo = Newsletter::Html::Upload->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head1 AUTHOR

Dominik Hochreiter, C<< <dominik at soft.uni-linz.ac.at> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-newsletter-html-upload at rt.cpan.org>, or through the web interface at
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

1; # End of Newsletter::Html::Upload
