#!/bin/bash

# activate environment, virtualenv etc...
#rm wf/*
#mkdir -p wf

for idx in $(seq 1 5); 
	do
	# Use match_strain to find triggers across templates
	python match_strain.py --input-file data/H1_strain_$idx.hdf5 --channel H1 --output-file H1_5-10_$idx.csv --template-range 8-12 --template-step 1.0
	python match_strain.py --input-file data/L1_strain_$idx.hdf5 --channel L1 --output-file L1_5-10_$idx.csv --template-range 8-12 --template-step 1.0

	# find coincident events between H1 and L1 triggers
	python coincidence.py --h1-trig H1_5-10_$idx.csv --l1-trig L1_5-10_$idx.csv --output-file 5-10_$idx_coincident_events.csv

	# make inference run scripts for each coincident event
	python make_inference.py --coincident-events 5-10_$idx_coincident_events.csv --output-dir wf --name-pattern 5-10_$idx --template-range 8-10 --template-step 1.0

	done




