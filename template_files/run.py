#!/usr/bin/env python
"""
# $1 is params.in.(fn_eval_num) from Dakota
# $2 is results.out.(fn_eval_num) returned to Dakota

# To test:  ./run_and_postprocess.py workdir.1/params.in.1 resultsTest.out  
#     (but not all file references will work when looking up/down a directory)

# To use:   	- ON CEE:  module load percept/anaconda2
                - ON HPC:  modele load anaconda
"""
import os
import sys
import time
import shutil
import pdb

# --- Read in newcase variable from the config file
# (probably a cleaner way to do this?)
with open("config_csh.txt", 'r') as f:
    for line in f:
        if "set NEWCASE=" in line and "#set" not in line:
            newcase = line.split("=")[-1].strip()

# ---- Print info about parameters passed in
params_file_name  = sys.argv[1]
results_file_name = sys.argv[2]
print("  Params file = ", params_file_name, "\n")
print( "  Results file = ", results_file_name, "\n")

pwd = os.getcwd() 
print(pwd)

# --------------
# DAKOTA PRE-PROCESSING
# --------------
print( "  Running dprepro to create input file  ... \n")
yml_tmp = newcase + '_inp.yml.template'
yml = newcase + '_inp.yaml'
cmd = 'dprepro --inline "{{ }}" ' + params_file_name + ' {t} {y}'.format(t=yml_tmp, y=yml)
os.system(cmd)

# --------
# BUILD E3SM 
# --------

print( '\n  Building E3SM job ... \n')
os.system('./create.csh') # create, configure, build E3SM. 


# ---------------
# POST-PROCESSING
# ---------------
print( '\n  No post processing --BMW  ... \n')
f = open("results.out", "w")
f.write(str(1.0))
f.close()

##-----File-Marshaling
pwd=os.getcwd()
results_file_name2 = pwd + '/' + results_file_name
shutil.copy('results.out', results_file_name2) 
print( results_file_name2)



