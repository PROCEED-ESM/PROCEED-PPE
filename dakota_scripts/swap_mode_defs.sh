#!/bin/bash

set -e

# get the file paths & settings from config.txt
source config.txt
FILE_DIR=$CODE_PATH/$NEWCASE
# NEWCASE=$NEWCASE
WORK_DIR=$WORKING_PATH/workdir
MODE_DEFS_CSV=$FILE_DIR/$NEWCASE"_parameter_vals_MODE_DEFS_annotated.csv"
RESAMPLE=$RESAMPLE
n_samples=$N_SIMS

# if resample=True, change the mode defs csv name
if [ "$RESAMPLE" = true ]; then
    MODE_DEFS_CSV=$FILE_DIR/$NEWCASE"_parameter_vals_MODE_DEFS_annotated_RESAMPLE.csv"
fi

# Get an array of the full paths to each user_nl_eam file
# (but only swap if it's a resampled value!)
if [ "$RESAMPLE" = true ]; then
    tot_samples=$((n_samples*2))
    # rs_start=$((n_samples + 1))
    # SampleArr=( $(seq $rs_start $tot_samples) )
    seq_og=$(seq 1 $n_samples) # list of original workdir #'s
else
    # SampleArr=( $(seq 1 $n_samples) )
    tot_samples=$n_samples
fi


SampleArr=( $(seq 1 $tot_samples) )
echo "${#SampleArr[@]} new mode_defs values will be swapped."

NamelistArr=()
for i in "${!SampleArr[@]}"; do
    sample=${SampleArr[$i]}
    workdir=$WORK_DIR"."$sample
    nl_eam=$workdir/$NEWCASE/user_nl_eam
    NamelistArr+=($nl_eam)
done

# Read the mode defs into an array - each element will be a single line of each definiton
# (i.e., length is >> n_samples)
SplitDefsArr=($(python -c 'import pandas as pd; print(pd.read_csv("'$MODE_DEFS_CSV'")["mode_defs"].values)' | tr -d '[]*'))
split_def_len=${#SplitDefsArr[@]}

# Get the number of lines of strings (# elements in the array) corresponding to a single mode_def
# (this is the same for all mode_defs, so just use the first)
mode_def_len=($(python -c 'import pandas as pd; val = pd.read_csv("'$MODE_DEFS_CSV'")["mode_defs"].values[0].split(","); print(len(val))'))

# Loop through each mode_def and append to the corresponding user_nl_eam file
# Loop through ALL - but if it's resampled, only do the appending for the new ones
if [ "$RESAMPLE" = true ]; then
    echo "Only the NEW (resampled) definitions will actually be swapped."
fi

for i in `seq 0 $mode_def_len $(($split_def_len - 1))`; do
    nl_idx=$(($i / $mode_def_len))
    nl_file=${NamelistArr[$nl_idx]}
    # if resampled, check if it's part of the original set or not
    if [ "$RESAMPLE" = true ]; then
        workdir_num=$(echo "$nl_file" | grep -oP '(?<=workdir\.)\d+')
        if [ ! "$workdir_num" -le "$n_samples" ]; then
            echo "" >> $nl_file
            echo "! -- mode_defs swapped outside of Dakota ----- " >> $nl_file
            echo "mode_defs = " >> $nl_file
            end_index=$(($mode_def_len - 1))
            for j in `seq 0 1 $end_index`; do
                newind=$(( $j + $i ))
                line="${SplitDefsArr[$newind]//\"}" # drop the " if present
                echo "$line" >> $nl_file
            done
            echo "Swapping done for workdir.$workdir_num"
        fi
    else
        echo "" >> $nl_file
        echo "! -- mode_defs swapped outside of Dakota ----- " >> $nl_file
        echo "mode_defs = " >> $nl_file
        end_index=$(($mode_def_len - 1))
        for j in `seq 0 1 $end_index`; do
            newind=$(( $j + $i ))
            line="${SplitDefsArr[$newind]//\"}" # drop the " if present
            echo "$line" >> $nl_file
        done
    fi
done
echo "All mode_defs swapped! You are now ready to submit each job."
