package Newsletter::Html::Templ;

use warnings;

use strict;
use CGI;
use Newsletter;
use File::Path;
use File::Type;

sub init {
	my ($self) = @_;
	$self->{'cgi'} = new CGI;
}


sub forumBegin {
	my ($self, %param) = @_;
	$self->_out( $self->{'cgi'}->start_form( -method=> 'GET', %param ) );
}


sub forumEnd {
	my ($self) = @_;
	$self->_out( "</form>" );
}


sub startpage {
	my ($self) = @_;



	$self->forumBegin;
	$self->_out( qq~
        <table cellspacing="1" cellpadding="1" border="0" width="900" height="400">
          <tr>
            <td valign="top" width="300" class="nlTdDarker">
	      <h2>Email Lists</h2>
	      <table cellspacing="5" cellpadding="0" border="0">
		<tr>
		  <td>
		    <h3>Available Lists</h3> 
		    <select name="pOpenList" size="10" class="nlSelect">	    
	~);
			foreach my $name ( $self->{'nl'}->list( get => "listnames") ) {
				
				my $memebersCount = $self->{'nl'}->list( count => $name);

				if( exists $self->{'persistent'}->{"pOpenList"} ) {
					if( $self->{'persistent'}->{"pOpenList"} eq $name ) {
		     				$self->_out( qq~ 
				  	 	<option value=$name selected>$name [$memebersCount]</option>
						~);
					} else {
						$self->_out( qq~
                                                <option value=$name>$name [$memebersCount]</option>
                                                ~);
					}
				} else {
					$self->_out( qq~
                                         <option value=$name>$name [$memebersCount]</option>
                                        ~);
				}   	
			}
	$self->_out( qq~
		  </select><br>
		  <input type="radio" name="pSection" value="sendList" checked="checked">Send
		  <input type="radio" name="pSection" value="openList">Edit
		  <br><br>
		  <input type="submit" value="open list" class="nlInput"><br><br>
		  </td>
		</tr>
	~);
	$self->forumEnd;
	$self->forumBegin;
	$self->_out( qq~
		<tr>
                  <td>
		    <h3>Create a new Newsletter List</h3>
              	    <b>List</b> <input type="text" name="pOpenList">
                    <input type="hidden" name="pSection" value="openList">
                    <input type="submit" value="create/load"><br>
                    List name is equal to the "from" field in the email! E.g. a valid list name: foo\@bar.com
		  </td>
		</tr>
              </table>
	    </td>
	~);
	$self->forumEnd;


        $self->forumBegin;
	$self->_out( qq~
	    <td valign="top" width="300" class="nlTdLighter">
	      <h2>Email Templates</h2>
	      <table cellspacing="5" cellpadding="0" border="0">
                <tr>
                  <td>
                    <h3>Schema</h3>
                    <select name="pOpenSchema" size="6" class="nlSelect">
	~);

			my %short = (
				+HEADER => 'H',
        			+FOOTER => 'F'
			);

			my %already = ();

			foreach my $name ( $self->{'nl'}->template( get => { schema => "*" } ) ) {
				next if( exists $already{ $name->{'schema'} } );	
				next if( $name->{'schema'} eq 'undef' );

				if( exists $self->{'persistent'}->{"pOpenSchema"} ) {
					if( $self->{'persistent'}->{"pOpenSchema"} eq $name->{'schema'}) {
	                                	$self->_out( qq~
      	  	                          	<option value="$name->{'schema'}" selected>
					  	$name->{'schema'} 
					  	</option>
                                		~);
					} else {
						$self->_out( qq~
                                                <option value="$name->{'schema'}">
                                                $name->{'schema'}
                                                </option>
                                                ~);
					}
				} else {
					$self->_out( qq~
                                          <option value="$name->{'schema'}">
                                          $name->{'schema'}
                                          </option>
                                        ~);
				}

				$already{ $name->{'schema'} } = 1;
                        }

	$self->_out( qq~
		    </select><br>
		    <input type="submit" value="load Schema" class="nlInput"><br>
		  </td>
	        </tr>
	        <tr>
                  <td>
                    <h3>All Files</h3>
                    <select name="plOpenFile" size="6" class="nlSelect" multiple>
	~);
			foreach my $name ( $self->{'nl'}->template( get => {} ) ) {
				if( exists $self->{'persistent'}->{"plOpenFile"} ) {

					my $found = 0;
					foreach my $tf ( @{ $self->{'persistent'}->{"plOpenFile"} } ) {
						if( $tf eq $name->{'filename'}.'-is-'.$name->{'is'} ) {
							$found = 1;
							last;
						}					
					}

					if( $found == 1) {
                                		$self->_out( qq~
                                  		<option value="$name->{'filename'}-is-$name->{'is'}" selected>
                                  		[$name->{'filename'}] [$short{$name->{'is'}}] [$name->{'type'}]
                                  		</option>
                                		~);
					} else {
						$self->_out( qq~
                                                <option value="$name->{'filename'}-is-$name->{'is'}">
                                                [$name->{'filename'}] [$short{$name->{'is'}}] [$name->{'type'}]
                                                </option>
                                                ~);
					}
				} else {
					$self->_out( qq~
                                        <option value="$name->{'filename'}-is-$name->{'is'}">
                                        [$name->{'filename'}] [$short{$name->{'is'}}] [$name->{'type'}]
                                        </option>
                                        ~);
				}
                        }

	$self->_out( qq~
                    </select><br>
		    <input type="hidden" name="pSection" value="home">
		    <input type="submit" value="load selected" class="nlInput"><br>
		    [H]=Header [F]=Footer<br>
	~);
	$self->forumEnd;


	$self->forumBegin;
	$self->_out( qq~
		<input type="hidden" name="pOpenSchema" value="">
		<input type="hidden" name="plOpenFile" value="">
		<input type="submit" value="unload selected" class="nlInput"><br><br><br>
	~);
	$self->forumEnd;


	$self->forumBegin;
	$self->_out( qq~
		    <input type="hidden" name="pSection" value="editTmpl">
		    <input type="submit" value="Edit" class="nlInput">
                  </td>
                </tr>
	      </table>
	    </td>
	 ~ );

	$self->forumEnd;

	$self->_out( qq~
	    <td valign="top" width="300" class="nlTdDarker">
              <h2>Email Archiv</h2>
	      <table cellspacing="5" cellpadding="0" border="0">
                <tr>
                  <td>
	~ );
		my $path = $self->{'nl'}->archiv( get => "archivPath" );
		my %mailByTime = $self->{'nl'}->archiv( get => "mails" );
		my $countMail = 8;
		foreach my $mail ( sort {$b cmp $a} keys %mailByTime ) {
			$mailByTime{ $mail } =~/(.+\d\d\d\d)\_(.*)/;
			my $mailDate = $1;
			my $linkName = $2;
			$self->_out( 
				qq~ <a href="$path/$mailByTime{ $mail }">[$linkName]</a> 
			~ );

			if( -e "$path/$mailByTime{ $mail }/explode/file.html") {
				$self->_out(
                                	qq~ <a href="$path/$mailByTime{ $mail }/explode/file.html">[html]</a>    
                        	~ );
			}
			
			if( -e "$path/$mailByTime{ $mail }/explode/file.txt") {
                                $self->_out(
                                        qq~ <a href="$path/$mailByTime{ $mail }/explode/file.txt">[text]</a>                    
                                ~ );
                        }

			$self->_out(
                                qq~ <br>($mailDate)<br>
                        ~ );

			last if($countMail == 0);
			$countMail--;
		}


	$self->_out( qq~
		   <br><br><a href="$path">[ complete archiv ]</a>
		  </td>
		</tr>
	      </table>
            </td>
	  </tr>
	</table>
	~ );

	if( $self->{'nl'}->error ) {
        	$self->_info( $self->{'nl'}->error );
        }

}


sub openList {
	my ($self) = @_;

	my $listname = $self->{'persistent'}->{"pOpenList"};

	$self->forumBegin;
        $self->_out( qq~
        
        <table cellspacing="1" cellpadding="1" border="0" width="600" height="400">
          <tr>
            <td valign="top" width="300" class="nlTdDarker">
              <h2>List Members from</h2><b>$listname</b><br>
	      search <input type="text" name="searchList"><br><br>
	      <select name="openListMembers" size="18" class="nlSelect" multiple>
	~);

		if( $self->{'cgi'}->param("searchList") ) {
			my $search = $self->{'cgi'}->param("searchList");
			foreach my $name ( $self->{'nl'}->list( get => $listname) ) {
                                last if( ref($name) ne "HASH" );
				next if( $name->{'mail'} !~ /$search/ );
                                $self->_out( qq~
                                  <option>$name->{'mail'}</option>
                                ~);
                        }
		} else {
			foreach my $name ( $self->{'nl'}->list( get => $listname) ) {
				last if( ref($name) ne "HASH" );
                		$self->_out( qq~
                                  <option>$name->{'mail'}</option>
                        	~);
                	}
		}		

	$self->_out( qq~
	      </select><br>
	      <input type="radio" name="pSection" value="openList" checked="checked">search
	      <input type="radio" name="pSection" value="delFromList">Selected delete
	      <br><br>
	      <input type="submit" value="Make" class="nlInput">
            </td>
            <td valign="top" class="nlTdLighter">
              <table cellspacing="0" cellpadding="0" border="0">
                <tr>
                  <td>
                    <h2>Add new members</h2> 
	~ );
	$self->forumEnd;

	$self->forumBegin;
		for( my $m = 1; $m < 7; $m++ ) {
			my $formatedNr = sprintf("%04d",$m);
			$self->_out( qq~
			  <input type="text" name="newMember$formatedNr" class="nlInput"><br><br>
			~);
		}

	$self->_out( qq~
		    <input type="hidden" name="pSection" value="addToList">
		    <input type="submit" value="Add to list" class="nlInput">
	~ );
	$self->forumEnd;

	if( $listname ) {
		$self->forumBegin;
		$self->_out( qq~
			    <br><h2>Delete List</h2>
			    Delete:<input type="radio" name="pSection" value="openList" checked="checked">No
              		    <input type="radio" name="pSection" value="deleteList">Yes<br><br>
			    <input type="hidden" name="listName" value="$listname">
			    <input type="hidden" name="pOpenList" value="">
                    	    <input type="submit" value="delete [$listname]" class="nlInput">
		~ );
 		$self->forumEnd;
	}

	$self->_out( qq~
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
        ~ );

	if( $self->{'nl'}->error ) {
        	$self->_info( $self->{'nl'}->error(1) );
       	}

}


sub editTmpl {
	my ($self) = @_;

 	$self->forumBegin;
        $self->_out( qq~

        <table cellspacing="1" cellpadding="1" border="0" width="600" height="400">
          <tr>
            <td valign="top" width="300" class="nlTdDarker">
              <h2>All Templates Files</h2>
	      Header Files<br>
              <select name="tmplFilesHeader" size="6" class="nlSelect" multiple>
        ~);
			my %short = (
                                +HEADER => 'H',
                                +FOOTER => 'F'
                        );


			foreach my $name ( $self->{'nl'}->template( get => {} ) ) {
				next if( $name->{'is'} eq +FOOTER );
                                $self->_out( qq~
                                  <option value="$name->{'filename'}">
                                  [$name->{'filename'}] [$name->{'schema'}] [$short{$name->{'is'}}] [$name->{'type'}]
                                  </option>
                                ~);
                        }

        $self->_out( qq~
              </select><br>
	      Footer Files<br>
	      <select name="tmplFilesFooter" size="6" class="nlSelect" multiple>
	~);

			foreach my $name ( $self->{'nl'}->template( get => {} ) ) {
                                next if( $name->{'is'} eq +HEADER );
                                $self->_out( qq~
                                  <option value="$name->{'filename'}">
                                  [$name->{'filename'}] [$name->{'schema'}] [$short{$name->{'is'}}] [$name->{'type'}]
                                  </option>
                                ~);
                        }
			

	$self->_out( qq~
	      </select><br>
	      [H]=Header [F]=Footer<br><br>
	      <input type="hidden" name="pSection" value="editTmpl">
              <input type="radio" name="tmplFilesAction" value="open" checked="checked">open
              <input type="radio" name="tmplFilesAction" value="delete">delete
              <br><br>
              <input type="submit" value="Make" class="nlInput">
            </td>
	~ );
	$self->forumEnd;

	my $html = +HTML_TMPL;
	my $text = +TEXT_TMPL;
	my $header = +HEADER;
	my $footer = +FOOTER;

        $self->forumBegin( -enctype => "multipart/form-data", -method => "post" );
	$self->_out( qq~
            <td valign="top" class="nlTdLighter">
              <table cellspacing="0" cellpadding="0" border="0">
                <tr>
                  <td>
                    <h2>Add new Template File</h2>
		    <input name="tmplFileUpload" type="file" accept="text/*" class="nlInput"><br><br>
		    <input type="radio" name="pTmplFileUploadType" value=$html checked="checked">Html
              	    <input type="radio" name="pTmplFileUploadType" value=$text>Text<br><br>
		    <input type="radio" name="pTmplFileUploadIs" value=$header checked="checked">Header
                    <input type="radio" name="pTmplFileUploadIs" value=$footer>Footer<br><br>
		
		    Create new Schema<br>
		    <input type="text" name="pTmplFileUploadSchemaNew" class="nlInput"><br><br>
		    Add to existing Schema<br>
		    <select name="pTmplFileUploadSchema" class="nlSelect">
		      <option value="none">None</option>
	~ );
			my %already = ();

                        foreach my $name ( $self->{'nl'}->template( get => { schema => "*" } ) ) {
                                next if( exists $already{ $name->{'schema'} } );
				next if( $name->{'schema'} eq 'undef' );
                                $self->_out( qq~
                                  <option value="$name->{'schema'}">
                                  $name->{'schema'}
                                  </option>
                                ~);
                                $already{ $name->{'schema'} } = 1;
                        }
	
	$self->_out( qq~
		    </select><br><br><br>
		     <input type="hidden" name="pSection" value="tmplFileUpload">
                    <input type="submit" value="Next" class="nlInput">
                  </td>
                </tr>
              </table>
	~ );

	$self->forumEnd;

	$self->_out( qq~
            </td>
          </tr>
        </table>
        ~ );

}


sub openTmpl {
	my ($self, $path, $type) = @_;

	my $nr = int(rand(10000) + 1);

	$self->_out( qq~
        <script type="text/javascript">
          var win$nr = window.open('', "$path", "width=300,height=400");
	~);

	my $str;
	open(FILE,"<$path") or warn "$path:$!\n";
	while(<FILE>) {
		$_ =~s/'/\\'/g;
		$_ =~s/\r//g;
		chomp;
		$str .= $_;
		#$self->_out( qq~ win$nr.document.writeln('$_'); ~);
	}
	close(FILE);


	$str =~s/<script.+<\/script>//gm;

	$self->_out( qq~
	  win$nr.document.write( '$str' );
        </script>
	~);
}


sub fileuploadTmpl {
	my ($self) = @_;

	my $fileName = $self->fileUpload("tmplFileUpload");

	$self->forumBegin( -enctype => "multipart/form-data", -method => "post" );

	$self->_out( qq~
	<table cellspacing="1" cellpadding="1" border="0" width="300" height="400">
          <tr>
            <td valign="top" width="300" class="nlTdDarker">
              <h2>Add embedded Files</h2>
	      Filename:<b>$fileName</b><br>
	      Is:<b>$self->{'persistent'}->{"pTmplFileUploadIs"}</b><br>
	      Type:<b>$self->{'persistent'}->{"pTmplFileUploadType"}</b><br>
	      Schema:
	~);
	
	if( $self->{'persistent'}->{"pTmplFileUploadSchemaNew"} ) {
		$self->_out( qq~ 
			<b>$self->{'persistent'}->{"pTmplFileUploadSchemaNew"}</b></br> 
			<input type="hidden" name="tmplSchema" value="$self->{'persistent'}->{"pTmplFileUploadSchemaNew"}">
		~);
	} 
	elsif( $self->{'persistent'}->{"pTmplFileUploadSchema"} ne "none") {
		$self->_out( qq~ 
			<b>$self->{'persistent'}->{"pTmplFileUploadSchema"}</b></br> 
			<input type="hidden" name="tmplSchema" value="$self->{'persistent'}->{"pTmplFileUploadSchema"}">
		~);
	} else {
		$self->_out( qq~ 
			<b>None</b></br> 
		~);
	}

	$self->_out( qq~
		<h3>Upload Embedded</h3>
	~);
	
	for(my $a = 0; $a < 10; $a++ ) {
		$self->_out( qq~ <input name="embFileUpload$a" type="file"><br> ~);
	}

	$self->_out( qq~
	      <br><br>
	      <input type="hidden" name="tmplFile" value="$fileName">
	      <input type="hidden" name="pSection" value="finishTmplFileUpload">
              <input type="submit" value="Create" class="nlInput">
	    </td>
	  </tr>
	</table>
	~);

	$self->forumEnd;

}


sub sendList {
	my ($self) = @_;

	if(! exists $self->{'persistent'}->{"pOpenList"} ) {
		$self->startpage;	
		$self->_info( "No Mailing List is selected!" );
		return;
	}

	if(! $self->{'persistent'}->{"pOpenList"} ) {
                $self->startpage;       
                $self->_info( "No Mailing List is selected!" );
                return;
        }



	$self->forumBegin( -enctype => "multipart/form-data", -method => "post" );


	my %mailType = (
		'text' => 'Text',
		'multipart/related' => 'Html',
		'multipart/mixed' => 'Html + Text'	
	);

        $self->_out( qq~
        <table cellspacing="1" cellpadding="1" border="0" width="900" height="400">
          <tr>
 
            <td valign="top" width="600" class="nlTdDarker">
	      <h2>Create Email</h2>
	      <table cellspacing="5" cellpadding="1" border="0" width="100%">
		<tr>
		  <td width="80">Mail Type</td>
		  <td>
		    <select name="pMailType" class="nlSelectShort">
	~);
		if( exists $self->{'persistent'}->{"pMailType"} ) {
			foreach my $key (keys %mailType ) {
				if( $self->{'persistent'}->{"pMailType"} eq $key) {
					 $self->_out( qq~
					  <option value="$key" selected>$mailType{$key}</option>
					~);
				} else {
					$self->_out( qq~
                                          <option value="$key">$mailType{$key}</option>
                                        ~);
				}
			}		
		} else {
			$self->_out( qq~
                          <option value="text">$mailType{'text'}</option>
			  <option value="multipart/related">$mailType{'multipart/related'}</option>
			  <option value="multipart/mixed" selected>$mailType{'multipart/mixed'}</option>
                        ~);
		}

	$self->_out( qq~
		    </select>
		  </td>
		</tr>
		<tr>
		  <td>Subject</td>	
	~);


	if( $self->{'persistent'}->{"pMailSubject"} ) {	
	         $self->_out( qq~ 
		<td><input type="text" name="pMailSubject" value="$self->{'persistent'}->{"pMailSubject"}" class="nlInputLarge"></td> 
		~);
	} else {
		$self->_out( qq~ <td><input type="text" name="pMailSubject" value="" class="nlInputLarge"></td> ~);
	}

	$self->_out( qq~
		</tr>

		<tr>
                  <td valign="top">Mail from File</td>   
                  <td><input name="mailFromFileHtml" type="file"> <b>Html</b> <br>
                      <input name="mailFromFileText" type="file"> <b>Text</b> </td>
                </tr>

		<tr>
                  <td valign="top">Mail Html Body</td>
	~);

	if( $self->{'persistent'}->{"pMailBodyHtml"} ) { 
                 $self->_out( qq~ 
                <td><textarea name="pMailBodyHtml" rows="10" class="nlInputLarge">$self->{'persistent'}->{"pMailBodyHtml"}</textarea></td>
                ~);
        } else {
                $self->_out( qq~ <td><textarea name="pMailBodyHtml" rows="10" class="nlInputLarge"></textarea></td> ~);
        }
	

	$self->_out( qq~
		</tr>
		<tr>
                  <td valign="top">Mail Text Body</td>
	~);

	if( $self->{'persistent'}->{"pMailBodyText"} ) {
                 $self->_out( qq~ 
                <td><textarea name="pMailBodyText" rows="10" class="nlInputLarge">$self->{'persistent'}->{"pMailBodyText"}</textarea></td>
                ~);
        } else {
                $self->_out( qq~ <td><textarea name="pMailBodyText" rows="10" class="nlInputLarge"></textarea></td> ~);
        }


	$self->_out( qq~
                </tr>

		<tr>
                  <td valign="top">Embedded Files</td>
                  <td>
		    <input name="mailEmbFile1" type="file"><input name="mailEmbFile2" type="file"><br>
		    <input name="mailEmbFile3" type="file"><input name="mailEmbFile4" type="file"><br>
		    <input name="mailEmbFile5" type="file"><input name="mailEmbFile6" type="file"><br>
                    <input name="mailEmbFile7" type="file"><input name="mailEmbFile8" type="file"><br>
		    <input name="mailEmbFile9" type="file"><input name="mailEmbFile10" type="file">
		  </td>
                </tr>

		<tr>
                  <td valign="top">Attachments</td>
                  <td>
                    <input name="mailAttFile1" type="file"><input name="mailAttFile2" type="file"><br>
                    <input name="mailAttFile3" type="file"><input name="mailAttFile4" type="file">
                  </td> 
                </tr>
		
		<tr>
                  <td colspan="2" align="center"><br>
		    <input type="hidden" name="pSection" value="sendListPreview">
	            <input type="submit" value="Preview" class="nlInput">
		  </td>
                </tr>
	      </table>
	    </td>
	    <td valign="top" width="300" class="nlTdLighter">
	~);
        $self->forumEnd;

	$self->sendListSetting;

	$self->_out( qq~
            </td>
	  </tr>
	</table>
        ~);
}


sub sendListSetting {
	my($self) = @_;
	
	$self->forumBegin();
        $self->_out( qq~
                <h3>Settings</h3>
                <table cellspacing="1" cellpadding="1" border="0" width="100%">
                  <tr>
                    <td width="80"><b>Maillist</b></td>
                    <td>$self->{'persistent'}->{"pOpenList"}</td>
                  </tr>
        ~);

        if( $self->{'persistent'}->{"pOpenSchema"} ) {
                $self->_out( qq~
                        <tr>
                        <td width="80"><b>Schema</b></td>
                        <td>$self->{'persistent'}->{"pOpenSchema"}</td>
                        </tr>
                        <tr>
                        <td valign="top"><b>Schema Files</b></td>
                        <td>
                ~);

         
                foreach my $name ( $self->{'nl'}->template( get => { schema => $self->{'persistent'}->{"pOpenSchema"} } ) ) {
                        $self->_out( qq~
                                 $name->{'filename'}<br>
                        ~);
                }
                $self->_out( qq~ </td></tr> ~);

        } else {

                if( $self->{'persistent'}->{"plOpenFile"}->[0] ) {
                        $self->_out( qq~
                                <tr>
                                <td valign="top"><b>Selected Files</b></td>
                                <td>
                        ~);
                        foreach my $tf ( @{ $self->{'persistent'}->{"plOpenFile"} } ) {
                                my @tmp = split(/-is-/,$tf);
                                
                                $self->_out( qq~ $tmp[0]<br> ~);
                        }
                        $self->_out( qq~ </td></tr> ~);
                }

        }

	$self->_out( qq~
                <tr><td colspan="2"><br></td></tr>
        ~);

	if( $self->{'persistent'}->{'pMailFromFileHtml'} ) {
		$self->_out( qq~
                  <tr>
		    <td valign="top"><b>Body Html File</b></td>
		    <td>
		      $self->{'persistent'}->{'pMailFromFileHtml'}<br>
		      <input type="hidden" name="delMailFromFileHtml" value="$self->{'persistent'}->{'pMailFromFileHtml'}">
		      Delete: <input type="radio" name="pMailFromFileHtml" value="$self->{'persistent'}->{'pMailFromFileHtml'}" checked="checked">No
                      <input type="radio" name="pMailFromFileHtml" value="">Yes
		    </td>
		  </tr>
        	~);
	}


	if( $self->{'persistent'}->{'pMailFromFileText'} ) {
                $self->_out( qq~
                  <tr>
                    <td valign="top"><b>Body Text File</b></td>
                    <td>
                      $self->{'persistent'}->{'pMailFromFileText'}<br>
                      <input type="hidden" name="delMailFromFileText" value="$self->{'persistent'}->{'pMailFromFileText'}">
                      Delete: <input type="radio" name="pMailFromFileText" value="$self->{'persistent'}->{'pMailFromFileText'}" checked="checked">No
                      <input type="radio" name="pMailFromFileText" value="">Yes
                    </td>
                  </tr>
                ~);
        }


	if( $self->{'persistent'}->{"pMailEmbFile1"} ) {

		$self->_out( qq~
                <tr><td valign="top"><b>Embedded</b></td><td>
        	~);
		for( my $a = 1; $a < 11; $a++ ) {
			if( $self->{'persistent'}->{"pMailEmbFile$a"} ) {
				$self->_out( qq~
				$self->{'persistent'}->{"pMailEmbFile$a"} - 
				<input type="hidden" name="delMailEmbFile$a" value=$self->{'persistent'}->{"pMailEmbFile$a"}>
				Delete <input type="radio" name="pMailEmbFile$a" value=$self->{'persistent'}->{"pMailEmbFile$a"} checked="checked">No
                      		<input type="radio" name="pMailEmbFile$a" value="">Yes<br>
				~);
			}
		}
		$self->_out( qq~
                	</td></tr>
        	~);
	}


	if( $self->{'persistent'}->{"pMailAttFile1"} ) {

                $self->_out( qq~
                <tr><td valign="top"><b>Attachments</b></td><td>
                ~);
                for( my $a = 1; $a < 5; $a++ ) {
                        if( $self->{'persistent'}->{"pMailAttFile$a"} ) {
                                $self->_out( qq~
                                $self->{'persistent'}->{"pMailAttFile$a"} -
                                <input type="hidden" name="delMailAttFile$a" value=$self->{'persistent'}->{"pMailAttFile$a"}>
                                Delete <input type="radio" name="pMailAttFile$a" value=$self->{'persistent'}->{"pMailAttFile$a"} checked="checked">No
                                <input type="radio" name="pMailAttFile$a" value="">Yes<br>
                                ~);
                        }
                }
                $self->_out( qq~
                        </td></tr>
                ~);
        }


        $self->_out( qq~
		  <tr>
		    <td colspan="2" algin="center">
		      <br>
	~);

	if( $self->{'persistent'}->{"pSection"} eq "sendListEdit" || $self->{'persistent'}->{"pSection"} eq "sendListPreview") {
		$self->_out( qq~
		      <input type="radio" name="pSection" value="sendListEdit" checked="checked">Preview
		      <input type="radio" name="pSection" value="sendList">Edit <b>(Go back!)</b><br>
		~);
	} else {
		$self->_out( qq~
                      <!-- <input type="radio" name="pSection" value="sendList" checked="checked">Edit<br> -->
		      <input type="hidden" name="pSection" value="sendList">
                ~);
	}

	$self->_out( qq~
		      <br><input type="submit" value="Update" class="nlInput">
		    </td>
		  </tr>
                </table>
        ~);

        $self->forumEnd;
}


sub sendListFileupload {
	my($self) = @_;

	if( $self->{'cgi'}->param("mailFromFileHtml") ) {
		$self->{'persistent'}->{'pMailFromFileHtml'} = $self->fileUpload("mailFromFileHtml");
		$self->_out( qq~
			<input type="hidden" name="pMailFromFileHtml" value="$self->{'persistent'}->{'pMailFromFileHtml'}">
		~);
	}

	if( $self->{'cgi'}->param("mailFromFileText") ) {
                $self->{'persistent'}->{'pMailFromFileText'} = $self->fileUpload("mailFromFileText");
                $self->_out( qq~
                        <input type="hidden" name="pMailFromFileText" value="$self->{'persistent'}->{'pMailFromFileText'}">
                ~);
        }


	for( my $a = 1; $a < 11; $a++ ) {
		if( $self->{'cgi'}->param("mailEmbFile$a") ) {
			$self->{'persistent'}->{"pMailEmbFile$a"} = $self->fileUpload("mailEmbFile$a");
			$self->_out( qq~ 
				<input type="hidden" name="pMailEmbFile$a" value=$self->{'persistent'}->{"pMailEmbFile$a"}>
			~);
		}

		if( $self->{'cgi'}->param("mailAttFile$a") ) {
                        $self->{'persistent'}->{"pMailAttFile$a"} = $self->fileUpload("mailAttFile$a");
                        $self->_out( qq~ 
                                <input type="hidden" name="pMailAttFile$a" value=$self->{'persistent'}->{"pMailAttFile$a"}>
                        ~);
                }
	}
}


sub sendListFileDelete {
	my($self) = @_;
	
	if( $self->{'cgi'}->param("delMailFromFileHtml") ) {
		my $file = $self->{'cgi'}->param("delMailFromFileHtml");
		$self->_out( qx "rm $self->{'uploadPath'}/$file 2>&1" );	
	}

	if( $self->{'cgi'}->param("delMailFromFileText") ) {
                my $file = $self->{'cgi'}->param("delMailFromFileText");
                $self->_out( qx "rm $self->{'uploadPath'}/$file 2>&1" );
        }
	

	for( my $a = 1; $a < 11; $a++ ) {
		if( $self->{'cgi'}->param("delMailEmbFile$a") ) {
			my $file = $self->{'cgi'}->param("delMailEmbFile$a");
			$self->_out( qx "rm $self->{'uploadPath'}/$file 2>&1" );
		}
	}

	for( my $a = 1; $a < 5; $a++ ) {
                if( $self->{'cgi'}->param("delMailAttFile$a") ) {
                        my $file = $self->{'cgi'}->param("delMailAttFile$a");
                        $self->_out( qx "rm $self->{'uploadPath'}/$file 2>&1" );
                }
        }

}


sub sendListPreview {
	my($self) = @_;

	if(! $self->{'persistent'}->{"pMailSubject"} ) {
                $self->sendList;
                $self->_info( "Alert no mail subject!" );
                return;
        }



	$self->forumBegin( );
	$self->sendListFileupload;
	$self->sendListBuild;

        $self->_out( qq~
        <table cellspacing="1" cellpadding="1" border="0" width="900" height="400">
          <tr>

            <td valign="top" width="600" class="nlTdDarker">
              <h2>Preview Email</h2>
              <table cellspacing="5" cellpadding="1" border="0" width="100%">
	        <tr>
                  <td width="80" valign="top">Subject</td>
                  <td><b>$self->{'persistent'}->{"pMailSubject"}</b></td>
                </tr>
	~);
		
	my $mailFile = $self->{'nl'}->previewMailFile( preview => 1 );

	if( $mailFile ) { 
		$self->_out( qq~
		       <tr>
			<td valign="top">Preview Mail</td>
			<td valign="top"><a href="$mailFile"><b>[Open Mail]</b></a></td>
		       </tr>
		~);

		if( $self->{'nl'}->error ) {
                	$self->_info( $self->{'nl'}->error(1) );
        	}

		my %explodeFiles;

        	my $headers = $self->{'nl'}->previewMailFileExplode( $mailFile );
		for my $part ( sort{ $a cmp $b } keys( %{ $headers } ) ) {
			for my $k ( keys( %{ $headers->{$part} } ) ) {
				if( $k eq 'content-disposition' ) {
					if( exists $headers->{$part}->{'content-disposition'}->{'filename'} ) {
						#warn $headers->{$part}->{'content-disposition'}->{'filename'};	
						if( !exists $explodeFiles{ $headers->{$part}->{'content-disposition'}->{'filename'} } ) {
							$explodeFiles{ $headers->{$part}->{'content-disposition'}->{'filename'} } = 1; 
						}
					}
				}
			}
		}


		my $explodePath = $self->{'nl'}->previewMailFile( getpath => 1 )."/explode";

		# remove attachment files from list!
		for( my $a = 1; $a < 5; $a++ ) {
                        if( $self->{'persistent'}->{"pMailAttFile$a"} ) {
				if( exists $explodeFiles{ $self->{'persistent'}->{"pMailAttFile$a"} } ) {
					delete $explodeFiles{ $self->{'persistent'}->{"pMailAttFile$a"} };
				}
			}
		}

		foreach my $file ( sort keys %explodeFiles ) {
			#warn "[$file]\n";
			if( $file =~ /\.html/) {
				$self->_out( qq~
				  <tr>
	                           <td valign="top">Preview HTML</td>
				   <td class="previewTdEmail">
				~);
				open(FILE, "<$explodePath/$file") or die "preview html file:$explodePath/$file:$!\n";
				while( defined( my $line = <FILE>) ) {
					$line =~ s/src="cid:/src="$explodePath\//gi;
					$self->_out( qq~ $line ~);
				}
				close(FILE);
				$self->_out( qq~
				   </td>
                                  </tr>
                                ~);
			}
			
			elsif( $file =~ /\.txt/ || $file !~ /\./ ) {
				$self->_out( qq~
                                  <tr>
                                   <td valign="top">Preview Text</td>
                                   <td class="previewTdEmail"><pre> ~);

				open(FILE, "<$explodePath/$file") or warn "preview text file:$explodePath/$file:$!\n";
                                while( defined( my $line = <FILE>) ) {
                                        $self->_out( qq~ $line ~);
                                }
                                close(FILE);
				$self->_out( qq~
                                    </pre>
                                   </td>
                                  </tr>
                                ~);
			}
		}		

        	if( $self->{'nl'}->error ) {
                	$self->_info( $self->{'nl'}->error );
        	}
        } else {
		if( $self->{'nl'}->error ) {
                        $self->_info( $self->{'nl'}->error );
                }
	}


#	$self->_out( qq~
#		<tr>
#		  <td width="80" valign="top">Mail Source</td>
#                  <td>
#		    <textarea rows="5" class="nlInputLarge">
#	~);
#	
#	my $sender = $self->{'nl'}->previewMail();
#	if( defined $sender ) {
#		my $mailBody = $sender->body_as_string;
# 		$self->_out( qq~ $mailBody ~);
#	}
#
#	if( $self->{'nl'}->error ) {
#        	$self->_info( $self->{'nl'}->error );
#        }
#
#	$self->_out( qq~
#	           </textarea>
#                  </td>
#                </tr>
#	~);


	$self->_out( qq~
		<tr>
		  <td></td>
		  <td align="center">
			<input type="hidden" name="pSection" value="sendListEmail">
                        <input type="submit" value="Send" class="nlInput">    
		  </td>
		</tr>
	      </table>
	    </td>
	    <td valign="top" width="300" class="nlTdLighter">
        ~);

        $self->forumEnd;

        $self->sendListSetting;
        $self->_out( qq~
            </td>
          </tr>
        </table>
        ~);
}


sub sendListBuild {
	my($self) = @_;

	# Set Sender type
	$self->{'nl'}->sender(
		type => $self->{'persistent'}->{"pMailType"}
	);


	# Load Footer / Header
	if( $self->{'persistent'}->{"pOpenSchema"} ) {
		$self->{'nl'}->template(
        		use => {
                		schema => $self->{'persistent'}->{"pOpenSchema"}
        		}
		);
        } else {

                if( $self->{'persistent'}->{"plOpenFile"}->[0] ) {
                        foreach my $tf ( @{ $self->{'persistent'}->{"plOpenFile"} } ) {
                                my @tmp = split(/-is-/,$tf);
         
				$self->{'nl'}->template(
                		        use => {
						is => $tmp[1],
                                		filename => $tmp[0]
                        		}
		                );
                        }
                }
        }

	# Load Subject
	if( $self->{'persistent'}->{"pMailSubject"} ) {
		$self->{'nl'}->body( subject => $self->{'persistent'}->{"pMailSubject"} );
	}


	# Load Body Html
	my @embHtml = ();
	for( my $a = 1; $a < 11; $a++ ) {
        	if( $self->{'persistent'}->{"pMailEmbFile$a"} ) {
			push( @embHtml, $self->{'uploadPath'}.'/'.$self->{'persistent'}->{"pMailEmbFile$a"} );	
                }
        }

	if( exists $self->{'persistent'}->{'pMailFromFileHtml'} ) {
		if( $self->{'persistent'}->{'pMailFromFileHtml'} ) {
			$self->{'nl'}->body(
        			file => {
                			path => $self->{'uploadPath'}.'/'.$self->{'persistent'}->{'pMailFromFileHtml'},
                			type => 'html',
					embedded => \@embHtml,
        			}
			);
		} else {
			$self->{'nl'}->body(
                        	data => {
                                	value => $self->{'persistent'}->{'pMailBodyHtml'},
                                	type => 'html',
                                	embedded => \@embHtml,
                        	}
                	);
		}
	} else {
		$self->{'nl'}->body(
                        data => {
				value => $self->{'persistent'}->{'pMailBodyHtml'},
				type => 'html',
				embedded => \@embHtml,
                        }
                );
	}


	# Load Body Text
	if( exists $self->{'persistent'}->{'pMailFromFileText'} ) {
                if( $self->{'persistent'}->{'pMailFromFileText'} ) {
                        $self->{'nl'}->body(
                                file => {
                                        path => $self->{'uploadPath'}.'/'.$self->{'persistent'}->{'pMailFromFileText'},
                                        type => 'text',
                                }
                        );
                } else {
                        $self->{'nl'}->body(
                                data => {
                                        value => $self->{'persistent'}->{'pMailBodyText'},
                                        type => 'text',
                                }
                        );
                }
        } else {
                $self->{'nl'}->body(
                        data => {
                                value => $self->{'persistent'}->{'pMailBodyText'},
                                type => 'text',
                        }
                );
        }


	# add attachments
	my $msg = $self->{'nl'}->sender;
	if( $msg ) {
		my $ft = File::Type->new();

		for( my $a = 1; $a < 5; $a++ ) {
	               	if( $self->{'persistent'}->{"pMailAttFile$a"} ) {

				# 'file' and 'file.html' not allowed
				if( $self->{'persistent'}->{"pMailAttFile$a"} =~ /file/ ||
				    $self->{'persistent'}->{"pMailAttFile$a"} =~ /file\.html/
				) {
					next;
					$self->_info( "'file' and 'file.html' not allowed as attachment filenames\n" );
				}

				$msg->attach(
					Type => $ft->checktype_filename( $self->{'uploadPath'}.'/'.$self->{'persistent'}->{"pMailAttFile$a"} ),
					Path => $self->{'uploadPath'}.'/'.$self->{'persistent'}->{"pMailAttFile$a"}
				);
				warn "Path => ".$self->{'uploadPath'}.'/'.$self->{'persistent'}->{"pMailAttFile$a"};
       	        	}
        	}
	}

	if( $self->{'nl'}->error ) {
        	$self->_info( $self->{'nl'}->error );
        }
}




sub sendListMail {
	my($self) = @_;


	$self->sendListBuild;
	
	# add attachments
#        my $msg = $self->{'nl'}->sender;
#        if( $msg ) {
#                for( my $a = 1; $a < 5; $a++ ) {
#                        if( $self->{'persistent'}->{"pMailAttFile$a"} ) {
#
#                                # 'file' and 'file.html' not allowed
#                                if( $self->{'persistent'}->{"pMailAttFile$a"} =~ /file/ ||
#                                    $self->{'persistent'}->{"pMailAttFile$a"} =~ /file\.html/
#                                ) {
#                                        next;
#                                        $self->_info( "'file' and 'file.html' not allowed as attachment filenames\n" );
#                                }
#
#                                $msg->attach(
#                                        Path => $self->{'uploadPath'}.'/'.$self->{'persistent'}->{"pMailAttFile$a"}
#                                );
#                                warn "Path => ".$self->{'uploadPath'}.'/'.$self->{'persistent'}->{"pMailAttFile$a"};
#                        }
#                }
#        }


	# open mail list
	$self->{'nl'}->list(
		list => { name => $self->{'persistent'}->{"pOpenList"}  }
	);


	if( $self->{'nl'}->error ) {
                $self->_info( $self->{'nl'}->error );
        }

	# send !!!
	print qq~ <pre>~;
	$self->{'nl'}->send(1);
	print qq~ </pre>~;


	if( $self->{'nl'}->error ) {
                $self->_info( $self->{'nl'}->error );
        }

	# copy to archiv
	$self->{'nl'}->archiv( save => 1 );

	if( $self->{'nl'}->error ) {
                $self->_info( $self->{'nl'}->error );
        }

	# cleanup upload files
	$self->sendListClean();

}


sub sendListClean {
	my($self) = @_;

	rmtree $self->{'uploadPath'};
}



=head1 NAME

Newsletter::Html::Templ - Html parts!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

The html parts for the newsletter module

Perhaps a little code snippet.

    use Newsletter::Html::Templ;

    my $foo = Newsletter::Html::Templ->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head1 AUTHOR

Dominik Hochreiter, C<< <dominik at soft.uni-linz.ac.at> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-newsletter-html-templ at rt.cpan.org>, or through the web interface at
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

1; # End of Newsletter::Html::Templ
