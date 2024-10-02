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

echo "============ PPE DONE, READY TO SUBMIT!!!: ============"
echo ""
echo "Inside each workdir, run the following commands:"
echo "        ./xmlchange --id RESUBMIT --val (RESUBMIT)"
echo "        ./case.submit"
echo "where (RESUBMIT) is the number of times to resubmit the run."
echo ""
