#!/bin/bash
## HiC-Pro TDGP


##
## Launcher for TDGP compartments analysis
##

dir=$(dirname $0)

################### Initialize ###################

while [ $# -gt 0 ]
do
    case "$1" in
	(-c) conf_file=$2; shift;;
	(-h) usage;;
	(--) shift; break;;
	(-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
	(*)  break;;
    esac
    shift
done

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
################### Define Variables ###################
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


for RES_FILE_NAME in ${DATA_DIR}/*
do
    RES_FILE_NAME=$(basename $RES_FILE_NAME)
    ## out
    COMPARTMENTS_DIR=${TDGP_OUTPUT}/compartments


    ## Logs
    ldir=${LOGS_DIR}/${RES_FILE_NAME}
    mkdir -p ${ldir}

    
    for bsize in $(get_bsize ${HEATMAP_BIN_SIZE[*]});do

        if [[ $bsize == -1 ]]; then
        bsize='rfbin'
        fi
        RES_DIR=${COMPARTMENTS_DIR}/${RES_FILE_NAME}/${bsize}
        mkdir -p ${RES_DIR}
        echo "Logs: ${ldir}/compartments_${bsize}.log"
        
        abs_bed=$(find -L ${DATA_DIR}/${RES_FILE_NAME}/raw/${bsize}/ -name "*_${bsize}_abs.bed")
        iced_matrix=$(find -L ${DATA_DIR}/${RES_FILE_NAME}/iced/${bsize}/ -name "*_${bsize}_iced.matrix")
        prefix=$(basename ${iced_matrix} | sed 's/.matrix//g')
        
        cmd="run_cworld_ab.sh ${abs_bed} ${iced_matrix} ${CWORLD_SPECIES} ${GENOME_SIZE_FILE} ${RES_DIR} ${N_CPU} ${TE_DATA}" 
        
        exec_cmd $cmd >>${ldir}/compartments_${bsize}.log 2>&1

    done

done
