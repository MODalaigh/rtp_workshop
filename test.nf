#!/usr/bin/env nextfloww

Channel.fromFilePairs("*.dummy_files/*_R(1,2).fastq.gz", checkIfExists: true).view()
	.into{ch_fwd; ch_rev}
	

