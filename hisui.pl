#!/usr/bin/perl
use Hisui;
use Getopt::Long;

GetOptions ('help'=>\$help,
            'kbyte'=>\$kbyte,
            'mbyte'=>\$mbyte,
            'gbyte'=>\$gbyte
            );

if (!$help){
  $dic_file = $ARGV[0];
  $size     = $ARGV[1];
}

if (!defined($dic_file)){
  $help = true;
}
if (!defined($size)){
  $help = true;
}
if ($help){
  print <<EOS;

Hisui is randam string generater.

Usage:
  ./hisui.pl DIC_FILE [-kmg]SIZE [-h help]

-------------
  DIC_FILE : dictionary-file for generate
  SIZE     : size of generated string

!!Attention!!
  Sorry, Hisui is greed and gluttony and quiet.
  Let's make it a coffee time.

EOS

  die "\n";
}

if ($kbyte){
  $size = $size*1024;
}
if ($mbyte) {
  $size = $size*1024*1024;
}
if ($gbyte) {
  $size = $size*1024*1024*1024;
} 

$dic_ref = Hisui->Load_Dic($dic_file);
$markov_ref = Hisui->Make_Gen_Hash($dic_ref);
Hisui->generate($size,$markov_ref);
