#HLA-* can be HLA-A, HLA-B, HLA-C, HLA-DAB1 ...

# run novoalign for athlates
novoalign -d athlates/Athlates_2014_04_26/db/ref/ref.nix -f R1.fq R2.fq -t 10 -o SAM -r all 100 -e 100 -i PE 200 140 | samtools view -bS -h -F 4 - > output.bam

# run athlates
samtools view -b -L athlates/Athlates_2014_04_26/db/bed/HLA-*.bed sample.bam > HLA-*.bam      
samtools view -h -o HLA-*.sam HLA-*.bam                                                                      
grep -P "^@" HLA-*.sam > HLA-*.header                                                                        
grep -v -P "^@" HLA-*.sam > HLA-*.body                                                                       
sort -k 1,1 -k 3,3 HLA-*.body > HLA-*.temp.sam                                                               
cat HLA-*.header HLA-*.temp.sam > HLA-*.sort.sam
samtools view -bS HLA-*.sort.sam > HLA-*.sort.bam

samtools view -b -L athlates/Athlates_2014_04_26/db/bed/non-HLA-*.bed sample.bam > non-HLA-*.bam      
samtools view -h -o non-HLA-*.sam non-HLA-*.bam                                                                      
grep -P "^@" non-HLA-*.sam > non-HLA-*.header                                                                        
grep -v -P "^@" non-HLA-*.sam > non-HLA-*.body                                                                       
sort -k 1,1 -k 3,3 non-HLA-*.body > non-HLA-*.temp.sam                                                               
cat non-HLA-*.header non-HLA-*.temp.sam > non-HLA-*.sort.sam
samtools view -bS non-HLA-*.sort.sam > non-HLA-*.sort.bam

athlates/Athlates_2014_04_26/bin/typing -bam HLA-*.sort.bam -exlbam non-HLA-*.bam -hd 5 -msa HLA-*_nuc.txt -o output/HLA-*


# run PHLAT
python -O PHLAT.py -1 R1.fq -2 R2.fq -index phlat-1.0/index4phlat -b2url bowtie2_dir/bowtie2 -tag sample -e phlat-1.0/ -p 8 -o output_dir

# run optitype
python /OptiTypePipeline.py -i R1.fq R2.fq --dna --outdir output_dir
