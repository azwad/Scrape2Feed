package Scrape2Feed;
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
#use Encode;
use Moose;

has 'site_name' => (
	is => 'rw',
	isa => 'Str',
	required => 1,
);

has 'output' => (
	is => 'rw',
	isa => 'Str',
	required => 0,
	default => 'hash',
);

has 'config' => (
	is => 'rw',
	isa => 'Hash',
);

has 'contents' => (
	is => 'rw',
	isa => 'Hash',
);

has 'url' => (
	is => 'rw',
	isa => 'Str',
);

has 'user_agent' => (
	is => 'rw',
	isa => 'Str',
	default =>  'Mozilla/5.0 (Windows NT 6.0; WOW64) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.108
4.52 Safari/536.5',
);

has 'setting_file' => (
	is => 'rw',
	isa => 'Str',
	default => 'site_settings',
);

has 'rss_opt' => (
	isa => 'HashRef',
	is => 'rw',
	default	=>sub {{'ver'						 =>'1.0',
							 'encode_output'	 => '1',
							 'decode_entities' => '1',
							}},
);

has 'page_limit' => (
	is => 'rw',
	isa => 'Int',
	default => 100,
);

__PACKAGE__->meta->make_immutable;
no Moose;

sub rss_ver {
	my $self = shift;
	$self->rss_opt->{ver} = shift;
	return $self;
}

sub rss_out {
	my $self = shift;
	$self->rss_opt->{encode_output} = shift;
	return $self;
}
sub rss_ent {
	my $self = shift;
	$self->rss_opt->{entities} = shift;
	return $self;
}

sub _load_setting {
	my $self = shift;
	my $setting_file = $self->setting_file;
	Config::Pit::switch($setting_file);
	$self->{config} = Config::Pit::pit_get($self->site_name);
	Config::Pit::switch;
	if ($self->{url}){
		$self->{config}->{site_url} = $self->{url};
	}
	return $self;
}

sub get_list {
	my ($self, $first_page_no, $last_page_no ) = @_;
	$self->_load_setting;
#	my $site_title = $self->{config}->{site_title};
	my $site_url = $self->{config}->{site_url};
	my $next_page = $self->{config}->{next_page};
	my $container =  $self->{config}->{container} || $self->{config}->{index};
	my $entry_title = $self->{config}->{entry_title}|| $self->{config}->{index_entry_title};
	
	my $start_page_url;

 	$first_page_no = 1 unless defined $first_page_no;
	$last_page_no = $first_page_no unless defined $last_page_no;
	if ($last_page_no < $first_page_no) {
	 croak 'last page no. must be grater than first page no.';
	}
	unless (defined $next_page) {
		$first_page_no = $last_page_no = 1;
	} 
	my $current_page_no = 1;
	my $current_page_url  = $site_url;
	my $page = [];

	my $mech = new WWW::Mechanize( autocheck => 1 );
	$mech->agent($self->{user_agent});

	for  ($current_page_no = 1; $current_page_no <= $last_page_no; ++$current_page_no){
		my $uri = URI->new($current_page_url);
		$mech->get($uri);
		my $next_page_url = scraper { process $next_page, 'next_page' => '@href';}->scrape($mech->content,$uri) if defined $next_page;
		if ($current_page_no >= $first_page_no ) {
			$page->[$current_page_no]  = scraper {
				process $container.$entry_title, 'title[]' => 'TEXT';
			}->scrape($mech->content,$uri);
		$page->[$current_page_no]->{url} = $current_page_url;
    }
		$current_page_url = $next_page_url->{next_page} if defined $next_page;
	}
	return $page;
}


sub get_contents {
	my $self = shift;
	my @args = @_;

	$self->_load_setting;
	my $contents;
	my $type = $self->{config}->{type};

	if ($type eq 'flat'){
		$contents = _get_contents_flat($self,@args);
	}elsif ($type eq 'index'){
		$contents = _get_contents_index($self,@args);
	}elsif ($type eq 'subindex'){
		$contents = _get_contents_subindex($self,@args);
	}else{
		croak 'set an index type in the setting file';
	}
	$self->{contents} = $contents;
	return $contents;
} 
 

sub _get_contents_flat {
	my ($self, $first_page_no, $last_page_no) = @_;

	my $site_title = $self->{config}->{site_title};
	my $site_url = $self->{config}->{site_url};
	my $next_page = $self->{config}->{next_page};
	my $container =  $self->{config}->{container};
	my $entry_title = $self->{config}->{entry_title};
	my $entry_permalink = $self->{config}->{entry_permalink};
	my $entry_content = $self->{config}->{entry_content};
	my $entry_date;

	my $flag_defined_entry_date;

	if (defined($self->{config}->{entry_date})){
		$flag_defined_entry_date = 1;
		$entry_date = $self->{config}->{entry_date};
	}else{
		$flag_defined_entry_date = 0;
		$entry_date = '//a';
	}		 


 	$first_page_no = 1 unless defined $first_page_no;
	$last_page_no = $first_page_no unless defined $last_page_no;
	if ($last_page_no < $first_page_no) {
	 croak 'last page no. must be grater than first page no.';
	}
	unless (defined $next_page) {
		$first_page_no = $last_page_no = 1;
		$next_page = '//next';
	}
	my $current_page_no = 1;

	my $current_page_url  = $site_url;
	my $mech = new WWW::Mechanize( autocheck => 1 );
	$mech->agent($self->{user_agent});
	my $contents =[];

	for  ($current_page_no = 1; $current_page_no <= $last_page_no; ++$current_page_no){
		my $uri = URI->new($current_page_url);
		$mech->get($uri);
		my $next_page_url = scraper { process $next_page, 'next_page' => '@href';}->scrape($mech->content,$uri);
		if ($current_page_no >= $first_page_no ) {
			my $scraper = scraper { 
				process $site_title,			'site_title'			=> 'TEXT';
				process $next_page,				'next_page'				=> '@href';
				process $container,				'container[]'			=> scraper {
					process $entry_title,			'entry_title'			=> 'TEXT';
					process $entry_permalink,	'entry_permalink'	=> '@href';
					process $entry_content,		'entry_content'		=> 'HTML';
					process $entry_date,			'entry_date'	=> sub {
							if ($flag_defined_entry_date){
								my $timestr = $_->as_text;
								return datestr($timestr,'W3CDTF');
							}else{
								return datestr('now','W3CDTF');
							};						
						};
					};
				};
			$contents->[$current_page_no]  = $scraper->scrape($mech->content,$uri);
			$contents->[$current_page_no]->{url} = $current_page_url;
    }
		$current_page_url = $next_page_url->{next_page};
	}
	return $contents;
}

sub _get_contents_index {
	my ($self, $first_page_no, $last_page_no) = @_;

	my $site_title = $self->{config}->{site_title};
	my $site_url = $self->{config}->{site_url};
	my $next_page = $self->{config}->{next_page};
	my $index =  $self->{config}->{index};
	my $index_entry_title = $self->{config}->{index_entry_title};
	my $index_entry_permalink = $self->{config}->{index_entry_permalink};
	my $entry_content = $self->{config}->{entry_content};
	my $entry_date = $self->{config}->{entry_date};

	my $flag_defined_entry_date;
	if (defined($entry_date)){
		$flag_defined_entry_date = 1;
	}else{
		$flag_defined_entry_date = 0;
		$entry_date = '//div';
	}		 

 	$first_page_no = 1 unless defined $first_page_no;
	$last_page_no = $first_page_no unless defined $last_page_no;
	if ($last_page_no < $first_page_no) {
	 croak 'last page no. must be grater than first page no.';
	}
	unless (defined $next_page) {
		$first_page_no = $last_page_no = 1;
		$next_page = '//next';
	}
	
	my $current_page_no = 1;
	my $current_page_url  = $site_url;
	my $mech = new WWW::Mechanize( autocheck => 1 );
	$mech->agent($self->{user_agent});
	my $contents =[];
	
	for  ($current_page_no = 1; $current_page_no <= $last_page_no; ++$current_page_no){
		my $uri = URI->new($current_page_url);
		$mech->get($uri);
		my $next_page_url = scraper { process $next_page, 'next_page' => '@href';}->scrape($mech->content,$uri);
		if ($current_page_no >= $first_page_no ) {
			my $scraper = scraper { 
				process $site_title,			'site_title'			=> 'TEXT';
				process $next_page,				'next_page'				=> '@href';
				process $index,						'container[]'			=> scraper {
					process $index_entry_title,			'entry_title'			=> 'TEXT';
					process $index_entry_permalink,	'entry_permalink'	=> '@href';
				};
			};

			$contents->[$current_page_no]  = $scraper->scrape($mech->content,$uri);

			my $scraper2 = scraper {
				process $entry_content, 'entry_content' => 'HTML';
				process $entry_content, 'entry_content_text' => 'TEXT';
				process $entry_date,			'entry_date'	=> sub {
							if ($flag_defined_entry_date){
								my $timestr = $_->as_text || $_;
								return datestr($timestr,'W3CDTF');
							}else{
								return datestr('now','W3CDTF');
							}						
				};
			};
			my $num = 0;
			my $stop = $self->{page_limit};
			for my $var  (@{$contents->[$current_page_no]->{container}}){
				my $entry = {};
				my $uri = URI->new($var->{entry_permalink});
				eval { $mech->get($uri)};
				if ($@){
					say "count $num";
					warn "can't find $uri: $@";
					say 'status?: ' . $mech->status();
					++$num;
					next;
				}else{
#					say "count $num";
					say 'get uri: ' . $mech->uri();
#					say 'success? ' . $mech->success();
				}
				$entry = $scraper2->scrape($mech->content,$uri);

				$contents->[$current_page_no]->{container}->[$num]->{entry_content} = $entry->{entry_content};
				$contents->[$current_page_no]->{container}->[$num]->{entrt_date} = $entry->{entry_date};
				

				if ($num > $stop){
					last;
				}
				++$num;
			}
			$contents->[$current_page_no]->{url} = $current_page_url;
    }
		$current_page_url = $next_page_url->{next_page};
	}
	
	return  $contents;
}

sub _get_contents_subindex {
	my ($self, $first_page_no, $last_page_no) = @_;

	my $site_title = $self->{config}->{site_title};
	my $site_url = $self->{config}->{site_url};
	my $next_page = $self->{config}->{next_page};
	my $container =  $self->{config}->{container};
	my $entry_title = $self->{config}->{entry_title};
	my $entry_permalink = $self->{config}->{entry_permalink};
	my $entry_content = $self->{config}->{entry_content};
	my $entry_date = $self->{config}->{entry_date};

	my $flag_defined_entry_date;
	if (defined($entry_date)){
		$flag_defined_entry_date = 1;
	}else{
		$flag_defined_entry_date = 0;
		$entry_date = '//div';
	}		 

 	$first_page_no = 1 unless defined $first_page_no;
	$last_page_no = $first_page_no unless defined $last_page_no;
	if ($last_page_no < $first_page_no) {
	 croak 'last page no. must be grater than first page no.';
	}
	my $current_page_no = 1;
	my $current_page_url  = $site_url;
	my $mech = new WWW::Mechanize( autocheck => 1 );
	$mech->agent($self->{user_agent});
	my $contents =[];
	
	return  'これからつくる';
}

sub get_rss {
	my $self = shift;
	my @args = @_;
	my $contents;
	if (defined($self->{contents})){
		$contents = $self->{contents};
	}else{
		$contents	 = $self->get_contents(@args);
	}

	my $rss = XML::RSS->new(
			version => $self->rss_opt->{ver},
			enocode_output => $self->rss_opt->{encode_output},
	);

	my ($title, $link, $description);
	foreach my $value (@$contents){
		if (defined($value->{site_title})){
			$title = $value->{site_title};
			$link = $value->{url};
			$description = '';
			last;
		}else{
			next;
		}
	}
	
	$rss->channel(
		title => $title,
		link => $link,
		description => $description,
		dc => {
			date => datestr('now','W3CDTF'),
			subject => '',
			creator => 'Scrape2Feed.pm',
			publisher => 'toshi0104@gmail.com',
			rights => '',
		} ,
	);

	foreach my $value (@$contents){
		foreach my $value2 (@{$value->{container}}){
			$rss->add_item(
				title => $value2->{entry_title},
				link => $value2->{entry_permalink},
				description => $value2->{entry_content},
				dc => {
					date => $value2->{entry_date},
					subject => '',
					creator => 'Scrape2Feed.pm',
				},
			);
		}
	}

	if ($self->rss_opt->{decode_entities}){
		return	decode_entities($rss->as_string);
	}else{
		return $rss;
	}
}


1;





