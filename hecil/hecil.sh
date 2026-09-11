#!/bin/bash
enable -n cat

./fastq_generate.pl 1000 100 | tee ref.fastq

./fastq_generate.pl 1000 100 ref.fastq | tee query.fastq

./convert_fastq.py ref.fastq | tee ref.fasta

perl fastq_reduce query.fastq 10

./bwa index ref.fasta 2> index.err

for i in $(seq 0 99); do
    ./bwa mem ref.fasta query.fastq.$i > Out.$i.sam 2> mem.$i.err
done

./sam_cat.sh Out.*.sam > Out.sam

cat mem.*.err > mem.err


./samtools view -o View.bam -bS Out.sam


./samtools sort -o Out.bam View.bam 2> sort.err


./samtools mpileup -s -f ref.fasta Out.bam > pileup.txt 2> pileup.err

./Split_Pileup.sh pileup.txt 2 2> Split_Pileup.err

python3 Correction.py Pileup_Set1.txt ref.fasta lc.0.out Out.sam 1 > corr.0.out 2> corr.0.err ; echo "" >> lc.0.out ; echo "" >> corr.0.err

python3 Correction.py Pileup_Set2.txt ref.fasta lc.1.out Out.sam 1 > corr.1.out 2> corr.1.err ; echo "" >> lc.1.out ; echo "" >> corr.1.err

cat corr.*.out  > corr.out

cat corr.*.err > corr.err

cat lc.*.out > LowConf.txt

./fasta_reduce ref.fasta 100

for i in $(seq 0 9); do
    python3 Create_Corrected_AllLRReads.py ref.fasta.$i corr.out 2> create.err.$i
done

cat Corrected_ref.fasta.* > Corrected_ref.fasta

