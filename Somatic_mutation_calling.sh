# align reads to particular genome assembly
bwa mem -t 4 -M hg19.genome fq1 fq2 > output.sam

# use samtools to process sam/bam files
# filter out unmapped reads and convert sam format to bam format
samtoosl view -b -F 4 input.sam > output.bam

# use sambamba to filter out redundant reads
# these redundant reads could be introduced from PCR duplicates or seuqencing(optical duplicates)
sambamba markdup --remove-duplicates --nthreads=4 --tmpdir=tmp_dir input.bam output.bam

# use samtools to sort bam files and generate index files for downstream analysis
samtools sort -o output.bam input.bam
samtools index input.bam

# use picard and gtak suite to process bam files
# add reads group information
java -Xmx200g -jar picard AddOrReplaceReadGroups INPUT=input.bam OUTPUT=output.bam SO=coordinate RGID=4 RGLB=library RGPL=illumina RGPU=machine RGSM=sample
# reorder reads in bam files
java -Xmx200g -jar picard ReorderSam INPUT=input.bam OUTPUT=output.bam REFERENCE=hg19.genome CREATE_INDEX=TRUE
# create interval files for realignment
java -Xmx200g -jar gatk -T RealignerTargetCreator -R hg19.genome --num_threads 4 --bam_compression 0 -o sample_intervals.list -I input.bam
# realign reads within certain intervals
java -Xmx200g -jar gatk -T IndelRealigner --bam_compression 0 --filter_bases_not_stored --disable_auto_index_creation_and_locking_when_reading_rods -R hg19.genome -targetIntervals sample_intervals.list -o ouput.bam -I input.bam

# remove reads with more than two mismatches
python Mismatch_removal.py input.bam output.bam

# create mpileup files using samtools
samtools mpileup -f hg19.genome -B pancreas.bam spleen.bam > output.pileup

# run mutect to call somatic mutations
java -Xmx200g -jar mutect --analysis_type MuTect --reference_sequence hg19.genome --input_file:tumor pancreas.bam --input_file:normal spleen.bam --vcf output.vcf -l ERROR

# run strelka
strelka --normalBam spleen.bam --tumorBam pancreas.bam --referenceFasta hg19.genome --runDir output_dir
output_dir/runWorkflow.py -m local
gzip -d output_dir/results/variants/*
mv output_dir/results/variants/somatic.indels.vcf output_dir/passed.somatic.indels.vcf
mv output_dir/results/variants/somatic.snvs.vcf output_dir/passed.somatic.snvs.vcf

# run speedseq
speedseq somatic -q 1 -t 10 -T speed_tmp_dir -o output_dir hg19.genome spleen.bam pancreas.bam
gzip -d output_dir/sample.vcf.gz

# run varscan
java -jar varscan somatic sample.pileup output_dir --mpileup 1 --min-coverage 8 --min-coverage-normal 8 --min-coverage-tumor 6 --min-var-freq 0.10 --min-freq-for-hom 0.75 --normal-purity 1.0 --tumor-purity 1.0 --p-value 0.05 --somatic-p-value 0.05 --strand-filter 0 --output-vcf
java -jar varscan processSomatic sample.indel.vcf
java -jar varscan processSomatic sample.snps.vcf

# run muse
muse call -O output_dir -f hg19.genome pancreas.bam spleen.bam
muse sump -I sample.MuSE.txt -E -O output.vcf -D dbsnp.gzip



