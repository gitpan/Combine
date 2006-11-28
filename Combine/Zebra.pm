package Combine::Zebra;

#code based on alvis-zsink.pl from Alvis::Pipeline written by
#Mike Taylor, Index Data ApS.

use strict;
use Combine::XWI2XML;
use ZOOM;

my $options = new ZOOM::Options();
#$options->option(user => $user) if defined $user;
#$options->option(password => $password) if defined $password;
my $conn = create ZOOM::Connection($options);
my $connected=0;

sub update {
  my ($zhost, $xwi) = @_;
  if (!$connected) {
     $conn->connect($zhost);
     print STDERR "connected:\n";
     $connected=1;
  }
  my $xml =  '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
     $xml .= "<documentCollection>\n";
     $xml .= Combine::XWI2XML::XWI2XML($xwi, 0, 0);
     $xml .= "</documentCollection>\n";
  return if length($xml)>4718592; #Record to large for indexing

  AGAIN:
    eval {
	my $p = $conn->package();
	$p->option(action => "specialUpdate");
	$p->option(record => $xml);
	# Could set "recordIdOpaque" if we had a record-ID
	$p->send("update");
	print STDERR "sent package ... ";
	$p->destroy();

	$p = $conn->package();
	$p->option(action => "commit");
	$p->send("commit");
	print STDERR "commit ... ";
    };

    if (!$@) {
	print STDERR "added document\n";
    } elsif (!ref $@ || !$@->isa("ZOOM::Exception")) {
	# A non-ZOOM error, which is totally unexepected.  Treat this
	# as fatal:
	warn $@;
    } elsif ($@->diagset() ne "ZOOM" ||
	     $@->code() != ZOOM::Error::CONNECTION_LOST) {
	# A ZOOM error other than connection lost, e.g. BIB-1 224,
	# "ES: immediate execution failed".  Most such cases need not
	# be treated as fatal, so we just log it and continue.
	warn "$@\n";
    } else {
	# Connection lost, most likely because Zebra got bored and
	# timed it out.  Re-forge the connection and try again.
	warn "ZOOM connection lost (probably due to timeout): re-forging\n";
	create ZOOM::Connection($options);
	$conn->connect($zhost);
	goto AGAIN;
    }

  return;
}

sub init {
  my ($zhost) = @_;
  if (!$connected) {
     $conn->connect($zhost);
     print STDERR "connected:\n";
     $connected=1;
  }

    eval {
	my $p = $conn->package();
	$p->option(action => "drop");
	$p->send("drop");
	print STDERR "sent drop ... ";
	$p->destroy();
	$p = $conn->package();
	$p->option(action => "commit");
	$p->send("commit");
	print STDERR "commit ... ";
    };
  print STDERR "Done\n";
}
##########################
1;
