#!/bin/bash

start="start"
now="debug"
project_dir=`pwd`
output_dir="runs/run_${now}"

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
python3 "training/fno/train_fno.py" $CMD_ARGS --epochs 3 --batch 4 --lr 2e-3 --patience 3



# PINN Training
cd "$project_dir"
python3 "training/pinn/train_pinn.py" "${output_dir}/simulations" "pinn_model" --output_dir "${output_dir}/models/pinn" --subsample 20 --epochs 3 --cpoints 500 --learning_rate 1e-4 --patience 3 --test_size 0.15 --val_size 0.1



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
