sequence_to_multi_fasta.pl
This script requires bioperl-1.4 or newer.

This script accepts a file consisting of a single DNA sequence (in
raw, FASTA, GenBank, or EMBL format), and then divides the sequence
into smaller sequences of the size you specify. The new sequences are
written to a single output file with a modified title giving the
position of the subsequence in relation to the original sequence. The
new sequences are written in FASTA format.

There are three required command line parameters:

-i - Input file in FASTA, raw, GenBank, or EMBL format. [File].

-o - Output file. [File].

There is one optional parameter:

-v - The overlap to include between sequences, in bases. [Integer].

-s - The size of the sequences to create, in bases. [Integer]. Default
is to return the entire sequence as a single FASTA record.

Example usage:

perl sequence_to_multi_fasta.pl -i input.gbk -o output.fasta -s 10000 -v 500 

Written by Paul Stothard

stothard@ualberta.ca
