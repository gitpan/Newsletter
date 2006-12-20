#!/usr/bin/perl -w

use strict;
use Newsletter;
use Newsletter::Html;


my $news = Newsletter->new;

$news->template( path => '/tmp/Newsletter/Data' );

$news->list(
        empty => 1,
        path => '/tmp/Newsletter/Data/list'
);

$news->body(
        path => '/tmp/Newsletter/Data/body'
);

$news->sender(
	smtp => 'smtp.foo.bar',
	replayTo => 'foo@bar.com'
);


# relative paths ( access from webbrowser )?!

$news->previewMailFile(
	path => '/tmp/Newsletter/Data/preview'
);

$news->archiv(
	path => '/tmp/Newsletter/Data/archiv'
);



my $newsHtml = Newsletter::Html->new(\$news, '/tmp/Newsletter/Data/upload');

print $newsHtml->header( 
#	-style => {'src'=>'/css/formate.css'}, 
);

print $newsHtml->body;
print $newsHtml->footer;


