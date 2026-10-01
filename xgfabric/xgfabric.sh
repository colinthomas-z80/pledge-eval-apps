#!/bin/bash
start=$(date '+%s')
now=$(date '+%y_%m_%d_%H_%M_%S')
project_dir=`pwd`
output_dir="runs/run_${now}"

# Create directories
mkdir -p "${output_dir}/simulations"
mkdir -p "${output_dir}/params"
mkdir -p "${output_dir}/data"

# Options
num_sims=1
num_threads=1

# Environment
module --force purge
module add openfoam/10.0/gcc/11.5.0 > /dev/null 2>&1
module add paraview/5.11.2
module load cuda 2>/dev/null || true
module load cudnn 2>/dev/null || true
source ~/miniconda3/etc/profile.d/conda.sh
conda activate cfdaai
export PATH="bin/:$PATH"

# check if the cups simulation data is present
if ! [ -f simulation/cups_structure.zip ]; then
    FILEID=1ntOFnB_TNA_9QfKHAMX7T3hM99VgbzTF
    FILENAME=cups_structure.zip

    wget --no-check-certificate \
    "https://drive.usercontent.google.com/download?id=${FILEID}&confirm=t" -O "simulation/${FILENAME}"
fi


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


####################################
#            PHASE 2               #
####################################
extract_param() {
    local key="$1"
    python3 -c "import json; d=json.load(open('$PARAM_FILE')); print(d.get('$key', ''))"
}

for ((i = 0; i < num_sims; i++)); do
    CUPS_ARCHIVE="simulation/cups_structure.zip"
    PARAM_FILE=${params_dir}/sim_${i}.json

    # Parse simulation parameters from JSON
    SIM_ID=$(extract_param "sim_id")
    WIND_SPEED=$(extract_param "wind_speed")
    WIND_DIRECTION=$(extract_param "wind_direction")

    # Convert wind speed + direction to x/y components
    # x = north, y = east; wd = compass bearing wind blows towards (0=N, 90=E)
    read UX UY < <(python3 -c "import math; ws=$WIND_SPEED; wd=math.radians($WIND_DIRECTION); print(f'{ws*math.cos(wd):.6f} {ws*math.sin(wd):.6f}')")

    destination="ws${UX}_${UY}_0.0"
    working_dir="${output_dir}/simulations/.scratch_${destination}"
    mkdir -p "$working_dir"
    trap "rm -rf '$working_dir'" EXIT

    unzip -q "$CUPS_ARCHIVE" -d "$working_dir"

    mv "$working_dir/cups_structure"/* "$working_dir"/
    rm -rf "$working_dir/cups_structure"

    # Set windspeed using the helper script
    python3 simulation/set_windspeed.py "$working_dir" "$UX" "$UY" "0.0"

    # Update thread count in decomposition dictionary
    python3 simulation/replace.py "$working_dir/system/decomposeParDict" "$working_dir/system/decomposeParDict" @ "$num_threads"

    cd "$working_dir"

    # Run the solver
    if [ "$num_threads" -eq 1 ]; then
        porousSimpleFoam | tee log
    else
        decomposePar -force
        mpirun -np "$num_threads" porousSimpleFoam -parallel
        reconstructPar -latestTime
        rm -rf processor*
    fi

    # Process results: VTK -> CSV (passing working directory and output directory)
    # Export to VTK format
    foamToVTK -latestTime
    MAIN_VTK=$(find ./VTK -maxdepth 1 -name "*.vtk" -type f | sort -n | tail -1)
    WINDSPEED_SAFE=$(echo "$UX" | tr '.' '_')
    CSV_FILENAME="cups_structure_ws${WINDSPEED_SAFE}.csv"
    CSV_OUTPUT="${project_dir}/${output_dir}/simulations/sim_${i}.csv"

    # Convert VTK to CSV
    python3 "${project_dir}/simulation/vtk_to_csv.py" "$MAIN_VTK" "$CSV_OUTPUT"
    rm -rf ./VTK
    find . -type f -name "*.vtk" -delete
done


####################################
#            PHASE 3               #
####################################
cd "$project_dir"
mkdir -p ${output_dir}/models/fno
mkdir -p ${output_dir}/models/pinn
mkdir -p ${output_dir}/models/pcr
mkdir -p ${output_dir}/models/pcr/partitions

# FNO Training
CMD_ARGS="--data-dir ${output_dir}/simulations --output-dir ${output_dir}/models/fno"
python3 "training/fno/train_fno.py" $CMD_ARGS --epochs 5 --batch 4 --lr 2e-3 --patience 3



# PINN Training
cd "$project_dir"
python3 "training/pinn/train_pinn.py" "${output_dir}/simulations" "pinn_model" --output_dir "${output_dir}/models/pinn" --subsample 20 --epochs 5 --cpoints 500 --learning_rate 1e-4 --patience 3 --test_size 0.15 --val_size 0.1



# PCR Training
cd "$project_dir"
grid_config="training/pcr/grid_config.json"
partitions_dir="${output_dir}/models/pcr/partitions"
partitions_file="${partitions_dir}/pcr_partitions_full.json"
DATA_FILE="${partitions_dir}/machine_0_data.pkl"

export GRID_CONFIG_PATH="$grid_config"
pushd "$partitions_dir" > /dev/null
python3 "${project_dir}/training/pcr/partition_pcr_grid.py" "1"
popd > /dev/null

python3 "training/pcr/prepare_pcr_data.py" "$output_dir/data" "${output_dir}/simulations" "$partitions_file" "$partitions_dir" 2> /dev/null
python3 "training/pcr/train_pcr_chunk.py" "$DATA_FILE" "${output_dir}/models/pcr" 2> /dev/null


end=$(date '+%s')
elapsed=$((end - start))

echo "Entire script took ${elapsed} seconds."
