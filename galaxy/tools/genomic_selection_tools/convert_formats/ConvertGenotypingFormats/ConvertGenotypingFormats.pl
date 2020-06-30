#!/usr/bin/perl

use strict;

use Getopt::Long;

my $usage = qq~Usage:$0 <args> [<opts>]
where <args> are:
    -i, --input         <input file>
    -o, --output        <output file>
    -f, --format        <format for output: vcf, hapmap, hapmap_numeric, hapmap_iupac, numeric, csv, flapjack, transposed_csv>
<opts> are
    -k, --keep_metadata <keep metadata information. True/False. Default:True>
    -d, --directory     <directory to access transpose>
~;
$usage .= "\n";

my ($input,$outfile,$format,$keep,$dir);
$keep = "True";

GetOptions(
        "input=s"    => \$input,
        "format=s"   => \$format,
        "output=s"   => \$outfile,
	"keep=s"     => \$keep,
	"dir=s"      => \$dir
);



die $usage
  if ( !$input || !$outfile || !$format);
  
my %complement = ("A"=>"T","T"=>"A","G"=>"C","C"=>"G");

my %iupac =
(
		'[A/A]'=> "A",
		'[C/C]'=> "C",
		'[G/G]'=> "G",
		'[T/T]'=> "T",
		'[N/N]'=> "N",
        '[A/G]'=> "R",
        '[G/A]'=> "R",
        '[C/T]'=> "Y",
        '[T/C]'=> "Y",
        '[T/G]'=> "K",
        '[G/T]'=> "K",
        '[C/G]'=> "S",
        '[G/C]'=> "S",
        '[A/T]'=> "W",
        '[T/A]'=> "W",
        '[A/C]'=> "M",
        '[C/A]'=> "M",
        '[C/A/T]'=> "H",
        '[A/T/C]'=> "H",
        '[A/C/T]'=> "H",
        '[C/T/A]'=> "H",
        '[T/C/A]'=> "H",
        '[T/A/C]'=> "H",
        '[C/A/G]'=> "V",
        '[A/G/C]'=> "V",
        '[A/C/G]'=> "V",
        '[C/G/A]'=> "V",
        '[G/C/A]'=> "V",
        '[G/A/C]'=> "V",
        '[C/T/G]'=> "B",
        '[T/G/C]'=> "B",
        '[T/C/G]'=> "B",
        '[C/G/T]'=> "B",
        '[G/C/T]'=> "B",
        '[G/T/C]'=> "B",
        '[T/A/G]'=> "D",
        '[A/G/T]'=> "D",
        '[A/T/G]'=> "D",
        '[T/G/A]'=> "D",
        '[G/T/A]'=> "D",
        '[G/A/T]'=> "D",
        '[C/T/A/G]'=> "N",
        '[C/A/G/T]'=> "N",
        '[C/A/T/G]'=> "N",
        '[C/T/G/A]'=> "N",
        '[C/G/T/A]'=> "N",
        '[C/G/A/T]'=> "N",
        '[A/C/T/G]'=> "N",
        '[A/T/G/C]'=> "N",
        '[A/T/C/G]'=> "N",
        '[A/C/G/T]'=> "N",
        '[A/G/C/T]'=> "N",
        '[A/G/T/C]'=> "N",
        '[T/C/A/G]'=> "N",
        '[T/A/G/C]'=> "N",
        '[T/A/C/G]'=> "N",
        '[T/C/G/A]'=> "N",
        '[T/G/C/A]'=> "N",
        '[T/G/A/C]'=> "N",
        '[G/C/A/T]'=> "N",
        '[G/A/T/C]'=> "N",
        '[G/A/C/T]'=> "N",
        '[G/C/T/A]'=> "N",
        '[G/T/C/A]'=> "N",
        '[G/T/A/C]'=> "N"
);

my %reverse_iupac = reverse %iupac;


######################################################
# guess input format
######################################################
my $informat;
open(F,$input) or die "Can't open $input: $!";
while(<F>){
	if (!/^#/ && !/^rs#/){
		$_ =~s/\|/\//g;
		if (/,\d+,\d+,\d+/){
			$informat = "csv";
			last;
		}
		if (/\t\d+\t\d+\t\d+/){
			$informat = "hapmap_numeric";
			last;
		}
		if (/\t[ATCG][ATCG]\t[ATCG][ATCG]\t[ATCG][ATCG]/){
			$informat = "hapmap";
			last;
		}
		if (/\t[01\.]\/[01\.]\t[01\.]\/[01\.]\t[01\.]\/[01\.]/){
			$informat = "vcf";
			last;
		}
		if (/\t\w\t\w\t\w/){
			$informat = "hapmap_iupac";
			last;
		}
		
	}
}
close(F);


print $keep;
print "Format: $informat\n";
######################################################
# parse complete input
######################################################
open(F,$input) or die "Can't open $input: $!";
open(O,">$outfile") or die "Can't open $outfile: $!";
if ($format eq 'vcf'){
	print O "##fileformat=VCFv4.1\n";
}
if ($format eq 'flapjack'){
	#print O "# fjFile = GENOTYPE\n";
}
my %hash1;
my @individuals;
my $newheaders = 0;
my $countn = 0;
my $is_numeric_only = 0;
while(<F>){
	my $line = $_;$line=~s/\n//g;$line=~s/\r//g;
	$countn++;
	
	#####################################
	# individual info
	#####################################
	if ($informat =~/hapmap/ && /^rs#/){
		my @infos = split(/\t/,$line);
		for (my $i = 11; $i <= $#infos; $i++){
			my $ind = $infos[$i];
			$hash1{$i} = $ind;
			push(@individuals,$ind);
		}
	}
	if ($informat =~/hapmap/ && !/^rs#/ && !/^#/ && $countn == 1){
		my @infos = split(/\t/,$line);
		for (my $i = 0; $i <= $#infos; $i++){
			my $ind = $infos[$i];
			$hash1{$i} = $ind;
			push(@individuals,$ind);			
		}
		$is_numeric_only = 1;
	}
	if ($informat =~/vcf/ && /#CHROM/){
		my @infos = split(/\t/,$line);
		for (my $i = 9; $i <= $#infos; $i++){
			my $ind = $infos[$i];
			$hash1{$i} = $ind;
			push(@individuals,$ind);
		}
	}

	if ($informat =~/hapmap/ && /^#/ && $format =~/hapmap/ && $keep eq "True"){
		print O $_;
	}
	
	#####################################
	# re-write headers
	#####################################
	if (scalar @individuals > 1 && $newheaders==0){
		if ($format =~/hapmap/){
			print O "rs#	alleles	chrom	pos	strand	assembly#	center	protLSID	assayLSID	panelLSID	QCcode	".join("\t",@individuals)."\n";
		}
		elsif ($format =~/numeric/){
			print O join("\t",@individuals)."\n";
		}
		elsif ($format =~/flapjack/ or $format =~/transposed_csv/){
			print O "Marker	". join("\t",@individuals)."\n";
		}
		elsif ($format =~/csv/){
                        print O join(",",@individuals)."\n";
                }
		elsif ($format =~/vcf/){
			print O "#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	".join("\t",@individuals)."\n";	
		}
		$newheaders=1;
	}

	#####################################
	# get genotyping
	#####################################
	my %genotyping;
	my $marker;
	my $chrom;
	my $pos;
	my $refallele;
	my $altallele;
	my $altallele2;
	my %alleles;
	
	if ($is_numeric_only == 1 && $countn == 1){
		next;
	}
	#############################################
	# parse Hapmap
	#############################################
	if ($informat =~/hapmap/ && !/^#/ && !/^rs#/){
		# TODO: to be fixed
		if (/\/-/ or /\/\+/ or /-\// or /\+\//){
			next;
		} 
		my @infos = split(/\t/,$line);
		$chrom = $infos[2];
		$pos = $infos[3];
		
		my @alleles_found = split(/\//,$infos[1]);
		if (scalar @alleles_found == 2){
			$refallele = $alleles_found[0];
			$altallele = $alleles_found[1];
		}
		if (scalar @alleles_found == 3){
			$refallele = $alleles_found[0];
			$altallele = $alleles_found[1];
			$altallele2 = $alleles_found[2];
			next;
		}

		my $start_loop = 11;
		# numeric only must be converted
		if (!$refallele && !$altallele && $is_numeric_only){
			if ($countn == 1){next;}
			$chrom = 1;
			$pos = $countn;
			$refallele = "A";
			$altallele = "C";
			$start_loop = 0;
		}
			
		
		$marker = $chrom."_".$pos;
		my %alleles_fo;
		for (my $i = $start_loop; $i <= $#infos; $i++){
			my $allele = $infos[$i];
			
			my $ind = $hash1{$i};
			
			my $genotype;
			my $do = 0;
			if ($informat eq "hapmap_iupac"){
				if ($allele =~/[RYKSWM]/){
					
					$genotype = $reverse_iupac{$allele};
					$genotype =~s/\[//g;$genotype =~s/\]//g;#$genotype =~s/\///g;
					my @all = split("/",$genotype);
					foreach my $al(@all){$alleles{$al}++;}
					$do = 1;
				}
				elsif ($allele =~/[ATCGN]/){
					$genotype = $allele."/".$allele;			
				}
				elsif ($allele eq ""){
					$genotype = "N/N";
				}
			}
			
			if ($informat eq "hapmap"){
				my @letters = split("",$allele);
				$genotype = $letters[0]."/".$letters[1];
				if ($letters[0] =~/[ATCG]/ && $letters[1] =~/[ATCG]/){
					$alleles_fo{$letters[0]}++;
					$alleles_fo{$letters[1]}++;
				}
			}
			if ($informat eq "hapmap_numeric"){
				if ($allele eq "0"){
					$genotype = "$refallele/$refallele";
				}
				elsif ($allele eq "1"){
					$genotype = "$refallele/$altallele";
				}
				elsif ($allele eq "2"){
					$genotype = "$altallele/$altallele";
				}
				elsif ($allele eq "NA"){
					$genotype = "N/N";
				}
				#print "$ind $allele $altallele $genotype $pos $chrom\n";
			}
			
			if ($do == 0){$alleles{$allele}++;}
			
			$genotyping{$ind} = $genotype;
		}
		if (scalar keys(%alleles_fo) > 2){next;}
	}
	
	#############################################
	# parse VCF
	#############################################
	if ($informat =~/vcf/ && !/^#/){
	
		# TODO: to be fixed
		if (/\/-/ or /\/\+/ or /-\// or /\+\//){
			print "error\n";next;
		} 
		$line =~s/\|/\//g;	
		my @infos = split(/\t/,$line);
		$chrom = $infos[0];
		$pos = $infos[1];
		$refallele = $infos[3];
		$altallele = $infos[4];
		$marker = $infos[2];
		
		if ($altallele =~/(\w+),(\w+)/){
			$altallele = $1;
			$altallele2 = $2;
		}
		
		
		for (my $i = 9; $i <= $#infos; $i++){
			my $allele = $infos[$i];
			
			my $ind = $hash1{$i};
			
			my $genotype;
			my $do = 0;
			$genotype = $allele;
			$genotype =~s/0/$refallele/g;
			$genotype =~s/1/$altallele/g;
			$genotype =~s/2/$altallele2/g;
			$genotype =~s/\./N/g;
			
			if ($do == 0){$alleles{$allele}++;}
			$genotyping{$ind} = $genotype;
		}
	}
	
	# TODO: to be fixed
	if (!$altallele or $altallele eq "+"){next;}
	
	

	#####################################
	# re-write genotyping
	#####################################
	if (!/^#/ && !/^rs#/){
		my @line_geno;
		foreach my $ind(@individuals){
			push(@line_geno,$genotyping{$ind});
		}
		if ($format =~/hapmap/){
			print O "$marker	$refallele/$altallele	$chrom	$pos	+	NA	NA	NA	NA	NA	NA";
		}
		if ($format =~/vcf/){
			if ($altallele2){
				print O "$chrom	$pos	$marker	$refallele	$altallele,$altallele2	10000	PASS	.	GT";
			}
			else{
				print O "$chrom	$pos	$marker	$refallele	$altallele	10000	PASS	.	GT";
			}
			
		}
		if ($format eq "flapjack" or $format eq "transposed_csv"){
			print O "$marker";
		}
		my $counter = 0;
		foreach my $genotype(@line_geno){
			$counter++;
			if ($format =~/vcf/){
				$genotype =~s/$refallele/0/g;
				if ($altallele =~/\w+/){$genotype =~s/$altallele/1/g;}
				if ($altallele2 =~/\w+/){$genotype =~s/$altallele2/2/g;}
				$genotype =~s/N/\./g;
				
				print O "\t". $genotype;
			}
			elsif ($format =~/hapmap_iupac/){
				my $new_genotype = $iupac{"[".$genotype."]"};
				print O "\t". $new_genotype;
			}
			elsif ($format =~/numeric/ or $format =~/csv/ or $format =~/flapjack/){
				if ($genotype eq "$refallele/$refallele"){
					$genotype = "0";
				}
				elsif ($genotype eq "$refallele/$altallele" or $genotype eq "$altallele/$refallele"){
					$genotype = "1";
				}
				elsif ($genotype eq "$altallele/$altallele"){
					$genotype = "2";
				}
				elsif ($genotype eq "N/N"){
					$genotype = "NA";
				}
				if ($format =~/hapmap_numeric/){
					print O "\t". $genotype;
				}
				elsif ($format eq "numeric" or $format =~/csv/ or $format eq "flapjack"){
					if ($counter == 0){
						print O $genotype;
					}
					else{
						if ($format eq "numeric" or $format eq "flapjack" or $format eq "transposed_csv"){
							print O "\t". $genotype;
						}
						elsif ($format eq "csv"){
							print O ",". $genotype;
						}
					}
				}
			}
			elsif ($format =~/hapmap/){
				$genotype =~s/\///g;
				print O "\t". $genotype;
			}
			
		}
		print O "\n";
		
	}

}
close(F);
close(O);


if (($format eq "flapjack" or $format eq "transposed_csv") && $dir){
	system("$dir/transpose.awk $outfile >$outfile.2");
	if ($format eq "flapjack"){
		`sed "s/ /\t/g" $outfile.2 >$outfile`;
	}
	else{
		`sed "s/ /,/g" $outfile.2 >$outfile`;
	}
}
