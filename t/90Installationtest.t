use strict;
local $^W = 0;
our $jobname;
require './t/defs.pm';

use Test::More tests => 2;
use Cwd;

my $orec='';
while (<DATA>) { chop; $orec .= $_; }
$orec =~ s|<checkedDate>.*</checkedDate>||;
$orec =~ s|<httpServer>.*</httpServer>||;
$orec =~ tr/\n\t //d;
my $olen=length($orec);
my $onodes=0;
while ( $orec =~ m/</g ) { $onodes++; }
#print "ORIG Nodes=$onodes; Len=$olen\n";

my $confdir=getcwd . '/blib/conf';

system("perl  \"-Iblib/lib\" blib/script/combineINIT --baseconfig $confdir --jobname $jobname --topic conf/Topic_carnivor.txt > /dev/null 2> /dev/null");

system("perl  \"-Iblib/lib\" blib/script/combine --baseconfig $confdir --jobname $jobname --harvest http://combine.it.lth.se/CombineTests/InstallationTest.html");

open(REC,"perl  \"-Iblib/lib\" blib/script/combineExport --baseconfig $confdir --jobname $jobname |");

my $rec='';
while (<REC>) { chop; $rec .= $_; }
close(REC);
$rec =~ s|<checkedDate>.*</checkedDate>||;
$rec =~ s|<httpServer>.*</httpServer>||;
$rec =~ tr/\n\t //d;

my $len=length($rec);
my $nodes=0;
while ( $rec =~ m/</g ) { $nodes++; }
#print "NEW Nodes=$nodes; Len=$len\n";

is($onodes,$nodes, 'Number of XML nodes') ;

if ($olen == $len) {
  ok(1,"Size of XML match");
} else {
  $orec =~  s|<originalDocument.*</originalDocument>||s;
  $rec =~  s|<originalDocument.*</originalDocument>||s;
  is(length($orec),length($rec), 'Size of XML match (after removal of originalDocument)');
}

#print "O: $orec\n\nN: $rec\n";

#if (($OK == 0) && ($orec eq $rec)) { print "All tests OK\n"; }
#else { print "There might be some problem with your Combine Installation\n"; }

__END__
<?xml version="1.0" encoding="UTF-8"?>
<documentCollection version="1.1" xmlns="http://alvis.info/enriched/">
<documentRecord id="1">
<acquisition>
<acquisitionData>
<modifiedDate>2006-12-05 13:20:25</modifiedDate>
<checkedDate>2006-10-03 9:06:42</checkedDate>
<httpServer>Apache/1.3.29 (Debian GNU/Linux) PHP/4.3.3</httpServer>
<urls>
    <url>http://combine.it.lth.se/CombineTests/InstallationTest.html</url>
  </urls>
</acquisitionData>
<originalDocument mimeType="text/html" compression="gzip" encoding="base64" charSet="UTF-8">
H4sIAAAAAAAAA4WQsU7DMBCG9zzF4bmpBV2QcDKQVKJSKR2CEKObXBSrjm3sSyFvT0yCQGJgusG/
//u+E1flU1G9HrfwUD3u4fh8v98VwFLOXzYF52VVzg+b9Q3n2wPLE9FRr+NA2UyDFGnMdyaQ1FqS
sgYIA0FrPRS2PymDgs+hRPRIEozsMWNnHN+tbwKD2hpCQxkrpDfqYr0dAjgtDYUVlN4G9HIFB3RT
qMPAvns6Ipfi26Au09e5I61Gh78aCT+IR947qDvpA1I2UJvexg6+CJxsM0ad6/8kpkQiXB5XSWUC
BNsj/GGG4LBWrarhSw+0OiOIidZjmzGPeh15WL6ICS7zFUjT/AiuBXeRbwHj870/AeRYaTupAQAA
</originalDocument>
<canonicalDocument>  
  <section>
    <section title="Installation test for Combine">
      <section>Installation test for Combine</section> 
      <section>Contains some Carnivorous plant specific words like <ulink url="rel.html">Drosera </ulink>, and Nepenthes.</section></section></section></canonicalDocument>
<metaData>
    <meta name="title">Installation test for Combine</meta>
    <meta name="dc:format">text/html</meta>
    <meta name="dc:format">text/html; charset=iso-8859-1</meta>
    <meta name="dc:subject">Carnivorous plants</meta>
    <meta name="dc:subject">Drosera</meta>
    <meta name="dc:subject">Nepenthes</meta>
  </metaData>
<links>
    <outlinks>
      <link type="a">
        <anchorText>Drosera</anchorText>
        <location>http://combine.it.lth.se/CombineTests/rel.html</location>
      </link>
    </outlinks>
  </links>
<analysis>
<property name="topLevelDomain">se</property>
<property name="univ">1</property>
<property name="country">Sweden</property>
<property name="language">en</property>
<topic absoluteScore="1000" relativeScore="99415">
    <class>ALL</class>
  </topic>
<topic absoluteScore="375" relativeScore="37281">
    <class>CP.Drosera</class>
    <terms>drosera</terms>
  </topic>
<topic absoluteScore="375" relativeScore="37281">
    <class>CP.Nepenthes</class>
    <terms>nepenthe</terms>
  </topic>
<topic absoluteScore="250" relativeScore="24854">
    <class>CP</class>
    <terms>carnivorous plant</terms>
    <terms>carnivor</terms>
  </topic>
</analysis>
</acquisition>
</documentRecord>

</documentCollection>
