#!/bin/bash

## TDGP

##
## Create SGE files
##

dir=$(dirname $0)

usage()
{
    echo "usage: $0 -c CONFIG [-s STEP]"
}

MAKE_OPTS=""

while [ $# -gt 0 ]
do
    case "$1" in
	(-c) conf_file=$2; shift;;
	(-s) MAKE_OPTS=$2; shift;;
	(--) shift; break;;
	(-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
	(*)  suffix=$1; break;;
    esac
    shift
done

if [ -z "$conf_file" ]; then usage; exit 1; fi

CONF=$conf_file . $dir/hic.inc.sh
. $dir/tdgp.inc.sh
unset FASTQFILE

if [[ ! -z ${HEATMAP_BIN_SIZE} ]]; then
    count=3
else
    count=${#HEATMAP_BIN_SIZE[@]}
fi

if [[ ! -z ${TAD_BIN_SIZE} ]]; then
    tad_count=3
else
    tad_count=${#TADBIN_SIZE[@]}
fi

    ## step 1 - parallel
    sge_script=TDGP_com_heatmap_${JOB_NAME}.sh
    cat > ${sge_script} <<EOF
#!/bin/bash
#$ -l h_vmem=${JOB_MEM}
#$ -l h_rt=${JOB_WALLTIME}
#$ -M ${JOB_MAIL}
#$ -m ae
#$ -j y
#$ -N TDGP_com_heatmap_${JOB_NAME}
#$ -q ${JOB_QUEUE}
#$ -V
#$ -pe mpi ${N_CPU}
#$ -cwd
EOF

    if [[ $count -gt 1 ]]; then
	echo -e "#$ -t 1-$count" >> ${sge_script} 
    fi

cat >> ${sge_script} <<EOF
make --file ${SCRIPTS}/Makefile CONFIG_FILE=${conf_file} CONFIG_SYS=${INSTALL_PATH}/config-system.txt com_heatmap 2>&1
EOF
    
    chmod +x ${sge_script}

    ## User message
    echo "The following command will launch the parallel workflow through $count sge jobs:"
    echo qsub ${sge_script}
   


## make tad script

    sge_script_tad=TDGP_tad_${JOB_NAME}.sh
    cat > ${sge_script_tad} <<EOF
#!/bin/bash
#$ -l h_vmem=${JOB_MEM}
#$ -l h_rt=${JOB_WALLTIME}
#$ -M ${JOB_MAIL}
#$ -m ae
#$ -j y
#$ -N TDGP_tad_${JOB_NAME}
#$ -q ${JOB_QUEUE}
#$ -pe mpi ${N_CPU}
#$ -V
#$ -cwd
EOF
    if [[ $tad_count -gt 1 ]]; then
	echo -e "#$ -t 1-$tad_count" >> ${sge_script_tad} 
    fi
cat >> ${sge_script_tad} << EOF
make --file ${SCRIPTS}/Makefile CONFIG_FILE=${conf_file} CONFIG_SYS=${INSTALL_PATH}/config-system.txt tad 2>&1
EOF
    
    chmod +x ${sge_script_tad}

    ## User message
    echo "The following command will launch the parallel workflow through $count sge jobs:"
    echo qsub ${sge_script_tad}


## make loops script

    sge_script_loops=TDGP_loops_${JOB_NAME}.sh
    cat > ${sge_script_loops} <<EOF
#!/bin/bash
#$ -l h_vmem=${JOB_MEM}
#$ -l h_rt=${JOB_WALLTIME}
#$ -M ${JOB_MAIL}
#$ -m ae
#$ -j y
#$ -N TDGP_loops_${JOB_NAME}
#$ -q ${JOB_QUEUE}
#$ -V
#$ -cwd
make --file ${SCRIPTS}/Makefile CONFIG_FILE=${conf_file} CONFIG_SYS=${INSTALL_PATH}/config-system.txt loops 2>&1
EOF
    
    chmod +x ${sge_script_loops}

    ## User message
    echo "The following command will launch the loops workflow:"
    echo qsub ${sge_script_loops}

## make qc script

    sge_script_qc=TDGP_qc_${JOB_NAME}.sh
    cat > ${sge_script_qc} <<EOF
#!/bin/bash
#$ -l h_vmem=${JOB_MEM}
#$ -l h_rt=${JOB_WALLTIME}
#$ -M ${JOB_MAIL}
#$ -m ae
#$ -j y
#$ -N TDGP_qc_${JOB_NAME}
#$ -q ${JOB_QUEUE}
#$ -pe mpi ${N_CPU}
#$ -V
#$ -cwd

make --file ${SCRIPTS}/Makefile CONFIG_FILE=${conf_file} CONFIG_SYS=${INSTALL_PATH}/config-system.txt qc 2>&1
EOF
    
    chmod +x ${sge_script_qc}

    ## User message
    echo "The following command will launch the qc workflow:"
    echo qsub ${sge_script_qc}


    cat > TDGP_qsub_all.sh <<EOF
#!/bin/bash
qsub ${sge_script}
qsub ${sge_script_tad}
qsub ${sge_script_loops}
qsub ${sge_script_qc}

EOF


    chmod +x TDGP_qsub_all.sh
    echo "The following command will submit all TDGP scripts:"
    echo qsub TDGP_qsub_all.sh