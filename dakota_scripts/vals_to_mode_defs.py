"""
vals_to_mode_defs.py

Replace sampled hygroscopicity values in the parameter
value files (.txt plain, .csv annotated) with the full 
mode_defs value for the namelist. 

-----------------------
usage: vals_to_mode_defs.py [-h] -i IN_FILE [-p POM_REL_PATH] [-r RESAMPLED_PATH] [-o OUT_PATH]

options:
  -h, --help            show this help message and exit
  -i IN_FILE, --in_file IN_FILE
                        Input CSV file name of the POM hygroscopicity values
  -p POM_REL_PATH, --POM_rel_path POM_REL_PATH
                        Relative path to the new POM files
  -r RESAMPLED_PATH, --resampled_path RESAMPLED_PATH
                        Relative path to the new POM files from just resampling
  -o OUT_PATH, --out_path OUT_PATH
                        Path to save the new output parameter value files to
-----------------------

The string 'DEFAULT_MODE_DEF' is hardcoded to the default value for E3SM; 
you can regenerate this by building a new case for E3SMv3, then copying 
all text following the line "mode_defs = " in the file atm_in. To python-ify 
it, you should end each individual line with a backlash escape character.
"""
import argparse
import glob
import os
import pandas as pd


DEFAULT_POM_FILE = "/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/ocpho_rrtmg_c130709_kPOM0.04.nc"

DEFAULT_MODE_DEF = "'mam5_mode1:accum:=', 'A:num_a1:N:num_c1:num_mr:+',\
         'A:so4_a1:N:so4_c1:sulfate:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/sulfate_rrtmg_c080918.nc:+', 'A:pom_a1:N:pom_c1:p-organic:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/ocpho_rrtmg_c130709_kPOM0.04.nc:+',\
         'A:soa_a1:N:soa_c1:s-organic:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/ocphi_rrtmg_c100508.nc:+', 'A:bc_a1:N:bc_c1:black-c:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/bcpho_rrtmg_c100508.nc:+',\
         'A:dst_a1:N:dst_c1:dust:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/dust_aeronet_rrtmg_c141106.nc:+', 'A:ncl_a1:N:ncl_c1:seasalt:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/ssam_rrtmg_c100508.nc:+',\
         'A:mom_a1:N:mom_c1:m-organic:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/poly_rrtmg_c130816.nc', 'mam5_mode2:aitken:=',\
         'A:num_a2:N:num_c2:num_mr:+', 'A:so4_a2:N:so4_c2:sulfate:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/sulfate_rrtmg_c080918.nc:+',\
         'A:soa_a2:N:soa_c2:s-organic:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/ocphi_rrtmg_c100508.nc:+', 'A:ncl_a2:N:ncl_c2:seasalt:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/ssam_rrtmg_c100508.nc:+',\
         'A:mom_a2:N:mom_c2:m-organic:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/poly_rrtmg_c130816.nc', 'mam5_mode3:coarse:=',\
         'A:num_a3:N:num_c3:num_mr:+', 'A:dst_a3:N:dst_c3:dust:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/dust_aeronet_rrtmg_c141106.nc:+',\
         'A:ncl_a3:N:ncl_c3:seasalt:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/ssam_rrtmg_c100508.nc:+', 'A:so4_a3:N:so4_c3:sulfate:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/sulfate_rrtmg_c080918.nc:+',\
         'A:bc_a3:N:bc_c3:black-c:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/bcpho_rrtmg_c100508.nc:+', 'A:pom_a3:N:pom_c3:p-organic:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/ocpho_rrtmg_c130709_kPOM0.04.nc:+',\
         'A:soa_a3:N:soa_c3:s-organic:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/ocphi_rrtmg_c100508.nc:+', 'A:mom_a3:N:mom_c3:m-organic:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/poly_rrtmg_c130816.nc',\
         'mam5_mode4:primary_carbon:=', 'A:num_a4:N:num_c4:num_mr:+',\
         'A:pom_a4:N:pom_c4:p-organic:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/ocpho_rrtmg_c130709_kPOM0.04.nc:+', 'A:bc_a4:N:bc_c4:black-c:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/bcpho_rrtmg_c100508.nc:+',\
         'A:mom_a4:N:mom_c4:m-organic:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/poly_rrtmg_c130816.nc', 'mam5_mode5:strat_coarse:=',\
         'A:num_a5:N:num_c5:num_mr:+', 'A:so4_a5:N:so4_c5:sulfate:/glade/campaign/uwyo/wyom0191/cime/inputdata/atm/cam/physprops/sulfate_rrtmg_c080918.nc'"


def parse_args():
    """ Parase command-line arguments
    """
    parser = argparse.ArgumentParser()
    
    parser.add_argument("-i", "--in_file", help="Input CSV file name of the POM hygroscopicity values", required=True)
    parser.add_argument("-p", "--POM_rel_path", help="Relative path to the new POM files", required=False, default="POM_ppe/")
    parser.add_argument("-r", "--resampled_path", help="Relative path to the new POM files from just resampling", required=False, default=None)
    parser.add_argument("-o", "--out_path", help="Path to save the new output parameter value files to", required=False)

    return parser.parse_args()


def zero_pad(num):
    """ Zero-pad a number (0-999) into a 3-digit string
    """
    if num < 10:
        num_pad = "00" + str(num)
    elif num >= 10 and num < 100:
        num_pad = "0" + str(num)
    elif num >= 100:
        num_pad = str(num)
    return num_pad


def main(default_file=DEFAULT_POM_FILE, default_mode_def=DEFAULT_MODE_DEF):
    """ DESCRIPTION HERE
    """
    args = parse_args()
    param_sampled_csv = args.in_file
    pom_path = args.POM_rel_path
    resampled_path = args.resampled_path

    # drop file path and extension
    pom_file_name = default_file.split("/")[-1][:-3]
    pom_full_path = os.path.dirname(default_file) + "/" + pom_path
    
    # get the sampled values
    df = pd.read_csv(param_sampled_csv)
    n_samples = len(df)

    # get a list of all files in the new directory & make sure you have them all
    new_files_pattern = pom_full_path + "*.nc"
    new_file_list = list(sorted(glob.glob(new_files_pattern)))
    
    # if you have resampled files, add those too
    if resampled_path is not None:
        resampled = True
        pom_full_path_rs = resampled_path
        rs_files_pattern = pom_full_path_rs + "*.nc"
        rs_file_list = list(sorted(glob.glob(rs_files_pattern)))
        new_file_list += rs_file_list
    else:
        resampled = False

    # check that you have the same number of files as samples
    if len(new_file_list) != n_samples:
        raise Exception("Mismatch between number of files in {p} ({n1}) and number of samples ({n2})!".format(p=pom_path, n1=len(new_file_list), n2=n_samples))

    # get a list of new mode_defs with the POM files swapped out for the new ones
    mode_def_list = [[]]*n_samples
    for i, new_file in enumerate(new_file_list):
        new_mode_def = default_mode_def.replace(default_file, new_file)
        mode_def_list[i] = new_mode_def

    # replace the hygroscopicity values with the altered mode_defs values
    new_df = pd.DataFrame(data=mode_def_list, index=None, columns=["mode_defs"])

    # save the new parameter value files as plain txt and annotated csv files
    if args.out_path is None:
        out_path = os.path.dirname(param_sampled_csv) + "/"

    if resampled:
        out_file_plain = out_path + param_sampled_csv.split("/")[-1].replace("_annotated_RESAMPLE.csv", "_MODE_DEFS_freeform_RESAMPLE.txt")
        out_file_annot = out_path + param_sampled_csv.split("/")[-1].replace("_annotated_RESAMPLE", "_MODE_DEFS_annotated_RESAMPLE")
    else:
        out_file_plain = out_path + param_sampled_csv.split("/")[-1].replace("_annotated.csv", "_MODE_DEFS_freeform.txt")
        out_file_annot = out_path + param_sampled_csv.split("/")[-1].replace("_annotated", "_MODE_DEFS_annotated")
    new_df.to_csv(out_file_plain, sep="\t", header=False, index=False)
    new_df.to_csv(out_file_annot, index=False)
    print("Parameter values files for mode_defs saved to {o} and {a}.".format(o=out_file_plain, a=out_file_annot))
    

if __name__ == "__main__":
    main()
