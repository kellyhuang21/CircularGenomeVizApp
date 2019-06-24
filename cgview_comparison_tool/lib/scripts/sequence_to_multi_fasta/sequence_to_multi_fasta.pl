#!/usr/bin/perl
#sequence_to_multi_fasta.pl
#version 1.1
#
#This script requires bioperl-1.4 or newer.
#
#Written by Paul Stothard
#stothard@ualberta.ca

use strict;
use warnings;

use Getopt::Long;
use Bio::SeqIO;

my %options = (
    input   => undef,
    output  => undef,
    size    => undef,
    overlap => undef,
    title   => undef,
    type    => undef
);

Getopt::Long::Configure('bundling');
GetOptions(
    'i=s' => \$options{'input'},
    'o=s' => \$options{'output'},
    's=i' => \$options{'size'},
    'v=i' => \$options{'overlap'}
);

if ( !( defined( $options{'input'} ) ) ) {
    _usage();
}
if ( !( defined( $options{'output'} ) ) ) {
    _usage();
}

my $seqObject = _getSeqObject( \%options );
if ( ( $options{"type"} eq "embl" ) || ( $options{"type"} eq "genbank" ) ) {
    $options{"accession"} = $seqObject->accession_number;
    if ( !( defined( $options{"title"} ) ) ) {
        $options{"title"} = $seqObject->description();
    }
}
if ( $options{"type"} eq "fasta" ) {
    if ( !( defined( $options{"title"} ) ) ) {
        $options{"title"} = $seqObject->description();
    }
}

if ( !( defined( $options{"title"} ) ) ) {
    $options{"title"} = "split";
}

my $dna    = $seqObject->seq();
my $length = length($dna);

$options{'title'} =~ s/\s+/_/g;

if ( !( defined( $options{'size'} ) ) ) {
    $options{'size'} = $length;
}

open( OUTFILE, ">" . $options{"output"} ) or die("Cannot open file : $!");
for ( my $i = 0; $i < $length; $i = $i + $options{'size'} ) {

    #if using overlap adjust $i
    if ( ( defined( $options{'overlap'} ) ) && ( $i > $options{'overlap'} ) )
    {
        $i = $i - $options{'overlap'};
    }
    my $start         = $i + 1;
    my $subseq        = substr( $dna, $i, $options{'size'} );
    my $subseq_length = length($subseq);
    my $end           = $start + $subseq_length - 1;
    print(    OUTFILE ">"
            . $options{'title'}
            . "_start=$start;end=$end;length=$subseq_length;source_length=$length\n$subseq\n"
    );
}
close(OUTFILE) or die("Cannot close file : $!");

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
        elsif ( $line =~ m/^>/ ) {
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

sub _usage {
    die('Usage: sequence_to_multi_fasta.pl -i <input file> -o <output file> -s <size of new sequences>'
    );
}
