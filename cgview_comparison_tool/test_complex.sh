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
for i in sample_project_1 sample_project_2 sample_project_3 sample_project_4 sample_project_5 sample_project_6
do
  for j in project_settings_a.conf project_settings_b.conf project_settings_c.conf
  do
    cgview_comparison_tool.pl -c ./conf/global_settings.conf -p ./sample_projects/$i -s ./sample_projects/$i/$j -f ${i}_${j}_
  done

done


