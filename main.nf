#!/usr/bin/env nextflow

// parse input data

if(has_extension(params.input, ".csv")){

   csv_file = file(params.input, checkIfExists: true)
   ch_input = extract_data(csv_file)

}else{

   exit 1, "error: The sample input file must have the extension '.csv'."

}

// stage input data
( ch_qc_reads, ch_raw_reads) = ch_input.into(2)

ch_raw_reads.view()

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

/*
================================================================================
                            AUXILLARY FUNCTIONS
================================================================================
*/

// Check if a row has the expected number of item
def checkNumberOfItem(row, number) {
    if (row.size() != number) exit 1, "error:  Invalid CSV input - malformed row (e.g. missing column) in ${row}, consult documentation."
    return true
}

// Return file if it exists
def return_file(it) {
    if (!file(it).exists()) exit 1, "error: Cannot find supplied FASTQ input file. Check file: ${it}"
    return file(it)
}

// Check file extension
def has_extension(it, extension) {
    it.toString().toLowerCase().endsWith(extension.toLowerCase())
}

// Parse samples.csv file
def extract_data(csvFile){
    Channel
        .fromPath(csvFile)
        .splitCsv(header: true, sep: ',')
        .map{ row ->

        def expected_keys = ["Sample_ID", "Read1", "Read2"]
        if(!row.keySet().containsAll(expected_keys)) exit 1, "error: Invalid CSV input - malformed column names. Please use the column names 'Sample_ID', 'Read1', 'Read2'."

        checkNumberOfItem(row, 3)

        def samples = row.Sample_ID
        def read1 = row.Read1.matches('NA') ? 'NA' : return_file(row.Read1)
        def read2 = row.Read2.matches('NA') ? 'NA' : return_file(row.Read2)

        if( samples == '' || read1 == '' || read2 == '' ) exit 1, "error: a field does not contain any information. Please check your CSV file"
        if( !has_extension(read1, "fastq.gz") && !has_extension(read1, "fq.gz") && !has_extension(read1, "fastq") && !has_extension(read1, "fq")) exit 1, "error: A R1 file has a non-recognizable FASTQ extension. Check: ${r1}"
        if( !has_extension(read2, "fastq.gz") && !has_extension(read2, "fq.gz") && !has_extension(read2, "fastq") && !has_extension(read2, "fq")) exit 1, "error: A R2 file has a non-recognizable FASTQ extension. Check: ${r2}"

        // output tuple mimicking fromFilePairs
        [ samples, [read1, read2] ]

        }
}
