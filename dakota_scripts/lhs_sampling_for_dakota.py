"""
lhs_sampling_for_dakota.py

Script to use Latin Hypercube Sampling to sample
a given list of parameters within their specified ranges.
Specify seed for reproducibility (if any), file name, and 
number of samples to take for each parameter at runtime.
If number of samples is not specified, takes 10*(num parameters). 

Works for any parameters that have an integer value as well if their names
are added to INTEGER_PARAMS before running. 

Updated Sept 2024 to allow resampling/generation of new samples. This will produce
new files (with "_RESAMPLE" added to the end of the name) containing ALL values (including the original ones).
NOTE - for resampling, the replicated "old" values may be off by a tiny amount (10^-14)
due to rounding error. 

-----------------------
usage: lhs_sampling_for_dakota.py [-h] -i IN_FILE [-o OUT_FILE] [-s SEED] [-n N_SAMPLES] [-a] [-r]

options:
  -h, --help            show this help message and exit
  -i IN_FILE, --in_file IN_FILE
                        Input CSV file name
  -o OUT_FILE, --out_file OUT_FILE
                        Freeform output file name (.txt)
  -s SEED, --seed SEED  Seed for the LHS sampler (for reproducibility)
  -n N_SAMPLES, --n_samples N_SAMPLES
                        Number of samples to take of each parameter
  -a, --save_annotated  Also save a human-readable, annotated copy of the sampled parameter values
  -r, --resample        Generate new additional samples from the same sampler and save an updated csv
                        containing ALL samples (old + new)
-----------------------

Input CSV files must use commas as a delimiter and contain a header line
"parameter, min, max" followed by the parameter names and their ranges.
"""
import argparse
import math
import numpy as np
import pandas as pd

from scipy.stats import qmc


# List of parameters that have integer values
INTEGER_PARAMS = ["n_so4_monolayers_pcage"]


def parse_args():
    """ Parase command-line arguments
    """
    parser = argparse.ArgumentParser()

    # required
    parser.add_argument("-i", "--in_file", help="Input CSV file name", required=True)

    # optional
    parser.add_argument("-o", "--out_file",
                        help="Freeform output file name (.txt)",
                        default="./dakota_import_points_file_freeform.txt")
    parser.add_argument("-s", "--seed", type=int,
                        help="Seed for the LHS sampler (for reproducibility)",
                        default=None)
    parser.add_argument("-n", "--n_samples", type=int,
                        help="Number of samples to take of each parameter")
    parser.add_argument("-a", "--save_annotated", help="Also save a human-readable, annotated copy of the sampled parameter values", action="store_true")
    parser.add_argument("-r", "--resample", help="Generate new additional samples from the same sampler and save an updated csv containing ALL samples (old + new)", 
                        action="store_true")

    return parser.parse_args()


def map_to_integer(p, a, b):
    """ 
    Map a float p in (0, 1) to an integer in [a, b]. Adapted from
    https://stats.stackexchange.com/questions/550575/latin-hypercube-sampling-for-both-float-and-integers
    """
    map_int = math.floor(p*(b - a + 1)) + a

    return map_int


def main():
    """ 
    Sample parameter values and output samples to a freeform tabular file for Dakota
    as well as an annotated CSV for the user's reference if save_annotated=True (default). 
    This script saves a version with and without the POM hygroscopicity parameters 
    (need to sample it with LHS, but the actual parameter swap for this must happen outside of Dakota!).
    """
    args = parse_args()

    seed = args.seed
    n_samples = args.n_samples
    param_ranges_csv = args.in_file
    out_file = args.out_file
    save_annotated = args.save_annotated
    resample = args.resample

    # read in info from CSV file
    df_params = pd.read_csv(param_ranges_csv, header=0)
    parameters = df_params["parameter"].values
    n_params = len(parameters)
    l_bounds = df_params["min"].values
    u_bounds = df_params["max"].values

    # create a sample in the unit hypercube & scale it
    if n_samples is None:
        n_samples = 10*n_params
    sampler = qmc.LatinHypercube(d=n_params, seed=seed)
    sample = sampler.random(n=n_samples)
    sample_scaled = qmc.scale(sample, l_bounds, u_bounds)

    # if you're resampling for additional parameters - make an additional sample
    if resample:
        new_sample = sampler.random(n=n_samples)
        new_sample_scaled = qmc.scale(new_sample, l_bounds, u_bounds)

    # make an annotated data frame
    # (if resample=True, it will contain old samples followed by new)
    if resample:
        combined_samples = np.vstack((sample_scaled, new_sample_scaled))
        df_resampled = pd.DataFrame(combined_samples,
                                    index=np.arange(1, (n_samples*2)+1),
                                    columns=parameters)
    else:
        df_sampled = pd.DataFrame(sample_scaled,
                                  index=np.arange(1, n_samples+1),
                                  columns=parameters)

    # for categorical/integer parameters, map the sampled floats to corresponding integers in the range
    for param in INTEGER_PARAMS:
        if param in parameters:
            pind = np.where(parameters == param)[0][0]
            lower = int(l_bounds[pind])
            upper = int(u_bounds[pind])
            if resample:
                sample_param = sample[:, pind]
                new_sample_param = new_sample[:, pind]
                resample_param = np.concatenate((sample_param, new_sample_param))
                resample_map_int = [map_to_integer(x, lower, upper) for x in resample_param]
                df_resampled[param] = resample_map_int
            else:
                sample_param = sample[:, pind]
                sample_map_int = [map_to_integer(x, lower, upper) for x in sample_param]
                df_sampled[param] = sample_map_int
            print("...Sampled parameter range for \'{}\' mapped from floats to ints.".format(param))
        else:
            print("...Ignoring parameter \'{}\' for float-->int mapping; not found in parameter ranges csv file.".format(param))

    # drop POM, if it's in the parameter list (won't get sampled by Dakota)
    if "POM_hygroscopicity_param" in parameters:
        drop_POM = True
        if resample:
            df_resampled_no_pom = df_resampled.drop(columns="POM_hygroscopicity_param")
        else:
            df_sampled_no_pom = df_sampled.drop(columns="POM_hygroscopicity_param")
        params_no_pom = parameters[parameters != "POM_hygroscopicity_param"]
    else:
        drop_POM = False
    
    # save freeform formatted files for Dakota
    if resample:
        out_file_rs = out_file[:-4] + "_RESAMPLE.txt"
        df_resampled.to_csv(out_file_rs, sep="\t", header=False, index=False)
        if drop_POM:
            out_file_rs_no_pom = out_file_rs[:-4] + "_no_POM.txt"
            df_resampled_no_pom.to_csv(out_file_rs_no_pom, sep="\t", header=False, index=False)
            extra = " and {p}".format(p=out_file_rs_no_pom)
        else:
            extra = ""
        print("Parameter values files saved to {o}{e}.".format(o=out_file_rs, e=extra))
    else:
        df_sampled.to_csv(out_file, sep="\t", header=False, index=False)
        if drop_POM:
            out_file_no_pom = out_file[:-4] + "_no_POM.txt"
            df_sampled_no_pom.to_csv(out_file_no_pom, sep="\t", header=False, index=False)
            extra = " and {p}.".format(p=out_file_no_pom)
        else:
            extra = ""
        print("Parameter values files saved to {o}{e}.".format(o=out_file, e=extra))

    # also save in a human-readable annotated format for user reference
    # (Dakota won't use this)
    if save_annotated:
        if resample:
            out_file_rs_annot = out_file_rs.replace("txt", "csv").replace("freeform", "annotated")
            df_rs_annotated = pd.read_csv(out_file_rs, header=None, names=parameters, delimiter="\t")
            df_rs_annotated.to_csv(out_file_rs_annot, index=False)
            if drop_POM:
                out_file_rs_annot_no_pom = out_file_rs_annot[:-4] + "_no_POM.csv"
                df_rs_annotated_no_pom = pd.read_csv(out_file_rs_no_pom, header=None, names=params_no_pom, delimiter="\t")
                df_rs_annotated_no_pom.to_csv(out_file_rs_annot_no_pom, index=False)
                extra = " and {p}".format(p=out_file_rs_annot_no_pom)
            else:
                extra = ""
            print("Annotated parameter values files saved to {o}{e}.".format(o=out_file_rs_annot, e=extra))
        else:
            out_file_annot = out_file.replace("txt", "csv").replace("freeform", "annotated")
            df_annotated = pd.read_csv(out_file, header=None, names=parameters, delimiter="\t")
            df_annotated.to_csv(out_file_annot, index=False)
            if drop_POM:
                out_file_annot_no_pom = out_file_annot[:-4] + "_no_POM.csv"
                df_annotated_no_pom = pd.read_csv(out_file_no_pom, header=None, names=params_no_pom, delimiter="\t")
                df_annotated_no_pom.to_csv(out_file_annot_no_pom, index=False)
                extra = " and {p}".format(p=out_file_annot_no_pom)
            else:
                extra = ""
            print("Annotated parameter values files saved to {o}{e}.".format(o=out_file_annot, e=extra))


if __name__ == "__main__":
    main()
