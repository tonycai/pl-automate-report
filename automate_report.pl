#!/usr/bin/perl -w
use strict;
use warnings;
use utf8;
use DBI;
use Encode;
use Getopt::Long;
use Time::HiRes qw(gettimeofday);
use Net::SMTP;
use Authen::SASL;
#use Encode::HanExtra;
#use utf8;
#binmode(STDIN, ':encoding(utf8)');
#binmode(STDOUT, ':encoding(utf8)');
#binmode(STDERR, ':encoding(utf8)');

BEGIN {
push (@INC,'/usr/lib/perl5/5.8.8/Net/ ');

}

use Encode;

use POSIX;

binmode(STDOUT, ":utf8");


my ($timestamp, $start_usec) = gettimeofday;

my ($sec,$min,$hour,$mday,$mon,$year, $wday,$yday,$isdst) = localtime($timestamp-86400*1);


####
my %opt = (
                "db_name" => '',
                "db_host" => '',
                "db_port" => '',
                "db_user" => '',
                "db_password" => '',
                "mail_orgname" => '',
                "mail_sender" => '',
                "mail_password" => '',
                "mail_receiver" => '',
        );
####

my $config = './config/settings.txt';
if (-e $config)
{
    if (open CFG, "<$config")
    {
        while (<CFG>)
        {
            next if /^\s*$/;  ## skip blanks
            next if /^\s*#/;  ## skip comments

            chomp;

            if (/(\S+)\s*=\s*(.*\S)/)
            {
                #$opt{lc $1} = $2 if exists $opt{lc $1};
                $opt{lc $1} = $2 ;
            }
        }
        close CFG;
    }
}
####
####

#print "$current_date\n";
#exit 1;


#my $orgname = encode(utf8=>$opt{mail_orgname});
my $orgname = $opt{mail_orgname};
my $from = $orgname . ' <'.$opt{mail_sender}.'>';
my $to = $opt{mail_receiver};
my $username = $opt{mail_sender};
my $passwd = $opt{mail_password};
my $subject = 'Test Email';
my $smtp = Net::SMTP->new($opt{mail_smtp_server});

#print Dumper(%opt);
#print "smtp: " .$opt{mail_smtp_server}." \n";
#exit 1;

$smtp->auth($username,$passwd) or die "Could not authenticate $!";
$smtp->mail($from);

my $db_name = $opt{db_name};

my $db_host = $opt{db_host};
my $db_port = $opt{db_port};
my $dbw = "DBI:mysql:$db_name$db_host$db_port";
my $db_user = $opt{db_user};
my $db_pass = $opt{db_password};

my $dbh = DBI->connect($dbw,$db_user,$db_pass);
$dbh->do("SET NAMES '".$opt{db_charset}."';");

&seek_sales_list('', $dbh);

$smtp->quit;

sub repl{
    my($str) = @_;
    $str =~ s/ //g;
    $str =~ s/　//g;
    $str =~ s/"//g;
    $str =~ s/\n//g;
    return $str;
}

sub repl_string{
    my($str) = @_;
    $str =~ s/'/\\'/g;
    return $str;
}

sub removing_html_tags {
    my($str) = @_;
    $str =~ s/<[^>]*>//sg;
    $str =~ s/\&nbsp;/ /sg;
    $str =~ s/\s+/ /sg;
    $str =~ s/^\s+//sg;
    $str =~ s/\s+$//sg;
    return $str;
}

sub replp{
  my($str) = @_;
  $str =~ s/\?/\\?/g;
  $str =~ s/&/\\&/g;
  $str =~ s/=/\\=/g;
  return $str;
}

sub query{
    my($sql, $dbh) = @_;
    return "" if ($sql eq "");
    my $sth = $dbh->prepare($sql);
    $sth->execute() or die "error-SQL:$dbh->errstr";
    return 1;
}

sub removing_html_tags2 {
    my($str) = @_;
    $str =~ s/<[^>]*>//gs;
    $str =~ s/\s\s\s+/, /gs;
    $str =~ s/^, //gs;
    $str =~ s/, $//gs;
    return $str;
}

sub remove_a_tag {
    my $str  = shift;
    $str =~ s/<a .+?>(.+?)<\/a>/$1/ig;
    $str =~ s/^\s+//ig;
    $str =~ s/\s+$//ig;
    return $str;
}

sub seek_user_list {
    my($str, $dbh) = @_;
    my $current_date = sprintf("%d-%02d-%02d", $year+1900, $mon+1, $mday);
    my $current_month = sprintf("%d-%02d", $year+1900, $mon+1, $mday);
    my $mail_body = '';
    print "$current_date\n";
    my ($mail_body_daily, $mail_body_monthly) = ('', '');
    my $sql = "select * from t_name where 1=1 order by id desc limit 10;";
    my $sth = $dbh->prepare($sql);
    
    $sth->execute() or die "error-SQL:$dbh->errstr";
    while (my $ref = $sth->fetchrow_hashref()) {
        my $sid = $ref->{id};
        my $s_name = decode(utf8=>$ref->{name});
        my $email_address = $ref->{email_address};

        print "$sid , $s_name , $email_address \n";
        sleep(10);

        if(1){
           $mail_body = '
'.$s_name.' :

<br />
<br />
'.$mail_body_daily.'
<br />
<br />
'.$mail_body_monthly.'
<br />
<br />
-TEAMWORK

<!-- CSS goes in the document HEAD or added to your external stylesheet -->
<style type="text/css">
table.imagetable {
font-family: verdana,arial,sans-serif;
font-size:11px;
color:#333333;
border-width: 1px;
border-color: #999999;
border-collapse: collapse;
}
table.imagetable th {
background:#b5cfd2 ;
border-width: 1px;
padding: 8px;
border-style: solid;
border-color: #999999;
}
table.imagetable td {
background:#dcddc0 ;
border-width: 1px;
padding: 8px;
border-style: solid;
border-color: #999999;
}
</style>
';
        my $guest_mail = 'xxx@gmail.com';
        
        
        my $mail_subject = 'automated - ' . ${current_date};
        
          $mail_subject = encode(utf8=>$mail_subject);
          $mail_body = encode(utf8=>$mail_body);
        
          $smtp->to($to);
          $smtp->data();
          $smtp->datasend("From:$from\n");
          $smtp->datasend("To: $to\n");
          $smtp->datasend("Subject: $mail_subject\n");
          $smtp->datasend("Content-type:text/html\n\n");
          $smtp->datasend($mail_body);
          $smtp->dataend();
        
        }
    }
=head
=cut
    return 1;
}
