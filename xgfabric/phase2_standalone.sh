#!/bin/bash

start="start"
now="debug"
project_dir=`pwd`
output_dir="runs/run_${now}"

# Create directories
mkdir -p "${output_dir}/simulations"

# Options
num_threads=1
sim_num=$1

param_dir="${output_dir}/params"  

params_file="${param_dir}/sim_params.csv"

####################################
#            PHASE 2               #
####################################
extract_param() {
    local key=$1
    python3 -c "import json; d=json.load(open('$PARAM_FILE')); print(d.get('$key', ''))"
}

CUPS_ARCHIVE="simulation/cups_structure.zip"
PARAM_FILE=${param_dir}/sim_${sim_num}.json

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
#trap "rm -rf '$working_dir'" EXIT

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
CSV_OUTPUT="${project_dir}/${output_dir}/simulations/sim_${sim_num}.csv"

# Convert VTK to CSV
python3 "${project_dir}/simulation/vtk_to_csv.py" "$MAIN_VTK" "$CSV_OUTPUT"
find . -type f -name "*.vtk" -delete

