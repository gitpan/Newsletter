package Newsletter::Html;

use warnings;

use strict;

use Newsletter::Html::Templ;
use Newsletter;
use base ("Newsletter::Html::Templ", "Newsletter::Html::Upload");
use MIME::Base64;
use File::Path;

use vars qw($VERSION);

our $VERSION = '0.02';

sub new {
        my $obj = shift;
	my $newsletterObj = shift;
	my $uploadPath = shift;

	if(!$newsletterObj) {
		die "Newsletter Param is empty\n";
	}

        my $self = {};
	#$self->{'cgi'} = new CGI;
	$self->{'nl'} = $$newsletterObj;
	$self->{'out'} = '';
	$self->{'persistent'} = {};
	$self->{'tmp'} = {};
	$self->{'info'} = undef;
	$self->{'uploadPath'} = '/tmp';

	if( $uploadPath ) {
		$self->{'uploadPath'} = $uploadPath;
		if(! -d $self->{'uploadPath'} ) {
			warn "Upload path [$uploadPath] does not exist! try to create\n";
			mkpath( $self->{'uploadPath'} );		
		}
	}

        bless($self,$obj);
	$self->init;

        return($self);
}


sub header {
	my ($self, %param) = @_;

	my @cookies = $self->_persistent();

	if( exists $self->{'persistent'}->{'pSection'} ) {
		if( $self->{'persistent'}->{'pSection'} eq "home" && 
		    $self->{'cgi'}->param() == 1
		) {
			@cookies = $self->_persistentClean();
		}
	} 

	$self->_out( $self->{'cgi'}->header( 
			-cookie=>\@cookies, 
			-expires=>'now',
	) );

	$self->_out( $self->{'cgi'}->start_html( 
			-title=>'Newsletter Simple',
		    	-author=>'hochreiter@soft.uni-linz.ac.at',
			-meta=>{'keywords' => 'Newsletter Mail Sender Simple',
			    	'copyright'=> 'Dominik Hochreiter published under GNU'},
			%param,
	) );

	if(! exists $param{'-style'} ) {
		require Newsletter::Html::CSS;
		$self->_out( $Newsletter::Html::CSS::CSS );
	}

	$self->_out( $self->{'cgi'}->p( {-align=>'left'}, $self->{'cgi'}->a( {-href => "?pSection=home"}, "Home" ) ) );
	$self->_out( $self->{'cgi'}->hr );

	return $self->_outString;
}


sub body {
	my ($self) = @_;



	if( !exists $self->{'persistent'}->{'pSection'} ) {
		$self->startpage;
	}

	elsif( $self->{'persistent'}->{'pSection'} eq "home" ) {
               $self->startpage;
        }

	elsif( $self->{'persistent'}->{"pSection"} eq "openList" ) {
               if( $self->{'nl'}->list( list => { name => $self->{'persistent'}->{"pOpenList"} } ) ) {
                       	$self->openList;
               } else {
                       $self->_out( $self->{'nl'}->error(1) );
               }
        }

	elsif( $self->{'persistent'}->{"pSection"} eq "addToList" ) {

		foreach my $key ( $self->{'cgi'}->param ) {
			if( $key =~ /newMember\d\d\d\d/ ) {

				next if( !$self->{'cgi'}->param($key) );

				if( $self->{'nl'}->list( member => {
					listname => $self->{'persistent'}->{"pOpenList"},
					mail => $self->{'cgi'}->param($key),
					rereadOff => 1
				} ) ) {
					$self->_info( $self->{'cgi'}->param($key)." added" );
					if( $self->{'nl'}->error ) {
						$self->_info( $self->{'nl'}->error(1) );
					}
				} else {
					$self->_info( $self->{'nl'}->error(1) );
				}
			}
		}

		if( $self->{'nl'}->list( list => { name => $self->{'persistent'}->{"pOpenList"} } ) ) {
                        $self->openList;
               	} else {
                       	$self->_out( $self->{'nl'}->error(1) );
               	}

        }

#ONLY VCM [start]
	elsif( $self->{'persistent'}->{"pSection"} eq "addToListRemote" ) {

                foreach my $key ( $self->{'cgi'}->param ) {
                        if( $key =~ /newMember\d\d\d\d/ ) {

                                next if( !$self->{'cgi'}->param($key) );

                                if( $self->{'nl'}->list( member => {
                                        listname => $self->{'persistent'}->{"pOpenList"},
                                        mail => $self->{'cgi'}->param($key),
                                        rereadOff => 1
                                } ) ) {
                                        #$self->_info( $self->{'cgi'}->param($key)." added" );
                                        #if( $self->{'nl'}->error ) {
                                        #        $self->_info( $self->{'nl'}->error(1) );
                                        #}
                                } else {
                                        #$self->_info( $self->{'nl'}->error(1) );
                                }
                        }
                }

                #if( $self->{'nl'}->list( list => { name => $self->{'persistent'}->{"pOpenList"} } ) ) {
                #        $self->openList;
                #} else {
                #        $self->_out( $self->{'nl'}->error(1) );
                #}

        }
#ONLY VCM [end]


	elsif( $self->{'persistent'}->{"pSection"} eq "delFromList" ) {

		foreach my $member ( $self->{'cgi'}->param("openListMembers") ) {
			if( $self->{'nl'}->list( remove => {
                                        listname => $self->{'persistent'}->{"pOpenList"},
                                        mail => $member
                        } ) ) {
                        	$self->_info( "$member removed" );
                                if( $self->{'nl'}->error ) {
                                                $self->_info( $self->{'nl'}->error(1) );
                                }
                        } else {
                       	        $self->_info( $self->{'nl'}->error(1) );
			}
		}

                if( $self->{'nl'}->list( list => { name => $self->{'persistent'}->{"pOpenList"} } ) ) {
                        $self->openList;
                } else {
                        $self->_out( $self->{'nl'}->error(1) );
                }

        }

	elsif( $self->{'persistent'}->{"pSection"} eq "deleteList" ) {
		$self->{'nl'}->list(
        		remove => {
                		# remove whole list
                		listname => $self->{'cgi'}->param('listName')
        		}
		);

		$self->{'nl'}->list( reread => 1 );
		$self->startpage;
		$self->_out( $self->{'nl'}->error(1) );
	}

	elsif( $self->{'persistent'}->{"pSection"} eq "editTmpl" ) {
	
		foreach my $is ('tmplFilesHeader', 'tmplFilesFooter') {	
			foreach my $tmpl ( $self->{'cgi'}->param($is) ) {
				if( $is eq 'tmplFilesHeader') {
					$self->{'nl'}->template( use => { filename => $tmpl, is => +HEADER } );
				}

				if( $is eq 'tmplFilesFooter') {
					$self->{'nl'}->template( use => { filename => $tmpl, is => +FOOTER } );
				}

				if( $self->{'cgi'}->param("tmplFilesAction") eq "open" ) {
					if( $self->{'nl'}->{'senderHeader'}->{ +HTML_TMPL } ) {
						$self->openTmpl($self->{'nl'}->{'senderHeader'}->{ +HTML_TMPL }, +HTML_TMPL);
					}
					elsif( $self->{'nl'}->{'senderHeader'}->{ +TEXT_TMPL } ) {
                                        	$self->openTmpl($self->{'nl'}->{'senderHeader'}->{ +TEXT_TMPL }, +TEXT_TMPL );
                                	}
					elsif( $self->{'nl'}->{'senderFooter'}->{ +HTML_TMPL } ) {
                                                $self->openTmpl($self->{'nl'}->{'senderFooter'}->{ +HTML_TMPL }, +HTML_TMPL);
                                        }
					elsif( $self->{'nl'}->{'senderFooter'}->{ +TEXT_TMPL } ) {
                                                $self->openTmpl($self->{'nl'}->{'senderFooter'}->{ +TEXT_TMPL }, +TEXT_TMPL );
                                        }

				}

				elsif( $self->{'cgi'}->param("tmplFilesAction") eq "delete" ) { 
					if( $is eq 'tmplFilesHeader') {
					 	$self->{'nl'}->template( 
							use => { is => 'header', filename => $tmpl },
							remove => 1
						);
					}
					elsif( $is eq 'tmplFilesFooter') {
                                                $self->{'nl'}->template( 
                                                        use => { is => 'footer', filename => $tmpl },
                                                        remove => 1
                                                );
                                        }
					$self->{'nl'}->template( reread => 1 );
                                }


				if( $self->{'nl'}->error ) {
                                	$self->_info( $self->{'nl'}->error(1) );
                        	}
                	}
		}

		$self->editTmpl;
	}

	elsif( $self->{'persistent'}->{"pSection"} eq "tmplFileUpload") {
		$self->fileuploadTmpl;
	}
	
	elsif( $self->{'persistent'}->{"pSection"} eq "finishTmplFileUpload" ) {

		# Upload embedded
		my @embedded = ();
		for( my $a = 0; $a < 10; $a++ ) {
			if( $self->{'cgi'}->param("embFileUpload$a") ) {
				my $filename = $self->fileUpload("embFileUpload$a");
				push(@embedded, $self->{'uploadPath'}.'/'.$filename);
			}
		}

		
		if( $self->{'cgi'}->param("tmplSchema") ) {
			$self->{'nl'}->template(
                                file => {
                                        path => $self->{'uploadPath'}.'/'.$self->{'cgi'}->param("tmplFile"),
                                        type => $self->{'persistent'}->{"pTmplFileUploadType"},
                                        is => $self->{'persistent'}->{"pTmplFileUploadIs"},
					schema => $self->{'cgi'}->param("tmplSchema"),
					embedded => \@embedded
                                }
                        );

		} else {

			$self->{'nl'}->template(
				file => {
					path => $self->{'uploadPath'}.'/'.$self->{'cgi'}->param("tmplFile"),
					type => $self->{'persistent'}->{"pTmplFileUploadType"},
					is => $self->{'persistent'}->{"pTmplFileUploadIs"},
					embedded => \@embedded
				}
			);
		}

		$self->{'nl'}->template( reread => 1 );

		$self->editTmpl;
		$self->_out( $self->{'nl'}->error );
	}


	elsif( $self->{'persistent'}->{"pSection"} eq "sendList" ) {
		$self->sendList;
	}	

	elsif( $self->{'persistent'}->{"pSection"} eq "sendListPreview" ) {
		$self->sendListPreview;
        }

	elsif( $self->{'persistent'}->{"pSection"} eq "sendListEdit" ) {
		$self->sendListPreview;
	}

	elsif( $self->{'persistent'}->{"pSection"} eq "sendListEmail" ) {
		$self->sendListMail;
		return "";
	}

	else {
		$self->startpage;
	}

	return $self->_outString;
}


sub footer {
	my ($self) = @_;

	if( $self->{'info'} ) {
		$self->_out( "<font color=\"red\"><pre>".$self->{'info'}."</pre></font>" );
	}

	$self->_out( $self->{'cgi'}->hr );
	$self->_out( $self->{'cgi'}->p( {-align=>'right'}, "HTML Newsletter Simple Version $Newsletter::VERSION") );
	$self->_out( $self->{'cgi'}->end_html );

	return $self->_outString;
}


sub _out ($$) {
	my ($self, $string) = @_;
	if( $string ) {
		$self->{'out'} .= $string;
	}
}


sub _outString {
        my ($self) = @_;
	my $out = $self->{'out'};
	$self->{'out'} = '';
        return $out;
}


sub _persistent {
	my ($self) = @_;

	my @coockies = ();


	# read in
        foreach my $key ( $self->{'cgi'}->cookie() ) {
		if( $self->{'cgi'}->cookie($key) ) {
			if( $key =~ /^pl/ ) {
				foreach my $file ( $self->{'cgi'}->cookie($key) ) {
                                        push( @{ $self->{'persistent'}->{$key} }, $file );
                                }
			} else {
		                $self->{'persistent'}->{$key} = decode_base64( $self->{'cgi'}->cookie($key) );
			}
		} elsif( $key =~ /^p/ ) {
			if( $key =~ /^pl/ ) {
				$self->{'persistent'}->{$key} = [];
			} else {
				$self->{'persistent'}->{$key} = '';
			}
		}
        }


	foreach my $key ( $self->{'cgi'}->param ) {
		if( $key =~ /^p/) {

			if( $key =~ /^pl/ ) {
				push(@coockies,
                                        $self->{'cgi'}->cookie(
                                        -name => $key,
                                        -value => [ $self->{'cgi'}->param($key) ]
                                        )
                                );

				if( exists $self->{'persistent'}->{$key} ) {
					$self->{'persistent'}->{$key} = [];
				}

				foreach my $file ( $self->{'cgi'}->param($key) ) {
					push( @{ $self->{'persistent'}->{$key} }, $file );
				}

			}  elsif( $key =~ /^p/ ) {

				push(@coockies,
					$self->{'cgi'}->cookie(
					-name => $key,
                        	        -value => encode_base64( $self->{'cgi'}->param($key) )
					)
				);
				$self->{'persistent'}->{$key} = $self->{'cgi'}->param($key);
			}
		}
	}


	return @coockies;
}


sub _persistentClean {
	my ($self) = @_;
	
	my @coockies = ();

	# read in
        foreach my $key ( $self->{'cgi'}->cookie() ) {
		if( $key =~ /^p/) {
	        	push(@coockies,
        	        	$self->{'cgi'}->cookie(
                	        -name => $key,
                        	-value => ''
                		)
			);

			if( exists $self->{'persistent'}->{$key} ) {
				delete $self->{'persistent'}->{$key};
			}
		}
        }

	return @coockies;
}


sub _info {
	my ($self,$msg) = @_;
	$self->{'info'} .= "$msg\n";
}




=head1 NAME

Newsletter::Html - generate html!

=head1 VERSION

Version 0.02

=cut

#our $VERSION = '0.01';

=head1 SYNOPSIS

The Html module for Newsletter

Perhaps a little code snippet.

    use Newsletter::Html;

    my $foo = Newsletter::Html->new( $newsletterObj, $uploadPath );
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head1 AUTHOR

Dominik Hochreiter, C<< <dominik at soft.uni-linz.ac.at> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-newsletter-html at rt.cpan.org>, or through the web interface at
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

1; # End of Newsletter::Html
