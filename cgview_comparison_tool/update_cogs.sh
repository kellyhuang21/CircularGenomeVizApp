#!/bin/bash -e
#This script downloads files needed for COG assignment
wd=`pwd`

function error_exit {
        echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        exit 1
}

if [ -z $CCT_HOME ]; then
    error_exit "Please set the \$CCT_HOME environment variable to the path to the cgview_comparison_tool directory"
fi

cct_home=$CCT_HOME

#COG files
if [ ! -d "$cct_home"/db/cogs ]; then
    mkdir -p "$cct_home"/db/cogs
fi

echo "Updating COG files"
cd "$cct_home"/db/cogs
wget -c -N -v ftp://ftp.ncbi.nih.gov/pub/COG/COG/myva
wget -c -N -v ftp://ftp.ncbi.nih.gov/pub/COG/COG/whog
echo "Formatting myva for BLAST"
formatdb -p T -i myva -o T -l "$cct_home"/db/cogs/formatdb.log
cd "$wd"

echo "Update complete."