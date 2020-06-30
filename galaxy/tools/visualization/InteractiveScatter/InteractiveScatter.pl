#!/usr/bin/perl

use strict;

use Getopt::Long;

my $usage = qq~Usage:$0 <args> [<opts>]
where <args> are:
    -i, --input         <input tabular file>
    -o, --output        <output HTML file>
    -x, --x_axis        <column for X axis>
    -y, --y_axis        <column for Y axis>
    -n, --name          <column for getting each point names>
    -r, --root_dir      <root directory>	
<opts>
    -c, --category      <column for getting category for colorization>
    -z, --z_axis        <column for Z axis. In case of a 3D scatter plot>
~;
$usage .= "\n";

my ($input,$outfile,$x_axis,$y_axis,$name,$category,$z_axis,$root_dir);

GetOptions(
		"input=s"    => \$input,
		"output=s"   => \$outfile,
		"x_axis=s"   => \$x_axis,
		"y_axis=s"   => \$y_axis,
		"z_axis=s"   => \$z_axis,
		"name=s"     => \$name,
		"root_dir=s" => \$root_dir,
		"category=s" => \$category
);

die $usage
  if ( !$input || !$outfile || !$x_axis || !$y_axis);
  
my @colors = ("rgba(223, 83, 83, .5)","rgba(119, 152, 191, .5)","rgb(0, 204, 0, .5)","rgb(194, 194, 163, .5)","rgb(194, 194, 214, .5)");

my $jsondirectory = "/static/json";
if ($root_dir){
	$jsondirectory = $root_dir . "/static/json";
	if (!-d $jsondirectory){
		mkdir $jsondirectory;
	}
}

my $separator = "\t";
my $grep_csv = `grep -c ',' $input`;
my $grep_tab = `grep -c '\t' $input`;
if ($grep_csv > $grep_tab){
	$separator = ",";
}

# check input file
if ($input !~/[\w\/]+/){
	die "Error with input file $input";
}
`sed 's/"//g' $input >$input.2`;

my %infos_axis;
my %categories;
open(I,"$input.2") or die "Can't open $input.2: $!";
my $firstline = <I>;
$firstline=~s/\n//g;$firstline=~s/\r//g;
my @headers = split(/$separator/,$firstline);
my $titlex = $headers[$x_axis-1];
my $titley = $headers[$y_axis-1];
my $titlez = $headers[$z_axis-1];
my $min_x = 100000000000;
my $max_x = -1000000000;
my $min_y = 100000000000;
my $max_y = -1000000000;
my $min_z = 100000000000;
my $max_z = -1000000000;
my @pairs;
while(<I>){
	my $line = $_;
	$line =~s/\n//g;
	$line =~s/\r//g;
	my @infos = split(/$separator/,$line);
	my $id = $infos[$name-1];
	my $valx = $infos[$x_axis-1];
	my $valy = $infos[$y_axis-1];
	if ($valx !~/\d+/ or $valy !~/\d+/){
		next;
		#die "Error with Y values: $valy";
	}
	
	if ($valx < $min_x){
		$min_x = $valx;
	}
	if ($valx > $max_x){
		$max_x = $valx;
	}
	if ($valy < $min_y){
		$min_y = $valy;
	}
	if ($valy > $max_y){
		$max_y = $valy;
	}
	$infos_axis{1}{"min"} = $min_x;
	$infos_axis{1}{"max"} = $max_x;
	$infos_axis{2}{"min"} = $min_y;
        $infos_axis{2}{"max"} = $max_y;
	$infos_axis{1}{"title"} = $titlex;
	$infos_axis{2}{"title"} = $titley;	
	my $valcat = "series";
	if ($category ne 'None'){
		$valcat = $infos[$category-1];
	}
	#if ($valcat eq "series" && $id =~/_(\w+)/){
	#	$valcat = $1;
	#}
	if ($z_axis ne 'None'){
		my $valz = $infos[$z_axis-1];
		if ($valz < $min_z){
 			$min_z = $valz;
		}
		if ($valz > $max_z){
			$max_z = $valz;
		}
		if ($valz !~/\d+/){
			next;
		}
		$infos_axis{3}{"min"} = $min_z;
		$infos_axis{3}{"max"} = $max_z;
		$infos_axis{3}{"title"} = $titlez;
		$categories{$valcat} .= "\{\"name\":\"$id\",\"x\":$valx,\"y\":$valy,\"z\":$valz\},";
	}
	else{
		$categories{$valcat} .= "\{\"name\":\"$id\",\"x\":$valx,\"y\":$valy\},";
	}
	
}
close(I);


my $data = "";
my $j = 0;
foreach my $valcat(sort {$a<=> $b}keys(%categories)){
	my $subdata = $categories{$valcat};
	chop($subdata);
	$data .= "{ \"name\": \"$valcat\", \"data\": [$subdata]},";
	$j++;
}
chop($data);



my $tmp = int(rand(10000000000));
open(JSON,">$jsondirectory/data.$tmp.json") or die "Can't open $jsondirectory/data.$tmp.json: $!";
print JSON "[$data]";
close(JSON);

my $bloc_slider = qq~
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.1.0/jquery.min.js"></script>
<script>window.jQuery || document.write(decodeURIComponent('%3Cscript src="js/jquery.min.js"%3E%3C/script%3E'))</script>
    <link rel="stylesheet" type="text/css" href="https://cdn3.devexpress.com/jslib/18.2.3/css/dx.common.css" />
    <link rel="dx-theme" data-theme="generic.light" href="https://cdn3.devexpress.com/jslib/18.2.3/css/dx.light.css" />
    <script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.3.16/angular.min.js"></script>
<script>window.angular || document.write(decodeURIComponent('%3Cscript src="js/angular.min.js"%3E%3C\/script%3E'))</script>
    <script src="https://cdn3.devexpress.com/jslib/18.2.3/js/dx.all.js"></script>


	
	<style>
    .custom-height-slider {
    height: 75px;
}

.dx-field > .dx-rangeslider {
    flex: 1;
}
</style>
    <script>
~;
	
foreach my $k(sort {$a<=>$b} keys(%infos_axis)){
	my $min = $infos_axis{$k}{"min"};
	my $max = $infos_axis{$k}{"max"};
	my $step = ($max - $min)/100;
	$bloc_slider .= qq~
\$(function(){
    
    
    var handlerRangeSlider = \$("#handler-range-slider$k").dxRangeSlider({
        min: $min,
        max: $max,
        start: $min,
        end: $max,
	step: $step,
        onValueChanged: function(data){
            startValue.option("value", data.start);
            endValue.option("value", data.end);
        }
    }).dxRangeSlider("instance");
    
    var startValue = \$("#start-value$k").dxNumberBox({
        value: $min,
        min: $min,
        max: $max,
	step: $step,
        showSpinButtons: true,
        onValueChanged: function(data) {
		document.getElementById("min$k").value = data.value;
		handlerRangeSlider.option("start", data.value);
        }
    }).dxNumberBox("instance");
    
    var endValue = \$("#end-value$k").dxNumberBox({
        value: $max,
        min: $min,
        max: $max,
	step: $step,
        showSpinButtons: true,
        onValueChanged: function(data) {
		document.getElementById("max$k").value = data.value;
		handlerRangeSlider.option("end", data.value);
        }
    }).dxNumberBox("instance");
});
~;
}
$bloc_slider.= "</script>";



########################################################################################
# bloc for Highcharts javascript: Scatter plot
########################################################################################
my $bloc_scatter = qq~

\$(function () {

	var jsonfile = window.location.origin+"/static/json/data.$tmp.json";

	var min_x = document.getElementById("min1").value;
	var max_x = document.getElementById("max1").value;
	var min_y = document.getElementById("min2").value;
	var max_y = document.getElementById("max2").value;
	\$.getJSON(jsonfile, function (data) {
	var chart;
	
	var string = JSON.stringify(data);
		var chart;
		var jsonData = [];
		var names = [];
		for(var i = 0; i < data.length; i++){
				var myseries = {};
				myseries.name=data[i].name;
				var points = [];
				for(var j = 0; j < data[i].data.length; j++){
					if (data[i].data[j].x >= min_x && data[i].data[j].x <= max_x && data[i].data[j].y >= min_y && data[i].data[j].y <= max_y){
						
						var point = {};
						point.name=data[i].data[j].name;
						names.push(data[i].data[j].name);
						point.x=data[i].data[j].x;
						point.y=data[i].data[j].y;
						points.push(point);
					}
				}
				myseries.data = points;
				jsonData.push(myseries);
			}
                var names_length = names.length;
		
	document.getElementById("liste").innerHTML = "List of point names: <br/><textarea name='list_samples' rows=4 cols=50>"+names+"</textarea>";
						
	\$(document).ready(function() {
		
	chart = new Highcharts.chart('container1', {
    chart: {
        type: 'scatter',
        zoomType: 'xy'
    },
    title: {
        text: ''
    },
    subtitle: {
        text: ''
    },
    xAxis: {
        title: {
            enabled: true,
            text: '$titlex'
        },
        startOnTick: true,
        endOnTick: true,
        showLastLabel: true
    },
    yAxis: {
        title: {
            text: '$titley'
        }
    },
    
    plotOptions: {
        scatter: {
            marker: {
                radius: 3,
                states: {
                    hover: {
                        enabled: true,
                        lineColor: 'rgb(100,100,100)'
                    }
                }
            },
            turboThreshold:300000,
            states: {
                hover: {
                    marker: {
                        enabled: false
                    }
                }
            },
            tooltip: {
				pointFormat: '<b>{point.name}</b><br/>',
                headerFormat: '<b>{point.id}</b><br><b>{point.x}</b><br><b>{point.y}</b><br><b>{series.name}</b><br/>'
            }
        }
    },
	series: jsonData
			
			});

		
		});

	});

	});
~;

########################################################################################
# bloc for Highcharts javascript: 3D Scatter plot
########################################################################################
my $bloc_3D = qq~
\$(function () {

		var jsonfile = window.location.origin+"/static/json/data.$tmp.json";

		var min_x = document.getElementById("min1").value;
		var max_x = document.getElementById("max1").value;
		var min_y = document.getElementById("min2").value;
		var max_y = document.getElementById("max2").value;
		var min_z = document.getElementById("min3").value;
		var max_z = document.getElementById("max3").value;
		\$.getJSON(jsonfile, function (data) {
		

		var string = JSON.stringify(data);
		var chart;
                var names = [];
		var jsonData = [];
		for(var i = 0; i < data.length; i++){
				var myseries = {};
				myseries.name=data[i].name;
				var points = [];
				for(var j = 0; j < data[i].data.length; j++){
					if (data[i].data[j].x >= min_x && data[i].data[j].x <= max_x && data[i].data[j].y >= min_y && data[i].data[j].y <= max_y && data[i].data[j].z >= min_z && data[i].data[j].z <= max_z){
						
						var point = {};
						point.name=data[i].data[j].name;
						names.push(data[i].data[j].name);
						point.x=data[i].data[j].x;
						point.y=data[i].data[j].y;
						point.z=data[i].data[j].z;
						points.push(point);
					}
				}
				myseries.data = points;
				jsonData.push(myseries);
			}

		
		document.getElementById("liste").innerHTML = "List of point names: <br/><textarea name='list_samples' rows=4 cols=50>"+names+"</textarea>";
							
		\$(document).ready(function() {
			chart = new Highcharts.Chart({
				chart: {
					renderTo: 'container1',
					type: 'scatter',
					
					options3d: {enabled: true,alpha: 10,beta: 30,depth: 250,viewDistance: 5,}
				},
				title: 
				{
					text: ''
				},
				subtitle: 
				{
					text: ''
				},
				yAxis: { title: {text: '$titley'},},
				xAxis: { title: {text: '$titlex'},},
				zAxis: {title: {text: '$titlez'},},
				
				 plotOptions: {
                                        series:{
                                           turboThreshold:20000//larger threshold or set to 0 to disable
                                        },
                                        scatter: {
                                                
                                                tooltip: {headerFormat: '<b></b>',pointFormat: '<b>{point.name}'},
                                                marker: {
                                                        radius:3,
                                                }
                                        }
                                },
				series: jsonData
			});
			
			



		
    \$(chart.container).bind('mousedown.hc touchstart.hc', function (e) {
        e = chart.pointer.normalize(e);

        var posX = e.pageX,
            posY = e.pageY,
            alpha = chart.options.chart.options3d.alpha,
            beta = chart.options.chart.options3d.beta,
            newAlpha,
            newBeta,
            sensitivity = 5; // lower is more sensitive

        \$(document).bind({
            'mousemove.hc touchdrag.hc': function (e) {
                // Run beta
                newBeta = beta + (posX - e.pageX) / sensitivity;
                chart.options.chart.options3d.beta = newBeta;

                // Run alpha
                newAlpha = alpha + (e.pageY - posY) / sensitivity;
                chart.options.chart.options3d.alpha = newAlpha;

                chart.redraw(false);
            },
            'mouseup touchend': function () {
                \$(document).unbind('.hc');
            }
        });
    });
	
		});

	});

	});
~;


my $bloc;
if ($z_axis ne 'None'){
	$bloc = $bloc_3D;
}
else{
	$bloc = $bloc_scatter;
}
open(O,">$outfile") or die "Can't open $outfile: $!";

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

$bloc_slider
~;
print O $html;

for (my $j = 1; $j <= 1; $j++) 
{

my $zsection = "";
if ($min_z){
	$zsection = "Z: Min <input type=\"text\" size=5 name=\"min_z\" id=\"min3\" value=\"$min_z\">&nbsp;&nbsp;Max <input type=\"text\" size=5 name=\"max_z\" id=\"max3\" value=\"$max_z\"><br>";
}
my $javascript = qq~

<!--
<div class="demo-container" ng-app="DemoApp" ng-controller="DemoController">
        <div class="form">
            <div class="dx-fieldset">

                <div class="dx-field custom-height-slider">
                    <div class="dx-field-value">
                        <div dx-range-slider="rangeSlider.withTooltip">
                        </div>
                    </div>
                </div>
                
        </div>
    </div>
-->

<div id="container$j" style="min-width: 310px; height: 800px; max-width: 800px; margin: 0 auto"></div>

<div id="liste"></div>

<script type="text/javascript">

$bloc

function reload(){
    $bloc
	//chart.redraw();

	
}
</script>
<br/><br/><b>Filters</b>: &nbsp;&nbsp; <button name="update" onclick="reload();">Reload plot</button><br/>


	~;

	print O $javascript;


	my $sliders = "<table><tr>";
	foreach my $k(sort {$a<=>$b} keys(%infos_axis)){
		my $title = $infos_axis{$k}{"title"};
		my $min = $infos_axis{$k}{"min"};
		my $max = $infos_axis{$k}{"max"};
		$sliders .= qq~
<td width="300px">
 <div class="dx-fieldset$k">
<b>$title</b><br/>
                <div class="dx-field$k">
                    <div id="handler-range-slider$k"></div>
                </div>
                <div class="dx-field$k">
				
                    <div class="dx-field-label$k">Min</div>
                    <div class="dx-field-value$k">
                        <div id="start-value$k"></div>
                    </div>
                </div>
                <div class="dx-field$k">
                    <div class="dx-field-label$k">Max</div>
                    <div class="dx-field-value$k">
                        <div id="end-value$k"></div>
                    </div>
                </div>
            </div>
	<input type="hidden" size=5 name="min$k" id="min$k" value="$min"><input type="hidden" size=5 name="max$k" id="max$k" value="$max">
</td>
<td width="30px"></td>
~;
	}
	$sliders.= "</tr></table>";
	print O $sliders;

}

print O "</body></html>";

close(O);
