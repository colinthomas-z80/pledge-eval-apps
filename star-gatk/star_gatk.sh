#!/bin/bash
set -e 
set -o pipefail

FastqFiles=("SRR10307460" "ERR4179434" "SRR40644330" "SRR40639328" "SRR40639326" "SRR40315802" "SRR40315804" "SRR40315804" "SRR40315805" "SRR40315806")
FastqBase="${FastqFiles[0]}"
BaseFastaGz="GRCh38.primary_assembly.genome.fa.gz"
BaseFasta="GRCh38.primary_assembly.genome.fa"
FastaPrefix="GRCh38.gencode.pa.genome"
MAXFA=6
GenomeDir="gdir"
STAR_filein="${FastqBase}.fastq"
STARPATH=$(realpath ~/contour-scripts/bin/STAR)
#head -n 26091 SRR40671052.fastq > srr_trimmed.fastq
ThreadNum=1

if [ "$1" = "fetch" ]; then

    if [[ ! -f "${FastqBase}.fastq" ]]; then
       fasterq-dump --split-files "${FastqBase}"
       for f in ${FastqBase}*.fastq; do
           head -n 40000 ${f} > shortened_${f}
       done 

    else
        echo "${FastqBase} found..."
    fi

    if [[ ! -f "${BaseFasta}" ]]; then
        wget "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_50/GRCh38.primary_assembly.genome.fa.gz"
        gunzip "${BaseFastaGz}"

    else
        echo "${BaseFastaGz} found..."
    fi

    # This shouldnt be here for too long
    for i in $(seq 1 $MAXFA); do 
        echo "${FastaPrefix}.${i}"
        if [[ -f ${FastaPrefix}.${i}.fa ]]; then 
            continue 
        fi
        j=$((i + 1))
        echo "Extracting chr${i} from Fasta file (${BaseFastaGz})" 
        sed -n "/>chr${i} ${i}/,+10000p" ${BaseFasta} > ${FastaPrefix}.${i}.fa
    done

elif [[ $1 = "clean" ]]; then
    rm SRR10307460.g.vcf.6.gz.tbi
    rm SRR10307460.g.vcf.6.gz
    rm GRCh38.gencode.pa.genome.6.dict
    rm SRR10307460Aligned.sortedByCoord.out.bam.bai
    rm SRR10307460.g.vcf.5.gz.tbi
    rm SRR10307460.g.vcf.5.gz
    rm GRCh38.gencode.pa.genome.6.fa.fai
    rm GRCh38.gencode.pa.genome.5.dict
    rm SRR10307460.g.vcf.4.gz.tbi
    rm SRR10307460.g.vcf.4.gz
    rm GRCh38.gencode.pa.genome.5.fa.fai
    rm GRCh38.gencode.pa.genome.4.dict
    rm SRR10307460.g.vcf.3.gz.tbi
    rm SRR10307460.g.vcf.3.gz
    rm GRCh38.gencode.pa.genome.4.fa.fai
    rm GRCh38.gencode.pa.genome.3.dict
    rm SRR10307460.g.vcf.2.gz.tbi
    rm SRR10307460.g.vcf.2.gz
    rm GRCh38.gencode.pa.genome.3.fa.fai
    rm GRCh38.gencode.pa.genome.2.dict
    rm SRR10307460.g.vcf.1.gz.tbi
    rm SRR10307460.g.vcf.1.gz
    rm GRCh38.gencode.pa.genome.2.fa.fai
    rm SRR10307460SJ.out.tab
    rm SRR10307460Log.progress.out
    rm SRR10307460Log.out
    rm SRR10307460Log.final.out
    rm SRR10307460Aligned.sortedByCoord.out.bam
    rm GRCh38.gencode.pa.genome.1.fa.fai
    rm GRCh38.gencode.pa.genome.1.dict
    rm SRR10307460Aligned.out.bam
    rm -r gdir

else

	printf -v row "%$(tput cols)s"; echo "${row// /=}"
	echo "Generate GenomeRequirements.txt"
	printf -v row "%$(tput cols)s"; echo "${row// /=}"
	${STARPATH} --runThreadN ${ThreadNum} --runMode genomeGenerate --genomeDir ${GenomeDir} --genomeFastaFiles "${FastaPrefix}"*.fa

	printf -v row "%$(tput cols)s"; echo "${row// /=}"
	echo "Mapping Fastq files"
	printf -v row "%$(tput cols)s"; echo "${row// /=}"

	${STARPATH} --runThreadN ${ThreadNum} --genomeDir ${GenomeDir} --readFilesIn shortened_${FastqBase}*.fastq --outFileNamePrefix ${FastqBase} --outSAMtype BAM SortedByCoordinate Unsorted --outSAMattrRGline ID:srr SM:Sample1 PL : ILLUMINA LB:Lib1

    samtools index "${FastqBase}Aligned.sortedByCoord.out.bam"

	for i in $(seq 1 $MAXFA); do


		samtools faidx "${FastaPrefix}.${i}.fa"

		if [[ -f "${FastaPrefix}.${i}.dict" ]]; then
			printf -v row "%$(tput cols)s"; echo "${row// /*}"
			echo "Deleting previous dictionary"
			printf -v row "%$(tput cols)s"; echo "${row// /*}"
			rm "${FastaPrefix}.${i}.dict"
		fi
		~/contour-scripts/bin/gatk/gatk CreateSequenceDictionary -R ${FastaPrefix}.${i}.fa

		printf -v row "%$(tput cols)s"; echo "${row// /=}"
		echo "Running the HaplotypeCaller"
		printf -v row "%$(tput cols)s"; echo "${row// /=}"
		~/contour-scripts/bin/gatk/gatk --java-options "-Xmx16g" HaplotypeCaller -R ${FastaPrefix}.${i}.fa -I "${FastqBase}Aligned.sortedByCoord.out.bam" -O "${FastqBase}.g.vcf.${i}.gz"
	done

fi
