#!/bin/bash
enable -n cat
enable -n grep
enable -n tail

./fastq_generate.pl 1000 100 | tee ref.fastq

./fastq_generate.pl 1000 100 ref.fastq | tee query.fastq

./convert_fastq.py ref.fastq | tee ref.fasta

perl fastq_reduce query.fastq 10

./bwa index ref.fasta 

for i in $(seq 0 9); do
./bwa mem ref.fasta query.fastq.$i | tee Out.$i.sam 
done

./sam_cat.sh Out.*.sam | tee Out.sam

./samtools view -o View.bam -bS Out.sam

./samtools sort -o Out.bam View.bam 

./samtools mpileup -s -f ref.fasta Out.bam | tee pileup.txt 

./Split_Pileup.sh pileup.txt 2

python3 Correction.py Pileup_Set1.txt ref.fasta lc.0.out Out.sam 10 | tee corr.0.out #; echo "" | tee -a lc.0.out ;

python3 Correction.py Pileup_Set2.txt ref.fasta lc.1.out Out.sam 10 | tee corr.1.out #; echo "" | tee -a lc.1.out ;

cat corr.0.out corr.1.out | tee corr.out

#cat lc.0.out lc.1.out | tee LowConf.txt

python3 ./fasta_reduce ref.fasta 100

for i in $(seq 0 9); do
python3 Create_Corrected_AllLRReads.py ref.fasta.$i corr.out 
done

cat Corrected_ref.fasta.0 Corrected_ref.fasta.1 Corrected_ref.fasta.2 Corrected_ref.fasta.3 Corrected_ref.fasta.4 Corrected_ref.fasta.5 Corrected_ref.fasta.6 Corrected_ref.fasta.7 Corrected_ref.fasta.8 Corrected_ref.fasta.9 | tee Corrected_ref.fasta

rm *.sam
rm query.fastq.*
rm ref.fasta.*
rm Out.bam
rm View.bam
rm *.out
rm ref.fasta query.fastq ref.fastq
rm Corrected_ref.fasta.*
rm Corrected_ref.fasta
