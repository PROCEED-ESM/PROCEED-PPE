#!/bin/bash

set -e

# ---------- EDIT THE FOLLOWING VARIABLES AS NEEDED ----------
# Set this equal to "RESUBMIT=" in the original/default case run script
N_RESUBMIT=7

# How many jobs to submit per bundle, per type (PI and PD)
N_PER_BUNDLE=5

# Total number of simulations for each PI/PD (from config.txt)
# (also the starting point - resample!)
N_SIMS=125

# Copy these paths over from the _e3sm.in files and/or config.txt
WORKDIR_PI=/glade/derecho/scratch/jnug/E3SM/v3.F2010.nudged.PI/PPE/workdir
WORKDIR_PD=/glade/derecho/scratch/jnug/E3SM/v3.F2010.nudged.PD/PPE/workdir
NEWCASE_base=ppev0


# ---------- LOOP TO MAKE/SAVE THE BUNDLE FILES ----------
# Zero pad workdir #'s so the scripts are saved in order
function zero_pad {
    printf "%03d" $1
}

# Put the bundle scripts in their own directory
mkdir -p $NEWCASE_base"_bundle_scripts/"
cd $NEWCASE_base"_bundle_scripts/"

# Make the files
tot_sims=$((2*N_SIMS))
start_sim=$((N_SIMS+1))
for i in `seq $start_sim $N_PER_BUNDLE $tot_sims`; do

    n_end=$(($i + $N_PER_BUNDLE - 1))
    zp_beg=$(zero_pad $i)
    zp_end=$(zero_pad $n_end)
    bundle_file="bundle."$zp_beg"-"$zp_end".PI-PD.sh"
    BundleArr=( $(seq $i $n_end) )

    if [ -f $bundle_file ]; then
        rm $bundle_file
    fi
    touch $bundle_file
    
    echo "#!/bin/bash" >> $bundle_file
    echo "" >> $bundle_file
    
    for j in "${BundleArr[@]}"; do
        LinesArr=()
        LinesArr+=("cd $WORKDIR_PI.$j/$NEWCASE_base""_PI")
        LinesArr+=("./xmlchange --id RESUBMIT --val "$N_RESUBMIT)
        LinesArr+=("./case.submit")
        LinesArr+=("")
        LinesArr+=("cd $WORKDIR_PD.$j/$NEWCASE_base""_PD")
        LinesArr+=("./xmlchange --id RESUBMIT --val "$N_RESUBMIT)
        LinesArr+=("./case.submit")
        LinesArr+=("")
        printf '%s\n'  "${LinesArr[@]}" >> $bundle_file
    done
    chmod +x $bundle_file
done
