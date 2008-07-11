#!/usr/bin/perl
#
# M00se on the L00se

package Chef::Rest;

use strict;
use warnings;

use LWP::UserAgent;
use URI;
use Params::Validate qw(:all);
use JSON::Syck;

sub new {
    my $self = shift;
    my %p = validate(@_,
        {
            content_type => { type => SCALAR },
        },
    );
    my $ref = { 
        'ua' => LWP::UserAgent->new,
        'content_type' => $p{'content_type'},
    };
    bless $ref, $self;
}

sub load {
    my $self = shift;
    my $data = shift;
    return JSON::Syck::Load($data);
}

sub get {
    my $self = shift;
    my %p = validate(@_,
        {
            url => { type => SCALAR },
            params => { type => ARRAYREF, optional => 1 },
        },
    );

    my $url = URI->new($p{'url'});
    if (defined($p{'params'})) {
        $url->query_form($p{'params'});
    }
    my $req = HTTP::Request->new('GET' => $url);
    $req->content_type($self->{'content_type'});
    return $self->ua->request($req);
}

sub delete {
    my $self = shift;
    my %p = validate(@_,
        {
            url => { type => SCALAR },
        },
    );
    my $req = HTTP::Request->new('DELETE' => $p{'url'});
    $req->content_type($self->{'content_type'});
    return $self->ua->request($req);    
}

sub put {
    my $self = shift;
    my %p = validate(@_,
        {
            url => { type => SCALAR },
            data => 1,
        },
    );
    my $data = JSON::Syck::Dump($p{'data'});
    my $req = HTTP::Request->new('PUT' => $p{'url'});
    $req->content_type($self->{'content_type'});
    $req->content_length(do { use bytes; length($data) });
    $req->content($data);
    return $self->ua->request($req);    
}

sub post {
    my $self = shift;
    my %p = validate(@_,
        {
            url => { type => SCALAR },
            data => { required => 1 },
        },
    );
    my $data = JSON::Syck::Dump($p{'data'});
    my $req = HTTP::Request->new('POST' => $p{'url'});
    $req->content_type($self->{'content_type'});
    $req->content_length(do { use bytes; length($data) });
    $req->content($data);
    return $self->{ua}->request($req);    
}

my $rest = Chef::Rest->new(content_type => 'application/json');

while (my @passwd = getpwent) {
  print "Ensuring we have $passwd[0]\n";
  $rest->post(
    url => 'http://localhost:4000/search/user/entries',
    data => {
      id     => $passwd[0],
      name   => $passwd[0],
      uid    => $passwd[2],
      gid    => $passwd[3],
      gecos  => $passwd[6],
      dir    => $passwd[7],
      shell  => $passwd[8],
      change => '',
      expire => $passwd[9],
    }
  )
}
