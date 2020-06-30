#!/usr/bin/perl

use strict;

use Getopt::Long;

my $usage = qq~Usage:$0 <args> [<opts>]
where <args> are:
    -i, --input         <input tabular file>
    -o, --output        <output HTML file>
    -n, --name          <column for getting each point names>	
~;
$usage .= "\n";

my ($input,$outfile,$name);
my $jsondirectory = "/home/galaxy/data/alexis_dereeper/static/json";
my $json_URL = "http://galaxy-demo.excellenceinbreeding.org/static/json";

GetOptions(
		"input=s"    => \$input,
		"output=s"   => \$outfile,
		"name=s"     => \$name,
);

die $usage
  if ( !$input || !$outfile || !$name);
  
my @colors = ("rgba(223, 83, 83, .5)","rgba(119, 152, 191, .5)","rgb(0, 204, 0, .5)","rgb(194, 194, 163, .5)","rgb(194, 194, 214, .5)");

my $separator = "\t";
my $grep_csv = `grep -c ',' $input`;
my $grep_tab = `grep -c '\t' $input`;
if ($grep_csv > $grep_tab){
	$separator = ",";
}
`sed 's/"//g' $input >$input.2`;

my @categories;
my %infos_axis;
my %categories;
my %values;
open(I,"$input.2");
my $firstline = <I>;
$firstline=~s/\n//g;$firstline=~s/\r//g;
my @headers = split(/$separator/,$firstline);
while(<I>){
	my $line = $_;
	$line =~s/\n//g;
	$line =~s/\r//g;
	my @infos = split(/$separator/,$line);
	my $id = $infos[$name-1];
	push(@categories,$id);
	for (my $i = 0; $i <= $#infos; $i++){
		if ($i != $name-1){
			my $val = $infos[$i];
			my $header = $headers[$i];
			$values{$header}.= $val.",";
		}

	}	
}
close(I);


my $data = "";
foreach my $header(keys(%values)){
	my $subdata = $values{$header};
	chop($subdata);
	$data .= "{ \"name\": \"$header\", \"data\": [$subdata]},";
}
chop($data);


my $cat = join("','",@categories);

########################################################################################
# bloc for Highcharts javascript: Scatter plot
########################################################################################
my $bloc_scatter = qq~
Highcharts.chart('container', {
    chart: {
        type: 'column'
    },
    title: {
        text: ''
    },
    xAxis: {
        categories: ['$cat'],
        crosshair: true
    },
    yAxis: {
        min: 0,
        title: {
            text: ''
        }
    },
    tooltip: {
        headerFormat: '<span style="font-size:10px">{point.key}</span><table>',
        pointFormat: '<tr><td style="color:{series.color};padding:0">{series.name}: </td>' +
            '<td style="padding:0"><b>{point.y:.1f}</b></td></tr>',
        footerFormat: '</table>',
        shared: true,
        useHTML: true
    },
    plotOptions: {
        column: {
            pointPadding: 0.2,
            borderWidth: 0
        }
    },
    series: [$data]
});
~;



my $bloc = $bloc_scatter;
open(O,">$outfile");

my $html = qq~

<!DOCTYPE HTML>
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<title>Highcharts Example</title>

		<style type="text/css">

		</style>
	</head>
	<body>


<script src="http://code.highcharts.com/highcharts.js"></script>
<script src="http://code.highcharts.com/highcharts-more.js"></script>
<script src="http://code.highcharts.com/modules/data.js"></script>
<script src="http://code.highcharts.com/modules/exporting.js"></script>
<script src="http://code.highcharts.com/modules/heatmap.js"></script>
<script src="http://code.highcharts.com/highcharts-3d.js"></script>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.5.1/jquery.min.js"></script>
<script src="http://code.jquery.com/jquery-latest.min.js"></script>

<script type="text/javascript" src="http://highslide.com/highslide/highslide-full.min.js"></script>
<script type="text/javascript" src="http://sniplay.southgreen.fr/javascript/highslide.config.js" charset="utf-8"></script>
<link rel="stylesheet" type="text/css" href="http://www.highcharts.com/media/com_demo/highslide.css" />

~;
print O $html;


my $javascript = qq~

<div id="container" style="min-width: 310px; height: 800px; max-width: 800px; margin: 0 auto"></div>

<div id="liste"></div>

<script type="text/javascript">

$bloc

</script>


	~;

	print O $javascript;



print O "</body></html>";

close(O);
