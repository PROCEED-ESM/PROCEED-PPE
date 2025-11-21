#!/bin/bash

set -e

echo "Create PPE using the parameter values already swapped in a previous PPE - for Nephele rerun2, to get additional outputs not saved in the first Nephele rerun."
echo "--> BEFORE YOU START, you must "
echo "       1. edit the config.txt file"
echo "       2. run setup_steps.sh."
echo "       3. once you have the new ppe case (rerun2.PD/ or rerun2.PI/), copy all parameter value csvs from rerun.PD into rerun2.PD and change name so it matches (e.g., cp rerun.PD/rerun.PD_parameter_vals.... rerun2.PD/rerun2.PD_parameter_vals....)"
echo "       4. THEN come back here to run the script. This script skips LHS sampling and creating the POM files and just reuses the ones already made for the Neph rerun."
echo ""
while true; do
    read -p "Are you ready to proceed?? " yn
    case $yn in
        [Yy]* ) echo "Great! Continuing with automatic setup..."; break;;
        [Nn]* ) echo "Rerun this script after you have completed the steps above."; exit 1;;
        * ) echo "Please answer yes or no";;
    esac
done


echo ""
echo "============ ***SKIPPING** SETTING UP NEW CASE (was done separately): ============"
echo ""
# ./setup_steps.sh || exit 1
echo ""

# get into the new case directory (aka PPE subdirectory)
source config.txt
cd $NEWCASE/

echo "============ ***SKIPPING*** CREATING SAMPLING FILES: ============"
echo ""
# ./create_sampling_files.sh
echo ""

echo "============ ***SKIPPING*** CONVERTING POM HYGROSCOPICITY VALUES TO MODE_DEFS: ============"
echo ""
# ./POM_hygro_to_mode_defs.sh
echo ""

echo "============ RUNNING DAKOTA TO SWAP NUMERIC PARAMETERS: ============"
echo ""
source config.txt
RESAMPLE=$RESAMPLE
if [ "$RESAMPLE" = true ]; then
    ./run_dakota_RESAMPLE.sh
else
    ./run_dakota.sh
fi
echo ""

echo "============ SWAPPING MODE_DEFS: ============"
echo ""
./swap_mode_defs.sh
echo ""

echo "============ COPY .CASE.RUN AND CHANGE VALUES ============ "
echo ""
echo "(This is necessary because Dakota no longer can copy/clone the .case.run files for some reason, as of April 2025)"
echo ""
# loop through work directories, copy default .case.run file, and change the job name and os.chdir line
for i in $(seq 1 $N_SIMS); do
    ensn_scripts=$WORKING_PATH/workdir.$i/$NEWCASE
    def_scripts=$E3SM_OUTPUT_DIR/$PARENT_CASENAME/case_scripts
    cp $def_scripts/.case.run $ensn_scripts/.
    new_path=$(printf '%s\n' "$ensn_scripts" | sed 's/[&/\]/\\&/g')
    old_path=$(printf '%s\n' "$def_scripts" | sed 's/[&/\]/\\&/g')
    sed -i "s/${old_path}/${new_path}/g" "$ensn_scripts/.case.run"
    sed -i "s/run.${PARENT_CASENAME}/run.${NEWCASE}.${i}/g" "$ensn_scripts/.case.run"  
done
echo ""

echo "============ PPE DONE, READY TO SUBMIT!!!: ============"
echo ""
echo "Inside each workdir, run the following commands:"
echo "        ./xmlchange --id RESUBMIT --val (RESUBMIT)"
echo "        ./case.submit"
echo "where (RESUBMIT) is the number of times to resubmit the run."
echo ""
