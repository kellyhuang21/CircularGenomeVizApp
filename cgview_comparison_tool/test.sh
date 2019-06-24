#!/bin/bash -e

function abort_test {
  echo "
  For details see the CCT installation instructions in the 'docs' directory or
  online:

  http://stothard.afns.ualberta.ca/downloads/CCT/installation.html

  Aborting test!
" >&2
  exit 1
}


# Check that the CCT_HOME variable is set
if [ -z $CCT_HOME ]; then
  echo "
  Please set the \$CCT_HOME environment variable to the full path to the
  cgview_comparison_tool directory.

  For example, add something like the following to your ~/.bashrc
  or ~/.bash_profile file:

     export CCT_HOME="/path/to/cgview_comparison_tool"

  After saving reload your ~/.bashrc or ~/.bash_profile file:

    source ~/.bashrc
"
  abort_test
fi

# Check for Java
if ! command -v java &>/dev/null; then
  echo "
  Java is required but it's not installed." >&2

  abort_test
fi

# Check for blast
if ! command -v blastall &>/dev/null; then
  echo "
  Blast is required but it's not installed." >&2

  abort_test
fi

# Check for ImageMagick
if   ( ! command -v convert &>/dev/null ) || ( ! command -v montage &>/dev/null ); then
  echo "
  WARNING: ImageMagick is not installed. ImageMagick is required for the build_blast_atlas_all_vs_all.sh command.
  
  For details see the CCT installation instructions in the 'docs' directory or
  online:

  http://stothard.afns.ualberta.ca/downloads/CCT/installation.html

  Testing will continue in 10 seconds...
" >&2
  sleep 10
fi

# Check for blast
if ! command -v blastall &>/dev/null; then
  echo "
  Blast is required but it's not installed." >&2

  abort_test
fi


# Check for cgview_comparison_tool.pl
if ! command -v  cgview_comparison_tool.pl &>/dev/null; then
  echo "
  Could not find 'cgview_comparison_tool.pl'. Have you added the
  cgview_comparison_tool/scripts directory to your PATH?
  
  For example, add the following to your ~/.bashrc or ~/.bash_profile file:

    export PATH="\$PATH":"${CCT_HOME}"/scripts
" >&2

  abort_test
fi


# Run tests
for i in test_blastn test_blastx test_tblastx test_blastp test_tblastn test_plots test_orfs
do
  for j in project_settings.conf
  do
    cgview_comparison_tool.pl -c ./conf/global_settings.conf -p ./sample_projects/$i -s ./sample_projects/$i/$j
  done

done


