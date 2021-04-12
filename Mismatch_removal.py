# python 3.7
# pysam 0.12
import os,sys
import pysam

bamIn  = sys.argv[1]
bamOut = sys.argv[2]

bamfile_in = pysam.AlignmentFile(bamIn, "rb")
with pysam.AlignmentFile(bamOut, "wb", header=bamfile_in.header) as bamfile_out:
    index = 0
    for read in bamfile_in:
        if read.mapping_quality > 0:#only look at mapped reads
            #print(read)

            #get tags/fields such as XO, XG, XS, NM...
            tags = read.get_tags()
            tags = read.get_tags()
            NM = "NULL"
            for tag in tags:
                if tag[0] == "NM":
                    NM = tag[1]

            bq = read.query_qualities
           #print(NM, np.array(bq).mean(), np.median(np.array(bq)))
            index += 1
            if int(NM) <= 2:
                bamfile_out.write(read)