#!/bin/bash
## HiC-Pro TDGP


##
## Launcher for TDGP heatmap plotting
##


dir=$(dirname $0)


##################### Initialize ########################

function usage(){
    echo
    echo "Usage: $0 -c conf_file"
    echo
}

while [ $# -gt 0 ]
do 
    case "$1" in
    (-c) conf_file=$2; shift;;
    (-h) usage;;
    (--) shift; break;;
    (-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
    (*) break;;
    esac
    shift
done

CONF=$conf_file . $dir/hic.inc.sh
. $dir/tdgp.inc.sh


input_data_type=$(get_data_type)
if [[ $input_data_type == "allvalid" ]]
then
    DATA_DIR=${RAW_DIR}
else
    DATA_DIR=${MAPC_OUTPUT}/matrix
fi

GENOME_SIZE_FILE=`abspath $GENOME_SIZE`
if [[ ! -e $GENOME_SIZE_FILE ]]; then
    GENOME_SIZE_FILE=$ANNOT_DIR/$GENOME_SIZE
    if [[ ! -e $GENOME_SIZE_FILE ]]; then
	echo "$GENOME_SIZE not found. Exit"
	exit -1
    fi
fi

## Default
    if [[ -z ${HEATMAP_BIN_SIZE} ]]; then
        HEATMAP_BIN_SIZE=(100000 500000 1000000)
    fi
    if [[ -z ${HEATMAP_COLORMAP} ]]; then
        HEATMAP_COLORMAP='RdYlBu_r'
    fi

for RES_FILE_NAME in ${DATA_DIR}/*;do

    RES_FILE_NAME=$(basename $RES_FILE_NAME)
    ## out
    HEATMAP_DIR=${TDGP_OUTPUT}/heatmap
    
    ldir=${LOGS_DIR}/${RES_FILE_NAME}
    mkdir -p ${ldir}

    
    for bsize in $(get_bsize ${HEATMAP_BIN_SIZE[*]});do

        if [[ $bsize == -1 ]]; then
        bsize='rfbin'
        fi
        mkdir -p ${DATA_DIR}/${RES_FILE_NAME}/raw/${bsize}
        mkdir -p ${DATA_DIR}/${RES_FILE_NAME}/iced/${bsize}
        mkdir -p ${HEATMAP_DIR}/${RES_FILE_NAME}/${bsize}
        echo "Logs: ${ldir}/heatmap_${bsize}.log"
        
        
        abs_bed=$(find -L ${DATA_DIR}/${RES_FILE_NAME}/raw/${bsize}/ -name "*_${bsize}_abs.bed")
        iced_matrix=$(find -L ${DATA_DIR}/${RES_FILE_NAME}/iced/${bsize}/ -name "*_${bsize}_iced.matrix")
        if [[ ! -e $abs_bed || ! -e $iced_matrix ]]; then
            cmd="generate_new_resolution.py -i ${MAPC_OUTPUT}/data/${RES_FILE_NAME}/${RES_FILE_NAME}.allValidPairs -b ${bsize} -c ${GENOME_SIZE_FILE} -o ${DATA_DIR}/${RES_FILE_NAME}/ "
            exec_cmd ${cmd} >> ${ldir}/heatmap_${bsize}.log 2>&1

        fi
        abs_bed=$(find -L ${DATA_DIR}/${RES_FILE_NAME}/raw/${bsize}/ -name "*_${bsize}_abs.bed")
        iced_matrix=$(find -L ${DATA_DIR}/${RES_FILE_NAME}/iced/${bsize}/ -name "*_${bsize}_iced.matrix")
        prefix=$(basename ${iced_matrix} | sed 's/.matrix//g')

        #ln -s ${abs_bed} ${HEATMAP_DIR}/${RES_FILE_NAME}/${bsize}/ 2>/dev/null &
        #ln -s ${iced_matrix} ${HEATMAP_DIR}/${RES_FILE_NAME}/${bsize}/ 2>/dev/null &

        if [[ ! -z ${HEATMAP_BIGWIG} ]]; then
            big_suffix=""
            ylabel_suffix=""
            for tag in ${HEATMAP_BIGWIG[*]}; do
                if [[ ${tag} == 'compartments' ]]; then
                    if [[ -e ${TDGP_OUTPUT}/compartments/${RES_FILE_NAME}/${bsize}/${RES_FILE_NAME}_${bsize}_iced_all_eigen1.bw ]]; then
                        big_suffix=${big_suffix}" ${TDGP_OUTPUT}/compartments/${RES_FILE_NAME}/${bsize}/${RES_FILE_NAME}_${bsize}_iced_all_eigen1.bw"
                        ylabel_suffix=${ylabel_suffix}" 'Compartments'"
                    fi
                fi
                if [[ ${tag} == 'gene' ]]; then
                    if [[ -e ${TDGP_OUTPUT}/compartments/${RES_FILE_NAME}/${bsize}/${RES_FILE_NAME}_${bsize}_iced_gene_density.bw ]]; then
                        big_suffix=${big_suffix}" ${TDGP_OUTPUT}/compartments/${RES_FILE_NAME}/${bsize}/${RES_FILE_NAME}_${bsize}_iced_gene_density.bw"
                        ylabel_suffix=${ylabel_suffix}" 'Gene'"
                    fi
                fi
                if [[ ${tag} == 'RNA' ]]; then
                    if [[ -e ${TDGP_OUTPUT}/compartments/${RES_FILE_NAME}/${bsize}/${RES_FILE_NAME}_${bsize}_iced_RNA_log1p_density.bw ]]; then
                        big_suffix=${big_suffix}" ${TDGP_OUTPUT}/compartments/${RES_FILE_NAME}/${bsize}/${RES_FILE_NAME}_${bsize}_iced_RNA_log1p_density.bw"
                        ylabel_suffix=${ylabel_suffix}" 'RNA'"
                    fi
                fi
                if [[ ${tag} == 'TE' ]]; then
                    if [[ -e ${TDGP_OUTPUT}/compartments/${RES_FILE_NAME}/${bsize}/${RES_FILE_NAME}_${bsize}_iced_TE_density.bw ]]; then
                        big_suffix=${big_suffix}" ${TDGP_OUTPUT}/compartments/${RES_FILE_NAME}/${bsize}/${RES_FILE_NAME}_${bsize}_iced_TE_density.bw"
                        ylabel_suffix=${ylabel_suffix}" 'TE'"
                    fi
                fi
                if [[ ${tag} == 'Retro' ]]; then
                    if [[ -e ${TDGP_OUTPUT}/compartments/${RES_FILE_NAME}/${bsize}/${RES_FILE_NAME}_${bsize}_iced_Retro_density.bw ]]; then
                        big_suffix=${big_suffix}" ${TDGP_OUTPUT}/compartments/${RES_FILE_NAME}/${bsize}/${RES_FILE_NAME}_${bsize}_iced_Retro_density.bw"
                        ylabel_suffix=${ylabel_suffix}" 'Retro-TE'"
                    fi
                fi
                if [[ ${tag} == 'DNA' ]]; then
                    if [[ -e ${TDGP_OUTPUT}/compartments/${RES_FILE_NAME}/${bsize}/${RES_FILE_NAME}_${bsize}_iced_DNA_density.bw ]]; then
                        big_suffix=${big_suffix}" ${TDGP_OUTPUT}/compartments/${RES_FILE_NAME}/${bsize}/${RES_FILE_NAME}_${bsize}_iced_DNA_density.bw"
                        ylabel_suffix=${ylabel_suffix}" 'DNA-TE'"
                    fi
                fi
            done
            if [[ ! -z $big_suffix ]]; then
            big_suffix="-b "${big_suffix}
            fi
            if [[ ! -z $ylabel_suffix ]]; then
            ylabel_suffix="--bgYlabel "${ylabel_suffix}
            fi
        fi

        cmd1="hicConvertFormat -m ${iced_matrix} --bedFileHicpro ${abs_bed} --inputFormat hicpro --outputFormat cool -o ${HEATMAP_DIR}/${RES_FILE_NAME}/${bsize}/${prefix}.cool && "
        
        cmd2="hicmatrix_visualization.py ${HEATMAP_DIR}/${RES_FILE_NAME}/${bsize}/${prefix}.cool ${GENOME_SIZE_FILE} -c ${HEATMAP_COLORMAP} -t $(($N_CPU/${#HEATMAP_BIN_SIZE[@]})) ${big_suffix} ${ylabel_suffix}"
        cmd=${cmd1}${cmd2}
        exec_cmd $cmd >>${ldir}/heatmap_${bsize}.log 2>&1
    done

 
wait
done
wait