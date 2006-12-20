package Newsletter;

use warnings;

use Carp ();
use MIME::Lite;
use MIME::Explode;
use File::Path;
use File::Type;
use Time::HiRes;

use POSIX qw(strftime);
use strict;
use Exporter;

use vars qw($VERSION @ISA @EXPORT $ERR);
use subs qw(warn die);#die

our $VERSION = '0.03';

@ISA = qw(Exporter);
@EXPORT = qw(
	HEADER
	FOOTER
	HTML_TMPL
	TEXT_TMPL
);


use constant HEADER => 	'HEADER';
use constant FOOTER => 	'FOOTER';
use constant HTML_TMPL => 'HTML';
use constant TEXT_TMPL => 'TEXT';
use constant HTML_EMB =>  'EMBEDDED';
use constant SUFFIX_TMPL => '.tmpl';


sub warn {
	$ERR = $_[0];
}

sub die { 
        $ERR = "FATAL:$_[0]";
}


sub new {
        my $obj = shift;
        my $self = {};

	$self->{'sender'} = undef;
	$self->{'senderType'} = 'multipart/mixed';
	$self->{'senderSubject'} = 'none';
	$self->{'senderFrom'} = 'newsletter@simple.newsletter';
	$self->{'replayTo'} = $self->{'senderFrom'};
	$self->{'senderHeader'} = {};
	$self->{'senderFooter'} = {};
	$self->{'senderAddressList'} = {};

        $self->{'templatePath'} = undef;
	$self->{'tmplHeaderHtmlFiles'} = [];
	$self->{'tmplFooterHtmlFiles'} = [];
	$self->{'tmplHeaderTextFiles'} = [];
        $self->{'tmplFooterTextFiles'} = [];
	$self->{'tmplList'} = [];

	$self->{'listPath'} = undef;
	$self->{'listNames'} = [];
	$self->{'listMembers'} = {};
	$self->{'listCurrent'} = undef;

	$self->{'bodyPath'} = undef;
	$self->{'buildMail'} = 0;
	
	$self->{'archivPath'} = undef;
	$self->{'previewPath'} = undef;	
	
	$self->{'smtpServer'} = undef;

        bless($self,$obj);
	$self->sender( type => $self->{'senderType'} );

        return($self);
}


sub error {
	my ($self,$clean) = @_;
	
	if($clean) {
		my $tmp = $ERR;
		$ERR = undef;
		return $tmp;
	}
	
	return $ERR;
}


sub sender {
	my ($self, %para) = @_;
	
	if( exists $para{'type'} ) {
	
		my $type = $para{'type'};

		if( $type =~/text/i || 
		    $type =~/html/i ||
		    $type =~/multipart\/mixed/i ||
		    $type =~/multipart\/related/i
		) {

			$self->{'senderType'} = lc $type;
			if( $type ne "text" ) {
				$self->{'sender'} = MIME::Lite->new( 
					Type => $type
				);
			}
		
		} else {
			die "Sender Type [$type] is not valid!\n";
		}
	}

	if( exists $para{'smtp'} ) {
		#MIME::Lite->send( 'smtp', $para{'smtp'} );#Timeout => 60
		$self->{'smtpServer'} = $para{'smtp'};
	}

	if( exists $para{'replayTo'} ) {
		$self->{'replayTo'} = $para{'replayTo'};
	}

	if( $self->{'sender'} ) {
		return $self->{'sender'};
	}
}


sub addAddress {
	my ($self, %para) = @_;

	if( exists $para{'addressType'} ) {
		if( $para{'addressType'} eq 'Cc' ||
		    $para{'addressType'} eq 'Bcc' ||	
		    $para{'addressType'} eq 'To'
		) {
			# OK
		} else {
			die "addAddress: addressType unknown\n";
		}
        } else {
		die "addAddress: addressType is missing\n";
	}

	if( exists $para{'addressList'} ) {
		foreach my $addr ( @{ $para{'addressList'} } ) {
			$self->_lowAddAddress( $addr, $para{'addressType'});
		}
	}

	if( exists $para{'address'} ) {
		$self->_lowAddAddress( $para{'address'}, $para{'addressType'} );
        }

	if( exists $para{'empty'} ) {
		$self->{'senderAddressList'}->{ $para{'addressType'} } = [];
	}
}


sub send {
	my ( $self, $output, $block ) = @_;
	
	my $saveSender = $self->{'sender'};

	#return 0 if ! $self->_lowPrepairSend();
	if( $self->{'buildMail'} == 0) {
		return 0 if ! $self->_lowPrepairSend();
	}
	

	$self->{'sender'}->add( From => $self->{'senderFrom'} );
	$self->{'sender'}->add( 'To' => $self->{'senderFrom'} );
	$self->{'sender'}->add( 'Reply-To' => $self->{'replayTo'} );

	# output buffering off
	$| = 1;

#	for(my $a= 0; $a < 12000; $a++) {
#		push(@{ $self->{'senderAddressList'}->{ 'Bcc' } }, "nobody\@soft.uni-linz.ac.A$a.at" );
#	}

	foreach my $adrType ( 'To', 'Cc', 'Bcc' ) {
#		foreach my $adr ( @{ $self->{'senderAddressList'}->{ $adrType } } ) {
#			$self->{'sender'}->add( $adrType => $adr );
#			#$self->{'sender'}->add( 'Bcc' => $adr );
#			print "$adrType => $adr\n" if( $output );
#			#$self->{'sender'}->send;
#			#$self->{'sender'}->delete( $adrType );
#			#Time::HiRes::usleep(1);
#		}

		if( defined $self->{'senderAddressList'}->{ $adrType } ) {
		
			if( $block ) {
				my $lengthToSend = @{ $self->{'senderAddressList'}->{ $adrType } };
				my $pos = 0;
				my $blockPos = 0;
				my $toListStr = '';
				while( $pos < $lengthToSend ) {
					if( $blockPos < $block ) {
						$toListStr .= $self->{'senderAddressList'}->{ $adrType }->[$pos].";";
						print "$adrType => $self->{'senderAddressList'}->{ $adrType }->[$pos]\n"; 
						$blockPos++;
						$pos++;
					} else {
						$self->{'sender'}->add( $adrType => $toListStr);
						$self->{'sender'}->send;
						print "send\n";
						$toListStr = '';
						$blockPos = 0;
						$self->{'sender'}->delete( $adrType );
					}				
				}

			} else {

				$self->{'sender'}->add( $adrType => join(";", @{ $self->{'senderAddressList'}->{ $adrType } } ) );

				if( $output ) {
					foreach my $adr ( @{ $self->{'senderAddressList'}->{ $adrType } } ) {
                       				print "$adrType => $adr\n";
                			}
				}
			}
		}
	}

	if( !$block ) {

		if( defined $self->{'smtpServer'} ) {
			$self->_lowSend( $self->{'smtpServer'}, Timeout => 3600 );	
		} else {
			$self->{'sender'}->send;
		}
	}


	# reset
	$self->{'sender'} = $saveSender;
	$self->{'buildMail'} = 0;
	$| = 0;
}


sub buildMail {
	my ($self) = @_;
	return 0 if ! $self->_lowPrepairSend();
	$self->{'buildMail'} = 1;
	return $self->{'sender'};
}


sub previewMail {
	my ($self) = @_;
	my $saveSender = $self->{'sender'};

	return undef if ! $self->_lowPrepairSend();

	my $returnSender = $self->{'sender'};
	$self->{'sender'} = $saveSender;

	return $returnSender;
}


sub previewMailFile {
	my ($self, %para) = @_;

	if( exists $para{'path'} ) {
                if( -d $para{'path'} ) {
			$self->{'previewPath'} = $para{'path'};
                } else {
                        $self->{'previewPath'} = $para{'path'};
                        mkpath( $para{'path'} );
                }
        }

	if( exists $para{'getpath'} ) {
	        return $self->{'previewPath'};
        }


	if( exists $para{'preview'} ) {
		if( -e $self->{'previewPath'}."/preview.eml" ) {
			unlink( $self->{'previewPath'}."/preview.eml" );
		}

		my $saveSender = $self->{'sender'};

		return 0 if ! $self->_lowPrepairSend();

		#warn "type here:".$self->{'sender'}->as_string;

		open( FILE, ">".$self->{'previewPath'}."/preview.eml" ) or die "Could not open preview file:$!\n";
		$self->{'sender'}->print(\*FILE);
		close(FILE);
	
		#$self->previewMailFileExplode( $self->{'previewPath'}."/preview.eml" );

		$self->{'sender'} = $saveSender;

		return $self->{'previewPath'}."/preview.eml";
	}
}


sub previewMailFileExplode ($$) {
	my ($self, $path) = @_;

	my $mail = $path;
	my $decode_subject = 1;
	my $tmp_dir = $self->{'previewPath'}."/explode";
	my $output = $self->{'previewPath'}."/file.tmp";

	# clean first
	rmtree $tmp_dir;

	my $explode = MIME::Explode->new(
        	output_dir         => $tmp_dir,
	        mkdir              => 0755,
        	decode_subject     => $decode_subject,
        	check_content_type => 1,
	);

	open(MAIL, "<$mail") or die("Couldn't open $mail for reading: $!\n");
	open(OUTPUT, ">$output") or die("Couldn't open $output for writing: $!\n");
	my $headers = $explode->parse(\*MAIL, \*OUTPUT);
	close(OUTPUT);
	close(MAIL);

	return $headers;
}


sub body {
	my ($self, %para) = @_;

	# path is tmp
	if( exists $para{'path'} ) {
                if( -d $para{'path'} ) {
                        $self->{'bodyPath'} = $para{'path'};
			mkpath( $self->{'bodyPath'}.'/'.TEXT_TMPL ) if ! -d $self->{'bodyPath'}.'/'.TEXT_TMPL;
			mkpath( $self->{'bodyPath'}.'/'.HTML_TMPL ) if ! -d $self->{'bodyPath'}.'/'.HTML_TMPL;
			mkpath( $self->{'bodyPath'}.'/'.HTML_EMB ) if ! -d $self->{'bodyPath'}.'/'.HTML_EMB;
                } else {
                        warn "Body: Path [$para{'path'}] does not exists. Try to create\n";
			$self->{'bodyPath'} = $para{'path'};
                        mkpath( $para{'path'} );
			mkpath( $self->{'bodyPath'}.'/'.TEXT_TMPL );
                        mkpath( $self->{'bodyPath'}.'/'.HTML_TMPL );
			mkpath( $self->{'bodyPath'}.'/'.HTML_EMB );
                }
        }

	if( exists $para{'file'} ) {
		if( exists $para{'file'}->{'path'} &&
                    exists $para{'file'}->{'type'} 
                ) {
			if( $para{'file'}->{'type'} =~ /^text$/i ) {
				$self->_lowEmptyDir( $self->{'bodyPath'}.'/'.TEXT_TMPL );
				$self->_lowCopy( $para{'file'}->{'path'}, $self->{'bodyPath'}.'/'.TEXT_TMPL);
			}
			elsif( $para{'file'}->{'type'} =~ /^html$/i ) {
				$self->_lowEmptyDir( $self->{'bodyPath'}.'/'.HTML_TMPL );
                                $self->_lowCopy( $para{'file'}->{'path'}, $self->{'bodyPath'}.'/'.HTML_TMPL);

				if ( exists $para{'file'}->{'embedded'} ) {
					$self->_lowBodyEmbedded( $para{'file'}->{'embedded'} );
				}
                        } else {
                                die "Body: [type] value is invalid\n";
                        }

		}
	}

	if( exists $para{'data'} ) {
                if( exists $para{'data'}->{'type'} &&
		    exists $para{'data'}->{'value'}
		) {
                        if( $para{'data'}->{'type'} =~ /^text$/i ) {
				$self->_lowEmptyDir( $self->{'bodyPath'}.'/'.TEXT_TMPL );
                                $self->_lowWrite( $para{'data'}->{'value'}, $self->{'bodyPath'}.'/'.TEXT_TMPL.'/new.txt');
                        }
                        elsif( $para{'data'}->{'type'} =~ /^html$/i ) {
				$self->_lowEmptyDir( $self->{'bodyPath'}.'/'.HTML_TMPL );
                                $self->_lowWrite( $para{'data'}->{'value'}, $self->{'bodyPath'}.'/'.HTML_TMPL.'/new.html');

                                if ( exists $para{'data'}->{'embedded'} ) {
                                        $self->_lowBodyEmbedded( $para{'data'}->{'embedded'} );
                                }
                        } else {
                                die "Body: [type] value is invalid\n";
                        }

                }
        }

	if( exists $para{'subject'} ) {
		$self->_lowWrite( $para{'subject'}, $self->{'bodyPath'}.'/subject.txt');		
	}
}


sub template {
	my ($self, %para) = @_;

	if( exists $para{'path'} ) {
		if( -d $para{'path'} ) {
			$self->{'templatePath'} = $para{'path'};
			$self->_lowReadTemplates();
		} else {
			warn "template: Path [$para{'path'}] does not exists. Try to create\n";
			mkpath( $para{'path'} );
			$self->_lowReadTemplates();
		}
	}

	if( exists $para{'file'} ) {
		if( exists $para{'file'}->{'path'} &&
		    exists $para{'file'}->{'type'} &&
		    exists $para{'file'}->{'is'} 
		) {

			my $path = '';

			if( $para{'file'}->{'type'} =~ /^text$/i ) {
				if( $para{'file'}->{'is'} =~/^header$/i) {
					$self->_lowCopy( $para{'file'}->{'path'}, $self->{'templatePath'}.'/'.TEXT_TMPL.'/'.HEADER);
					$path = $self->{'templatePath'}.'/'.TEXT_TMPL.'/'.HEADER;
				} 
				elsif( $para{'file'}->{'is'} =~/^footer$/i) {
                                        $self->_lowCopy( $para{'file'}->{'path'}, $self->{'templatePath'}.'/'.TEXT_TMPL.'/'.FOOTER);
					$path = $self->{'templatePath'}.'/'.TEXT_TMPL.'/'.FOOTER;
                                } else {
					die "template: [is] value is invalid\n";
				}
			} elsif ( $para{'file'}->{'type'} =~ /^html$/i ) {
				if( $para{'file'}->{'is'} =~/^header$/i) {
                                        $self->_lowCopy( $para{'file'}->{'path'}, $self->{'templatePath'}.'/'.HTML_TMPL.'/'.HEADER); 
					$path = $self->{'templatePath'}.'/'.HTML_TMPL.'/'.HEADER;
                                } 
                                elsif( $para{'file'}->{'is'} =~/^footer$/i) {
                                        $self->_lowCopy( $para{'file'}->{'path'}, $self->{'templatePath'}.'/'.HTML_TMPL.'/'.FOOTER);
					$path = $self->{'templatePath'}.'/'.HTML_TMPL.'/'.FOOTER;
                                } else {
                                        die "template: [is] value is invalid\n";
                                }

				if ( exists $para{'file'}->{'embedded'} ) {

					$para{'file'}->{'path'} =~ /\/*([\w\d _\-\.]+)$/;
		                        my $fileName =  $1;

					my $embPath = $self->{'templatePath'}.'/'.HTML_TMPL.'/'.HTML_EMB.'/'.
                                                uc $para{'file'}->{'is'}.'/'.$fileName; #.'/'.$para{'file'}->{'path'};

					mkpath( $embPath ) if( ! -d $embPath );

					if( ref $para{'file'}->{'embedded'} eq "ARRAY" ) {
						my $embStr = '';
						foreach my $emb ( @{ $para{'file'}->{'embedded'} } ) {
							$self->_lowCopy( $emb, $embPath );
							$emb =~ /\/*([\w\d _\-\.]+)$/;
							$embStr .= "$1,";
						}
						$para{'file'}->{'embedded'} = $embStr;
					} else {
						$self->_lowCopy( $para{'file'}->{'embedded'}, $embPath );
						$para{'file'}->{'embedded'} =~ /\/*([\w\d _\-\.]+)$/;
						$para{'file'}->{'embedded'} = "$1,";
					}
				}

			} else {
				die "template: [type] value is invalid\n";
			}

			$para{'file'}->{'path'} =~ /\/*([\w\d _\-\.]+)$/;
			my $fileName = 	$1;
			$para{'file'}->{'fileName'} = $fileName;
			my $fileNameTmpl = $fileName.SUFFIX_TMPL;
			
			if( $fileName ) {
				 $self->_lowWriteFile( $path.'/'.$fileNameTmpl, $para{'file'} );

			 	if( $para{'file'}->{'is'} =~/^header$/i ) {
					$self->{'senderHeader'}->{ uc $para{'file'}->{'type'} } = $path.'/'.$fileName;
				}

				if( $para{'file'}->{'is'} =~/^footer$/i ) {
					$self->{'senderFooter'}->{ uc $para{'file'}->{'type'} } = $path.'/'.$fileName;
                                }

			} else {
				die "template: Invalid File name!";
			} 

		} else {
			die "template: File a main parameter is missing (path,type,is)!\n";
		}
	}

	if( exists $para{'use'} ) {
		# use saved tmpl (Header/Footer) by name or File Name or Schema!
		if( exists $para{'use'}->{'schema'} ) {
			
			my $tmpHeader = $self->{'senderHeader'};
			my $tmpFooter = $self->{'senderFooter'};
			$self->{'senderHeader'} = {};
			$self->{'senderFooter'} = {};

			foreach my $listRef ( 
			  { list => $self->{'tmplHeaderHtmlFiles'}, is => HEADER, type => HTML_TMPL },
        		  { list => $self->{'tmplFooterHtmlFiles'}, is => FOOTER, type => HTML_TMPL },
        		  { list => $self->{'tmplHeaderTextFiles'}, is => HEADER, type => TEXT_TMPL },
        		  { list => $self->{'tmplFooterTextFiles'}, is => FOOTER, type => TEXT_TMPL }
			) {
				#next if ! $listRef->{'list'};
				foreach my $file ( @{ $listRef->{'list'} } ) {
					my $path = $self->{'templatePath'}.'/'.$listRef->{'type'}.'/'.$listRef->{'is'}.'/'.$file;
					my $tupels = $self->_lowReadFile( $path.SUFFIX_TMPL );

					if( exists $tupels->{'schema'} ) {
						if( $para{'use'}->{'schema'} eq $tupels->{'schema'} ) {
							if( $listRef->{'is'} eq HEADER ) {
								if( $self->{'senderHeader'}->{ $listRef->{'type'} } ) {
									warn "The Header for this schema exists more then one time\n";
								} else {
									$self->{'senderHeader'}->{ $listRef->{'type'} } = $path;
								}
							} elsif( $listRef->{'is'} eq FOOTER ) {
								if( $self->{'senderFooter'}->{ $listRef->{'type'} } ) {
                                                                        warn "The Footer for this schema exists more then one time\n";
                                                                } else {
                                                                        $self->{'senderFooter'}->{ $listRef->{'type'} } = $path;
                                                                }

							} else {
								die "FATAL: This should never happen!\n";
							}
						}
					}
				}	
			}
			
			if( !$self->{'senderHeader'}->{ +HTML_TMPL } ) {
				$self->{'senderHeader'}->{ +HTML_TMPL } = $tmpHeader->{ +HTML_TMPL };
			}
			if( !$self->{'senderHeader'}->{ +TEXT_TMPL } ) {
                                $self->{'senderHeader'}->{ +TEXT_TMPL } = $tmpHeader->{ +TEXT_TMPL };
                        }


			if( !$self->{'senderFooter'}->{ +HTML_TMPL } ) {
				$self->{'senderFooter'}->{ +HTML_TMPL } = $tmpFooter->{ +HTML_TMPL };
			}
			if( !$self->{'senderFooter'}->{ +TEXT_TMPL } ) {
                                $self->{'senderFooter'}->{ +TEXT_TMPL } = $tmpFooter->{ +TEXT_TMPL };
                        }



		} elsif ( exists $para{'use'}->{'is'} && ( exists $para{'use'}->{'name'} || $para{'use'}->{'filename'} ) ) {
			foreach my $listRef (
                          { list => $self->{'tmplHeaderHtmlFiles'}, is => HEADER, type => HTML_TMPL },
                          { list => $self->{'tmplFooterHtmlFiles'}, is => FOOTER, type => HTML_TMPL },
                          { list => $self->{'tmplHeaderTextFiles'}, is => HEADER, type => TEXT_TMPL },
                          { list => $self->{'tmplFooterTextFiles'}, is => FOOTER, type => TEXT_TMPL }
                        ) {

				next if( $listRef->{'is'} !~ /$para{'use'}->{'is'}/i);

				if( exists $para{'use'}->{'name'} ) {
					foreach my $file ( @{ $listRef->{'list'} } ) {
						my $path = $self->{'templatePath'}.'/'.$listRef->{'type'}.'/'.$listRef->{'is'}.'/'.$file;
                                        	my $tupels = $self->_lowReadFile( $path.SUFFIX_TMPL );
						if( exists $tupels->{'name'} ) {
							if( $para{'use'}->{'name'} eq $tupels->{'name'} ) {
								if( $listRef->{'is'} eq HEADER ) {
									$self->{'senderHeader'}->{ $listRef->{'type'} } = $path;
								} elsif( $listRef->{'is'} eq FOOTER ) {
									$self->{'senderFooter'}->{ $listRef->{'type'} } = $path;
								} else {
									die "FATAL: This should never happen!\n";
								}
							}
						}
					}
				}
				if( exists $para{'use'}->{'filename'} ) {
					foreach my $file ( @{ $listRef->{'list'} } ) {
                                                my $path = $self->{'templatePath'}.'/'.$listRef->{'type'}.'/'.$listRef->{'is'}.'/'.$file;
						if( $para{'use'}->{'filename'} eq $file ) {
							if( $listRef->{'is'} eq HEADER ) {
                                                		$self->{'senderHeader'}->{ $listRef->{'type'} } = $path;
                                               		} elsif( $listRef->{'is'} eq FOOTER ) {
                                                		$self->{'senderFooter'}->{ $listRef->{'type'} } = $path;
                                                	} else {
                                                		die "FATAL: This should never happen!\n";
                                               		}
						}
                                        }
				}
			}
		} else {
			die "template: use a parameter is missing!\n";
		}
		
	}

	if(  exists $para{'get'} ) {

		# clean List, reread ...
		$self->{'tmplList'} = [];


		foreach my $listRef (
                          { list => $self->{'tmplHeaderHtmlFiles'}, is => HEADER, type => HTML_TMPL },
                          { list => $self->{'tmplFooterHtmlFiles'}, is => FOOTER, type => HTML_TMPL },
                          { list => $self->{'tmplHeaderTextFiles'}, is => HEADER, type => TEXT_TMPL },
                          { list => $self->{'tmplFooterTextFiles'}, is => FOOTER, type => TEXT_TMPL }
                        ) {


			if( exists $para{'get'}->{'is'} ) {
				next if( $para{'get'}->{'is'} ne $listRef->{'is'} );
			}

			if( exists $para{'get'}->{'type'} ) {
                                next if( $para{'get'}->{'type'} ne $listRef->{'type'} );
                        }

                        foreach my $file ( @{ $listRef->{'list'} } ) {
                        	my $path = $self->{'templatePath'}.'/'.$listRef->{'type'}.'/'.$listRef->{'is'}.'/'.$file;
                              	my $tupels = $self->_lowReadFile( $path.SUFFIX_TMPL );
	
				if( exists $para{'get'}->{'schema'} ) {
					if( exists $tupels->{'schema'} ) {
						if( $para{'get'}->{'schema'} ne "*" ) {
							next if( $para{'get'}->{'schema'} ne $tupels->{'schema'} );
						}
					} else {
						if( $para{'get'}->{'schema'} ne "*" ) {
                                                        next;
                                                }
					}
				}


				my $filename = $file;
				my $name = 'undef';
				my $schema = 'undef';

				if( exists $tupels->{'name'} ) {
					$name = $tupels->{'name'};
				}	

				if( exists $tupels->{'schema'} ) {
					$schema = $tupels->{'schema'};
				}

				push( @{ $self->{'tmplList'} },
				  { filename => $filename, name => $name, schema => $schema, is => $listRef->{'is'}, type => $listRef->{'type'} }
				);			
			}
		}	


		return @{ $self->{'tmplList'} };
	}

	if( exists $para{'remove'} ) {
		if( exists $para{'use'} ) {
			my $rm = 0;


			if( $self->{'senderHeader'}->{ +HTML_TMPL } ) {
				if( $self->_lowRemoveFile( $self->{'senderHeader'}->{ +HTML_TMPL } ) && 
				    $self->_lowRemoveFile( $self->{'senderHeader'}->{ +HTML_TMPL }.SUFFIX_TMPL ) ) {
					$rm++;
					$self->{'senderHeader'}->{ +HTML_TMPL } = undef;

					if( exists $para{'use'}->{'filename'} ) {
						my $embPath = $self->{'templatePath'}.'/'.HTML_TMPL.'/'.HTML_EMB.'/'.
							HEADER.'/'.$para{'use'}->{'filename'};
                                                	#HEADER.'/'.$para{'file'}->{'path'};
						if( -d $embPath ) {
							if( !rmtree( $embPath ) ) {
								warn "$embPath:$!\n";
							}
						}
					}
				}
			} 
			if( $self->{'senderHeader'}->{ +TEXT_TMPL } ) {
                                if( $self->_lowRemoveFile( $self->{'senderHeader'}->{ +TEXT_TMPL } ) && 
                                    $self->_lowRemoveFile( $self->{'senderHeader'}->{ +TEXT_TMPL }.SUFFIX_TMPL ) ) {
                                        $rm++;
                                        $self->{'senderHeader'}->{ +TEXT_TMPL } = undef;
                                }
                        }

			

			if( $self->{'senderFooter'}->{ +HTML_TMPL } ) {
                                if( $self->_lowRemoveFile( $self->{'senderFooter'}->{ +HTML_TMPL } ) && 
				    $self->_lowRemoveFile( $self->{'senderFooter'}->{ +HTML_TMPL }.SUFFIX_TMPL ) ) {
                                        $rm++;
					$self->{'senderFooter'}->{ +HTML_TMPL } = undef;
					if( exists $para{'use'}->{'filename'} ) {
						my $embPath = $self->{'templatePath'}.'/'.HTML_TMPL.'/'.HTML_EMB.'/'.
							FOOTER.'/'.$para{'use'}->{'filename'};
                                                	#FOOTER.'/'.$para{'file'}->{'path'};
                                        	if( -d $embPath ) {
                                                	if( !rmtree( $embPath ) ) {
                                                        	warn "$embPath:$!\n";
                                                	}
                                        	}
					}
                                }
                        }
			if( $self->{'senderFooter'}->{ +TEXT_TMPL } ) {
                                if( $self->_lowRemoveFile( $self->{'senderFooter'}->{ +TEXT_TMPL } ) && 
                                    $self->_lowRemoveFile( $self->{'senderFooter'}->{ +TEXT_TMPL }.SUFFIX_TMPL ) ) {
                                        $rm++;
                                        $self->{'senderFooter'}->{ +TEXT_TMPL } = undef;
                                }
                        }

			return $rm;
		} else {
			die "template: We need 'use' for 'remove'\n";
		}
	}

	if( exists $para{'reread'} ) {
                $self->{'tmplHeaderHtmlFiles'} = [];
                $self->{'tmplHeaderTextFiles'} = []; 
                $self->{'tmplFooterHtmlFiles'} = [];
                $self->{'tmplFooterTextFiles'} = [];
                $self->_lowReadTemplates();
        }
}


sub list {
	my ($self, %para) = @_;

	if( exists $para{'path'} ) {
                if( -d $para{'path'} ) {
                        $self->{'listPath'} = $para{'path'};
			$self->_lowReadLists();
                } else {
                        warn "List: Path [$para{'path'}] does not exists. Try to create\n";
                        if( mkpath( $para{'path'} ) ) {
				 $self->{'listPath'} = $para{'path'};
			} else {
				warn "Failed!\n";
			}
                }
        }

	if( exists $para{'list'} ) {
		if( exists $para{'list'}->{'name'} ) {

			if(! $self->_lowValidListName( $para{'list'}->{'name'} ) ) {
				warn "Not a valid list name\n";
				return 0;
			}

			if( -d $self->{'listPath'}.'/'.$para{'list'}->{'name'} ) {
				$self->_lowReadListMembers( $para{'list'}->{'name'} );
				$self->{'listCurrent'} = $para{'list'}->{'name'};
			} else {
				mkpath( $self->{'listPath'}.'/'.$para{'list'}->{'name'} );
				$self->_lowReadLists();
			}
		}
	}

	if( exists $para{'member'} ) {
                if( exists $para{'member'}->{'listname'} &&
		    exists $para{'member'}->{'mail'} 
		) {
			if( -d $self->{'listPath'}.'/'.$para{'member'}->{'listname'} ) {
				if( $self->_lowValidMailAddress( $para{'member'}->{'mail'} ) ) {
	         			$self->_lowWriteFile( $self->{'listPath'}.'/'.$para{'member'}->{'listname'}.'/'.$para{'member'}->{'mail'}, $para{'member'} ); 
					if( !exists $para{'member'}->{'rereadOff'} ) {
						$self->_lowReadListMembers( $para{'member'}->{'listname'} );
					}
					$self->{'listCurrent'} = $para{'member'}->{'listname'};
				} else {
					warn "Not a valid Mail Address [$para{'member'}->{'mail'}]\n";
				}
			} else {
				warn "You want add a member to a list [$para{'member'}->{'listname'}] which does not exists\n";
				return 0;
			}
                }
        }

	if( exists $para{'remove'} ) {
		# list = value : remove whole list
		# member = value && list = value : remove member from list  
		if( exists $para{'remove'}->{'listname'} && 
		    ! exists $para{'remove'}->{'mail'}
		) {
			if( defined $para{'remove'}->{'listname'} ) {
				if( -d $self->{'listPath'}.'/'.$para{'remove'}->{'listname'} ) {
					if(! rmtree( $self->{'listPath'}.'/'.$para{'remove'}->{'listname'} ) ) {
						warn "Could not remove list [$para{'remove'}->{'listname'}]\n";
					}
				} else {
					warn "The list [$para{'remove'}->{'listname'}] you tried to remove does not exists\n";
				}
			} else {
				warn "The listname to remove was empty!\n";
			}
		}
		if( exists $para{'remove'}->{'listname'} && 
                    exists $para{'remove'}->{'mail'}
                ) {
			if( -e $self->{'listPath'}.'/'.$para{'remove'}->{'listname'}.'/'.$para{'remove'}->{'mail'} ) {
				if(! unlink( $self->{'listPath'}.'/'.$para{'remove'}->{'listname'}.'/'.$para{'remove'}->{'mail'} ) ) {
					warn "Could not remove [$para{'remove'}->{'mail'}]\n";
				}
			} else {
				warn "The selected mail adr [$para{'remove'}->{'mail'}] does not exists\n";
			}
			$self->_lowReadListMembers( $para{'remove'}->{'listname'} );
                }
        }

	if( exists $para{'empty'} ) {
		$self->_lowUnloadListMember('all');
	}

	if( exists $para{'get'} ) {
		if( $para{'get'} eq "listnames") {
			return @{ $self->{'listNames'} };
		} else {
			if( exists $self->{'listMembers'}->{ $para{'get'} } ) {
				return @{ $self->{'listMembers'}->{ $para{'get'} } };
			} else {
				warn "This [$para{'get'}] list does not exist\n";
				return 0;
			}
		}
	}

	if( exists $para{'count'} ) {
		$para{'count'} =~ s/@/\\@/g;
		my $str = qx "ls $self->{'listPath'}/$para{'count'} | wc -l 2>&1";
		$str =~ s/[^\d]//g;
		return $str;
	}
	

	if( exists $para{'reread'} ) {
		$self->{'listNames'} = [];
                $self->_lowReadLists();
        }

	return 1;
}


sub archiv {
	my ($self, %para) = @_;
	
	if( exists $para{'path'} ) { 
                if( -d $para{'path'} ) {
                        $self->{'archivPath'} = $para{'path'};
                } else {
                        warn "archiv: Path [$para{'path'}] does not exists. Try to create\n";
                        if( mkpath( $para{'path'} ) ) {
                                 $self->{'archivPath'} = $para{'path'};
                        } else {
                                die "Failed!\n";
                        } 
                }
        }

	if( exists $para{'save'} ) {
		my $now_string = strftime '%a-%b-%d-%H:%M:%S-%Y', localtime;
		#my $now_string = strftime '%d-%m-%Y-%H:%M:%S', localtime;
		my $subject = $self->{'senderSubject'};
		$subject =~ s/\s/_/g;
		$subject =~ s/\!/_/g;
		$subject =~ s/\?/_/g;
		if( mkpath( $self->{'archivPath'}."/".$now_string."_".$subject ) ) {
			my $mailFile = $self->previewMailFile( preview => 1 );
			$self->previewMailFileExplode( $mailFile );
			$self->_lowCopy( $self->{'previewPath'}.'/*', $self->{'archivPath'}."/".$now_string."_".$subject, 1);

			if( -e $self->{'archivPath'}."/".$now_string."_".$subject."/explode/file.html") {
				warn qx "perl -pi -e 's/cid://g;' $self->{'archivPath'}/$now_string\_$subject/explode/file.html 2>&1"; 
			}

			$self->_lowWrite( time() , $self->{'archivPath'}."/".$now_string."_".$subject."/timestmp.txt" );
			$self->_lowWrite( $self->{'listCurrent'}, $self->{'archivPath'}."/".$now_string."_".$subject."/list.txt" );
			$self->_lowRemoveFile( $self->{'archivPath'}."/".$now_string."_".$subject."/file.tmp" );

		} else {
			die "could not create Dir [".$now_string."_".$subject."]\n";
		}
	}

	if( exists $para{'get'} ) {
		if( $para{'get'} eq "mails" ) {
			#return $self->_lowReadDir( $self->{'archivPath'} );	
			my @mails = $self->_lowReadDir( $self->{'archivPath'} );
			my %mailByTimeStmp = ();

			foreach my $m (@mails) {
				my $time = $self->_lowRead( $self->{'archivPath'}."/$m/timestmp.txt" );
				chomp $time;
				$mailByTimeStmp{ $time } = $m; 
			}

			return %mailByTimeStmp;
		} 
		elsif( $para{'get'} eq "archivPath" ) {
			return $self->{'archivPath'};
		}
	}
}


sub _lowReadTemplates {
	my ($self) = @_;
	if( -d $self->{'templatePath'}.'/'.HTML_TMPL.'/'.HEADER ) {
		push( @{ $self->{'tmplHeaderHtmlFiles'} }, $self->_lowReadTemplateDir( $self->{'templatePath'}.'/'.HTML_TMPL.'/'.HEADER ) );
	} else {
		mkpath( $self->{'templatePath'}.'/'.HTML_TMPL.'/'.HEADER );
	}

	if( -d $self->{'templatePath'}.'/'.TEXT_TMPL.'/'.HEADER ) {
                push( @{ $self->{'tmplHeaderTextFiles'} }, $self->_lowReadTemplateDir( $self->{'templatePath'}.'/'.TEXT_TMPL.'/'.HEADER ) );
        } else {
		mkpath( $self->{'templatePath'}.'/'.TEXT_TMPL.'/'.HEADER );
        }


	if( -d $self->{'templatePath'}.'/'.HTML_TMPL.'/'.FOOTER ) {
                push( @{ $self->{'tmplFooterHtmlFiles'} }, $self->_lowReadTemplateDir( $self->{'templatePath'}.'/'.HTML_TMPL.'/'.FOOTER ) );
        } else {
		mkpath( $self->{'templatePath'}.'/'.HTML_TMPL.'/'.FOOTER );
        }

        if( -d $self->{'templatePath'}.'/'.TEXT_TMPL.'/'.FOOTER ) {
                push( @{ $self->{'tmplFooterTextFiles'} }, $self->_lowReadTemplateDir( $self->{'templatePath'}.'/'.TEXT_TMPL.'/'.FOOTER ) );
        } else {
		mkpath( $self->{'templatePath'}.'/'.TEXT_TMPL.'/'.FOOTER );
        }

	# Embedded files in html
	if(! -d $self->{'templatePath'}.'/'.HTML_TMPL.'/'.HTML_EMB ) {
		mkpath( $self->{'templatePath'}.'/'.HTML_TMPL.'/'.HTML_EMB );
		mkpath( $self->{'templatePath'}.'/'.HTML_TMPL.'/'.HTML_EMB.'/'.HEADER );
		mkpath( $self->{'templatePath'}.'/'.HTML_TMPL.'/'.HTML_EMB.'/'.FOOTER );
	}
}


sub _lowReadTemplateDir {
	my ($self, $path) = @_;
	my @files = $self->_lowReadDir( $path );
	my @tmplFiles = ();
	my $regExpConst = SUFFIX_TMPL;
	foreach my $f ( @files ) {
		if( $f !~/$regExpConst$/) {
			push(@tmplFiles, $f);
		}
	}
	return @tmplFiles;
}


sub _lowReadLists {
	my ($self) = @_;
	push( @{ $self->{'listNames'} }, $self->_lowReadDir( $self->{'listPath'} ) );
}


sub _lowReadListMembers {
        my ($self, $listname) = @_;

	my @member = $self->_lowReadDir( $self->{'listPath'}.'/'.$listname );

	# reset
	$self->{'listMembers'}->{ $listname } = [];
	$self->{'senderFrom'} = $listname;

	foreach my $m ( @member ) {
		push( @{ $self->{'listMembers'}->{ $listname } },
		      $self->_lowReadFile( $self->{'listPath'}.'/'.$listname.'/'.$m ) );
	}

	# load Mail addr to sender
	if( $self->{'sender'} ) {
		foreach my $m ( @member ) {
			#$self->addAddress( address => $m, addressType => 'To' );
			$self->addAddress( address => $m, addressType => 'Bcc' );
		}
	}
}


sub _lowUnloadListMember {
	my ($self, $listname) = @_;

	if($listname eq "all") {
		$self->addAddress( empty => 1, addressType => 'To' );
	} else {
		#TODO
	}
}


sub _lowReadDir {
	my ($self, $dir) = @_;
	opendir( DIR, $dir ) or die "Could not open [$dir]: $!\n";
        my @tmp = readdir( DIR );
	my @ret = ();
	foreach my $entry ( @tmp ) {
                next if( $entry eq "." || $entry eq "..");
		push(@ret, $entry);
	}
        closedir( DIR );
	return @ret;
}


sub _lowEmptyDir {
	my ($self, $dir) = @_;
	my @files = $self->_lowReadDir($dir);
	foreach my $f ( @files ) {
		$self->_lowRemoveFile("$dir/$f");
	}
}


sub _lowReadFile ($$) {
        my ($self, $file) = @_;
        if ( open(FILE, "<$file") ) {
                my $firstLine = '';
                while( defined(my $line=<FILE>) ) {
                        $firstLine .= $line;
                }
                close(FILE);

                # remove special sign
                $firstLine =~s/\r//mg;
                #warn "[$firstLine]\n";

                my @tupels = split(/\n/, $firstLine);
                my $tupelHash = {};
                foreach my $tupel ( @tupels ) {
                        my @keyValue = split(/=/, $tupel);
                        $tupelHash->{ $keyValue[0] } =  $keyValue[1];
                }
                return $tupelHash;
        } else {
                die "_lowReadFile [$file], $!\n";
        }
}


sub _lowWriteFile ($$$) {
        my ($self, $file, $refHash) = @_;
        if ( open(FILE, ">$file") ) {
		foreach my $key (keys %{ $refHash } ) {
			#print "$key=$refHash->{$key}\n";
			print FILE "$key=$refHash->{$key}\n"; 
		}
		close(FILE);
        } else {
                die "_lowWriteFile [$file], $!\n";
        }
}


sub _lowCopy {
	my ($self, $from, $to, $recursive ) = @_;
	
	if( $recursive ) {
		#warn "[$from] [$to]\n";
		warn qx "cp -r $from $to 2>&1";
	} else {
		warn qx "cp $from $to 2>&1";
	}
}


sub _lowRemoveFile ($$) {
	my ($self, $path ) = @_;

        if( -e $path ) {
        	if( unlink( $path ) ) {
			return 1;
		} else {
                	warn "Could not unlink [$path]\n";
		}
       	} else {
        	warn "Could not find [$path]\n";
        } 

	return 0;
}


sub _lowPrepairSend {
	my ($self) = @_;
	
	if( -e $self->{'bodyPath'}.'/subject.txt' ) {
		$self->{'senderSubject'} = $self->_lowRead( $self->{'bodyPath'}.'/subject.txt' );
	} else {
		warn "No Subject found!\n";
	}

	#$self->{'sender'}->attach( Subject => $self->{'senderSubject'} );
	$self->{'sender'}->add( Subject => $self->{'senderSubject'} );

	if( $self->{'senderType'} eq "multipart/mixed" ) {
                my $msgStrText = '';
		my $msgStrHtml = '';
                my $textPart = $self->{'sender'}->attach(
                        Type => 'multipart/alternative'
                );


                if( exists $self->{'senderHeader'}->{ +TEXT_TMPL } ) {
			if( $self->{'senderHeader'}->{ +TEXT_TMPL } ) {
	                        $msgStrText .= $self->_lowRead( $self->{'senderHeader'}->{ +TEXT_TMPL } );
			}
                }

		foreach my $bodyFile ( $self->_lowReadDir( $self->{'bodyPath'}.'/'.TEXT_TMPL ) ) {
                        $msgStrText .= $self->_lowRead( $self->{'bodyPath'}.'/'.TEXT_TMPL.'/'.$bodyFile);
                }

                if( exists $self->{'senderFooter'}->{ +TEXT_TMPL } ) {
			if( $self->{'senderFooter'}->{ +TEXT_TMPL } ) {
	                        $msgStrText .= $self->_lowRead( $self->{'senderFooter'}->{ +TEXT_TMPL } );
			}
                }

		if( !$msgStrText ) {
			warn "_lowPrepairSend: try to send multipart but text part is missing!\n";
			return 0;
		}

                $textPart->attach(
                        Type => 'text/plain',
                        Data => $msgStrText,
                );



		my $htmlPart = $textPart->attach(
                        Type => 'multipart/related'
                );

		my @imgParts = ();

		if( exists $self->{'senderHeader'}->{ +HTML_TMPL } ) {
			if( $self->{'senderHeader'}->{ +HTML_TMPL } ) {
	                        $msgStrHtml .= $self->_lowRead( $self->{'senderHeader'}->{ +HTML_TMPL } );
				push( @imgParts, $self->_lowReadEmbeddedFiles( $self->{'senderHeader'}->{ +HTML_TMPL }) );
			}
                }

		foreach my $bodyFile ( $self->_lowReadDir( $self->{'bodyPath'}.'/'.HTML_TMPL ) ) {
			$msgStrHtml .= $self->_lowRead( $self->{'bodyPath'}.'/'.HTML_TMPL.'/'.$bodyFile);
		}
		push( @imgParts, $self->_lowReadEmbeddedFilesBody( $self->{'bodyPath'}.'/'.HTML_EMB ) );

                if( exists $self->{'senderFooter'}->{ +HTML_TMPL } ) {
			if( $self->{'senderFooter'}->{ +HTML_TMPL } ) {
	                        $msgStrHtml .= $self->_lowRead( $self->{'senderFooter'}->{ +HTML_TMPL } );
				push( @imgParts, $self->_lowReadEmbeddedFiles( $self->{'senderFooter'}->{ +HTML_TMPL } ) );
			}
                }


		if( !$msgStrHtml ) {
                        warn "_lowPrepairSend: try to send multipart but html part is missing!\n";
                        return 0;
                }

		$htmlPart->attach(
			Type => 'text/html',
			Data => $msgStrHtml
		);

		foreach my $part ( @imgParts ) {
			$htmlPart->attach($part);
		}

        }

	elsif( $self->{'senderType'} eq "text" ) {
		my $msgStrText = '';

                if( exists $self->{'senderHeader'}->{ +TEXT_TMPL } ) {
			if( $self->{'senderHeader'}->{ +TEXT_TMPL } ) {
	                        $msgStrText .= $self->_lowRead( $self->{'senderHeader'}->{ +TEXT_TMPL } );
			}
                }

                foreach my $bodyFile ( $self->_lowReadDir( $self->{'bodyPath'}.'/'.TEXT_TMPL ) ) {
                        $msgStrText .= $self->_lowRead( $self->{'bodyPath'}.'/'.TEXT_TMPL.'/'.$bodyFile);
                }

                if( exists $self->{'senderFooter'}->{ +TEXT_TMPL } ) {
			if( $self->{'senderFooter'}->{ +TEXT_TMPL } ) {
	                        $msgStrText .= $self->_lowRead( $self->{'senderFooter'}->{ +TEXT_TMPL } );
			}
                }

		if( !$msgStrText ) {
                        warn "_lowPrepairSend: try to send but text part is missing!\n";
                        return 0;
                }

		$self->{'sender'} = MIME::Lite->new(
                	Type => $self->{'senderType'},
			Data => $msgStrText	
                );

		$self->{'sender'}->add( Subject => $self->{'senderSubject'} );

	#	$self->{'sender'}->attach(
        #                Type => 'text/plain',
	#		Data => $msgStrText
        #        );

	}

	elsif( $self->{'senderType'} eq "html" || $self->{'senderType'} eq "multipart/related") {
		my $msgStrHtml = '';
		my @imgParts = ();

                if( exists $self->{'senderHeader'}->{ +HTML_TMPL } ) {
			if( $self->{'senderHeader'}->{ +HTML_TMPL } ) {
	                        $msgStrHtml .= $self->_lowRead( $self->{'senderHeader'}->{ +HTML_TMPL } );
        	                push( @imgParts, $self->_lowReadEmbeddedFiles( $self->{'senderHeader'}->{ +HTML_TMPL } ) );
			}
                }

                foreach my $bodyFile ( $self->_lowReadDir( $self->{'bodyPath'}.'/'.HTML_TMPL ) ) {
                        $msgStrHtml .= $self->_lowRead( $self->{'bodyPath'}.'/'.HTML_TMPL.'/'.$bodyFile);
                }
                push( @imgParts, $self->_lowReadEmbeddedFilesBody( $self->{'bodyPath'}.'/'.HTML_EMB ) );

                if( exists $self->{'senderFooter'}->{ +HTML_TMPL } ) {
			if( $self->{'senderFooter'}->{ +HTML_TMPL } ) {
	                        $msgStrHtml .= $self->_lowRead( $self->{'senderFooter'}->{ +HTML_TMPL } );
        	                push( @imgParts, $self->_lowReadEmbeddedFiles( $self->{'senderFooter'}->{ +HTML_TMPL } ) );
			}
                }

		#warn "##$msgStrHtml";

		if( !$msgStrHtml ) {
                        warn "_lowPrepairSend: try to send but html part is missing!\n";
                        return 0;
                }

		$self->{'sender'}->attach(
                        Type => 'text/html',
			Data => $msgStrHtml
                );

		foreach my $part ( @imgParts ) {
                         $self->{'sender'}->attach($part);
                }

	}

	else {
		warn "Sender Type is wrong! [$self->{'senderType'}]\n";
		return 0;
	}

	return 1;
}


sub _lowReadEmbeddedFiles {
	my ($self, $path) = @_;
	my $tupels = $self->_lowReadFile($path.SUFFIX_TMPL);
	my @files = split(/,/, $tupels->{'embedded'} );
	my $ft = File::Type->new();
	my @attachedPart = ();
	foreach my $file (@files) {
		my $embPath = $self->{'templatePath'}.'/'.HTML_TMPL.'/'.HTML_EMB.'/'.
				(uc $tupels->{'is'}.'/'.$tupels->{'fileName'}).'/'.$file;
		push(@attachedPart,
			MIME::Lite->new(
				Type => $ft->checktype_filename( $embPath ),
                       		Id   => $file,
                        	Path => $embPath
                        )
		);
	}

	return @attachedPart;
}


sub _lowReadEmbeddedFilesBody {
        my ($self, $path) = @_;
        my $ft = File::Type->new();
	my @attachedPart = ();
        foreach my $file ( $self->_lowReadDir( $path ) ) {
                my $embPath = $path.'/'.$file;
		push(@attachedPart, 
                        MIME::Lite->new(
                                Type => $ft->checktype_filename( $embPath ),
                                Id   => $file,
                                Path => $embPath
                        )
                );

        }

	return @attachedPart;
}


sub _lowRead ($$) {
	my ($self, $path ) = @_;

	if( ! $path ) {
		warn "_lowRead: path is empty\n";
		return "";
	}

	if ( open(FILE, "<$path") ) {
		my $buffer = '';
		while( defined(my $line=<FILE>) ) {
                        $buffer .= $line;
                }
		close(FILE);
		return $buffer;
	} else {
		warn "_lowRead: Could not open [$path],$!\n";
		return "";
	}	
}


sub _lowWrite ($$$) {
	my ($self, $data, $path) = @_;

	if ( open(FILE, ">$path") ) {
		print FILE $data;
                close(FILE);
        } else {
                warn "_lowWite: Could not open [$path],$!\n";
                return 0;
        }

}	


sub _lowBodyEmbedded {
	my ($self, $embedded) = @_;

	if( !$embedded ) {
		warn "_lowBodyEmbedded: empty parameter!\n";
		return 0;
	}

	my $embPath = $self->{'bodyPath'}.'/'.HTML_EMB;

	$self->_lowEmptyDir( $embPath );
                                      
        if( ref $embedded eq "ARRAY" ) {
	        foreach my $emb ( @{ $embedded } ) {
        	        $self->_lowCopy( $emb, $embPath );
                }
     	} else {
       		$self->_lowCopy( $embedded, $embPath );
        }

}


sub _lowAddAddress {
	my ($self, $mail, $type) = @_;

	foreach my $adr ( @{ $self->{'senderAddressList'}->{ $type } } ) {
		if( $adr eq $mail) {
			#warn "_lowAddAddress: [$mail] already in Mail address list for type [$type]!\n";
			return 0;
		}
	}
	push( @{ $self->{'senderAddressList'}->{ $type } }, $mail );
	return 1;
}


sub _lowValidListName {
	my ($self, $name) = @_;
	if( $name =~ /^([\w\d_\.\-]+\@[\w\d_\.\-]+)$/i ) {
		#if( $name =~ /[\, ]/) {
		#	return 0;
		#} else {
		#	return 1;
		#}
		if($1) {
			#warn "--$1\n";
			return 1;
		} else {
			return 0;
		}

	} else {
		return 0;
	}
}


sub _lowValidMailAddress {
	my ($self, $name) = @_;
	return $self->_lowValidListName( $name );
}

sub _lowSend {
    my ($self, @args) = @_;

    ### We need the "From:" and "To:" headers to pass to the SMTP mailer:
    my $hdr  = $self->{'sender'}->fields();
    my $from = $self->{'sender'}->get('From');
    my $to   = $self->{'sender'}->get('To');

    ### Sanity check:
    defined($to) or Carp::croak "send_by_smtp: missing 'To:' address\n";


    ### Get the destinations as a simple array of addresses:
    my @to_all = MIME::Lite::extract_addrs($to);
    if ($MIME::Lite::AUTO_CC) {
        foreach my $field (qw(Cc Bcc)) {
            my $value = $self->{'sender'}->get($field);
            push @to_all, MIME::Lite::extract_addrs($value) if defined($value);
        }
    }

    ### Create SMTP client:
    require Net::SMTP;
    my $smtp = MIME::Lite::SMTP->new(@args)
        or Carp::croak("Failed to connect to mail server: $!\n");
    $smtp->mail($from)
        or Carp::croak("SMTP MAIL command failed: $!\n".$smtp->message."\n");
    #do not skip on bad
    #$smtp->to(@to_all)
    $smtp->to(@to_all, { SkipBad => 1 } )
        or Carp::croak("SMTP RCPT command failed: $!\n".$smtp->message."\n");
    $smtp->data()
        or Carp::croak("SMTP DATA command failed: $!\n".$smtp->message."\n");

    ### MIME::Lite can print() to anything with a print() method:
    $self->{'sender'}->print_for_smtp($smtp);
    $smtp->dataend();
    $smtp->quit;
    1;
}






=head1 NAME

Newsletter - A Simple website based Newsletter interface!

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

The backend module for the newsletter web interface

Perhaps a little code snippet.

    use Newsletter;

    my $foo = Newsletter->new();
    ...

More docu is coming ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 EXAMPLE

    #!/usr/bin/perl -w

    use strict;
    use Newsletter;

    my $news = Newsletter->new;

    $news->template( path => '/tmp/newsletter' );

    $news->template( 
	file => {
		# u need
		path => 'test/myHeader.html',
		type => 'html',
		is => 'header',

		# here starts the optional Params
		name => 'My Header Name',
		schema => 'My First Template',
		embedded => '/tmp/opera.jpg'

		# here starts self defined Params
		# ...
	}
    );

    $news->template(
	use => {
		schema => 'My First Template'
	}
    );

    $news->template(
        use => {
		is => 'header',
                name => 'My Header Name'
        }
    );

    $news->template(
        use => {
                is => 'header',
                filename => 'myHeader.txt'
        }
    );

    #print $news->template(
    #        use => {
    #                is => 'header',
    #                filename => 'myHeader.html'
    #        },
    #	remove => 1
    #);


    #print $news->{'senderHeader'}->{'HTML'}, "\n";


    #######################################################
    # TEST List
    #######################################################

    $news->list(
	path => '/tmp/newsletter/list'
    );

    $news->list(
	list => {
		name => 'the-top@foo.bar'
	}
    );

    $news->list(
      	member => {
		# u need
		listname => 'the-top@foo.bar',
		mail => 'foo@bar.bla'
	}
    );

    $news->list(
        member => {
                # u need
                listname => 'the-top@foo.bar',
                mail => 'hello@world.bla'
        }
    );

    $news->list(
        remove => {
		# remove one member
                listname => 'the-top@foo.bar',
                mail => 'hello@world.bla'
        }
    );

    $news->list(
        remove => {
		# remove whole list
                listname => 'the-top@foo.bar',
        }
    );


    ############################################
    # Test Send
    ############################################

    $news->list(
	empty => 1,
        path => '/tmp/newsletter/list'
    );

    $news->list(
        list => {
                name => 'news@vienna-marathon.com',
        }
    );

    $news->list(
        member => {
                # u need
                listname => 'news@vienna-marathon.com',
                mail => 'dominik@soft.uni-linz.ac.at'
        }
    );

    $news->body(
	path => '/tmp/newsletter/body'
    );

    $news->body(
	subject => 'A test mail!',
	file => {
		path => 'test/myBody.html',
		type => 'html',
		embedded => '/tmp/opera.jpg'
	}	
    ); 

    $news->body(
        file => {
                path => 'test/myBody.txt',
                type => 'text',
        }
    );


    $news->sender(
        smtp => 'soft.uni-linz.ac.at'
    );

    my $sender = $news->buildMail();

    #print $sender->as_string;
    #print "\n";

    $news->send();





=head1 AUTHOR

Dominik Hochreiter, C<< <dominik at soft.uni-linz.ac.at> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-newsletter at rt.cpan.org>, or through the web interface at
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

1; # End of Newsletter
