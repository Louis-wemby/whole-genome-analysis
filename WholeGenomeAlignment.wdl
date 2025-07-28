version 1.0

workflow WholeGenomeAlignment {
    input {
        File reference_genome 
        Array[File] query_genomes
    }

    String dockerURL = "stereonote_hpc_external/xiongyihan_fb76517ee63f444b81314169c1a3c85e_private:latest"

    call FaSize {
        input:
            dockerURL = dockerURL,
            genome = reference_genome
    }

    call FaToTwoBit {
        input:
            dockerURL = dockerURL,
            genome = reference_genome
    }

    scatter (query in query_genomes) {
        call FaSize as QryFaSize {
            input:
                dockerURL = dockerURL,
                genome = query
        }
        call FaToTwoBit as QryTwoBit {
            input:
                dockerURL = dockerURL,
                genome = query
        }
        call LastzAlign {
            input:
                dockerURL = dockerURL,
                ref = reference_genome,
                qry = query
        }
        call ChainNet {
            input:
                dockerURL = dockerURL,
                chain_input = LastzAlign.chain,
                ref_sizes = FaSize.sizes,
                qry_sizes = QryFaSize.sizes
        }
        call NetToAxt {
            input:
                dockerURL = dockerURL,
                net = ChainNet.net,
                chain = LastzAlign.chain,
                ref2bit = FaToTwoBit.twoBit,
                qry2bit = QryTwoBit.twoBit
        }
        call AxtToMaf {
            input:
                dockerURL = dockerURL,
                axt = NetToAxt.filtered_axt,
                ref_sizes = FaSize.sizes,
                qry_sizes = QryFaSize.sizes
        }
        call MafSwap {
            input:
                dockerURL = dockerURL,
                maf_input = AxtToMaf.filtered_maf
        }
    }

    call Multiz {
        input:
            dockerURL = dockerURL,
            ref2bit = FaToTwoBit.twoBit,
            mafs = MafSwap.output_mafs
    }

    output {
        File multiple_alignment = Multiz.multiz_alignment
    }
}

task FaSize {
    input {
        String dockerURL
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

task FaToTwoBit {
    input {
        String dockerURL
        File genome
    }
    command {
        faToTwoBit ${genome} ${genome}.2bit
    }
    output {
        File twoBit="${genome}.2bit"
    }
    runtime {
        docker_url: "${dockerURL}"
        req_memory: "1Gi"
    }
}

task LastzAlign {
    input {
        String dockerURL
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
        String dockerURL
        File chain_input
        File ref_sizes
        File qry_sizes
    }
    command {
        chainPreNet ${chain_input} ${ref_sizes} ${qry_sizes} stdout | \
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
        String dockerURL
        File net
        File chain
        File ref2bit
        File qry2bit
    }
    command {
        netToAxt ${net} ${chain} ${ref2bit} ${qry2bit} filtered.axt
    }
    output {
        File filtered_axt="filtered.axt"
    }
    runtime {
        docker_url: "${dockerURL}"
        req_memory: "2Gi"
    }
}

task AxtToMaf {
    input {
        String dockerURL
        File axt
        File ref_sizes
        File qry_sizes
    }
    command {
        axtToMaf ${axt} ${ref_sizes} ${qry_sizes} filtered.maf
    }
    output {
        File filtered_maf="filtered.maf"
    }
    runtime {
        docker_url: "${dockerURL}"
    }
}

task MafSwap {
    input {
        String dockerURL
        File maf_input
    }
    command {
        maf-swap ${maf_input} swapped.maf
    }
    output {
        File output_mafs="swapped.maf"
    }
    runtime {
        docker_url: "${dockerURL}"
    }
}

task Multiz {
    input {
        String dockerURL
        File ref2bit
        Array[File] mafs
    }
    command {
        multiz ${ref2bit} ${sep=" " mafs} > multiz_alignment.maf
    }
    output {
        File multiz_alignment="multiz_alignment.maf"
    }
    runtime {
        docker_url: "${dockerURL}"
        req_cpu: 8
        req_memory: "16Gi"
    }
}
