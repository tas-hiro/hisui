package Hisui;
use Encode;

##########################################
# make-hisui-dic.pl
##########################################

### 対象のファイルをmecabuに渡して、結果を一時ファイルに保存する
sub make_Tempfile{
  my ($mecab,$read_file,$temp_file,$read_str,@str_list,$kaiseki,@kaiseki,$word);
  $mecab = "/usr/local/bin/mecab";
  $hisui = shift;  $read_file = shift;
  $temp_file = "$read_file.tmp";

  open READ,"$read_file"or die "Read file not found\n";
  open TEMP ,"> $temp_file"or die "Can not open tmp file\n";

  while(chomp($read_str = <READ>)){
    $read_str = &shellEsc($read_str);
    if (length(decode('UTF-8',$read_str)) > 10){
      open MECAB , "echo \'$read_str\' | $mecab |";
      while(chomp($kaiseki = <MECAB>)){
        @kaiseki = split(/\t/,$kaiseki);
        $word = $kaiseki[0];
        print TEMP "$word,";
        undef @kaiseki;
      }
    print TEMP "\n";
    }
  }
  close TEMP;  close MECAB;  close READ;
  return $temp_file or die "$!";
}

### shell的に意味のある文字を消す
sub shellEsc {
  my ($read_str);
  $read_str = shift;
  $read_str =~ s/[\&\;\:\&\@\`\,\.\'\"\|\*\?\~\<\>\^\(\(\)\[\]\{\}\$]//g;
  return $read_str or die "$!";
}

### 一時ファイルを読み込む
sub load_temp{
  my ($temp_file,@temp,$temp_str);
  $hisui = shift;
  $temp_file = shift;
  open READ,"$temp_file"or die"Temp file not found\n";
  while(chomp($tmp_str = <READ>)){;
    push @temp,split (",",$tmp_str);
  }
  close READ;
  $temp_ref = \@temp;
  return $temp_ref or die "$!";
}

### 一時ファイルからハッシュを作る
sub hash_by_temp {
  my ($temp_ref,@temp,$markov_ref,%markov,$key1,$key2,$val,$word_count);
  $hisui = shift;
  $temp_ref = shift;   @temp = @{$temp_ref};
  $markov_ref = shift; %markov =%{$markov_ref}; 
  
  if ( @temp > 2) {
    $j=2;
    while ($j < @temp){
      $key1 = $temp[0];
      $key2 = $temp[1];
      $val = $temp[2];
      $markov{$key1}{$key2}{$val}++;
      $j++; $trash=shift @temp;
                        }
    }else{
      die "The word is not enough\n";
    }
  undef @temp;
  $markov_ref = \%markov;
  return $markov_ref or die "$!";
}

### csvとして保存する。形式は key1,key2,val1,出現回数,val2,出現回数,val3...
sub save_dic {
  my($write_file,$markov_ref,%markov,$print,@print,$key1,$key2,$val,$score,$score_num);
  $hisui = shift;    $write_file = shift;
  $markov_ref = shift;  %markov = %{$markov_ref};
  $score_num = shift;

  open WRITE , "> $write_file " or die "Write file not found\n";
  foreach my $key1 (keys %markov){
    foreach my $key2 (keys %{$markov{$key1}}){
      $print[0] = $key1;
      $print[1] = $key2;
      foreach my $val (keys %{$markov{$key1}{$key2}}){
        $count_num = $markov{$key1}{$key2}{$val};
        $score =&get_score($count_num,$score_num);
        if ($score > 0){
           push @print,$val;
           push @print,$score;
        }
      }
    &Check_End(@print);
    undef @print;
    }
  }
  close WRITE;
  return 1;
}

### 出現回数を計算する
sub get_score {
  my ($score,$count_num,$count_num);
  $count_num = shift;
  $score_num = shift;
  $score = int($count_num/$score_num);
  if($score > 10){
    $score = 10;
  }
  return $score;
}

### mecabuの結果、文末ならEOSを、
### それ以外ならカンマを辞書ファイルに書きこむ
sub Check_End{
  my(@print);
  @print = @_;	
  if($print[0] eq $print[2] ){
  undef @print;
  }elsif($print[1] =~ "EOS"){
    undef @print;
  }elsif(defined($print[2])){
    print WRITE join ",",@print;
    print WRITE "\n";
    undef @print;
  }
}


##########################################
# hisui.pl
##########################################
### 辞書ファイルを読み込む
sub Load_Dic {  
  my  (@dic,$dic_str,$dic_ref);
  $hisui = shift;
  $dic_file = shift;
  
  open FILE , "$dic_file"or die "Dictionary file not found\n";
  while($dic_str = <FILE>){
    chomp ($dic_str);
    push (@dic,$dic_str);
  }
  close FILE;
  undef $dic_str;
  $dic_ref = \@dic;
  return $dic_ref;
}
=put
sub hash_by_dic {
  my (@dic,$dic,$num,@word,%markov,$a,$b,$dic_ref,$markov_ref);
  $hisui = shift;
  $dic_ref = shift;
  @dic = @{$dic_ref};

  foreach $dic (@dic){
    @word = split (/,/, $dic );
    for($a=3 ; $a < @word ; $a+=2){
      $num = $word[$a];
      for( $b=0 ; $b<$num ;$b++ ){
        $markov{$word[0]}{$word[1]}{$word[$a-1]} = $word[$a];
      }
    }
  }
  undef @dic;  undef @word;
  $markov_ref = \%markov;
  return $markov_ref or die "$!";
}
=cut

### 文字列作成用のハッシュを作る
sub Make_Gen_Hash {
  my($dic_ref,@dic,$dic,@word,$a,$b,$markov_ref);
  our(%markov);
  $hisui = shift;
  $dic_ref = shift;  @dic = @{$dic_ref};
  foreach $dic (@dic){
    @word = split(/,/,$dic);
    for($a=3 ; $a < @word ; $a+=2){
#     $score = $word[$a];              #####重み付け
#     for( $b=0 ; $b<$score ;$b++ ){   #####重み付け
        push (@{$markov{$word[0]}{$word[1]}},$word[$a-1]);
      #}
    }
  }
  undef @dic;
  $markov_ref = \%markov;
  return $markov_ref or die "$!";
}

### ハッシュから文字列の作成
sub generate{
  my ($byte,$markov_ref,%markov,$key1,$key2,$next,$EOS_list,$string_ref);
  our (@EOS);
  $hisui = shift;
  $byte = shift;
  $markov_ref = shift;  %markov = %{$markov_ref};
  undef $markov_ref;

  # マルコフ連鎖の初期値設定
  $key1 = "EOS";
  foreach (keys %{$markov{$key1}}){
    push (@EOS,$_);
  }
  $key2 = $EOS[int(rand(@EOS))];
  $next = &Get_Next($key1,$key2);

  &Gen_String($key1,$key2,$next,$byte);
  undef @EOS;
  undef %markov;
  return;
}

sub Gen_String{
  my($key1,$key2,$next,$string,$byte,$trush,$length);
  $key1 = shift; $key2 = shift; $next = shift; $byte = shift;
  $string = $key2;

  while($length < $byte){
    $string = &Check_Next($next);
    print $string;
    $length += length($string);
    $trash = $key1;
    $key1 = $key2;
    $key2 = $next;
    $next = &Get_Next($key1,$key2);
    ($key2,$next) = &Check_Loop($key2,$next,$trush);
  }
  return ;
}

sub Check_Loop{
  my($key2,$trush,$next);
  $key2 = shift;
  $next = shift;
  $trush = shift;
  unless($next){
    $key2 = "EOS";
    $next = $EOS[int(rand(@EOS))];
  }
  if($trash eq $next){
    $key2 = "EOS";
    $next = $EOS[int(rand(@EOS))];
  }
  return $key2,$next or die "$!";
}

sub Check_Next{
  my($next);
  $next = shift;
  if($next eq "。"){
    $next .= "\n";
  }elsif($next ne "EOS"){
    $next = $next;
  }else{
    $next = "\n";
  }
  return $next or die "$!";
}

sub Get_Next{
my($key1,$key2,$next,$rand);
  $key1 = shift;
  $key2 = shift; 
  $rand = int(rand(@{$markov{$key1}{$key2}}));
  $next = $markov{$key1}{$key2}[$rand];
  return $next or die "$!";
}
return 1;
