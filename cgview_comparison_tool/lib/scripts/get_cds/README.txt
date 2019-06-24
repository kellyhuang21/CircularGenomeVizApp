get_cds.pl
This script requires bioperl-1.4 or newer.

This script accepts a GenBank or EMBL file and extracts the protein
translations or the DNA coding sequences and writes them to a new file
in FASTA format. Information indicating the reading frame and position
of the coding sequence relative to the source sequence is added to the
titles.

There are two required command line parameters:
-----------------------------------------------

-i - Input file (GenBank, or EMBL). [File].

-o - Output file. [File].

Optional parameters:
--------------------

-dna - Return DNA instead of protein. [T/F]. Default is F.

Example usage:

perl get_cds.pl -i input.gbk -o output.fasta

Written by Paul Stothard

stothard@ualberta.ca
