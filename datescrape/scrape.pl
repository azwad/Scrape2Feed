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

my $entry_content = '//div[@class="article"]';
my $entry_date = '//div[@class="red"]';
my $entry = {};

			my $scraper2 = scraper {
				process $entry_content, 'entry_content' => 'HTML';
				process $entry_date,			'entry_date'	=> sub {
								my $timestr = $_->as_text || $_;
							  return  datestr($timestr,'W3CDTF');
							};						
			};
			
			
			
			my $mech = WWW::Mechanize->new( 'autocheck' => 1, );
			my $url = 'http://www.shihoujournal.co.jp/news/120629_1.html';
			
			my $uri = URI->new($url);
				say $uri;
			$mech->get($uri);
			$entry = $scraper2->scrape($mech->content,$uri);

			HashDump->load($entry);

