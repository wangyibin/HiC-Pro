#!/bin/bash
## HiC-Pro TDGP


##
## Launcher for TDGP quality control
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

input_data_type=$(get_data_type)
if [[ $input_data_type == "allvalid" ]]
then
    DATA_DIR=${RAW_DIR}
else
    DATA_DIR=${MAPC_OUTPUT}/data/
fi


nbf=$(find -L ${DATA_DIR} -mindepth 1 | wc -l)
if [[ $nbf == 0 ]]; then die "Error : empty ${DATA_DIR} folder."; fi

GENOME_SIZE_FILE=`abspath $GENOME_SIZE`
if [[ ! -e $GENOME_SIZE ]]; then
    GENOME_SIZE_FILE=$ANNOT_DIR/$GENOME_SIZE
    if [[ ! -e $GENOME_SIZE_FILE ]]; then
	echo "$GENOME_SIZE not found. Exit"
	exit -1
    fi
fi


for RES_FILE_NAME in ${DATA_DIR}/*
do
    RES_FILE_NAME=$(basename $RES_FILE_NAME)
    ## out
    echo ${TDGP_OUTPUT}
    QC_DIR=${TDGP_OUTPUT}/qc 
    mkdir -p ${QC_DIR}/${RES_FILE_NAME}
    
    ldir=${LOGS_DIR}/${RES_FILE_NAME}
    mkdir -p ${ldir}
    echo "Logs: ${ldir}/qc.log"

    if [ -d ${DATA_DIR}/${RES_FILE_NAME} ]; then
        cmd="python -m TDGP.analysis.qc validStat ${MAPC_OUTPUT}/stats/${RES_FILE_NAME}/ hicvalidPairs.stat -f 2 "
        exec_cmd $cmd >> ${ldir}/qc.log 2>&1

        cmd="estimate_hic_resolution.py ${DATA_DIR}/${RES_FILE_NAME}/${RES_FILE_NAME}.allValidPairs ${GENOME_SIZE} -o ${QC_DIR}/${RES_FILE_NAME}"
        exec_cmd $cmd >> ${ldir}/qc.log 2>&1
        
        
    fi

done
