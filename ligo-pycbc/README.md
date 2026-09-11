# PyCBC GW Analysis Example

This collection of scripts provides the basic steps of a LIGO gravitational wave search using PyCBC.

PyCBC offers workflow generation utilities, however the product is a highly abstract Pegasus workflow which
must be configured for site-specific condor pools data staging locations.

An example workflow implementation is provided using the TaskVine API. 

In order to run the tasks there is a specific environment required, detailed by requirements.txt. It is advisable
to create a virtual environment based on this file, to be activated on the worker nodes running the tasks.

These requriements differ from those of TaskVine. A conda environment specification is detailed in conda\_env\_spec. A simple 
way to run is to activate the conda environment, the virtual environment, then invoke the python interpreter from 
the conda environment to run the script. In this way python subprocesses will be invoked using the PyCBC required versions but
the workflow script will be run with the conda environment.

# Workflow Stages

get\_data.py downloads a set of raw detector data from the two main detector sites over a fixed time frame. It creates both
.hdf5 and .gwf files which are necessary for later stages. 

match\_strain.py reads in the hdf5 data for one detector time segment. It computes an array of template waveforms and calculates
SNR for each template compared to the time segment. It reports the peak time and template number for each event above a certain SNR threshold. At the smallest scale
it will produce one file for each instrument data file. It may be scaled to have many invocations with large template sets operating on different mass ranges within the same
time segment (input file). 

coincidence.py reads in two outputs from match\_strain.py, which are the events from each detector over the same time frame. e.g. H1\_strain\_0 and L1\_strain\_0. 
It produces an output which lists events in which both detectors observed a peak SNR at a similar time. The number of coincidence tasks will be half the number of match\_strain.py

make\_inference.py takes the coincidence output and generates a shell script and config files to run the PyCBC inference utility on each coincident event. The number of inference
tasks is based on the number of coincident events, which is highly variable depending on the initial scale, template ranges, and cutoff threshold. The inference jobs depend on the .gwf
file, and must read in the whole file to consider the surrounding data. Each inference job results in a .hdf output which can be used with PyCBC visualization tools. 


