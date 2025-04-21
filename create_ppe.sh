#!/bin/bash

set -e

echo ""
echo "============ SETTING UP NEW CASE: ============"
echo ""
./setup_steps.sh || exit 1
echo ""

# get into the new case directory (aka PPE subdirectory)
source config.txt
cd $NEWCASE/

echo "============ CREATING SAMPLING FILES: ============"
echo ""
./create_sampling_files.sh
echo ""

echo "============ CONVERTING POM HYGROSCOPICITY VALUES TO MODE_DEFS: ============"
echo ""
./POM_hygro_to_mode_defs.sh
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
