#!/bin/bash

./split_fasta 2 test.fasta

for i in $(seq 0 9);
	do
		./blastp -db swissprot/swissprot -query test.fasta.$i -out test.fasta.$i.out;
	done

./cat_blast output.fasta test.fasta.{1..9}.out

