## tdgp.inc.sh


#CURRENT_PATH=`dirname $0`


get_bsize()
{
    local array=$*
    if [ ! -z "$PBS_ARRAYID" ]; then TASKID=$PBS_ARRAYID; fi
    if [ ! -z "$PBS_ARRAY_INDEX" ]; then TASKID=$PBS_ARRAY_INDEX; fi
    if [ ! -z "$SGE_TASK_ID" ]; then TASKID=$SGE_TASK_ID; fi
    if [ ! -z "$SLURM_ARRAY_TASK_ID" ]; then TASKID=$SLURM_ARRAY_TASK_ID; fi
    if [ ! -z "$LSB_JOBINDEX" ]; then TASKID=$LSB_JOBINDEX; fi
    if [ ! -z "$TASKID" ]; then
        idx=$(($TASKID-1))
        echo ${array[@]} | python -c "import sys;l=[i.strip().split() for i in sys.stdin][0];print(l[$idx])"
        return
    fi
    echo ${array[*]}
}


