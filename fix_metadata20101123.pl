#!/usr/bin/perl

use strict;
use File::Temp qw/ tempfile tempdir /;

# where to look for experiment directories
my $rootdatadir = "/groups/sciserv/flyolympiad/Olympiad_Screen/fly_bowl/00_incoming";

# name of metadata file within experiment directory
my $metadatafilestr = "Metadata.xml";

# name of success file within experiment directory
my $successfilestr = "SUCCESS";

# set outputdir to something different from rootdatadir for testing
my $outputdir = "/groups/branson/bransonlab/projects/olympiad/FlyBowlDataCapture/TestFixMetadata";
#my $outputdir = $rootdatadir;

# get all experiment directories
my @expdirs = glob("$rootdatadir/*");

# declare timestamp
my $timestamp;

# loop through all experiment directories
foreach my $expdir(@expdirs){

    # parse the expdir
    if($expdir =~ /(.*\/)?([^\/]+)_(TrpA)_Rig([0-9]+)Plate([0-9]+)Bowl([A-D])_([^_\/]+)\/?$/){

	# we don't really use most of these, but it will be useful to have the full parsing
	# of the directory name someday
	my $pathstr = $1;
	my $line = $2;
	my $effector = $3;
	my $rig = $4;
	my $plate = $5;
	my $bowl = $6;
	$timestamp = $7;
	
	# use a subroutine to do all the work
	&fix_metadata($expdir);
    }
    else{
	print "could not parse $expdir\n";
    }
}

sub fix_metadata
{

    # get argument
    my $expdir = $_[0];
    #print "expdir = $expdir\n";

    # metadata file to read from
    my $inputfile = "$expdir/$metadatafilestr";
    if(! -e $inputfile){
	print "Input metadata file $inputfile does not exist, skipping.\n";
	return;
    }

    # parse into rootdir and expdir
    $expdir =~ /^(.*\/)?([^\/]+)\/?$/;

    # output directory is expdir within outputdir
    my $outputdircurr = "$outputdir/$2";

    print "\n*** Fixing Metadata for experiment $2 ***\n";

    # if the output directory doesn't exist, then skip
    if(! -d $outputdircurr){
	print "Output directory $outputdircurr does not exist, creating\n";
	`mkdir $outputdircurr`;
    }

    # open file for reading
    open(IN,"<$inputfile");

    # file we will write to
    my $outputfile = "$outputdircurr/$metadatafilestr";
    my ($OUT,$tmpoutputfile) = tempfile();
    my $outputsuccessfile = "$outputdircurr/$successfilestr";
    print "Writing to tempfile $tmpoutputfile\n";

    #open($OUT,">$tmpoutputfile");

    # read each line
    while(my $l = <IN>){

	# check for errors
	if($l =~ /^(\s*\<note_behavioral\>.*)(\<\/note\>)(\s*)$/){
	    print $OUT "$1</note_behavioral>$3";
	    print "Fixed note_behavioral\n";
	}
	elsif($l =~ /^(\s*\<note_technical\>.*)(\<\/note\>)(\s*)$/){
	    print $OUT "$1</note_technical>$3";
	    print "Fixed note_technical\n";
	}
	elsif($l =~ /^(\s*)\<note type=\"behavioral\"\>(.*)\<\/note\>(\s*)$/){
	    print $OUT "$1<note_behavioral>$2</note_behavioral>$3";
	    print "Fixed note type=\"behavioral\"\n";
	}
	elsif($l =~ /^(\s*)\<note type=\"technical\"\>(.*)\<\/note\>(\s*)$/){
	    print $OUT "$1<note_technical>$2</note_technical>$3";
	    print "Fixed note type=\"technical\"\n";
	}
	elsif($l =~ /^(.*rearing.*) incubator="AM"(.*\s*)$/){
	    print $OUT "$1 incubator=\"1\"$2";
	    print "Fixed incubator=AM\n";
	}
	elsif($l =~ /^(.*rearing.*) incubator="PM"(.*\s*)$/){
	    print $OUT "$1 incubator=\"2\"$2";
	    print "Fixed incubator=PM\n";
	}
	else{
	    if($l =~ /^(.*\<flag_aborted\>)(.*)(\<\/flag_aborted\>.*\s*)$/){
		my $didabort = $2;
		
		if($didabort == "0"){
		    my $successfile = "$expdir/$successfilestr";
		    if(! -e $successfile){
			print "Creating successfile $outputsuccessfile\n";
			my $cmd = "echo $timestamp > $outputsuccessfile";
			`$cmd`;
		    }
		}
	    }
	    print $OUT "$l";
	}
    }

    close($OUT);
    close(IN);

    my $cmd = "mv $tmpoutputfile $outputfile";
    print "Renaming temporary file $tmpoutputfile as $outputfile\n";
    `$cmd`;

}
