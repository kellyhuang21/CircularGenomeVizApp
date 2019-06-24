This script performs BLAST searches against a local BLAST database. It
prompts the user for a BLAST search type and an input file of FASTA
formatted sequences. The script then submits each sequence to BLAST
and retrieves the results. For each of the hits the script retrieves a
detailed title by performing a separate query of NCBI's
databases. Each BLAST hit and its descriptive title are written to a
single tab-delimited output file.

Edit the following line in the script so that BLAST_PATH points to the
blastall program:

BLAST_PATH => "/usr/local/blast/bin/blastall";

or use the -y option to specify the path to blastall.

To run, enter 'perl local_blast_client.pl' or use command line
parameters to specify the options you would like to use.

Terminology: BLAST hits are comprised of one or more HSPs
("High-scoring Segment Pairs").

There are four required parameters:

-i - Input file containing multiple fasta sequences. [File].

-o - Output file to create. [File].

-d - Database to search. [File].

-b - BLAST program (blastn, blastp, blastx, tblastn, tblastx).
[String].

Optional parameters:

-h - Number of HSPs to keep per query. [Integer]. Default is to 
keep all HSPs.

-filter - Whether to filter query sequence. [T/F]. Default is T.

-a - Minimum HSP length to keep. [Integer]. Default is to keep
all HSPs.

-p - Minimum HSP length to keep, expressed as a proportion of
the query sequence length. [Real]. Overrides -a. Default is to keep
all HSPs.

-s - Minimum HSP score to keep. [Integer]. Default is to keep
all HSPs. 

-n - Minimum HSP identity to keep. [Real]. Default is to keep
all HSPs.

-x - Expect value to supply to the BLAST program. [Real]. Default is
10.0.

-t - Number of hits to keep. [Integer]. Default is 5.

-f - Whether to fetch sequence descriptions using Entrez. [T/F].
Default is T.

-Q - The genetic code to use for the query sequence, for translated
BLAST searches. [Integer]. Default is 1.

-D - The genetic code to use for the database sequences, for
translated BLAST searches. [Integer]. Default is 1.

-y - The path to the blastall program. [File]. Default is 
/usr/local/blast/bin/blastall

-hsp_label - Whether to add a label to the match_description of each
HSP to indicate which hit it belongs to. [T/F]. Default is F.

-W - The word size to use. [Integer]. Default depends on search type.

example usage:

perl local_blast_client.pl -i my_seqs.fasta -o blast_results.txt -b blastn -d plant

Note that you will have to run formatdb (included with BLAST) to
create your database. For example, to build a BLAST database from a
fasta file called fungi.fasta you might use:

formatdb -t fungi -i fungi.fasta -p F -o F -n fungi

See the README.formatdb file included with BLAST for more information.

Written by Paul Stothard, University of Alberta.
