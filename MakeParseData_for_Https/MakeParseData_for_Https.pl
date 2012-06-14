#!/usr/bin/perl
use WWW::Mechanize;
use URI;
use feature 'say';

my ($url) = (@ARGV);
say $url;

my $uri = URI->new($url);
my $mech = new WWW::Mechanize( autocheck => 1);
my $user_agent = 'Mozilla/5.0 (Windows NT 6.0; WOW64) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.108
4.52 Safari/536.5';
$mech->agent($user_agent);
$mech->get($uri);
say $mech->uri;
my $content = $mech->content;
open my $fh, '>', 'parse.txt';
print $fh $content;
