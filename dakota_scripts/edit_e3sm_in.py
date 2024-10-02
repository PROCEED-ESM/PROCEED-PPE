"""
edit_e3sm_in.py

Script to edit the filepaths and other values in the e3sm.in file for each specific PPE case. 
The input file (template_files/newcase_e3sm.in) is unchanged and a new file is saved as 
[NEWCASE]/[NEWCASE]_e3sm.in where [NEWCASE] is the value specified by the user in config.txt.

The values of NEWCASE and WORKING_PATH from config.txt are passed in during the
setup_steps.sh script, which executes this python script.

The following lines in template_files/newcase_e3sm.in will change:
* Name of the sampled parameter values file
  --> line 9: import_points_file = ...
* Number of parameters to be varied by Dakota
  --> line 15: uniform_uncertain = ...
* Descriptors and lower/upper bounds on the parameters to be varied
  by Dakota
  --> lines 16-18: descriptors...
* Path to the work_directory
  --> line 29: work_directory named ...
* Name of the in.yml.template file for parameter swapping
  --> line 30: copy_files = ...
"""
import sys
import pandas as pd
from tabulate import tabulate


def format_descriptor_table(csv_file):
    """ 
    Make a formatted table of descriptors and lower/upper bounds
    from the .csv file. Returns a list of strings containing formatted
    row values and the number of Dakota-varied parameters.
    """
    ranges = pd.read_csv(csv_file)
    
     # this is needed to properly indent inside of the e3sm.in file
    indent_list = ["  "]*4 
    
    # Drop POM hygroscopicity line
    ranges = ranges[ranges["parameter"].str.contains("POM_hygroscopicity_param") == False]

    # Add quotes to beginning/end of each parameter name
    params = ["'" + param + "'" for param in ranges["parameter"].values]
    n_params_no_pom = len(params)

    # Make the table & split into row strings
    table = [
        [*indent_list, "descriptors", *params],
        [*indent_list, "lower_bounds", *ranges["min"].values],
        [*indent_list, "upper_bounds", *ranges["max"].values]
    ]
    table_string = str(tabulate(table, tablefmt="plain"))
    row_strings = table_string.split("\n")
    
    return row_strings, n_params_no_pom


def get_lines_for_new_in_file(row_strings, new_case, working_path, n_params_dakota):
    """
    Read in the template file and edit specific lines as necessary. 
    Returns a list of strings, one for each line in the new .in file.
    """
    new_lines = []
    
    with open("../template_files/newcase_e3sm.in", 'r') as f:
        for line in f:
            # update descriptors and lower/upper bounds for params to vary in Dakota
            if "descriptors" in line:
                new_lines.append(row_strings[0] + "\n")
            elif "lower_bounds" in line:
                new_lines.append(row_strings[1] + "\n")
            elif "upper_bounds" in line:
                new_lines.append(row_strings[2] + "\n")
    
            # change name of the .csv parameter ranges file
            elif "import_points_file" in line:
                new_lines.append(line.replace("NEWCASE", new_case))
    
            # change the number of **Dakota-varied** parameters
            elif "uniform_uncertain" in line:
                new_lines.append(line.replace("num_uncertain", str(n_params_dakota)))
    
            # change the working path where workdir.[1-n] will be saved
            elif "work_directory named" in line:
                new_lines.append(line.replace("WORKING_PATH", working_path))
    
            # change the name of the inp.yml.template file
            elif "copy_files" in line:
                new_lines.append(line.replace("NEWCASE", new_case))
    
            # keep all other lines the same!
            else:
                new_lines.append(line)

    return new_lines


def main():
    """ Read in e3sm.in template file, edit as needed, and save new file
    """
    new_case = sys.argv[1]
    working_path = sys.argv[2]
    csv_file = "{}_param_ranges.csv".format(new_case)

    row_strings, n_params_dakota = format_descriptor_table(csv_file)
    new_lines = get_lines_for_new_in_file(row_strings, new_case, working_path, n_params_dakota)
    
    # write to a new .in file and put it in the PPE subdirectory
    with open("{}_e3sm.in".format(new_case), 'w') as nf:
        nf.writelines(new_lines)


if __name__ == "__main__":
    main()
