#!/bin/bash
## HiC-Pro TDGP


##
## Launcher for TDGP tad analysis
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

for RES_FILE_NAME in ${DATA_DIR}/*
do
    RES_FILE_NAME=$(basename $RES_FILE_NAME)
    ## out
    TAD_DIR=${TDGP_OUTPUT}/tad


    ## Logs
    ldir=${LOGS_DIR}/${RES_FILE_NAME}
    mkdir -p ${ldir}

    ## Default
    if [[ -z ${TAD_BIN_SIZE} ]]; then
        TAD_BIN_SIZE=(10000 20000 40000)
    fi

    for bsize in $(get_bsize ${TAD_BIN_SIZE[*]});do

        if [[ $bsize == -1 ]]; then
        bsize='rfbin'
        fi
        RES_DIR=${TAD_DIR}/${RES_FILE_NAME}/${bsize}
        mkdir -p ${RES_DIR}
        echo "Logs: ${ldir}/tad_${bsize}.log"
        if [[ ! -e ${DATA_DIR}/${RES_FILE_NAME}/raw/${bsize}/ || ! -e ${DATA_DIR}/${RES_FILE_NAME}/iced/${bsize}/ ]]; then
            cmd="generate_new_resolution.py -i ${MAPC_OUTPUT}/data/${RES_FILE_NAME}/${RES_FILE_NAME}.allValidPairs -b ${bsize} -c ${GENOME_SIZE_FILE} -o ${DATA_DIR}/${RES_FILE_NAME}/ "
            exec_cmd ${cmd} >> ${ldir}/tad_${bsize}.log 2>&1
        fi

        abs_bed=$(find -L ${DATA_DIR}/${RES_FILE_NAME}/raw/${bsize}/ -name "*_${bsize}_abs.bed")
        iced_matrix=$(find -L ${DATA_DIR}/${RES_FILE_NAME}/iced/${bsize}/ -name "*_${bsize}_iced.matrix")
        #ln -s ${abs_bed} ${RES_DIR}/
        #ln -s ${iced_matrix} ${RES_DIR}/
        if [[ ! -z $abs_bed || ! -z $iced_matrix ]]; then
            cmd="generate_new_resolution.py -i ${MAPC_OUTPUT}/data/${RES_FILE_NAME}/${RES_FILE_NAME}.allValidPairs -b ${bsize} -c ${GENOME_SIZE_FILE} -o ${DATA_DIR}/${RES_FILE_NAME}/ "
            exec_cmd ${cmd} >> ${ldir}/tad_${bsize}.log 2>&1

        fi
        abs_bed=$(find -L ${DATA_DIR}/${RES_FILE_NAME}/raw/${bsize}/ -name "*_${bsize}_abs.bed")
        iced_matrix=$(find -L ${DATA_DIR}/${RES_FILE_NAME}/iced/${bsize}/ -name "*_${bsize}_iced.matrix")
        prefix=$(basename ${iced_matrix} | sed 's/.matrix//g')
        cmd="run_hitad.py ${iced_matrix} ${abs_bed} -t ${N_CPU} -o ${RES_DIR} --no_qsub"
        
        exec_cmd $cmd >>${ldir}/tad_${bsize}.log 2>&1
        cmd="sh run_${prefix}.sh"
        exec_cmd $cmd >>${ldir}/tad_${bsize}.log 2>&1

    done

done