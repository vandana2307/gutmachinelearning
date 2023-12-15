#!/bin/bash
set -x
set -e

usage()  
{  
  echo "Usage: $0 <cellranger base path> <wget file path> <destination directory>" 
  exit 1  
} 

if [ $# -ne 3 ] ; then
  usage
else
  cellranger_base_path=$1
  sratoolkit_bin_path="${cellranger_base_path}/sratoolkit/sratoolkit.3.0.7-ubuntu64/bin"
  reference_path="${cellranger_base_path}/reference/refdata-gex-GRCh38-2020-A"
  cellranger_bin_path="${cellranger_base_path}/cellranger-7.2.0/bin"
  sra_file_path=$2
  dest_dir=$3

  #prefetch_cmd="${sratoolkit_bin_path}/prefetch"
  #fasterq_dump_cmd="${sratoolkit_bin_path}/fasterq-dump"
  cellranger_cmd="${cellranger_bin_path}/cellranger"
  #mkdir -p "${dest_dir}/prefetch_output"
  #mkdir -p "${dest_dir}/fasterq_dumps"
  mkdir -p "${dest_dir}/gzip_files"

  while IFS= read -r line; do
    line=$(echo "${line}" | awk '{$1=$1};1')
    links=$(echo "${line}" | tr ' ' '\n')
    cd "${dest_dir}/gzip_files"
    #$prefetch_cmd --max-size 200g ${line}
    #prefetch_dir=$(ls "${dest_dir}/prefetch_output")
    #$fasterq_dump_cmd --split-files ${prefetch_dir} --outdir "${dest_dir}/fasterq_dumps"
    #
    #ls "${dest_dir}/fasterq_dumps" | while IFS= read -r fasterqfile; do
    #  pigz -p8 "${dest_dir}/fasterq_dumps/${fasterqfile}"
    #done

    #ls "${dest_dir}/fasterq_dumps" | while IFS= read -r gzipfile; do
    #  echo ${gzipfile}
    #  sample_name=$(echo ${gzipfile} | sed -r 's/(.*)_([0-9]+).fastq.gz/\1/g')
    #  new_name=$(echo ${gzipfile} | sed -r 's/(.*)_([0-9]+).fastq.gz/\1_S1_L001_R\2_001.fastq.gz/g')
    #  mkdir -p "${dest_dir}/gzip_files/${sample_name}"
    #  mv "${dest_dir}/fasterq_dumps/${gzipfile}" "${dest_dir}/gzip_files/${sample_name}/${new_name}"
    #done
    echo "${links}" | xargs -I {} wget -c {}
    run_id=$(ls "${dest_dir}/gzip_files" | head -n1 | sed -r 's/(.*)_S([0-9]+)_L([0-9]+)_R([0-9]+)_([0-9]+).fastq.gz/\1/g')
    mkdir -p "${dest_dir}/gzip_files/${run_id}"
    find "${dest_dir}/gzip_files" -type f -exec mv {} "${dest_dir}/gzip_files/${run_id}" \;

    cd "${dest_dir}"
    ls "${dest_dir}/gzip_files" | while IFS= read -r gzipfile; do
      $cellranger_cmd count --id="run_count_${run_id}" \
        --fastqs="${dest_dir}/gzip_files/${gzipfile}" \
        --sample=${run_id} \
        --transcriptome=${reference_path}
    done

    #rm -rf ${dest_dir}/prefetch_output/*
    #rm -rf ${dest_dir}/fasterq_dumps/*
    rm -rf ${dest_dir}/gzip_files/*
    find "${dest_dir}/run_count_${run_id}/outs" -mindepth 1 -maxdepth 1 ! -name "filtered_feature_bc_matrix" -exec rm -rf {} \;
    find "${dest_dir}/run_count_${run_id}" -mindepth 1 -maxdepth 1 '!' -name "outs" -exec rm -rf {} \;
  done < "${sra_file_path}"

fi
