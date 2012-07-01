#!/usr/bin/perl
use warnings;
use strict;
use utf8;
use URI;
use Config::Pit;
use feature qw ( say );
use lib qw ( /home/toshi/perl/lib );
use DateTimeEasy qw ( datestr );
use HashDump;
use Carp 'croak';
use Web::Scraper;
use WWW::Mechanize;
use XML::RSS;
use HTML::Entities;

my $entry_content = '//div[@class="entry-content"]';
my $entry_date =  '//span[@class="post-footers"]';

my $flag_defined_entry_date = 0;
$flag_defined_entry_date = 1 if defined $entry_date;

my $entry = {};


my $scraper = scraper {
	process $entry_content, 'entry_content' => 'HTML';
	process $entry_content, 'entry_content_text', => 'TEXT';
	process $entry_date,'entry_date' => sub {
		if ($flag_defined_entry_date){
			my $timestr = $_->as_text || $_;
			return datestr($timestr,'W3CDTF');
		}else{
			return datestr('now','W3CDTF');
		}
	};
};

			
	my $mech = WWW::Mechanize->new( 'autocheck' => 1, );
	my $url = 'http://www.the-journal.jp/contents/kokkai/2012/06/post_305.html';
			
			my $uri = URI->new($url);
			say $uri;
			$mech->get($uri);
			$entry = $scraper->scrape($mech->content,$uri);

			HashDump->load($entry);

