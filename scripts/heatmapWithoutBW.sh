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
    HEATMAP_DIR=${TDGP_OUTPUT}/heatmapWithoutBW
    
    ldir=${LOGS_DIR}/${RES_FILE_NAME}
    mkdir -p ${ldir}

    
    for bsize in $(get_bsize ${HEATMAP_BIN_SIZE[*]});do

        if [[ $bsize == -1 ]]; then
        bsize='rfbin'
        fi
        mkdir -p ${DATA_DIR}/${RES_FILE_NAME}/raw/${bsize}
        mkdir -p ${DATA_DIR}/${RES_FILE_NAME}/iced/${bsize}
        mkdir -p ${HEATMAP_DIR}/${RES_FILE_NAME}/${bsize}
        echo "Logs: ${ldir}/heatmapWithoutBW_${bsize}.log"
        
        
        abs_bed=$(find -L ${DATA_DIR}/${RES_FILE_NAME}/raw/${bsize}/ -name "*_${bsize}_abs.bed")
        iced_matrix=$(find -L ${DATA_DIR}/${RES_FILE_NAME}/iced/${bsize}/ -name "*_${bsize}_iced.matrix")
        if [[ ! -e $abs_bed || ! -e $iced_matrix ]]; then
            cmd="generate_new_resolution.py -i ${MAPC_OUTPUT}/data/${RES_FILE_NAME}/${RES_FILE_NAME}.allValidPairs -b ${bsize} -c ${GENOME_SIZE_FILE} -o ${DATA_DIR}/${RES_FILE_NAME}/ "
            exec_cmd ${cmd} >> ${ldir}/heatmapWithoutBW_${bsize}.log 2>&1

        fi
        abs_bed=$(find -L ${DATA_DIR}/${RES_FILE_NAME}/raw/${bsize}/ -name "*_${bsize}_abs.bed")
        iced_matrix=$(find -L ${DATA_DIR}/${RES_FILE_NAME}/iced/${bsize}/ -name "*_${bsize}_iced.matrix")
        prefix=$(basename ${iced_matrix} | sed 's/.matrix//g')

        #ln -s ${abs_bed} ${HEATMAP_DIR}/${RES_FILE_NAME}/${bsize}/ 2>/dev/null &
        #ln -s ${iced_matrix} ${HEATMAP_DIR}/${RES_FILE_NAME}/${bsize}/ 2>/dev/null &


        cmd1="hicConvertFormat -m ${iced_matrix} --bedFileHicpro ${abs_bed} --inputFormat hicpro --outputFormat cool -o ${HEATMAP_DIR}/${RES_FILE_NAME}/${bsize}/${prefix}.cool && "
        
        cmd2="hicmatrix_visualization.py ${HEATMAP_DIR}/${RES_FILE_NAME}/${bsize}/${prefix}.cool ${GENOME_SIZE_FILE} -c ${HEATMAP_COLORMAP} -t $(($N_CPU/${#HEATMAP_BIN_SIZE[@]})) &"
        cmd=${cmd1}${cmd2}
        exec_cmd $cmd >>${ldir}/heatmapWithoutBW_${bsize}.log 2>&1
    done

 
wait
done
wait