#!/usr/bin/perl
#local_blast_client.pl
#Version 5.0
#
#This script requires blastall version 2.2.15 or newer
#
#Written by Paul Stothard, University of Alberta.
#stothard@ualberta.ca

use warnings;
use strict;
use Getopt::Long;
Getopt::Long::Configure('no_ignore_case');
use LWP::UserAgent;
use HTTP::Request::Common;
use File::Temp;
#use XML::DOM;
use Data::Dumper;

my %settings = (
    PROGRAM      => undef,
    DATABASE     => undef,
    EXPECT       => 10,
    WORD_SIZE    => undef,
    HITLIST_SIZE => 5,
    HSP_MAX      => undef,
    ERROR_RETRY  => 5,
    FILTER       => "T",
    OUTPUTFILE   => undef,
    INPUTFILE    => undef,
    INPUTTYPE    => undef,
    ENTREZ_DB    => undef,
    ALIGN_TYPE   => undef,
    BLAST_PATH   => "/usr/local/blast/bin/blastall",
    ENTREZ_URL =>
        "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?",
    MIN_HSP_LENGTH        => undef,
    MIN_HSP_PROP          => undef,
    MIN_SCORE             => undef,
    MIN_IDENTITY          => undef,
    FETCH_DESC            => "T",
    QUERY_GENETIC_CODE    => 1,
    DATABASE_GENETIC_CODE => 1,
    BROWSER               => undef,
    MAX_BYTES_RESPONSE    => 5000000,
    XML                   => 'F',
    HSP_LABEL             => 'F',
    HSPS_PER_HIT          => undef
);

my $blastType = undef;
my $wordSize  = undef;

GetOptions(
    'i|input_file=s'            => \$settings{INPUTFILE},
    'o|output_file=s'           => \$settings{OUTPUTFILE},
    'b|blast_program=s'         => \$blastType,
    'd|database=s'              => \$settings{DATABASE},
    'h|hsps=i'                  => \$settings{HSP_MAX},
    'l|filter=s'                => \$settings{FILTER},
    'a|min_hsp_length=i'        => \$settings{MIN_HSP_LENGTH},
    'p|min_hsp_prop=f'          => \$settings{MIN_HSP_PROP},
    's|min_score=i'             => \$settings{MIN_SCORE},
    'n|min_identity=f'          => \$settings{MIN_IDENTITY},
    'x|expect=f'                => \$settings{EXPECT},
    't|hit_list_size=i'         => \$settings{HITLIST_SIZE},
    'f|fetch_description=s'     => \$settings{FETCH_DESC},
    'Q|query_genetic_code=i'    => \$settings{QUERY_GENETIC_CODE},
    'D|database_genetic_code=i' => \$settings{DATABASE_GENETIC_CODE},
    'y|blast_path=s'            => \$settings{BLAST_PATH},
#    'xml=s'                     => \$settings{XML},
    'hsp_label=s'               => \$settings{HSP_LABEL},
#    'hsps_per_hit=i'            => \$settings{HSPS_PER_HIT},
    'W|word_size=i'             => \$wordSize
);

if ( !( defined($blastType) ) ) {
    print "------------------------------------------------------------\n";
    print "Please enter a number to indicated the type of BLAST search\n";
    print "you want to perform:.\n";
    print "1 - Nucleotide-nucleotide BLAST (blastn).\n";
    print "2 - Protein-protein BLAST (blastp).\n";
    print "3 - Translated query vs protein database (blastx).\n";
    print "4 - Protein query vs translated database (tblastn).\n";
    print "5 - Translated query vs. translated database (tblastx).\n";
    print "------------------------------------------------------------\n";
    $blastType = <STDIN>;
    chomp($blastType);

    if ( $blastType =~ m/(\d)/ ) {
        $blastType = $1;
    }
    else {
        die("Please enter a digit between 1 and 5.\n");
    }
    if ( ( $blastType < 1 ) || ( $blastType > 5 ) ) {
        die("Please enter a digit between 1 and 5.\n");
    }
}

if ( !( defined( $settings{DATABASE} ) ) ) {
    print "------------------------------------------------------------\n";
    print "Please enter the name of the database you wish to search.\n";
    print "------------------------------------------------------------\n";
    $settings{DATABASE} = <STDIN>;
    chomp( $settings{DATABASE} );
}

_setDefaults( $blastType, \%settings );

if ( !( defined( $settings{INPUTFILE} ) ) ) {
    print "------------------------------------------------------------\n";
    print "Enter the name of the FASTA format "
        . $settings{INPUTTYPE}
        . " sequence file\n";
    print "that contains your query sequences.\n";
    print "------------------------------------------------------------\n";
    $settings{INPUTFILE} = <STDIN>;
    chomp( $settings{INPUTFILE} );
}

open( SEQFILE, $settings{INPUTFILE} ) or die("Cannot open file : $!");

my $inputLessExtentions = $settings{INPUTFILE};
if ( $settings{INPUTFILE} =~ m/(^[^\.]+)/g ) {
    $inputLessExtentions = $1;
}

if ( !( defined( $settings{OUTPUTFILE} ) ) ) {
    $settings{OUTPUTFILE} = $inputLessExtentions . "_" . "results.tab";
    print "------------------------------------------------------------\n";
    print "The results of this "
        . $settings{PROGRAM}
        . " search will be written to\n";
    print "a file called " . $settings{OUTPUTFILE} . ".\n";
    print "Start the search? (y or n) y\n";
    print "------------------------------------------------------------\n";
    my $continue = <STDIN>;
    chomp($continue);

    if ( $continue =~ m/n/i ) {
        exit(0);
    }
}

$settings{HITLIST_SIZE}       = _get_integer( $settings{HITLIST_SIZE} );
$settings{HSP_MAX}            = _get_integer( $settings{HSP_MAX} );
$settings{MIN_HSP_LENGTH}     = _get_integer( $settings{MIN_HSP_LENGTH} );
$settings{MIN_HSP_PROP}       = _get_real( $settings{MIN_HSP_PROP} );
$settings{MIN_SCORE}          = _get_integer( $settings{MIN_SCORE} );
$settings{MIN_IDENTITY}       = _get_real( $settings{MIN_IDENTITY} );
$settings{EXPECT}             = _get_real( $settings{EXPECT} );
$settings{HSPS_PER_HIT}       = _get_integer( $settings{HSPS_PER_HIT} );
$settings{QUERY_GENETIC_CODE} = _get_integer( $settings{QUERY_GENETIC_CODE} );
$settings{DATABASE_GENETIC_CODE}
    = _get_integer( $settings{DATABASE_GENETIC_CODE} );
$wordSize = _get_integer($wordSize);

if ( defined($wordSize) ) {
    $settings{WORD_SIZE} = $wordSize;
}

open( OUTFILE, ">" . $settings{OUTPUTFILE} ) or die("Cannot open file : $!");
print( OUTFILE
        "#-------------------------------------------------------------------------------------------------------------------------------------------------\n"
);
print(    OUTFILE "#Results of automated BLAST query of performed on "
        . _getTime()
        . ".\n" );
print( OUTFILE
        "#Searches performed using local_blast_client.pl, written by Paul Stothard, stothard\@ualberta.ca.\n"
);
print( OUTFILE "#The following settings were specified:\n" );
my @settingsKeys = keys(%settings);

foreach (@settingsKeys) {
    if ( defined( $settings{$_} ) ) {
        print( OUTFILE "#" . $_ . "=" . $settings{$_} . "\n" );
    }
}
print( OUTFILE "#The following attributes are separated by tabs:\n" );
print( OUTFILE
        "#-------------------------------------------------------------------------------------------------------------------------------------------------\n"
);

print( OUTFILE
        "query_id\tmatch_id\tmatch_description\t\%_identity\talignment_length\tmismatches\tgap_openings\tq_start\tq_end\ts_start\ts_end\tevalue\tbit_score\n"
);

close(OUTFILE) or die("Cannot close file : $!");

$settings{BROWSER} = LWP::UserAgent->new();
$settings{BROWSER}->timeout(30);
$settings{BROWSER}->max_size( $settings{MAX_BYTES_RESPONSE} );

my $seqCount = 0;

local $/ = ">";
while ( my $sequenceEntry = <SEQFILE> ) {

    if ( $sequenceEntry eq ">" ) {
        next;
    }
    my $sequenceTitle = "";
    if ( $sequenceEntry =~ m/^([^\n\cM]+)/ ) {
        $sequenceTitle = $1;
    }
    else {
        $sequenceTitle = "No title available";
    }
    $sequenceEntry =~ s/^[^\n\cM]+//;
    $sequenceEntry =~ s/[^A-Z]//ig;
    if ( !( $sequenceEntry =~ m/[A-Z]/i ) ) {
        next;
    }
    my $query = ">" . $sequenceTitle . "\n" . $sequenceEntry;
    $seqCount++;

    if ( defined( $settings{MIN_HSP_PROP} ) ) {
        my $queryLength = length($sequenceEntry);
        if ( $settings{ALIGN_TYPE} eq "nucleotide" ) {
            $settings{MIN_HSP_LENGTH}
                = $settings{MIN_HSP_PROP} * $queryLength;
        }
        elsif ( $settings{ALIGN_TYPE} eq "protein" ) {
            $settings{MIN_HSP_LENGTH}
                = $settings{MIN_HSP_PROP} * $queryLength;
        }
        elsif ( $settings{ALIGN_TYPE} eq "translated" ) {
            $settings{MIN_HSP_LENGTH}
                = $settings{MIN_HSP_PROP} * $queryLength / 3;
        }
        $settings{MIN_HSP_LENGTH}
            = sprintf( "%.0f", $settings{MIN_HSP_LENGTH} );
    }

    #Write the query to a temporary file.
    #The $tmp object acts as a file handle
    my $tmp      = new File::Temp();
    my $filename = $tmp->filename;
    print( $tmp $query );
    close($tmp) or die ("Cannot close file : $!");

    #-m 9 returns table of HSPs with comment lines.
    #-m 7 returns xml
    my $format_type;
    if ( ( defined( $settings{XML} ) ) && ( $settings{XML} =~ m/t/i ) ) {
        $format_type = '7';
    }
    else {
        $format_type = '9';
    }

#-b can be used to specify the number of hits to return when using -m 9. Each hit may consist of one or more HSPs.
#-b and -v must be set to specify the number of hits to return when using -m 7. Each hit may consist of one or more HSPs.
    my $blast_command
        = "$settings{BLAST_PATH} -p $settings{PROGRAM} -d $settings{DATABASE} -e $settings{EXPECT} -i $filename -b $settings{HITLIST_SIZE} -v $settings{HITLIST_SIZE} -m $format_type -Q $settings{QUERY_GENETIC_CODE} -D $settings{DATABASE_GENETIC_CODE} -W $settings{WORD_SIZE} -F $settings{FILTER}";

    print
        "Performing BLAST search for sequence number $seqCount ($sequenceTitle).\n";

    my $result = `$blast_command`;

    my $hitFound = 0;
    my $HSPCount = 0;
    my @results;

    if ( !( defined($result) ) ) {
        die("Error: BLAST results not obtained for sequence number $seqCount ($sequenceTitle)."
        );
    }
    else {
        if ( ( defined( $settings{XML} ) ) && ( $settings{XML} =~ m/t/i ) ) {
            @results = @{ _parse_blast_xml( \%settings, $result ) };
        }
        else {
            @results = @{ _parse_blast_table( \%settings, $result ) };
        }
    }

    foreach (@results) {

        my $HSP = $_;

        $HSPCount++;

        if (   ( defined( $settings{HSP_MAX} ) )
            && ( $HSPCount > $settings{HSP_MAX} ) )
        {
            next;
        }

        if (   ( defined( $settings{HSPS_PER_HIT} ) )
            && ( defined( $HSP->{hsp_number} ) )
            && ( $HSP->{hsp_number} > $settings{HSPS_PER_HIT} ) )
        {
            next;
        }

        if ( defined( $settings{MIN_HSP_LENGTH} ) ) {
            if ( $HSP->{alignment_length} < $settings{MIN_HSP_LENGTH} ) {
                print "Skipping HSP because alignment length is less than "
                    . $settings{MIN_HSP_LENGTH} . ".\n";
                next;
            }
        }

        if ( defined( $settings{MIN_SCORE} ) ) {
            if ( $HSP->{bit_score} < $settings{MIN_SCORE} ) {
                print "Skipping HSP because score is less than "
                    . $settings{MIN_SCORE} . ".\n";
                next;
            }
        }

        if ( defined( $settings{MIN_IDENTITY} ) ) {
            if ( $HSP->{identity} < $settings{MIN_IDENTITY} ) {
                print "Skipping HSP because identity is less than "
                    . $settings{MIN_IDENTITY} . ".\n";
                next;
            }
        }

        #this is to return a single gi number in $col2
        if ( $HSP->{match_id} =~ m/(ref|gi)\|(\d+)/ ) {
            $HSP->{uid}      = $2;
            $HSP->{match_id} = $1 . "|" . $2;
        }

        #obtain description from NCBI
        if ( $settings{FETCH_DESC} =~ m/t/i ) {
            if ( !( defined( $HSP->{uid} ) ) ) {
                if ( !defined( $HSP->{match_description} ) ) {
                    $HSP->{match_description} = "No identifier available";
                }
            }
            else {
                $HSP->{match_description} = "-";
                my $ENTREZsuccess  = 0;
                my $ENTREZattempts = 0;
                my $ENTREZresponse = undef;
                my $ENTREZresult   = undef;
                while (( !($ENTREZsuccess) )
                    && ( $ENTREZattempts < $settings{ERROR_RETRY} ) )
                {
                    $ENTREZresponse = _getENTREZ( \%settings, $HSP->{uid} );
                    my $success = $ENTREZresponse->is_success();
                    if ($success) {
                        my $result = $ENTREZresponse->as_string();
                        if ( $result
                            =~ m/<Item Name="Title" Type="String">(.*?)<\/Item>/i
                            )
                        {
                            $ENTREZresult = $1;
                        }
                        else {
                            print
                                "Error: Could not parse Entrez information from response $result.\n";
                        }
                    }
                    else {
                        print
                            "Error: Could not get response when requesting Entrez information for gi "
                            . $HSP->{uid} . "\n";
                    }

                    if ( defined($ENTREZresult) ) {
                        $ENTREZsuccess = 1;
                        print "ENTREZ results received for "
                            . $HSP->{uid} . "\n";
                    }
                    else {
                        $ENTREZattempts++;
                        sleep(60);
                    }
                }

                if ( !($ENTREZsuccess) ) {
                    $HSP->{match_description}
                        = "Unable to obtain description from ENTREZ";
                }
                else {
                    $HSP->{match_description} = $ENTREZresult;
                }
            }
        }

        #write output
        print "Writing HSP to file.\n";

        if (   ( $settings{HSP_LABEL} =~ m/t/i )
            && ( defined( $HSP->{hit_number} ) )
            && ( defined( $HSP->{hsp_number} ) ) )
        {
            $HSP->{match_id}
                = $HSP->{match_id} . ";hit_number=$HSP->{hit_number}";
        }

        if ( !defined( $HSP->{match_description} ) ) {
            $HSP->{match_description} = "-";
        }

        open( OUTFILE, "+>>" . $settings{OUTPUTFILE} )
            or die("Cannot open file : $!");
        print( OUTFILE
                "$HSP->{query_id}\t$HSP->{match_id}\t$HSP->{match_description}\t$HSP->{identity}\t$HSP->{alignment_length}\t$HSP->{mismatches}\t$HSP->{gap_opens}\t$HSP->{q_start}\t$HSP->{q_end}\t$HSP->{s_start}\t$HSP->{s_end}\t$HSP->{evalue}\t$HSP->{bit_score}\n"
        );

        close(OUTFILE) or die("Cannot close file : $!");
        $hitFound = 1;

    }
    if ( !($hitFound) ) {
        open( OUTFILE, "+>>" . $settings{OUTPUTFILE} )
            or die("Cannot open file : $!");
        print( OUTFILE $sequenceTitle . "\t"
                . "no acceptable hits returned\n" );
        close(OUTFILE) or die("Cannot close file : $!");
    }

}
close(SEQFILE) or die("Cannot close file : $!");
print "Open " . $settings{OUTPUTFILE} . " to view the BLAST results.\n";

sub _getENTREZ {
    my $settings       = shift;
    my $uid            = shift;
    my $ENTREZresponse = $settings->{BROWSER}->request(
        GET(      $settings->{ENTREZ_URL} . "db="
                . $settings->{ENTREZ_DB}
                . "&id=$uid&tool=local_blast_client&retmode=xml"
        )
    );
    return $ENTREZresponse;
}

sub _getTime {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst )
        = localtime(time);
    $year += 1900;

    my @days = (
        'Sunday',   'Monday', 'Tuesday', 'Wednesday',
        'Thursday', 'Friday', 'Saturday'
    );
    my @months = (
        'January',   'February', 'March',    'April',
        'May',       'June',     'July',     'August',
        'September', 'October',  'November', 'December'
    );
    my $time
        = $days[$wday] . " "
        . $months[$mon] . " "
        . sprintf( "%02d", $mday ) . " "
        . sprintf( "%02d", $hour ) . ":"
        . sprintf( "%02d", $min ) . ":"
        . sprintf( "%02d", $sec ) . " "
        . sprintf( "%04d", $year );
    return $time;
}

sub _setDefaults {
    my $blastType = shift;
    my $settings  = shift;

    #1 - Nucleotide-nucleotide BLAST (blastn)
    if ( ( $blastType =~ /^blastn$/i ) || ( $blastType eq "1" ) ) {
        $settings->{PROGRAM}    = "blastn";
        $settings->{WORD_SIZE}  = "11";
        $settings->{INPUTTYPE}  = "DNA";
        $settings->{ENTREZ_DB}  = "nucleotide";
        $settings->{ALIGN_TYPE} = "nucleotide";
    }

    #2 - Protein-protein BLAST (blastp)
    elsif ( ( $blastType =~ /^blastp$/i ) || ( $blastType eq "2" ) ) {
        $settings->{PROGRAM}    = "blastp";
        $settings->{WORD_SIZE}  = "3";
        $settings->{INPUTTYPE}  = "protein";
        $settings->{ENTREZ_DB}  = "protein";
        $settings->{ALIGN_TYPE} = "protein";
    }

    #3 - Translated query vs protein database (blastx)
    elsif ( ( $blastType =~ /^blastx$/i ) || ( $blastType eq "3" ) ) {
        $settings->{PROGRAM}    = "blastx";
        $settings->{WORD_SIZE}  = "3";
        $settings->{INPUTTYPE}  = "DNA";
        $settings->{ENTREZ_DB}  = "protein";
        $settings->{ALIGN_TYPE} = "translated";
    }

    #4 - Protein query vs translated database (tblastn)
    elsif ( ( $blastType =~ /^tblastn$/i ) || ( $blastType eq "4" ) ) {
        $settings->{PROGRAM}    = "tblastn";
        $settings->{WORD_SIZE}  = "3";
        $settings->{INPUTTYPE}  = "protein";
        $settings->{ENTREZ_DB}  = "nucleotide";
        $settings->{ALIGN_TYPE} = "translated";
    }

    #5 - Translated query vs. translated database (tblastx)
    elsif ( ( $blastType =~ /^tblastx$/i ) || ( $blastType eq "5" ) ) {
        $settings->{PROGRAM}    = "tblastx";
        $settings->{WORD_SIZE}  = "3";
        $settings->{INPUTTYPE}  = "DNA";
        $settings->{ENTREZ_DB}  = "nucleotide";
        $settings->{ALIGN_TYPE} = "translated";
    }
    else {
        die("BLAST type $blastType is not recognized.");
    }
}

sub _get_integer {
    my $value = shift;
    my $int   = undef;
    if ( ( defined($value) ) && ( $value =~ m/(\-*\d+)/ ) ) {
        $int = $1;
    }
    return $int;
}

sub _get_real {
    my $value = shift;
    my $real  = undef;
    if ( ( defined($value) ) && ( $value =~ m/(\S+)/ ) ) {
        $real = $1;
    }
    return $real;
}

sub _parse_blast_table {
    my $settings = shift;
    my $table    = shift;
    my $searchPattern
        = '^([^\t]+)[\t]+([^\t]+)[\t]+([^\t]+)[\t]+([^\t]+)[\t]+([^\t]+)[\t]+([^\t]+)[\t]+([^\t]+)[\t]+([^\t]+)[\t]+([^\t]+)[\t]+([^\t]+)[\t]+([^\t]+)[\t]+([^\t]+)[\t\s]*$';

    my @results = split( /\n/, $table );
    my @HSPs = ();

    foreach (@results) {

        if ( $_ =~ m/^\#\sFields:/ ) {
            next;
        }

        if ( !( $_ =~ m/$searchPattern/ ) ) {
            next;
        }

        my %HSP = (
            query_id           => undef,
            match_id           => undef,
            match_description  => undef,
            identity           => undef,
            positives          => undef,
            query_sbjct_frames => undef,
            alignment_length   => undef,
            mismatches         => undef,
            gap_opens          => undef,
            q_start            => undef,
            q_end              => undef,
            s_start            => undef,
            s_end              => undef,
            evalue             => undef,
            bit_score          => undef,
            uid                => undef
        );

        $HSP{query_id}           = $1;
        $HSP{match_id}           = $2;
        $HSP{match_description}  = undef;
        $HSP{identity}           = $3;
        $HSP{positives}          = undef;
        $HSP{query_sbjct_frames} = undef;
        $HSP{alignment_length}   = $4;
        $HSP{mismatches}         = $5;
        $HSP{gap_opens}          = $6;
        $HSP{q_start}            = $7;
        $HSP{q_end}              = $8;
        $HSP{s_start}            = $9;
        $HSP{s_end}              = $10;
        $HSP{evalue}             = $11;
        $HSP{bit_score}          = $12;

        push( @HSPs, \%HSP );
    }
    return \@HSPs;
}

sub _parse_blast_xml {
    my $settings = shift;
    my $xml      = shift;
    my @HSPs     = ();

    #remove header text
    $xml =~ s/^[\s\S]*?(?=<\?xml version=)//;

    #check for complete document
    if ( !( $xml =~ m/<\/BlastOutput>\s*$/ ) ) {
        print "Error: Incomplete XML results returned.\n";
        return \@HSPs;
    }

    my $parser = new XML::DOM::Parser();
    my $doc    = $parser->parsestring($xml);

    my $query_id
        = $doc->getElementsByTagName('BlastOutput_query-def')->item(0)
        ->getFirstChild->getNodeValue;

    for my $hit ( $doc->getElementsByTagName('Hit') ) {
        my $match_id = $hit->getElementsByTagName('Hit_id')->item(0)
            ->getFirstChild->getNodeValue;
        my $match_description = $hit->getElementsByTagName('Hit_def')->item(0)
            ->getFirstChild->getNodeValue;
        my $accession = $hit->getElementsByTagName('Hit_accession')->item(0)
            ->getFirstChild->getNodeValue;
        my $hit_number = $hit->getElementsByTagName('Hit_num')->item(0)
            ->getFirstChild->getNodeValue;
        for my $hsp ( $hit->getElementsByTagName('Hsp') ) {
            my %HSP = (
                query_id           => undef,
                match_id           => undef,
                match_description  => undef,
                identity           => undef,
                positives          => undef,
                query_sbjct_frames => undef,
                alignment_length   => undef,
                mismatches         => undef,
                gap_opens          => undef,
                q_start            => undef,
                q_end              => undef,
                s_start            => undef,
                s_end              => undef,
                evalue             => undef,
                bit_score          => undef,
                uid                => undef,
                accession          => undef,
                id_to_return       => undef,
                hit_number         => undef,
                hsp_number         => undef
            );

            $HSP{query_id}          = $query_id;
            $HSP{match_id}          = $match_id;
            $HSP{match_description} = $match_description;

            my $query_frame = 0;
            my $hit_frame   = 0;
            if (defined(
                    $hsp->getElementsByTagName('Hsp_query-frame')->item(0)
                )
                )
            {
                $query_frame
                    = $hsp->getElementsByTagName('Hsp_query-frame')->item(0)
                    ->getFirstChild->getNodeValue;
            }
            if (defined(
                    $hsp->getElementsByTagName('Hsp_hit-frame')->item(0)
                )
                )
            {
                $hit_frame
                    = $hsp->getElementsByTagName('Hsp_hit-frame')->item(0)
                    ->getFirstChild->getNodeValue;
            }

            $HSP{query_sbjct_frames} = $query_frame . '/' . $hit_frame;

            $HSP{alignment_length}
                = $hsp->getElementsByTagName('Hsp_align-len')->item(0)
                ->getFirstChild->getNodeValue;

            #percent identity
            my $identity = $hsp->getElementsByTagName('Hsp_identity')->item(0)
                ->getFirstChild->getNodeValue;
            $HSP{identity} = 100 * $identity / $HSP{alignment_length};

            #percent positives
            my $positives
                = $hsp->getElementsByTagName('Hsp_positive')->item(0)
                ->getFirstChild->getNodeValue;
            $HSP{positives} = 100 * $positives / $HSP{alignment_length};

         #The 'Hsp_gaps' tag gives the number of gaps, whereas the 'gap_opens'
         #value in the tabular output is the number of gap openings. Need to
         #count gap openings.
            $HSP{gap_opens} = 0;

            my $Hsp_qseq = $hsp->getElementsByTagName('Hsp_qseq')->item(0)
                ->getFirstChild->getNodeValue;

            my $Hsp_hseq = $hsp->getElementsByTagName('Hsp_hseq')->item(0)
                ->getFirstChild->getNodeValue;

            while ( $Hsp_qseq =~ m/\-+/g ) {
                $HSP{gap_opens}++;
            }
            while ( $Hsp_hseq =~ m/\-+/g ) {
                $HSP{gap_opens}++;
            }

            my $gaps = 0;
            if ( defined( $hsp->getElementsByTagName('Hsp_gaps')->item(0) ) )
            {
                $gaps = $hsp->getElementsByTagName('Hsp_gaps')->item(0)
                    ->getFirstChild->getNodeValue;
            }

            $HSP{mismatches} = $HSP{alignment_length} - $identity - $gaps;

            $HSP{q_start}
                = $hsp->getElementsByTagName('Hsp_query-from')->item(0)
                ->getFirstChild->getNodeValue;
            $HSP{q_end} = $hsp->getElementsByTagName('Hsp_query-to')->item(0)
                ->getFirstChild->getNodeValue;
            $HSP{s_start}
                = $hsp->getElementsByTagName('Hsp_hit-from')->item(0)
                ->getFirstChild->getNodeValue;
            $HSP{s_end} = $hsp->getElementsByTagName('Hsp_hit-to')->item(0)
                ->getFirstChild->getNodeValue;
            $HSP{evalue} = $hsp->getElementsByTagName('Hsp_evalue')->item(0)
                ->getFirstChild->getNodeValue;
            $HSP{bit_score}
                = $hsp->getElementsByTagName('Hsp_bit-score')->item(0)
                ->getFirstChild->getNodeValue;
            $HSP{accession}  = $accession;
            $HSP{hit_number} = $hit_number;
            $HSP{hsp_number} = $hsp->getElementsByTagName('Hsp_num')->item(0)
                ->getFirstChild->getNodeValue;

            #round some values
            $HSP{bit_score} = sprintf( "%.2f", $HSP{bit_score} );
            $HSP{identity}  = sprintf( "%.2f", $HSP{identity} );
            $HSP{positives} = sprintf( "%.2f", $HSP{positives} );

       #NCBI uses different conventions to indicate which strand of a sequence
       #produced a hit. Adjust the values here to match the table output.
            if ( $settings->{PROGRAM} eq 'blastn' ) {

     #Make sure opposite strand match is indicated by subject positions rather
     #than by query positions
                if ( $HSP{q_start} > $HSP{q_end} ) {
                    ( $HSP{q_start}, $HSP{q_end} )
                        = ( $HSP{q_end}, $HSP{q_start} );
                    ( $HSP{s_start}, $HSP{s_end} )
                        = ( $HSP{s_end}, $HSP{s_start} );
                }

            }
            if (   ( $settings->{PROGRAM} eq 'blastx' )
                || ( $settings->{PROGRAM} eq 'tblastx' ) )
            {

                #Make sure q_start > q_end when Hsp_query-frame is negative
                if ( ( $query_frame < 0 ) && ( $HSP{q_start} < $HSP{q_end} ) )
                {
                    ( $HSP{q_start}, $HSP{q_end} )
                        = ( $HSP{q_end}, $HSP{q_start} );
                }

                #Make sure q_start < q_end when Hsp_query-frame is positive
                if ( ( $query_frame > 0 ) && ( $HSP{q_start} > $HSP{q_end} ) )
                {
                    ( $HSP{q_start}, $HSP{q_end} )
                        = ( $HSP{q_end}, $HSP{q_start} );
                }
            }
            if (   ( $settings->{PROGRAM} eq 'tblastn' )
                || ( $settings->{PROGRAM} eq 'tblastx' ) )
            {

                #Make sure s_start > s_end when Hsp_hit-frame is negative
                if ( ( $hit_frame < 0 ) && ( $HSP{s_start} < $HSP{s_end} ) ) {
                    ( $HSP{s_start}, $HSP{s_end} )
                        = ( $HSP{s_end}, $HSP{s_start} );
                }

                #Make sure s_start < s_end when Hsp_hit-frame is positive
                if ( ( $hit_frame > 0 ) && ( $HSP{s_start} > $HSP{s_end} ) ) {
                    ( $HSP{s_start}, $HSP{s_end} )
                        = ( $HSP{s_end}, $HSP{s_start} );
                }
            }

            push( @HSPs, \%HSP );
        }
    }
    $doc->dispose;
    return \@HSPs;

}
