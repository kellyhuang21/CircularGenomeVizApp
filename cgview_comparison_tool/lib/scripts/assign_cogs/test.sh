#!/bin/bash
set -e
formatdb=/usr/local/blast/bin/formatdb
scripts_path=/home/paul/stothard_group/projects


wd=`pwd`

if [ ! -d test_output ]; then
    mkdir test_output
fi

if [ ! -d db ]; then
    mkdir db
fi

cd db
if [ ! -f myva ]; then
    wget ftp://ftp.ncbi.nih.gov/pub/COG/COG/myva
fi

if [ ! -f whog ]; then
    wget ftp://ftp.ncbi.nih.gov/pub/COG/COG/whog
fi

if [ ! -f myva.phr ]; then
    formatdb -p T -i myva -o T
fi

cd $wd

perl assign_cogs.pl -i test_input/sample_1.gbk \
-o test_output/sample_1.gff -s cds \
-myva db/myva -whog db/whog \
-get_orfs $scripts_path/get_orfs/get_orfs.pl \
-get_cds $scripts_path/get_cds/get_cds.pl \
-local_bl $scripts_path/local_blast_client/local_blast_client.pl \
-blastall /usr/local/blast/bin/blastall -v

perl assign_cogs.pl -i test_input/sample_1.gbk \
-o test_output/sample_1b.gff -s cds \
-myva db/myva -whog db/whog \
-get_orfs $scripts_path/get_orfs/get_orfs.pl \
-get_cds $scripts_path/get_cds/get_cds.pl \
-local_bl $scripts_path/local_blast_client/local_blast_client.pl \
-blastall /usr/local/blast/bin/blastall \
-a -e 0.0000001 -p 0.60 -v

perl assign_cogs.pl -i test_input/sample_2.fna \
-o test_output/sample_2.gff -s orfs \
-myva db/myva -whog db/whog \
-get_orfs $scripts_path/get_orfs/get_orfs.pl \
-get_cds $scripts_path/get_cds/get_cds.pl \
-local_bl $scripts_path/local_blast_client/local_blast_client.pl \
-blastall /usr/local/blast/bin/blastall -v

perl assign_cogs.pl -i test_input/sample_2.fna \
-o test_output/sample_2b.gff -s orfs \
-myva db/myva -whog db/whog \
-get_orfs $scripts_path/get_orfs/get_orfs.pl \
-get_cds $scripts_path/get_cds/get_cds.pl \
-local_bl $scripts_path/local_blast_client/local_blast_client.pl \
-blastall /usr/local/blast/bin/blastall \
-a -e 0.0000001 -p 0.60 -v

perl assign_cogs.pl -i test_input/sample_3.fna \
-o test_output/sample_3.gff -s orfs \
-myva db/myva -whog db/whog \
-get_orfs $scripts_path/get_orfs/get_orfs.pl \
-get_cds $scripts_path/get_cds/get_cds.pl \
-local_bl $scripts_path/local_blast_client/local_blast_client.pl \
-blastall /usr/local/blast/bin/blastall -v

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