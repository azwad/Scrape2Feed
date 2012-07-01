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

my $site_title  = '//head/title';
my $next_page = '//next';
my $index = '//p/a[position()+1<last()-1]';
my $index_entry_title = '.';
my $index_entry_permalink = '.';
my $entry = {};

		my $scraper = scraper {
			process $site_title,			'site_title'			=> 'TEXT';
			process $next_page,				'next_page'				=> '@href';
			process $index,						'container[]'			=> scraper {
				process $index_entry_title,			'entry_title'			=> 'TEXT';
				process $index_entry_permalink,	'entry_permalink'	=> '@href';
				};
	};
			
	my $mech = WWW::Mechanize->new( 'autocheck' => 1, );
	my $url = 'http://the-journal.jp';
			
			my $uri = URI->new($url);
				say $uri;
			$mech->get($uri);
			$entry = $scraper->scrape($mech->content,$uri);

			HashDump->load($entry);

