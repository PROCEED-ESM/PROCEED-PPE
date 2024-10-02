#!/bin/bash

set -e

module load nco
module load conda
conda activate /glade/work/jnug/conda-envs/ppe

# get the file paths & settings from config.txt
source config.txt
PPE_SCRIPT_DIR=$CODE_PATH/$NEWCASE
PARAMS_CSV=$PPE_SCRIPT_DIR/$NEWCASE"_parameter_vals_annotated.csv"
PYTHON_DIR=$CODE_PATH/dakota_scripts
INPUT_DIR=$E3SM_INPUT_DIR
PATH_TO_POM=$INPUT_DIR/atm/cam/physprops
DEFAULT_FILE=$PATH_TO_POM/ocpho_rrtmg_c130709_kPOM0.04.nc
NEW_PATH=$PATH_TO_POM/$NEW_POM_RELPATH
RESAMPLE=$RESAMPLE

# append some of the variable anmes if resample=true
if [ "$RESAMPLE" = true ]; then
    PARAMS_CSV=$PPE_SCRIPT_DIR/$NEWCASE"_parameter_vals_annotated_RESAMPLE.csv"
    OLD_PATH=$NEW_POM_RELPATH
    NEW_PATH=$NEW_PATH"RESAMPLED/"
    N_SAMPLES=$N_SIMS # from config.txt
    echo "$N_SAMPLES new copies of the files will be generated."
fi

# Directory for the new files to go in; delete existing files if there are any
mkdir -p $NEW_PATH
echo "New files will be saved to "$NEW_PATH"."
if [ ! -z "$(ls -A $NEW_PATH)" ]; then
    echo "Directory "$NEW_PATH" is not empty; deleting old files..." 
    rm $NEW_PATH/*.nc 
    echo "...done."
fi

# Read the POM hygroscopicity values from the csv into an array using python
# (if you're resampling, this will read in ALL samples (the combined file), but only use the new ones
# to make the files)
if [ "$RESAMPLE" = true ]; then
    PomArrRS=($(python -c 'import pandas as pd; print(pd.read_csv("'$PARAMS_CSV'")["POM_hygroscopicity_param"].values['$N_SAMPLES':])' | tr -d '[],'))
fi
PomArr=($(python -c 'import pandas as pd; print(pd.read_csv("'$PARAMS_CSV'")["POM_hygroscopicity_param"].values)' | tr -d '[],'))

# Check you have the right length (should = number of samples)
echo "There are "${#PomArr[@]}" total values for the POM hygroscopicity parameter."
if [ "$RESAMPLE" = true ]; then
    echo "--> "${#PomArrRS[@]}" values are resampled/new; only those values will be saved into new files."
fi

# Loop through each sampled value, swap it for the default value, and save the new file
fbname="$(basename $DEFAULT_FILE .nc)"

# if it was resampled
if [ "$RESAMPLE" = true ]; then
    for i in "${!PomArrRS[@]}"; do
        new_val=${PomArrRS[$i]}
        ind=$((i + N_SAMPLES))
        sim=$(printf %03d $(($ind+1)))
        new_file=$NEW_PATH/$fbname"_"$sim".nc"
        ncap2 -s "hygroscopicity=$new_val" $DEFAULT_FILE $new_file
    done

# if NOT resampled
else
    for i in "${!PomArr[@]}"; do
        new_val=${PomArr[$i]}
        sim=$(printf %03d $(($i+1)))
        new_file=$NEW_PATH/$fbname"_"$sim".nc"
        ncap2 -s "hygroscopicity=$new_val" $DEFAULT_FILE $new_file
    done
fi


echo "Done with swapping; all new files saved."

# Make new annotated csv and freeform txt files (replacing
# the POM hygroscopicity values with full `mode_defs` namelist strings
# containing updated file paths to the new POM files) - SEPARATE from the other
# parameter swap files - bc you will do the swapping outside of Dakota
if [ "$RESAMPLE" = true ]; then
    python $PYTHON_DIR/vals_to_mode_defs.py -i $PARAMS_CSV --POM_rel_path $OLD_PATH --resampled_path $NEW_PATH 
else
    python $PYTHON_DIR/vals_to_mode_defs.py -i $PARAMS_CSV --POM_rel_path $NEW_POM_RELPATH
fi
