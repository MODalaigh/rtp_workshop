#!/usr/bin/env nextflow

Channel.fromFilePairs(params.input, checkIfExists: true)
       .set{ ch_reads }

process FASTQC{
    publishDir "./fastqc", mode: 'copy'

    input:
    tuple val(base), file(reads) from ch_reads

    output:
    file("*.{html,zip}") into ch_multiqc

    script:
    """
    fastqc -q $reads
    """
}

process MULTIQC{
    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    file(htmls) from ch_multiqc.collect()

    output:
    file("*.html") into ch_out

    script:
    """
    multiqc -q .
    """
}
