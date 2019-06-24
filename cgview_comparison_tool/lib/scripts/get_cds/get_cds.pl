#!/usr/bin/perl
#get_cds.pl version 1.2
#This script requires bioperl-1.4 or newer.
#
#Written by Paul Stothard
#
#stothard@ualberta.ca

use strict;
use warnings;

use Getopt::Long;
use Bio::SeqIO;

my %options = (
    input    => undef,
    output   => undef,
    cdsCount => 0,
    dna      => 'F'
);

GetOptions(
    'i=s'   => \$options{'input'},
    'o=s'   => \$options{'output'},
    'dna=s' => \$options{'dna'}
);

if ( !( defined( $options{'input'} ) ) ) {
    _usage();
}
if ( !( defined( $options{'output'} ) ) ) {
    _usage();
}

if ( -e $options{'output'} ) {
    unlink( $options{'output'} )
        or die("Cannot remove $options{'output'} file: $!");
}

my $seqObject = _getSeqObject( \%options );
if (   ( !( $options{"type"} eq "embl" ) )
    && ( !( $options{"type"} eq "genbank" ) ) )
{
    die("get_cds.pl requires a GenBank or EMBL file as input.");
}

_writeCDS( \%options, $seqObject, 1, 1 );
_writeCDS( \%options, $seqObject, 1, 2 );
_writeCDS( \%options, $seqObject, 1, 3 );

_writeCDS( \%options, $seqObject, -1, 1 );
_writeCDS( \%options, $seqObject, -1, 2 );
_writeCDS( \%options, $seqObject, -1, 3 );

print
    "A total of $options{cdsCount} records were written to $options{output}.\n";

sub _writeCDS {

    my $options    = shift;
    my $seqObject  = shift;
    my $strand     = shift;    #1 or -1
    my $rf         = shift;    #1,2,3
    my $rfForLabel = $rf;

    my $length = $seqObject->length();

    if ( ( defined($rf) ) && ( $rf == 3 ) ) {
        $rf = 0;
    }

    #need to get the features from from the GenBank record.
    my @features = $seqObject->get_SeqFeatures();
    @features = @{ _sortFeaturesByStart( \@features ) };

    if ( $strand == 1 ) {
        @features = reverse(@features);
    }

    foreach (@features) {
        my $feat = $_;

        my $type = lc( $feat->primary_tag );
        unless ( $type eq "cds" ) {
            next;
        }

        my $st = $feat->strand;
        unless (( defined($st) ) && ( $st == $strand )) {
            next;
        }

        my $start = $feat->start;
        my $stop  = $feat->end;

        my $location  = $feat->location;
        my $locString = $location->to_FTstring;
        my @loc       = split( /,/, $locString );

        if ( $loc[0] =~ m/(\d+)\.\.(\d+)/ ) {
            $start = $1;
        }

        if ( $loc[ scalar(@loc) - 1 ] =~ m/(\d+)\.\.(\d+)/ ) {
            $stop = $2;
        }

        if ( defined($rf) ) {
            if ( $strand == 1 ) {
                unless ( $rf == $start % 3 ) {
                    next;
                }
            }
            elsif ( $strand == -1 ) {
                unless ( $rf == ( $length - $stop + 1 ) % 3 ) {
                    next;
                }
            }
        }

        my @label = ();
        if ( $feat->has_tag('gene') ) {
            push( @label, join( ",", $feat->get_tag_values('gene') ) );
        }
        if ( $feat->has_tag('locus_tag') ) {
            push( @label, join( ",", $feat->get_tag_values('locus_tag') ) );
        }
        if ( $feat->has_tag('note') ) {

            #	    push (@label, join(",",$feat->get_tag_values('note')));
        }
        if ( $feat->has_tag('product') ) {

            #	    push (@label, join(",",$feat->get_tag_values('product')));
        }
        if ( $feat->has_tag('function') ) {

            #	    push (@label, join(",",$feat->get_tag_values('function')));
        }

        #add position information to label
        #label_start=4001;end=5000;strand=1;rf=1;
        #where strand is 1 or -1 and rf is 1,2, or 3
        #start should be smaller than the end
        push( @label,
            "_start=$start;end=$stop;strand=$strand;rf=$rfForLabel" );
        my $label = join( ";", @label );
        $label =~ s/\s+/_/g;
        $label =~ s/\n//g;
        $label =~ s/\t+/ /g;

        my $trans;
        if ( !( $feat->has_tag('translation') ) ) {
            print(
                "Warning: get_cds.pl was unable to obtain translation for $label. Skipping\n"
            );
            next;
        }
        else {
            my @translation = $feat->get_tag_values('translation');
            $trans = $translation[0];
            $trans =~ s/[^A-Z]//ig;
        }

        my $dna = $feat->spliced_seq->seq;
        if ( ( !( defined($dna) ) ) && ( $options{'dna'} =~ m/t/i ) ) {
            print(
                "Warning: get_cds.pl was unable to obtain the DNA coding sequence for $label. Skipping\n"
            );
            next;
        }
        $dna =~ s/[^A-Z]//ig;

        $options->{cdsCount}++;
        open( OUTFILE, "+>>" . $options->{"output"} )
            or die("Cannot open file : $!");

        if ( $options{'dna'} =~ m/t/i ) {
            print( OUTFILE ">$label\n$dna\n\n" );
        }
        else {
            print( OUTFILE ">$label\n$trans\n\n" );
        }
        close(OUTFILE) or die("Cannot close file : $!");
    }
}

sub _getSeqObject {
    my $options = shift;

    open( INFILE, $options->{'input'} ) or die("Cannot open input file: $!");
    while ( my $line = <INFILE> ) {
        if ( !( $line =~ m/\S/ ) ) {
            next;
        }

        #guess file type from first line
        if ( $line =~ m/^LOCUS\s+/ ) {
            $options->{'type'} = "genbank";
        }
        elsif ( $line =~ m/^ID\s+/ ) {
            $options->{'type'} = "embl";
        }
        elsif ( $line =~ m/^\s*>/ ) {
            $options->{'type'} = "fasta";
        }
        else {
            $options->{'type'} = "raw";
        }
        last;

    }

    close(INFILE) or die("Cannot close input file: $!");

    #get seqobj
    my $in = Bio::SeqIO->new(
        -format => $options->{'type'},
        -file   => $options->{'input'}
    );
    my $seq = $in->next_seq();

    return $seq;
}

sub _sortFeaturesByStart {
    my $features = shift;

    @$features = map { $_->[1] }
        sort { $a->[0] <=> $b->[0] }
        map { [ _getSortValueFeature($_), $_ ] } @$features;

    return $features;
}

sub _getSortValueFeature {
    my $feature = shift;
    my $start = $feature->start;
    #occasionally BioPerl will obtain an unusual start value like 'join(42734'
    #typically these values come from features that do not represent CDS features
    #and are removed by this script after sorting
    $start =~ s/\D//g;
    return $start;
}

sub _usage {
    die('Usage: get_cds.pl -i <input file> -o <output file>');
}
