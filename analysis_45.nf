

nextflow.enable.dsl=2

params.sam_url = "https://gitlab.com/dabrowskiw/cq-examples/-/raw/master/data/sequences.sam?inline=false"
params.outdir = "results"

process downloadSAM {
    storeDir "${params.outdir}/data"
    
    output:
    path "sequences.sam"
    
    script:
    """
    wget -O sequences.sam "${params.sam_url}"
    """
}

process samToFasta {
    publishDir "${params.outdir}/fasta", mode: 'copy'
    
    input:
    path samfile
    
    output:
    path "*.fasta", emit: fastas
    
    script:
    """
    awk '!/^@/ && \$10 != "*" {print ">" \$1 "\\n" \$10 > \$1 "_" NR ".fasta"}' ${samfile}
    """
}

process countCodons {
    publishDir "${params.outdir}/counts", mode: 'copy'
    
    input:
    path fasta
    
    output:
    path "${fasta.baseName}_counts.txt"
    
    script:
    """
    seq=\$(grep -v ">" ${fasta} | tr -d '\\n')
    start=\$(echo \$seq | grep -o ATG | wc -l)
    stop_taa=\$(echo \$seq | grep -o TAA | wc -l)
    stop_tag=\$(echo \$seq | grep -o TAG | wc -l)  
    stop_tga=\$(echo \$seq | grep -o TGA | wc -l)
    stop=\$((\$stop_taa + \$stop_tag + \$stop_tga))
    name=\$(basename ${fasta} .fasta)
    echo "\$name,\$start,\$stop" > ${fasta.baseName}_counts.txt
    """
}

process createSummary {
    publishDir params.outdir, mode: 'copy'
    
    input:
    path counts
    
    output:
    path "summary.csv"
    
    script:
    """
    echo "sequence,# start,# stop" > summary.csv
    cat ${counts} >> summary.csv
    """
}

workflow {
    downloadSAM() | samToFasta
    samToFasta.out.fastas.flatten() | countCodons | collect | createSummary
}
