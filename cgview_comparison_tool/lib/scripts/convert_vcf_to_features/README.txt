FILE: convert_vcf_to_features.pl
AUTH: Jason Grant (jason.grant@ualberta.com)
DATE: September 23, 2011
VERS: 1.0

DISCRIPTION:
This script converts a VCF (Variant Call Format) file into a feature
file (GFF). The resulting GFF file can be used by the CGview Comparison
tool. Simply place the GFF file in the 'features' directory of a CCT
project. 

The following describes how the conversion is done:
-The VCF file has a number of meta-information lines that start with ##.
These lines are ignored.
-This is followed by the header row which consists at a minimum of 8 fixed
mandatory columns:
#CHROM POS ID REF ALT QUAL FILTER INFO
-Each row after the header is a data line
-For each chromosome encountered, a separate output file will be created. If
the output file option was "results" and the chromsome is 20 then output
file name will be results_20.gff.
-GFF column names and generated data for each:
   seqname         variant_j, where j is a number from 1 to number of variants processed
   source          .
   feature         other
   start           POS (from VCF)
   end             POS (from VCF) + length of REF (from VCF) - 1
   score           .
   strand          +
   frame           .

-For a detailed description of the VCF file format see:
http://www.1000genomes.org/node/101

EXAMPLE INPUT:
file: input.vcf

##fileformat=VCFv4.0
##fileDate=20090805
##source=myImputationProgramV3.1
##reference=1000GenomesPilot-NCBI36
##phasing=partial
##INFO=<ID=NS,Number=1,Type=Integer,Description="Number of Samples With Data">
##INFO=<ID=DP,Number=1,Type=Integer,Description="Total Depth">
##INFO=<ID=AF,Number=.,Type=Float,Description="Allele Frequency">
##INFO=<ID=AA,Number=1,Type=String,Description="Ancestral Allele">
##INFO=<ID=DB,Number=0,Type=Flag,Description="dbSNP membership, build 129">
##INFO=<ID=H2,Number=0,Type=Flag,Description="HapMap2 membership">
##FILTER=<ID=q10,Description="Quality below 10">
##FILTER=<ID=s50,Description="Less than 50% of samples have data">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=GQ,Number=1,Type=Integer,Description="Genotype Quality">
##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read Depth">
##FORMAT=<ID=HQ,Number=2,Type=Integer,Description="Haplotype Quality">
#CHROM POS     ID        REF ALT    QUAL FILTER INFO                              FORMAT      NA00001        NA00002        NA00003
20	14370	rs6054257	G	A	29	PASS	NS=3;DP=14;AF=0.5;DB;H2	GT:GQ:DP:HQ	0|0:48:1:51,51	1|0:48:8:51,51	1/1:43:5:.,.
20	17330	.	T	A	3	q10	NS=3;DP=11;AF=0.017	GT:GQ:DP:HQ	0|0:49:3:58,50	0|1:3:5:65,3	0/0:41:3
21	1110696	rs6040355	A	G,T	67	PASS	NS=2;DP=10;AF=0.333,0.667;AA=T;DB	GT:GQ:DP:HQ	1|2:21:6:23,27	2|1:2:0:18,2	2/2:35:4
21	1230237	.	T	.	47	PASS	NS=3;DP=13;AA=T	GT:GQ:DP:HQ	0|0:54:7:56,60	0|0:48:4:51,51	0/0:61:2
20	1234567	microsat1	GTCT	G,GTACT	50	PASS	NS=3;DP=9;AA=G	GT:GQ:DP	0/1:35:4	0/2:17:2	1/1:40:3

EXAMPLE OUTPUT:
file: output_20.gff

seqname	source	feature	start	end	score	strand	frame
variant_1	.	other	14370	14370	.	+	.
variant_2	.	other	17330	17330	.	+	.
variant_3	.	other	1234567	1234570	.	+	.

file: output_21.gff

seqname	source	feature	start	end	score	strand	frame
variant_1	.	other	1110696	1110696	.	+	.
variant_2	.	other	1230237	1230237	.	+	.



 USAGE: perl convert_vcf_to_features.pl [-arguments]
 -i [FILE]     : input VCF file (tab deliminated)
 -o [FILE]     : output file
 perl convert_vcf_to_features.pl -i input.vcf -o output.gff
