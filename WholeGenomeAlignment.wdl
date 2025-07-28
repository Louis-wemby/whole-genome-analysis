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
        call FaSize as QryFaSize {
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
                qry_sizes = QryFaSize.sizes
        }
        call NetToAxt{
            input:
                net = ChainNet.net,
                axt = LastzAlign.axt,
                ref = reference_genome,
                qry = query
        }
        call AxtToMaf{
            input:
                axt = NetToAxt.filtered_axt,
                ref_sizes = FaSize.sizes,
                qry_sizes = QryFaSize.sizes
        }
        call MafSwap {
            input:
                maf_input = AxtToMaf.filtered_maf
        }
    }

    call Multiz {
        input:
            ref = reference_genome,
            mafs = MafSwap.output_mafs
    }

    output {
        File multiple_alignment = Multiz.multiz_alignment
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
        lastz ${ref}[multiple] ${qry} \
            K=4500 L=3000 Y=15000 E=150 H=2000 O=600 T=2 \
            --format=axt > alignment.axt
        axtChain -minScore=5000 -linearGap=medium \
                 alignment.axt ${ref} ${qry} output.chain
    }
    output {
        File axt="alignment.axt"
        File chain="output.chain"
    }
    runtime {
        docker_url: "${dockerURL}"
        req_cpu: 4
        req_memory: "8Gi"
    }
}

task ChainNet {
    input {
        File chain_input
        File ref_sizes
        File qry_sizes
    }
    command {
        chainPreNet ${chain_input} ${ref} ${qry} stdout | \
        chainNet stdin ${ref_sizes} ${qry_sizes} netOutput /dev/null
    }
    output {
        File net="netOutput"
    }
    runtime {
        docker_url: "${dockerURL}"
        req_memory: "4Gi"
    }
}

task NetToAxt {
    input {
        File net
        File chain
        File ref
        File qry
    }
    command {
        
    }
}


