version 1.0

workflow WholeGenomeAlignment {
    input {
        File reference_genome 
        Array[File] query_genomes
    }

    String dockerURL = "stereonote_hpc_external/xiongyihan_fb76517ee63f444b81314169c1a3c85e"
    
    call FaSize {
        input:
            genome = reference_genome
    }

    scatter (query in query_genomes) {
        call FaSize {
            input:
                genome = query
        }
        call LastzAlign {
            input:
                ref = reference_genome,
                qry = query
        }
        call ChainNet {
            input:
                chain_input = LastzAlign.chain,
                ref_sizes = FaSize.sizes,
                qry_sizes = FaSize.sizes
        }
        call MafSwap {
            input:
                maf_input = ChainNet.net_maf
        }
    }

    call Multiz {
        input:
            ref = reference_genome,
            mafs = MafSwap.output.mafs
    }

    output {
        File multiple_alignment = Multiz.multiz.alignment
    }
}

task Fasize {
    input {
        File genome
    }
    command {
        samtools faidx ${genome}
        cut -f1,2 ${genome}.fai > ${genome}.sizes
    }
    output {
        File sizes = "${genome}.sizes"
    }
    runtime {
        docker_url: "${dockerURL}"
        req_cpu: 1
        req_memory: "2Gi"
    }
}

task LastzAlign {
    input {
        File ref
        File qry
    }
    command {
        
    }
}
