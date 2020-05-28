get_bsize()
{
    local array=$*
    if [ ! -z "$SGE_TASK_ID" ]; then TASKID=$SGE_TASK_ID; fi
    if [ ! -z "$TASKID" ]; then
        idx=$((${TASKID}-1))
        echo ${array[@]} | python -c "import sys;l=[i.strip().split() for i in sys.stdin][0];print(l[$idx])"
        return
    fi
    echo ${array[*]}
}



get_bsize 1 3 4
