#!/bin/bash

# get the file paths & settings from config.txt
source config.txt


#Remove any existing workdirs in scratch for this basename. 
/bin/rm -rf $WORKING_PATH/workdir.* 

# Clean up
/bin/rm -f *.out *.err *.rst

## Run dakota
dakota -i $NEWCASE"_e3sm.in" -o $NEWCASE"_e3sm.out" -e $NEWCASE"_e3sm.err"
