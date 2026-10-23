#!/bin/bash

set -e

# load a virtual environment with conda and scipy installed
module load conda 
conda activate /glade/work/jnug/conda-envs/ppe

# get the file paths & settings from config.txt
source config.txt
FILE_DIR=$CODE_PATH/$NEWCASE
param_ranges_csv=$FILE_DIR/$NEWCASE"_param_ranges.csv"
inp_template_file=$FILE_DIR/$NEWCASE"_inp.yml.template"
RESAMPLE=$RESAMPLE

# SKIPPING the actual python sampling - where lhs_sampling python script is run
# (DO NOT RUN THIS SCRIPT if you aren't reusing sampling files from a previous case!)

# turn the column of parameter names into the substitution file for Dakota
# WILL OVERWRITE if $inp_template_file already exists, UNLESS you are resampling
# (otherwise will just tack on to the end of the file)
if [ "$RESAMPLE" = false ]; then
    if [ -f $inp_template_file ]; then
        echo "Input file template "$inp_template_file" already exists; deleting old version and making a new one."
        rm $inp_template_file
    fi
    {
        read
        while IFS=, read -r param min max || [[ -n "$param" ]]; do
           printf $param"\t = {{"$param"}}\n"
        done
    } < $param_ranges_csv >> $inp_template_file
    
    # delete the POM hygroscopicity parameter line - not swapped with Dakota
    sed -i '/POM_hygroscopicity_param/d' $inp_template_file
    
    if [ -f $inp_template_file ]; then
        echo "Parameter swap template file saved to "$inp_template_file". Contents of this file are:"
	echo ""
	cat "$inp_template_file"
	echo ""
	while true; do
	    read -p "****BEFORE CONTINUING****: do the file contents shown above list ALL namelist parameters to be perturbed (i.e., excluding parameters with values stored in mode_defs or similar)?" yn
	    case $yn in
		    [Yy]* ) echo ""; break;;
		    [Nn]* ) echo "Uh oh, something went wrong! Check that your "$NEWCASE"_param_ranges.csv does actually list all of your parameters and that the sampled parameter files copied from the PPE you're rerunning have all the parameters. If so, you may need to manually edit "$inp_template_file" to include all parameters. PROCEED WITH CAUTION IF SO - check the final user_nl_eam files in each work directory to make sure the parameters were perturbed before running!! ---> **** EXITING NOW ****"; exit 1;;
		    * ) echo "Please answer yes or no";;
	    esac
	done
    fi
fi
