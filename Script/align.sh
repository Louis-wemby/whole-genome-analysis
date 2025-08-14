#!/bin/bash

conda activate your_env

# main catalogue where your genome data is stored.
cd ../Macaca/genome

# key folders
INTER=../intermediate
RESULT=../result
TWOBIT=twobit
SIZE=size
AXT=../intermediate/axt
CHAIN=../intermediate/chain
NET=../intermediate/net
MAF=../result/single_maf

mkdir -p "$INTER" "$RESULT" "$TWOBIT" "$SIZE" "$AXT" "$CHAIN" "$NET" "$MAF"

# process reference genome specified manually
REF_FA=reference/ref.fasta
REF_PREFIX=ref

samtools faidx $REF_FA
cut -f1,2 "${REF_FA}.fai" > "${SIZE}/${REF_PREFIX}.sizes"
faToTwoBit "$REF_FA" "${TWOBIT}/${REF_PREFIX}.2bit"

# preprocess and alignment
for fasta in *.fasta
do
  base=$(basename "$fasta" .fasta)
  samtools faidx "$fasta"
  cut -f1,2 "${fasta}.fai" > "${SIZE}/${base}.sizes"
  faToTwoBit "$fasta" "${TWOBIT}/${base}.2bit"
  
  lastz_32 ${TWOBIT}/${REF_PREFIX}.2bit[multiple] ${TWOBIT}/${base}.2bit \
        K=4500 L=3000 Y=15000 E=150 H=2000 O=600 T=2 --format=axt > ${AXT}/${base}.axt

  axtChain -minScore=5000 -linearGap=medium ${AXT}/${base}.axt \
        ${TWOBIT}/${REF_PREFIX}.2bit ${TWOBIT}/${base}.2bit ${CHAIN}/${base}.chain

  chainPreNet ${CHAIN}/${base}.chain ${SIZE}/${REF_PREFIX}.sizes ${SIZE}/${base}.sizes stdout | \
    chainNet stdin ${SIZE}/${REF_PREFIX}.sizes ${SIZE}/${base}.sizes ${NET}/${base}.net /dev/null

  netToAxt ${NET}/${base}.net ${CHAIN}/${base}.chain \
        ${TWOBIT}/${REF_PREFIX}.2bit ${TWOBIT}/${base}.2bit ${AXT}/${base}.filtered.axt

  axtToMaf ${AXT}/${base}.filtered.axt ${SIZE}/${REF_PREFIX}.sizes ${SIZE}/${base}.sizes ${RESULT}/${REF_PREFIX}.${base}.sing.maf
done
