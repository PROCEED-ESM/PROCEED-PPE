#!/bin/bash

set -e

source config.txt

# Preliminary steps that must be executed before this script will run!
echo ""
echo "**** BEFORE CONTINUING: ****"
echo "---> A. Edit config.txt as needed. **IF YOU WANT TO MAKE ADDITIONAL PPE MEMBERS**, make sure \"RESAMPLE=true\""
echo "---> B. Rename your parameter ranges csv file as "$NEWCASE"_param_ranges.csv"
echo "---> C. Activate the virtual environment where necessary packages are installed (i.e., conda activate ppe)"
while true; do
    read -p "Have you done these three steps? " yn
    case $yn in
        [Yy]* ) echo "Great! Continuing with automatic setup..."; break;;
        [Nn]* ) echo "Rerun this script after you have completed steps A, B, and C above."; exit 1;;
        * ) echo "Please answer yes or no";;
    esac
done

echo ""

# Read in from config.txt if you want to resample/make new samples for an existing PPE
RESAMPLE=$RESAMPLE

# ------- setup steps if you are making a new PPE ---------
if [ "$RESAMPLE" = false ]; then
    
    # 1. Make a new directory named after your newcase
    mkdir -p $NEWCASE/
    echo "---> PPE subdirectory created for "$NEWCASE"/"
    
    # 2. Move your csv file in there
    cp $NEWCASE"_param_ranges.csv" $NEWCASE/.
    echo "---> "$NEWCASE"_param_ranges.csv copied into PPE subdirectory"
    
    # 3. Copy/link files for Dakota
    cp template_files/* $NEWCASE/.
    cd $NEWCASE/
    cp ../config.txt config.txt
    if [ ! -f create_sampling_files.sh ] ; then
        ln -s ../dakota_scripts/create_sampling_files.sh create_sampling_files.sh
    fi
    if [ ! -f POM_hygro_to_mode_defs.sh ] ; then
        ln -s ../dakota_scripts/POM_hygro_to_mode_defs.sh POM_hygro_to_mode_defs.sh
    fi
    if [ ! -f swap_mode_defs.sh ] ; then
        ln -s ../dakota_scripts/swap_mode_defs.sh swap_mode_defs.sh
    fi
    echo "---> Template files for Dakota copied/linked into PPE subdirectory"
    
    # 4. Edit the e3sm.in file according to config.txt
    python ../dakota_scripts/edit_e3sm_in.py $NEWCASE $WORKING_PATH
    if [ -f $NEWCASE"_e3sm.in" ] ; then
        rm newcase_e3sm.in
    else
        echo "ERROR: file $NEWCASE"_e3sm.in" was not created..."
        exit 1
    fi 
    echo "---> e3sm.in file edited for this case using config.txt values and param_ranges.csv file"
    
    # 5. Make a csh-readable copy of the config file
    cp config.txt config_csh.txt
    sed -i -e 's/export /set /g' config_csh.txt
    echo "---> Created a csh-readable copy of the config file"
    
    # 6. Copy contents of the case_scripts/ directory from the parent case into the parent run directory
    parent_run_dir=$E3SM_OUTPUT_DIR/$PARENT_CASENAME/$PARENT_RUN
    cp -r $parent_run_dir/case_scripts/* $parent_run_dir/.
    echo "---> Contents of case_scripts/ copied into the parent run directory for Dakota"
    
    echo ""
    echo "**** Automatic setup completed! ****"
    echo ""
fi

# ------- setup steps if you are resampling an existing PPE ---------
if [ "$RESAMPLE" = true ]; then
    echo "Beginning automatic setup steps to resample an existing PPE."
    echo "This will double the number of ensemble members; if you had 125 before, you will have 250 when this process is done. The first half are exactly the same (less a rounding error, potentially), but the other half will have new parameter values."

    # 0. Make sure the default run is in (or symbolically linked back into) the target directory where workdirs will be stored
    echo ""
    echo "**** BEFORE CONTINUING WITH THE RESAMPLE: ****"
    echo ""
    while true; do
        read -p "Is the default model simulation that will be cloned inside the target directory? " yn
        case $yn in
            [Yy]* ) echo "Great! Continuing with automatic setup..."; break;;
            [Nn]* ) echo "You can copy it symbolically using cp -rs --preserve=links /path/to/workdir.000/* /path/where/workdirs/will/go/. That must be done before continuing so Dakota knows what to clone!"; exit 1;;
            * ) echo "Please answer yes or no";;
        esac
    done
    
    echo ""

    # 1. Copy the old .in file and change the import_points_file to the one with "_RESAMPLE.txt" (will be created later)
    #    and change the name of the restart file to "e3sm_RESAMPLE.rst"
    cd $NEWCASE/
    cp ../config.txt config.txt
    new_in_file=$NEWCASE"_e3sm_RESAMPLE.in"
    cp $NEWCASE"_e3sm.in" $new_in_file
    sed -i 's/_freeform_no_POM.txt/_freeform_RESAMPLE_no_POM.txt/g' $new_in_file
    sed -i 's/e3sm.rst/e3sm_RESAMPLE.rst/g' $new_in_file
    echo "---> Made a new .in file and changed the import_points_file path to the one that will contain resampled values and changed the name of the restart file."

    # 2. Make a new run_dakota file that does NOT delete old workdirs but DOES pass in read_restart
    # (do this line by line - easier)
    new_run_file=run_dakota_RESAMPLE.sh
    touch $new_run_file
    echo "#!/bin/bash" >> $new_run_file
    echo "" >> $new_run_file
    echo "dakota -i $new_in_file -read_restart e3sm.rst -o "$NEWCASE"_e3sm.out -e "$NEWCASE"_e3sm.err" >> $new_run_file
    echo "" >> $new_run_file
    chmod +x $new_run_file
    echo "---> Made a new run_dakota file that will read in the last Dakota restart file so only the new/resampled parameters get swapped."

    # 5. Make a csh-readable copy of the config file
    cp config.txt config_csh.txt
    sed -i -e 's/export /set /g' config_csh.txt
    echo "---> Created a csh-readable copy of the config file"

    echo ""
    echo "**** Automatic setup for a resampled PPE completed! ****"
    echo ""

fi

