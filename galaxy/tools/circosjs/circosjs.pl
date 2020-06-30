#!/usr/bin/perl
use Getopt::Long;
use strict;
use CGI;
use Cwd;
my $dir = getcwd;

my $chromosome; #Partie qui récupère les variables
my $output;
my @tracks;
my @select;
my @name;

GetOptions ("chromosome=s" => \$chromosome,    #récupère le fichier de chromosomes
              "tracks=s"   => \@tracks,        #Récupère le tableau de fichier
              "select=s"  => \@select,		   #Récupère le tableau de Select
              "name=s"    => \@name,
              "output=s" => \$output)          #Sortie du fichier
or die("Error in command line arguments\n");

open(O,">$output");
my $q = CGI->new;       
print O $q->header('text/html'); # create the HTTP header
print O $q->start_html(''); # start the HTML


my $base_url = "http://galaxy-demo.excellenceinbreeding.org/";
if ($dir =~/galaxy_dev/){
        $base_url = "http://cc2-web1.cirad.fr/galaxydev/";
}

my $chromosomelength;
if ($chromosome && $chromosome ne 'None'){
	system("cp $chromosome \$HOME/galaxy/static/style/blue/circosjs/");
	my @part = split("/",$chromosome);
	#Déplacement des fichiers dans un répértoire accessible depuis l'exterieur
	$chromosomelength="$base_url/static/style/circosjs/".$part[$#part];
}
# guess chrom length
else{
	my $home = `echo \$HOME`;
	$home =~s/\r//g;$home =~s/\n//g;
	my $chromfile = int(rand(100000000));
	my %size_max;
	foreach my $i (0 .. $#tracks){
		if ($select[$i] ne 'Chords'){
			
			open(T,$tracks[$i]);
			while(<T>){
				my ($chr,$pos) = split(/\s+/,$_);
				if ($pos > $size_max{$chr}){
					$size_max{$chr} = $pos;
				}
			}
			close(T);
		}
	}
	open(F,">/home/galaxy/data/alexis_dereeper/static/style/blue/circosjs/$chromfile");
	foreach my $chrom(sort {$a<=>$b} keys(%size_max)){
		my $size = $size_max{$chrom};
		print F "$chrom $size\n";
	}
	close(F);
	$chromosomelength="$base_url/static/style/circosjs/$chromfile";
}

#Création de la partie script hml qui va être envoyée a Galaxy pour l'interprétation
my $iframe = qq~
<form target="myIframe" action="http://genomeharvest.southgreen.fr/visu/circosJS/demo/index.php" method="post" enctype="multipart/form-data">
<input type="hidden" name="chromosome" value="$chromosomelength" />
~;
foreach my $i (0 .. $#tracks){
	#print "$tracks[$i]";
	system("cp $tracks[$i] /home/galaxy/data/alexis_dereeper/static/style/blue/circosjs/");

	my @part = split("/",$tracks[$i]);
	my $track_file = "$base_url/static/style/circosjs/".$part[$#part];

	# replace tab by space if needed
	my $sed_cmd = "sed -i \"s/\t/ /g\" /home/galaxy/data/alexis_dereeper/static/style/blue/circosjs/".$part[$#part];
	system($sed_cmd);
	$iframe .= qq~
	<input type="hidden" name="select[]" id="annot" value="$select[$i]" />
        <input type="hidden" name="name[]" id="annot" value="$name[$i]" />
	<input type="hidden" name="data[]" id="annot" value="$track_file" />~;
}
$iframe .= qq~
<input type="submit" style="display: none;" id="load" value="reload">
</form><iframe src="" id="myIframe" name="myIframe" width=\"100%\" height=\"1700\" style='border:solid 0px black;'></iframe>
<script>document.getElementById("load").click();</script>
~;
print O $iframe;
close(O);
