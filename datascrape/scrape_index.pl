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

my $pit_name = 'china.org.cn';
my $type = 'index';
my $site_title  = '//head/title';
my $site_url = 'http://japanese.china.org.cn/node_7037619.htm';
my $next_page = '//center/a[2]';
my $index = '//body/div[2]//table[3]//tr';
my $index_entry_title = '.';
my $index_entry_permalink = '//a';
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
	my $url = $site_url;
			
			my $uri = URI->new($url);
				say $uri;
			$mech->get($uri);
			$entry = $scraper->scrape($mech->content,$uri);

			HashDump->load($entry);

open my $fh ,'>', 'setting.yaml';

print $fh "'" . $pit_name ."':\n";
print $fh '  "type": '. "'". $type ."'\n";
print $fh '  "site_title": '. "'". $site_title ."'\n";
print $fh '  "site_url": '. "'". $site_url ."'\n";
print $fh '  "next_page": '. "'". $next_page ."'\n";
print $fh '  "index": '. "'". $index ."'\n";
print $fh '  "index_entry_title": '. "'". $index_entry_title ."'\n";
print $fh '  "index_entry_permalink": '. "'". $index_entry_permalink ."'\n";

close $fh;

