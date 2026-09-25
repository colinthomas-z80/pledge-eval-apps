#!/bin/sh

# activate environment, virtualenv etc...
rm wf/*
mkdir -p wf

# Use match_strain to find triggers across templates
python match_strain.py --input-file data/H1_strain_4.hdf5 --channel H1 --output-file H1_5-10_1.csv --template-range 8-12 --template-step 1.0
python match_strain.py --input-file data/L1_strain_4.hdf5 --channel L1 --output-file L1_5-10_1.csv --template-range 8-12 --template-step 1.0

# find coincident events between H1 and L1 triggers
python coincidence.py --h1-trig H1_5-10_1.csv --l1-trig L1_5-10_1.csv --output-file 5-10_1_coincident_events.csv

# make inference run scripts for each coincident event
python make_inference.py --coincident-events 5-10_1_coincident_events.csv --output-dir wf --name-pattern 5-10_1 --template-range 8-10 --template-step 1.0

cd wf
ln ../inference/*.ini .
ln ../data/*.gwf .
ls *.sh | while read p; do chmod +x $p; ./$p; done





