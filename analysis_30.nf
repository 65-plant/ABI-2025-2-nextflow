#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Parameters
params.downloadurl = "https://tinyurl.com/cqbatch1"
params.prefix = "sequence"
params.outdir = "results"
params.input = "input.fasta"

// Print parameters
log.info """\
    FASTA SPLITTER PIPELINE
    =======================
    download : ${params.downloadurl}
    input    : ${params.input}
    prefix   : ${params.prefix}
    outdir   : ${params.outdir}
    """

process downloadFasta {
    output:
    path params.input
    
    script:
    """
    wget -q -O ${params.input} ${params.downloadurl}
    """
}

process splitSequences {
    publishDir params.outdir, mode: 'copy'
    
    input:
    path fasta_file
    
    output:
    path "*.fasta"
    
    shell:
    '''
    awk '
    BEGIN { count = 0; filename = "!{params.prefix}_" count ".fasta" }
    /^>/ { 
        if (NR > 1) { 
            close(filename)
            count++
            filename = "!{params.prefix}_" count ".fasta"
        }
        print $0 > filename
    }
    !/^>/ && NF > 0 { 
        print $0 > filename 
    }
    END { close(filename) }
    ' !{fasta_file}
    '''
}

workflow {
    // Download the FASTA file
    fasta_ch = downloadFasta()
    
    // Split the sequences
    split_files = splitSequences(fasta_ch)
    
    // Create a named channel for downstream processes
    split_channel = split_files.flatten()
    
    // Optional: show what files were created
    split_channel.view { "Created: $it" }
}
