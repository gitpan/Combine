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

# $Id: FromHTML.pm,v 1.11 2006/10/11 07:52:19 anders Exp $

package Combine::FromHTML;

use strict;
use Combine::Config;
use HTTP::Date;
use URI;
use URI::Escape;
use HTML::Entities;
use Encode;

# Character entities to char mapping. We do NOT convert those 
# entities with a structural meaning, because most likely 
# the output of this module will go through postprocessing. 
#
my %Ent2CharMap=(

# amp    => '&',
# gt    => '>',
# lt    => '<',
# quot   => '"',
# apos   => "'",

 AElig  => '�',
 Aacute => '�',
 Acirc  => '�',
 Agrave => '�',
 Aring  => '�',
 Atilde => '�',
 Auml   => '�',
 Ccedil => '�',
 ETH    => '�',
 Eacute => '�',
 Ecirc  => '�',
 Egrave => '�',
 Euml   => '�',
 Iacute => '�',
 Icirc  => '�',
 Igrave => '�',
 Iuml   => '�',
 Ntilde => '�',
 Oacute => '�',
 Ocirc  => '�',
 Ograve => '�',
 Oslash => '�',
 Otilde => '�',
 Ouml   => '�',
 THORN  => '�',
 Uacute => '�',
 Ucirc  => '�',
 Ugrave => '�',
 Uuml   => '�',
 Yacute => '�',
 aacute => '�',
 acirc  => '�',
 aelig  => '�',
 agrave => '�',
 aring  => '�',
 atilde => '�',
 auml   => '�',
 ccedil => '�',
 eacute => '�',
 ecirc  => '�',
 egrave => '�',
 eth    => '�',
 euml   => '�',
 iacute => '�',
 icirc  => '�',
 igrave => '�',
 iuml   => '�',
 ntilde => '�',
 oacute => '�',
 ocirc  => '�',
 ograve => '�',
 oslash => '�',
 otilde => '�',
 ouml   => '�',
 szlig  => '�',
 thorn  => '�',
 uacute => '�',
 ucirc  => '�',
 ugrave => '�',
 uuml   => '�',
 yacute => '�',
 yuml   => '�',

 copy   => '�',
 reg    => '�',
 nbsp   => "\240",

 iexcl  => '�',
 cent   => '�',
 pound  => '�',
 curren => '�',
 yen    => '�',
 brvbar => '�',
 sect   => '�',
 uml    => '�',
 ordf   => '�',
 laquo  => '�',
 not   => '�',
 shy    => '�',
 macr   => '�',
 deg    => '�',
 plusmn => '�',
 sup1   => '�',
 sup2   => '�',
 sup3   => '�',
 acute  => '�',
 micro  => '�',
 para   => '�',
 middot => '�',
 cedil  => '�',
 ordm   => '�',
 raquo  => '�',
 frac14 => '�',
 frac12 => '�',
 frac34 => '�',
 iquest => '�',
 times => '�',
 divide => '�',

);

my $log;

sub trans {
    my ($html, $xwi, $opt) = @_;
    return undef unless ref $xwi;
    $xwi->url_rewind;  # (BR)
    my $url = $xwi->url_get || return undef; # $xwi object must have url field
    if ( !defined($log) ) { $log = Combine::Config::Get('LogHandle'); }
    if ($$html eq '') { $html = $xwi->content; }
    if ( length($$html) > 1024 ) { # should we check shorter files as well ?
       my $teststring = substr($$html,0,1024);
       my $start_len = 1024;
       $teststring =~ s/[^\s\x20-\xfe]+//g;
       my $len = length($teststring);
       if ( $len > ( 0.9 * $start_len ) ) {  # this is some kind of text
          my @rows = split(/\n/,$teststring);
          shift(@rows); 
          my ($i,$uu,$b64,$r);
	  $uu=0; $b64=0;
	  my $n = $#rows>10 ? 10 : $#rows;
          for($i=0;$i<$n;$i++) {
             $r = shift(@rows);
             $uu++ if (length($r)==61) and (substr($r,0,1) eq "M");
             $b64++ if (length($r)==72) and ($r!~/\s/);
             if ( ( $uu == 10 ) or ( $b64 == 10 ) ) {
                # this is probably uuencoded or base64 encoded
		 $log->say('FromHTML: probably uuencoded or base64 encoded');
                return $xwi;
             }
          }
       } else {
          # this is most likely a binary file => don't parse it
	   $log->say('FromHTML: most likely a binary file');
          return $xwi;
       }
    }


    # Please refer to ToWIR.pm for an explanation of this test.
    # (Why done in two places?!)
    $html = $$html;
    if ($xwi->truncated()) {
       my $last_blank = rindex($html, ' ');
       if ($last_blank > 0) {
	 $html = substr($html, 0, $last_blank);
       }
       else {
	 # What ! No blanks ! This is some weird text => don't parse it
	   $log->say('FromHTML: No blanks');
	 return $xwi;
       }
    }

###    $opt = "HTMLFIC" unless $opt;
#TEST for HTML/text and set $opt accordingly
    $opt .= 'C'; #Always save cleaned content
   if ( $opt =~ /^Guess/ ) {
    if ( ($url =~ /\..?html?$|\/$/i) || 
	 ($html =~ /<\s*html\s*|<\s*head\s*|<\s*body\s*/i) ) {
        if ( ! ($opt =~ /HTML/) ) { 
	  $opt = "HTMLC";
	  $log->say("FromHTML: Changed to HTMLFIC");
        }
    } else {
#test for TeX file
	$opt = "TC";
        if ( ($opt =~ /HTML/) ) { 
	  $log->say("FromHTML: Changed to TC");
        }
    }
}

my $charset=$xwi->charset; #print "GOT charset $charset\n"; ##!!
#Change to robot_get field; do a sanity test

#Convert to UTF8 for Tidy
    my $html_utf8;
    foreach my $cs (split('; ',$charset)) {
        if ($cs eq 'utf8') { $cs = 'UTF-8'; }
	#print "Trying charset=$cs; ";
#	if ( eval{Encode::from_to($html, $cs, 'utf8', Encode::FB_HTMLCREF)} ) {
	if ( eval{$html_utf8 = Encode::decode($cs, $html, Encode::FB_HTMLCREF)} ) {
	    #print "OK";
	    last;
	}
#	else { print "NOT OK; "; }
    }
#    print "\n";
    #NOTHING in html_utf8 unless successfull conversion!! fail-safe below
    if ( ! $html_utf8 ) { 
	$html_utf8 = Encode::decode_utf8(Encode::encode_utf8($html));
	print STDERR "WARN can't decode charset($charset) for $url\n";
	$log->say("WARN can't decode charset($charset) for $url"); 
    }

#Only do for HTML files
if ( $opt =~ /H/ ) {
    # General modifications to the HTML code before extracting our information

    if ( Combine::Config::Get('useTidy') ) {

    #clean character entities #1..#255 to utf-8/latin1
    if (1)
    {
	my $c;
	$html_utf8=~s/(?:&\#(\d+);?)/$1<256 && $1>0 ? chr($1) : ""/ego;
	$html_utf8=~s/(?:&\#[xX]([0-9a-fA-F]+);?)/$c=hex($1); $c<256 && $c>0 ? chr($c) : ""/ego;
	$html_utf8=~s/(&(\w+);)/$Ent2CharMap{$2} || $1/ego;
    }

#	print "Doing Tidy\n";
	require HTML::Tidy;
#	my $tidy = new HTML::Tidy ( {config_file => '/etc/combine/tidy.cfg'} );
	my $tidy = new HTML::Tidy ( {config_file => Combine::Config::Get('baseConfigDir') . '/tidy.cfg'} );
#	$tidy->ignore( type => TIDY_WARNING );
#	if (!eval{$html = $tidy->clean( $html . "\n" )}) { print "TIDY ERR in eval\n"; }
	my $thtml;
        if (!eval{$thtml = $tidy->clean( $html_utf8 . "\n" )}) { print "TIDY ERR in eval\n"; }
#	for my $message ( $tidy->messages ) {
#	    print $message->as_string; #LOG!
#	}
	$html = Encode::decode('UTF-8', $thtml); # convert to Perl internal representation

#	$xwi->meta_add('orig-content-type',$origcharset);
    } else {
	$html_utf8 =~ s/<\!\-\-.*?\-\->/ /sgo; # replace all comments (including multiline) with whitespace
	$html = $html_utf8;
    }
if ( ! Encode::is_utf8($html) ) { print STDERR "WARN HTML content not in UTF-8\n"; } ##

    $html =~ s/<script.*?<\/script>/ /sigo; # remove all the scripts (including multiline)
    $html =~ s/<noscript.*?<\/noscript>/ /sigo; # remove all the scripts (including multiline)
    $html =~ s/<style.*?<\/style>/ /sigo; # remove all the style scripts (including multiline)
##    $html =~ s/[\s\240]+/ /g; # compress whitespace
} else {
    $html = Encode::decode('UTF-8', $html); #?? convert to Perl internal representation
    if ( ! Encode::is_utf8($html) ) { print STDERR "WARN Text content not in UTF-8\n"; } ##
##    $html =~ s/[\s\240]+/ /g; # compress whitespace
}
#End if H

    if ($opt =~ /C/) { # keep content
	my $xwicontent=$html;
	$xwi->content(\$xwicontent);
    }

#Only do for HTML files
if ( $opt =~ /H/ ) {
#    #Split into HEAD and BODY
#    my $head='';
##    if ($html =~ s|^(.*?)<\s*body\s*|<body |i) { #Does not work on ceratin frame-sets
## where the frameset is outside the <body> see http://poseidon.csd.auth.gr/EN/
#    if ( $html =~ s|^(.*?<\s*\/head[^>]*>)||i ) { ???
#	$head=$1;
#    }

    #Parsing and extraction of data
    if ($html =~ /<title>([^<]+)<\/title>/i) { # extract title
	my $tmp = $1;
#	$tmp =~ s/\s+/ /g;   #needed AA0?
	$tmp = HTML::Entities::decode_entities($tmp);
	$xwi->title($tmp);
    }    

=begin comment
This feature is temporarily disabled

    if ($opt =~ /M/) { # extract metadata

	my $summary = "";
	$xwi->meta_rewind;
	my ($name,$content);
	while(1) {
	    ($name,$content) = $xwi->meta_get;
	    if (!defined($name)) { last; }

          #If abstract, description or DC.Description is not a list of keywords: add it to summary
	  if ( $name eq 'description' || $name eq 'dc.description' || $name eq 'abstract' ) {
	      my @kom = split(', ',$content);
	      my @dot = split(' ',$content);
	      if ( $#kom < $#dot ) { #If several meta-fields check if they overlap or are the same##
		  $summary .= $content . ' ';
	      }
	  }
	}

    #Generate Summary
	my $sumlength = Combine::Config::Get('SummaryLength');
#	print "SUM1: $summary\nHTML: $html\n";
	if ( $sumlength > 0 ) {
	    if ( ($sumlength - length($summary)) > 0 ) {
		require HTML::Summary;
		require HTML::TreeBuilder;
		my $html_summarizer = new HTML::Summary( LENGTH => $sumlength - length($summary), USE_META => 0 );
		my $tree = new HTML::TreeBuilder;
		$tree->parse( Encode::encode('latin1',$html) );
#		$tree->parse( $html );
		$tree->eof();
##		$summary .= $html_summarizer->generate ( $tree );
		my $t .= Encode::decode('latin1',$html_summarizer->generate ( $tree ));
		$tree = $tree->delete;
		$summary .= $t;
	    }
	    if (length($summary)>2) {
#		$summary =~ s/[^\w\s,\.\!\?:;\'\"]//gs;
		$summary =~ s/[^\p{IsAlnum}\s,\.\!\?:;\'\"]//gs;
		$summary =~ s/[\s\240]+/ /g;
		$xwi->meta_add("Rsummary",$summary);
	    }
	}
    }#End if M

=end comment

=cut

} #End if H

    my $textdone=0;
    if ($opt =~ /L/) { # extract links
	use Combine::HTMLExtractor;
	my ($alt, $linktext, $linkurl, $base);
	$base = $xwi->base;  #Set by UA.pm
	my $lx = new Combine::HTMLExtractor(undef,undef,1);
#	print "INPUT: $html\n";
#	$html = HTML::Entities::decode_entities( Encode::encode('latin1',$html) );
        $html = HTML::Entities::decode_entities( $html );
	$lx->parse(\$html);

	my %Tags = ( a => 1, area => 1, frame => 1, img => 1, headings => 1, text => 1 );
	for my $link ( @{$lx->links} ) {
#	    print "GOTLINK: $$link{tag} = $$link{_TEXT}\n";
	    next unless exists($Tags{$$link{tag}});
	    my $linktext = $$link{_TEXT} ? $$link{_TEXT} : '';
	    if ( ($$link{tag} eq 'headings') ) {
		if ( $linktext !~ /^\s*$/ ) {
		    $linktext =~ s/^[\s;]+//;
		    $linktext =~ s/[\s;]+$//;
#		    $xwi->heading_add(Encode::decode('latin1',$linktext));
		    $xwi->heading_add($linktext);
		}
		next;
	    } elsif ( ($$link{tag} eq 'text') ) {
#		$linktext = Encode::decode('latin1',$linktext);
		$linktext =~ s/[\s\240]+/ /g; # compress whitespace??
		$xwi->text(\$linktext);
		if (length($linktext)>10) { $textdone=1; }
		next;
	    } elsif ( ($$link{tag} eq 'frame') || ($$link{tag} eq 'img') ) {
		$linkurl = $$link{src};
		$linktext .= $$link{alt} || '';
	    } else {
		$linkurl = $$link{href};
	    }
	    $linktext =~ s/\[IMG\]//g;
            if ( $linkurl !~ /^#/ ) {  # Throw away links within a document
		 $linkurl =~ s/\?\s+/?/;  #to be handled in normalize??
		 my $urlstr = URI->new_abs($linkurl, $base)->canonical->as_string;
#		 $xwi->link_add($urlstr, 0, 0, Encode::decode('latin1',$linktext), $$link{tag});
		 $xwi->link_add($urlstr, 0, 0, $linktext, $$link{tag});
#                 print "ADD: $$link{tag}; $urlstr; |$linktext|\n";
             }
	}
    }

    if ($opt =~ /T/) { # extract text
	if ($textdone == 0) { #not done above in the 'L' section
		$xwi->text(\$html);
	}
    }

    return $xwi;
}

1; 

__END__

=head1 NAME

Combine::FromHTML.pm - HTML parser in combine package

=head1 AUTHOR

Yong Cao <tsao@munin.ub2.lu.se> v0.06 1997-03-19
 Anders Ard� 1998-07-18 
   added <AREA ... HREF=link ...>
   fixed <A ... HREF=link ...> regexp to be more general
 Anders Ard� 2002-09-20
   added 'a' as a tag not to be replaced with space
   added removal of Cntrl-chars and some punctuation marks from IP
   added <style>...</style> as something to be removed before processing
   beefed up compression of sequences of blanks to include \240 (non-breakable space)
   changed 'remove head' before text extraction to handle multiline matching (which can be
      introduced by decoding html entities)
   added compress blanks and remove CRs to metadata-content
 Anders Ard� 2004-04
   Changed extraction process dramatically

=cut
