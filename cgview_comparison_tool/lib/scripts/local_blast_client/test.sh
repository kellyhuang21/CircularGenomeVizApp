#!/bin/bash
set -e
path_to_blast=/usr/local/blast/bin

if [ ! -d test_output ]; then
    mkdir test_output
fi
 
#build databases
if [ ! -d test_input/formatted_databases ]; then
    mkdir test_input/formatted_databases
fi

$path_to_blast/formatdb -i test_input/test_dna_database.fasta -p F -n test_input/formatted_databases/test_dna_database.fasta
$path_to_blast/formatdb -i test_input/test_protein_database.fasta -p T -n test_input/formatted_databases/test_protein_database.fasta
rm formatdb.log

#Nucleotide-nucleotide BLAST (blastn)
perl local_blast_client.pl -i test_input/test_input_dna.fasta -y $path_to_blast/blastall -b blastn -d test_input/formatted_databases/test_dna_database.fasta -o test_output/results_blastn.txt

#Protein-protein BLAST (blastp)
perl local_blast_client.pl -i test_input/test_input_protein.fasta -y $path_to_blast/blastall -b blastp -d test_input/formatted_databases/test_protein_database.fasta -o test_output/results_blastp.txt -x 1E-50

#Translated query vs protein database (blastx)
perl local_blast_client.pl -i test_input/test_input_dna.fasta -y $path_to_blast/blastall -b blastx -d test_input/formatted_databases/test_protein_database.fasta -o test_output/results_blastx.txt

#Protein query vs translated database (tblastn)
perl local_blast_client.pl -i test_input/test_input_protein.fasta -y $path_to_blast/blastall -b tblastn -d test_input/formatted_databases/test_dna_database.fasta -o test_output/results_tblastn.txt

#Translated query vs. translated database (tblastx)
perl local_blast_client.pl -i test_input/test_input_dna.fasta -y $path_to_blast/blastall -b tblastx -d test_input/formatted_databases/test_dna_database.fasta -o test_output/results_tblastx.txt

rm -rf test_input/formatted_databases

#compare new output to sample output
new_output=test_output
old_output=sample_output
new_files=($( find $new_output -type f -print0 | perl -ne 'my @files = split(/\0/, $_); foreach(@files) { if (!($_ =~ m/\.svn/)) {print "$_\n";}}'))
for (( i=0; i<${#new_files[@]}; i++ ));
do
    old_file=${old_output}`echo "${new_files[$i]}" | perl -nl -e 's/^[^\/]+//;' -e 'print $_'`
    echo "Comparing ${old_file} to ${new_files[$i]}"
    set +e
    diff -u $old_file ${new_files[$i]}
    if [ $? -eq 0 ]; then
	echo "No differences found"
    fi
    set -e
done