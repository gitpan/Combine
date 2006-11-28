# Copyright (c) 1996-1998 LUB NetLab
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 1, or (at your option)
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
# 
# 
# 			    NO WARRANTY
# 
# BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
# FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
# OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
# PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
# OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
# TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
# PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
# REPAIR OR CORRECTION.
# 
# IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
# WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
# REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
# INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
# OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
# TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
# YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
# PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGES.
# 
# Copyright (c) 1996-1998 LUB NetLab

# $Id: UA.pm,v 1.6 2006/10/20 07:02:08 anders Exp $


# COMB/XWI/UA.pm - harvesting robots with XWI interface
# v0.01 by Yong Cao, 1997-08-08

package Combine::UA;

use strict;
use Combine::Config;
use LWP::UserAgent;
use HTTP::Date;
use Digest::MD5;

my $expGar;
my $userAgentGetIfModifiedSince;

sub TruncatingUserAgent {

  # This function returns an LWP::UserAgent that truncates incoming data
  # when a number of bytes, that's dictated by Combine's configuration set,
  # has been received.
  #
  # Experiments (1999-02-02) have shown that the truncation is approximate
  # in that the resulting document size may vary up or down a few percents
  # or kilobytes.

  my $ua = new LWP::UserAgent();
#  $ua->max_size(COMB::Config::GetMaxDocSize()); #Problem with webservers returning 206 partial content in a multipart
  $ua->timeout(Combine::Config::Get('UAtimeout'));
  $ua->agent("Combine/3 http://combine.it.lth.se/");
  $ua->from(Combine::Config::Get('Operator-Email'));
  if (Combine::Config::Get('httpProxy')) {
    $ua->proxy(['http', 'https'], Combine::Config::Get('httpProxy'));
  }
  $expGar = Combine::Config::Get('WaitIntervalExpirationGuaranteed');
  $userAgentGetIfModifiedSince = Combine::Config::Get('UserAgentGetIfModifiedSince');
  return $ua;
}


sub fetch { # use get-if-modified-since
    my ($xwi, $since) = @_;
    my ($url_str, $ua, $req, $resp, $code, $msg, $method, $type, $ext);
    $ua = TruncatingUserAgent();
#FIX!    $since = $jcf->ftime unless $since; 
    $since = time - $expGar unless $since;
    $url_str = $xwi->url;
    $type = ''; #FIX $jcf->typ;
    $method = "GET";
    if ( $type ) {
       $method = "HEAD" unless defined(${Combine::Config::Get('converters')}{$type});
    } else {
       if ( $url_str =~ m/\.([^\/\s\.]+)\s*$/ ) {
         $ext = $1;
	 $ext =~ tr/A-Z/a-z/;
         $method = "HEAD" if  defined(${Combine::Config::Get('binext')}{$ext});
       }
    }
    if ( $method eq "HEAD" ) {
      $req = new HTTP::Request 'HEAD'=> $url_str;
      $req->header('If-Modified-Since' => &time2str($since))
	if $userAgentGetIfModifiedSince;
      if (Combine::Config::Get('UserAgentFollowRedirects')) { $resp = $ua->request($req); }
      else { $resp = $ua->simple_request($req); }
      $code = $resp->code;
      $msg = $resp->message();
      $method = "";
      if ( $code eq "200" ) {
         $type = $resp->header("content-type");
         $method = "GET" if $type and defined(${Combine::Config::Get('converters')}{$type}); 
      }
    }
    if ( $method eq "GET" ) {
      $req = new HTTP::Request 'GET'=> $url_str;
      $req->header('If-Modified-Since' => &time2str($since))
	if $userAgentGetIfModifiedSince;
      if (Combine::Config::Get('UserAgentFollowRedirects')) { $resp = $ua->request($req); }
      else { $resp = $ua->simple_request($req); }
      $code = $resp->code;
      $msg = $resp->message();
#      print "$url_str; " . &time2str($since) ."; $code; $msg\n";
    }
#Determine charset
#    my $t = $resp->content_type; print "  CT: $t;; TYPE=$type;\n";
    my $charset='';
    my @charset = ('iso-8859-1'); #default
    my @t = $resp->content_type;
    foreach my $t (@t) {
#	print "  CTA: $t\n";
	if ($t =~ /charset/ ) { $charset = $t; }
    }
    $charset=clean($charset);
#    print "tmpFINAL: $charset\n";
    if ( $charset ne '' ) { unshift(@charset,$charset); }

    my @cs=$resp->header('Content-Type');
    foreach my $c (@cs) {
#	print "  Content-Type:  $c\n";
	$charset=clean($c);
#	print "Charset=$charset;\n";
	if ( $charset ne '' ) { unshift(@charset,$charset); }
    }

#    if ( $charset eq '' ) {
#	$charset = 'iso-8859-1';
#	print "CHARSET=$charset; (default)\n";
#    }
    $charset = join('; ',@charset);
#    print "FINAL: $charset\n";
    $xwi->charset($charset); ##!! Change to robot_add; See FromHTML;
    $xwi->robot_add('charsetlist',$charset);
#Do a sanity test of charset
#From RFC 2616  Hypertext Transfer Protocol -- HTTP/1.1
#The "charset" parameter is used with some media types to define the
#   character set (section 3.4) of the data. When no explicit charset
#   parameter is provided by the sender, media subtypes of the "text"
#   type are defined to have a default charset value of "ISO-8859-1" when
#   received via HTTP. Data in character sets other than "ISO-8859-1" or
#   its subsets MUST be labeled with an appropriate charset value.
    sub clean {
	my ($cs) = @_;
	if ( $cs ne '' ) {
	    $cs =~ s|text/[^\s;]+;?\s*||i;
	    $cs =~ s|image/[^\s;]+;?\s*||i;
	    $cs =~ s|application/[^\s;]+;?\s*||i;
	    $cs =~ s/charset=//ig;
	    $cs =~ s/[\"\';]//g;
	    $cs =~ s/^\s+//;
	    $cs =~ s/\s+$//;
	    $cs =~ s/UTF-?/utf/i;
	    if (($cs ne '') && (!Encode::resolve_alias($cs))) {
#		print STDERR "RESET CHARSET cs=$cs;\n";
		$cs='';
	    }
	}
	return $cs;
    }
sub decodeText {
  my ($charset, $text) = @_;
  #Convert to UTF8
  my $t_utf8;
  foreach my $cs (split('; ',$charset)) {
    if ($cs eq 'utf8') { $cs = 'UTF-8'; }
#    print "Trying UA charset=$cs; ";
    if ( eval{$t_utf8 = Encode::decode($cs, $text)} ) {
#       print "OK";
       last;
    }
#       else { print "NOT OK; "; }
    }
#    print "\n";
    #NOTHING in t_utf8 unless successfull conversion!! fail-safe below
    if ( ! $t_utf8 ) { 
        $t_utf8 = Encode::decode_utf8(Encode::encode_utf8($text));
#        print STDERR "WARN can't decode charset($charset) for $url\n";
#        $log->say("WARN can't decode charset($charset) for $url"); 
    }
    return $t_utf8;
}

#Extract Meta tags to xwi-object
#print "Using Charset=$charset\n";
    my @mt = $resp->header_field_names;
    foreach my $f (@mt) {
#	print "Field: $f\n";
	if ( $f =~ /^X-Meta-(.*)$/ ) {
	    my $name = lc($1);
	    my @cs=$resp->header($f);
	    foreach my $c (@cs) {
#		$xwi->meta_add($name,Encode::decode($charset, $c));
		$xwi->meta_add($name,decodeText($charset, $c));
#		print "  XMETA: $name, $c\n";
	    }
	} elsif ( $f =~ /Content-Type/ ) {
	    my @cs=$resp->header($f);
	    my $name = lc($f);
	    foreach my $c (@cs) {
		$xwi->meta_add($name,$c);
#		print "  Content-Type: $name, $c\n";
	    }
	}
    }

    $xwi->stat($code);
    $xwi->url($url_str);
    $xwi->server($resp->header("server"));
    $xwi->etag($resp->header("etag"));
    my $t = $resp->content_type;
    $xwi->type($t);
    $t = $resp->content_language;
    if (defined($t)) {$xwi->meta_add('content-language',$t);}
    $xwi->length($resp->header("content-length"));
    $xwi->location($resp->header("location"));
    $xwi->base($resp->base);
    $xwi->expiryDate(&check_date($resp->expires));
    $xwi->modifiedDate(&check_date($resp->header("last-modified")));
    $xwi->expiryDate(&check_date($resp->header("expires")));
#?    $xwi->checkedDate(&check_date($resp->header("date")));
    $xwi->checkedDate(time) unless $xwi->checkedDate;
    if ($code eq "200" or $code eq "206") {
  	my $md5 = new Digest::MD5;
	$md5->reset;
        if ( $method eq "GET" and length($resp->content_ref) > 0 ) {
	  $xwi->truncated($resp->headers()->header('X-Content-Range'));
	  $md5->add(${$resp->content_ref});
        } else {
	  $md5->add($url_str);
	  $md5->add($xwi->type());
        }
	$_ = $md5->hexdigest;
	tr/a-z/A-Z/;
	$xwi->md5($_);
	$xwi->content($resp->content_ref);
    }
    return ($code, $msg); 
}

sub check_date { # makes sure the date is in a correct format (UnixTime)
   my ($str) = @_;
   my $tim = undef;
   if ( $str ) {
      eval { $tim = &str2time( $str ) };
      return $tim;
   }
}

1;
