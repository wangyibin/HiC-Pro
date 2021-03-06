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

GENOME_FRAGMENT_FILE=`abspath $GENOME_FRAGMENT`
if [[ ! -e $GENOME_FRAGMENT ]]; then
    GENOME_SIZE_FILE=$ANNOT_DIR/$GENOME_FRAGMENT
    if [[ ! -e $GENOME_FRAGMENT_FILE ]]; then
	echo "$GENOME_FRAGMENT not found. Exit"
	exit -1
    fi
fi

join(){
    local IFS=$1;
    shift;
    echo $* | python -c "import sys;l=[i.strip().split() for i in sys.stdin][0];print(','.join(l))"
}


for RES_FILE_NAME in ${DATA_DIR}/*
do
    RES_FILE_NAME=$(basename $RES_FILE_NAME)
    ## out
    LOOPS_DIR=${TDGP_OUTPUT}/hiccups_loops
    mkdir -p ${LOOPS_DIR}/${RES_FILE_NAME}
    
    ldir=${LOGS_DIR}/${RES_FILE_NAME}
    mkdir -p ${ldir}
    echo "Logs: ${ldir}/hiccups_loops.log"
    BIN_SIZE=$(join , ${LOOPS_BIN_SIZE[*]})
    prefix=`basename ${MAPC_OUTPUT}/data/${RES_FILE_NAME}/${RES_FILE_NAME}.allValidPairs`
    if [ -d ${DATA_DIR}/${RES_FILE_NAME} ]; then
        cmd1="hicpro2juicebox.sh -i ${MAPC_OUTPUT}/data/${RES_FILE_NAME}/${RES_FILE_NAME}.allValidPairs -g ${GENOME_SIZE_FILE} -j ${JUICETOOLS} -r ${GENOME_FRAGMENT_FILE} -o ${LOOPS_DIR}/${RES_FILE_NAME}/ && "
        cmd2="java -jar ${JUICETOOLS} hiccups --cpu --threads ${N_CPU} -r ${BIN_SIZE} ${LOOPS_DIR}/${RES_FILE_NAME}/${prefix}.hic ${LOOPS_DIR}/${RES_FILE_NAME}/hiccups"
        cmd=${cmd1}${cmd2}
        exec_cmd $cmd >> ${ldir}/hiccups_loops.log 2>&1   
        
    fi

done
