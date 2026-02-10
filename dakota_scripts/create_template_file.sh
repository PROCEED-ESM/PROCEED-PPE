#!/bin/bash

set -e

# load a virtual environment with conda and scipy installed
module load conda 
conda activate /glade/work/jnug/conda-envs/ppe

# get the file paths & settings from config.txt
source config.txt
PYTHON_DIR=$CODE_PATH/dakota_scripts
FILE_DIR=$CODE_PATH/$NEWCASE
param_ranges_csv=$FILE_DIR/$NEWCASE"_param_ranges.csv"
param_vals_file=$FILE_DIR/$NEWCASE"_parameter_vals_freeform.txt"
inp_template_file=$FILE_DIR/$NEWCASE"_inp.yml.template"
RESAMPLE=$RESAMPLE
seed=$SEED # for the LHS sampler
n_samples=$N_SIMS

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
        while IFS=, read -r param min max; do
           printf $param"\t = {{"$param"}}\n"
        done
    } < $param_ranges_csv >> $inp_template_file
    
    # delete the POM hygroscopicity parameter line - not swapped with Dakota
    sed -i '/POM_hygroscopicity_param/d' $inp_template_file
    
    if [ -f $inp_template_file ]; then
        echo "Parameter swap template file saved to "$inp_template_file"."
    fi
fi
