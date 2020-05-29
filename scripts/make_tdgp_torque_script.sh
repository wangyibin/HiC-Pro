#!/bin/bash

## TDGP

##
## Create PBS Torque files
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
    torque_script=TDGP_com_heatmap_${JOB_NAME}.sh
    cat > ${torque_script} <<EOF
#!/bin/bash
#PBS -l nodes=1:ppn=${N_CPU},mem=${JOB_MEM},walltime=${JOB_WALLTIME}
#PBS -M ${JOB_MAIL}
#PBS -m ae
#PBS -j eo
#PBS -N TDGP_com_heatmap_${JOB_NAME}
#PBS -q ${JOB_QUEUE}
#PBS -V
EOF

    if [[ $count -gt 1 ]]; then
	echo -e "#PBS -J 1-$count" >> ${torque_script} 
    fi

cat >> ${torque_script} <<EOF
if [ ! -z \$PBS_O_WORKDIR ]; then
cd \$PBS_O_WORKDIR
fi
make --file ${SCRIPTS}/Makefile CONFIG_FILE=${conf_file} CONFIG_SYS=${INSTALL_PATH}/config-system.txt com_heatmap 2>&1
EOF
    
    chmod +x ${torque_script}

    ## User message
    echo "The following command will launch the parallel workflow through $count torque jobs:"
    echo qsub ${torque_script}
   


## make tad script

    torque_script_tad=TDGP_tad_${JOB_NAME}.sh
    cat > ${torque_script_tad} <<EOF
#!/bin/bash
#PBS -l nodes=1:ppn=${N_CPU},mem=${JOB_MEM},walltime=${JOB_WALLTIME}
#PBS -M ${JOB_MAIL}
#PBS -m ae
#PBS -j eo
#PBS -N TDGP_tad_${JOB_NAME}
#PBS -q ${JOB_QUEUE}
#PBS -V
EOF

    if [[ $tad_count -gt 1 ]]; then
	echo -e "#PBS -J 1-$tad_count" >> ${torque_script_tad} 
    fi

cat >> ${torque_script_tad} <<EOF
if [ ! -z \$PBS_O_WORKDIR ]; then
cd \$PBS_O_WORKDIR
fi
make --file ${SCRIPTS}/Makefile CONFIG_FILE=${conf_file} CONFIG_SYS=${INSTALL_PATH}/config-system.txt tad 2>&1
EOF
    
    chmod +x ${torque_script_tad}

    ## User message
    echo "The following command will launch the parallel workflow through $count torque jobs:"
    echo qsub ${torque_script_tad}


## make loops script

    torque_script_loops=TDGP_loops_${JOB_NAME}.sh
    cat > ${torque_script_loops} <<EOF
#!/bin/bash
#PBS -l nodes=1:ppn=${N_CPU},mem=${JOB_MEM},walltime=${JOB_WALLTIME}
#PBS -M ${JOB_MAIL}
#PBS -m ae
#PBS -j eo
#PBS -N TDGP_loops_${JOB_NAME}
#PBS -q ${JOB_QUEUE}
#PBS -V
if [ ! -z \$PBS_O_WORKDIR ]; then
cd \$PBS_O_WORKDIR
fi
make --file ${SCRIPTS}/Makefile CONFIG_FILE=${conf_file} CONFIG_SYS=${INSTALL_PATH}/config-system.txt loops 2>&1
EOF
    
    chmod +x ${torque_script_loops}

    ## User message
    echo "The following command will launch the loops workflow:"
    echo qsub ${torque_script_loops}

## make qc script

    torque_script_qc=TDGP_qc_${JOB_NAME}.sh
    cat > ${torque_script_qc} <<EOF
#!/bin/bash
#PBS -l nodes=1:ppn=${N_CPU},mem=${JOB_MEM},walltime=${JOB_WALLTIME}
#PBS -M ${JOB_MAIL}
#PBS -m ae
#PBS -j eo
#PBS -N TDGP_qc_${JOB_NAME}
#PBS -q ${JOB_QUEUE}
#PBS -V
if [ ! -z \$PBS_O_WORKDIR ]; then
cd \$PBS_O_WORKDIR
fi
make --file ${SCRIPTS}/Makefile CONFIG_FILE=${conf_file} CONFIG_SYS=${INSTALL_PATH}/config-system.txt qc 2>&1
EOF
    
    chmod +x ${torque_script_qc}

    ## User message
    echo "The following command will launch qc workflow:"
    echo qsub ${torque_script_qc}


    cat > TDGP_qsub_all.sh <<EOF
#!/bin/bash 
qsub ${torque_script}
qsub ${torque_script_tad}
qsub ${torque_script_loops}
qsub ${torque_script_qc}

EOF 

    chmod +x TDGP_qsub_all.sh
    echo "The following command will submit all TDGP scripts:"
    echo qsub TDGP_qsub_all.sh