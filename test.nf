#!/usr/bin/env nextflow

//Code kindly provided by Jacopo Umberta Verga 
Channel.fromFilePairs("./dummy_files/*_R{1,2}.fastq.gz", checkIfExists: true )
       .into{ch_fwd; ch_rev}

forward_reads = ch_fwd.map{ it -> [ it[0], it[1][0]]}
reverse_reads = ch_rev.map{ it -> [ it[0], it[1][1]]}

joined_reads = forward_reads.join(reverse_reads)

process test{
       echo true 

       input:
       tuple val(key), file(r1), file(r2) from joined_reads

       """
       echo $key $r1 $r2
       """
}
