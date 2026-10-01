#!/bin/bash

start="start"
now="debug"
project_dir=`pwd`
output_dir="runs/run_${now}"

# Create directories
mkdir -p "${output_dir}/simulations"
mkdir -p "${output_dir}/params"
mkdir -p "${output_dir}/data"

# Options
num_sims=1
num_threads=1


export PATH="bin/:$PATH"

####################################
#            PHASE 1               #
####################################
# Get CSPOT Data
cspot_endpoint="woof://128.111.45.61/davisstations/daviscupsout"
cspot_limit="$num_sims"
python3 "utils/load_historical_data.py" "-W ${cspot_endpoint}" "--output-dir=${output_dir}/data" "-n ${cspot_limit}"

# Convert to CSV
python3 "utils/convert_cspot_to_csv.py" "$output_dir/data/sensor_data.txt" "$output_dir/data/sensor_out.csv"


# Convert to OPENFoam CSV
param_dir="${output_dir}/params"  
sensor_csv="${output_dir}/data/sensor_out.csv"
python3 "utils/sensor_to_sim_params.py" "$sensor_csv" "${param_dir}/sim_params.csv" "$num_sims"
params_file="${param_dir}/sim_params.csv"
params_dir="$(dirname "$params_file")"
python3 "utils/generate_params.py" "$params_file" "$params_dir"

