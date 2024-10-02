#!/bin/csh 

# get the file paths & settings from config.txt
set noglob
source config_csh.txt
unset noglob

set cwd=$PWD

# NOTE - the spacing between equals sign and the variable matters for the next block!
set code_root = $E3SM_CODE_ROOT
set parent_dir = $E3SM_OUTPUT_DIR/$PARENT_CASENAME
set parent_case=$PARENT_RUN  #Must cp its casescripts dir subdir contents into its main dir. 
set run_root = .
set newcase=$NEWCASE

mkdir -p ./old

if ( -d ./${newcase} ) then
    echo "removing old dir"
    rm -rf old/*
    mv -f ${newcase} old
endif 

# NOTE: Copy the contents of the case_scripts dir into the case_dir if not already done!
 ${code_root}/cime/scripts/create_clone --keepexe --case ${run_root}/${newcase} --clone ${parent_dir}/${parent_case} 

# If you get a warning from CIME about "SourceMods" then you have the wrong CIME version and need to run git clean -d in cime. 

# change the run and build directories to be local. 
cd ${newcase}
set casedir=$PWD
./xmlchange RUNDIR=${casedir}/run
./xmlchange DOUT_S_ROOT=${casedir}/archive #BMW 20220124 (after running the ensemble and realizing I should have included this). 


# Append dakota input params to user_nl_eam
cat ../$NEWCASE"_inp.yaml" >> user_nl_eam


# Don't submit the run.

# Let Dakota know we're finished. 
touch all_done.txt
date >> e3sm.log 
