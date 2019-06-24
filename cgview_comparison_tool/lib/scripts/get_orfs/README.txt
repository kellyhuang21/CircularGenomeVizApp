get_orfs.pl
This script requires bioperl-1.4 or newer.

This script accepts a sequence file as input and extracts the open
reading frames (ORFs) greater than or equal to the specified size. The
resulting ORFs can be returned as DNA sequences, or as protein
sequences translated using the specified genetic code. The titles of
the sequences include start, stop, strand, and reading frame
information. The sequence numbering includes the stop codon (when
encountered) but the translations do not include a stop codon
character.

This script does not use the genetic code to identify ORF starts and
stops. The starts and stops are specified using the 'starts' and
'stops' options.

There are three required command line parameters:
-------------------------------------------------

-i - Input file (GenBank, EMBL, raw, or fasta). [File].

-o - Output file. [File].

-m - Minimum ORF size in codons. [Integer].


Optional parameters:
-------------------

-starts - Start codons. Default is 'atg|ttg|att|gtg|ctg'. To allow
ORFs to begin with any codon, use the value 'any'. [String].

-stops - Stop codons. Default is 'taa|tag|tga'. [String].

-dna - Return DNA instead of translations. [T/F]. Default is F.

-g - Genetic code (based on genetic code numbers used by
bioperl). [Integer]. Default is 1.


Example usage:
--------------

perl get_orfs.pl -i input.gbk -o output.fasta -g 11 -m 100

Written by Paul Stothard

stothard@ualberta.ca
