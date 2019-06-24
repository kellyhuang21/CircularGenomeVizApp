FILE: assign_cogs.pl
AUTH: Paul Stothard (paul.stothard@gmail.com)
DATE: June 5, 2010
VERS: 1.0

DESCRIPTION:
This script accepts a GenBank, EMBL, FASTA, or raw DNA sequence file
as input and uses BLAST and a COG database to assign COG functional
categories and IDs to each protein produced by the input sequence. The
results are written to a tab-delimited file consisting of the
following columns: seqname, source, feature, start, end, score,
strand, frame. The results are formatted for use with the '-genes'
option of the cgview_xml_builder.pl script.

Note that this script assigns COG categories to the DNA regions
involved in BLAST hits. In many cases the region assigned a COG
category will represent a portion of the complete coding sequence of
the protein.

Only those proteins assigned functional COG categories are described
in the output file.

This script requires a COG myva file and whog file, which can be
obtained as follows:

wget ftp://ftp.ncbi.nih.gov/pub/COG/COG/myva
wget ftp://ftp.ncbi.nih.gov/pub/COG/COG/whog

The myva file should be formatted for use as a BLAST database as
follows:

formatdb -p T -i myva -o T

Three scripts are called by assign_cogs.pl: get_cds.pl, get_orfs.pl
and local_blast_client.pl. The full paths to these scripts must be
specified. Some of these scripts may require additional Perl modules
to be installed--see the README.txt files included with the scripts.

The full path to NCBI's blastall program is also required.

USAGE: perl assign_cogs.pl [-arguments]
 -i [FILE]        : GenBank, EMBL, FASTA, or raw DNA sequence file
                    (Required).
 -o [FILE]        : Output file to create (Required).
 -s [STRING]      : Source of protein sequences. Use 'cds' to indicate
                    that the CDS translations in the GenBank file
                    should be used. Use 'orfs' to indicate that
                    translated open reading frames should be used
                    (Required).
 -myva [FILE]     : COG myva file formatted as a BLAST database
                    (Required).
 -whog [FILE]     : COG whog file (Required).
 -get_orfs [FILE] : Path to the get_orfs.pl script (Required).
 -get_cds [FILE]  : Path to the get_cds.pl script (Required).
 -local_bl [FILE] : Path to the local_blast_client.pl script
                    (Required).
 -blastall [FILE] : Path to the blastall program (Required).
 -c [INTEGER]     : NCBI genetic code to use for translations
                    (Optional. Default is 11).
 -a               : report all COG functional categories identified by
                    BLAST (Optional. Default is to report functional
                    category from top BLAST hit). 
 -e [REAL]        : E value cutoff for BLAST search (Optional. Default
                    is 10.0).
 -p [REAL]        : Minimum HSP length to keep, expressed as a
                    proportion of the query sequence length
                    (Optional. Default is to ignore length).
 -starts [STRING] : Start codons for ORFs (Optional. Default is
                    'atg|ttg|att|gtg|ctg'. To allow ORFs to begin with
                    any codon, use the value 'any').
 -stops [STRING]  : Stop codons for ORFs (Optional. Default is
                    'taa|tag|tga').
 -m_orf [INTEGER] : Minimum acceptable length for ORFs in codons
                    (Optional. Default is 30 codons).
 -m_score [REAL]  : Minimum acceptable BLAST score for COG assignment
                    (Optional. Default is to ignore score).
 -v               : provide progress messages (Optional).

perl assign_cogs.pl -i test_input/NC_013407.gbk \
-o test_output/NC_013407.gff -s cds \
-myva db/myva -whog db/whog \
-get_orfs get_orfs/get_orfs.pl \
-get_cds get_cds/get_cds.pl \
-local_bl local_blast_client/local_blast_client.pl