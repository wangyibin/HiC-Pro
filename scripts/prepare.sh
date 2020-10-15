#!/bin/bash

function info {
    echo
    echo "Prepare for HiC-Pro, including chrom_reference.sizes, enzyme.bed, bowtie2-build"
    echo
}

function usage {
    echo -e "Usage: $(basename $0) -f fasta -e (HindIII/MboI)"
    echo -e "Use option -h for more information"
}

function help {
    info;
    usage;
    echo "  -f : input fasta file path"
    echo "  -e : enzyme for digest"
    echo "  [-t] : threads numbers [default:20]"
    echo "  [-h] : help"
    exit;
}

while getopts "f:e:t:vh" opt; do
    case $opt in
        f)ref=$OPTARG;;
        e)enzyme=$OPTARG;;
        t)nct=$OPTARG;;
        h)help ;;
        ?)echo "Invalid option:-$OPTARG"
            help;
            exit
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            help;
            exit
            ;;
    esac
done


if [[ -z $ref || -z $enzyme ]]; then
    help;
    exit
fi

if [ -z $nct ];then
    nct=20
fi


if [ ! -e  $ref ];then
    echo -e "No such file of $ref"
    exit
fi

if [[  $enzyme != "HindIII" &&  $enzyme  != "MboI" ]];then
    echo -e "enzyme only support MboI or HindIII"
fi


#digest_genome.py -r $enzyme -o ${enzyme}.bed ${ref}
#getChrLength.py ${ref} > chrom_referece.sizes
bowtie2-build --threads $nct ${ref} $(basename ${ref})
