# PROCEED-PPE
Code needed to generate a PPE in the PROCEED framework using E3SMv3. This version supports perturbing any parameters that are on the namelist as well as the hygroscopicity of POM. In the next version, additional non-namelist aerosol properties will also be able to be perturbed. 

This code was partially based off of the example from Yarger et al. (2024), _JAMES_ [1] and uses Dakota software [2] from Sandia National Lab to handle the parameter swapping.

## To use this software to create a PPE:
![figure describing the framework for v0 of this code](./images/flowchart_for_v0.png)

1. **Make a .csv file containing the parameter names and the min and max values** ("example_case_param_ranges.csv" in the example). These parameters will be perturbed using Latin Hypercube sampling within that range.
2. **Edit the file config.txt as needed.** This file specifies the casename for the PPE ("example_case" in the example) paths to the E3SMv3 run you want to clone for the PPE, paths to where the local copy of this code is stored, the number of parameters to perturb, the number of simulations/ensemble members to generate, and whether or not you want to resample an existing PPE (i.e., generate additional ensemble members).
3. Make sure you are in a conda environment with the necessary packages installed (see environment.yml) and **run create_ppe.sh**. This script runs all of the necessary scripts to setup the new case for the PPE, sample the parameters from the provided ranges, swap the namelist parameters using Dakota [2], and swaps the POM hygroscopicity value by making copies of the file controlling its value and passing the new file paths to the `mode_defs` namelist variable. See descriptions in the table of contents below for what each script does.
4. **Submit the runs!** Note that you will need to change the values of `RESUBMIT` and `CONTINUE_RUN` using `./xml_change` if the original model run you are cloning had a resubmit value greater than zero.

## Contents:
* [**setup_steps.sh**](./setup_steps.sh): Makes the necessary subdirectory for the new case, copies the necessary files from **template_files/**, creates symbolic links to the files in **dakota_scripts/**, runs **dakota_scripts/edit_e3sm_in.py** to edit the e3sm.in file for this case, and finally copies the contents of the parent run directory into the case run (a step needed for Dakota to run).
* [**config.txt**](./config.txt): Controls the file paths and PPE settings (number of parameters and ensemble runs, case name, etc.). This file is read by the other scripts to pass along the information.
* [**create_ppe.sh**](./create_ppe.sh): Runs all of the scripts needed to create a PPE; see step 3 above.
* [**environment.yml**](./environment.yml): List of the required python packages to run this software as well as some that are helpful for analysis. To create a virtual environment with these packages, run `conda env create -f environment.yml`, and then you can activate it using `conda activate ppe`.
* [**template_files/**](./template_files/): Contains files common to all PPEs that get copied into each case. These files are needed for Dakota to do the namelist parameter swapping.
  * [**create.csh**](./template_files/create.csh): Helper script for Dakota to do the parameter swapping.
  * [**run.py**](./template_files/run.py): Analysis driver for Dakota.
  * [**run_dakota.sh**](./template_files/run_dakota.sh): Runs Dakota to make work directories ("workdir.X") for each ensemble member and swap the namelist parameter values.
  * [**newcase_e3sm.in**](./template_files/newcase_e3sm.in): Input file for Dakota to specify the details of the PPE/parameter swapping.
* [**dakota_scripts/**](./dakota_scripts/):
  * [**edit_e3sm_in.py**](./dakota_scripts/edit_e3sm_in.py): Edits the e3sm.in file in **template_files/** for the specific PPE case by changing the parameter names, ranges, and file paths. This is run inside of **setup_steps.sh**.
  * [**create_sampling_files.sh**](./dakota_scripts/create_sampling_files.sh/): Performs Latin Hybercube sampling (LHS) for all of the parameters simulataneously by running **lhs_sampling_for_dakota.py**. Create an input template file for Dakota to do the parameter swapping (excluding the POM_hygroscopicity_param, which is not on the namelist).
  * [**lhs_sampling_for_dakota.py**](./dakota_scripts/lhs_sampling_for_dakota.py/): Helper Python script to do the LHS in **create_sampling_files.sh**. Samples the parameter values and saves the sampled results (columns are parameters, rows are values for each ensemble member) to a .txt file for Dakota to read and a labeled/annotated .csv file for reference.
  * [**POM_hygro_to_mode_defs.sh**](./dakota_scripts/POM_hygro_to_mode_defs.sh): Copies the default POM file into a separate directory and changes its hygroscopicity value so that there is one new file per ensemble member. Generates a new .csv/.txt file pair containing the full "mode_defs" namelist definition (containing the path to the copied/adjusted file with the new hygroscopicity value for each ensemble member) by running **vals_to_mode_defs.py**.
  * [**vals_to_mode_defs.py**](./dakota_scripts/vals_to_mode_defs.py): Copies the default definition for the "mode_defs" namelist variable for each ensemble member, replaces the path to the POM file with the new file that has the adjusted hygroscopicity value for each ensemble member, and saves the mode_defs definitions into new .txt/.csv file pairs (columns are the mode_defs string, rows are each ensemble member).
  * [**swap_mode_defs.sh**](./dakota_scripts/swap_mode_defs.sh): Loops through the new mode_defs definitions in the .txt file and appends the new mode_defs defintiion to the namelist for each ensemble member. This is the equivalent of doing parameter swapping for the POM hygroscopicity value.
* [**images/**](./images/):
  * Contains the image file for the figure above. Not part of the actual PPE software.
* [**example_case/**](./example_case/):
  * Contains an example PPE using the parameter ranges from **example_case_param_ranges.csv**. This example has 3 parameters and 30 ensemble members. The subdirectories **workdir.[1-30]/example_case/** contain the files needed to submit each ensemble member to generate the model run. You can recreate this example by running **create_ppe.sh** again (changing the paths in the first half of **config.txt** as necessary for your machine).

## References.
1. Yarger, D., Wagman, B. M., Chowdhary, K., & Shand, L. (2024). Autocalibration of the E3SM version 2 atmosphere model using a PCA-based surrogate for spatial fields. _Journal of Advances in Modeling Earth Systems_, 16, e2023MS003961. https://doi.org/10.1029/2023MS003961.
2. Adams, B. M., Bohnhoff, W. J., Dalbey, K. R., Ebeida, M. S., Eddy, J. P., Eldred, M. S., . . . Winokur, J. G. (2023, November). _Dakota 6.19.0 documentation_ (Technical Report No. SAND2023-133920). Albuquerque, NM: Sandia National Laboratories. Retrieved from http://snl-dakota.github.io.

