#!/bin/bash
set -e

source config/config.sh
WORKDIR=`pwd`
ROOTDIR=`dirname $WORKDIR`
SCRIPTS=`dirname $ROOTDIR`"/scripts"
echo "=============================="
echo "working directory: $WORKDIR"
echo "root directory: $ROOTDIR"
echo "scripts directory: $SCRIPTS"
echo "=============================="

nDumps=0
for i in {0..5}; do
    echo ""
    echo "*** RUN $i ***"
    tar xzf data/run$i.tar.gz
    
    cd run$i/perf
    rm -f replyl_issdm-$MDS replyt_issdm-$MDS reply_issdm-$MDS

    nMDS=0
    for MDS in $MDSs; do
        echo -e "\tMaking the reply file for MDS$MDS"
        if [ $nMDS -eq 0 ]; then
            for j in {0..1000}; do
                if [ -a 15-$j ]; then
                    nDumps=$j
                fi
            done
            echo -e "\t... found $nDumps performance counter dumps"
        fi

        # get the aggregate reply latency
        for j in $(seq 0 $nDumps); do
            parse_perf.py $MDS-$j mds reply_latency >> reply_issdm-$MDS
        done
        # get the instantaneous reply latency and throughput
        $SCRIPTS/parse_replyl.py reply_issdm-$MDS ops-per-second | sed 's/-[0-9][0-9]*/0/g' >> replyt_issdm-$MDS
        $SCRIPTS/parse_replyl.py reply_issdm-$MDS latency >> replyl_issdm-$MDS

        echo -e "\t... concatenating instaneous latencies/throughputs into one file"
        cat reply_issdm-$MDS | awk '{print $1}' > col1
        cat replyl_issdm-$MDS | awk '{print $2}' > col2
        cat replyl_issdm-$MDS | awk '{print $3}' > col3
        cat replyt_issdm-$MDS | awk '{print $3}' > col4
        # fill in 0s if the number of samples don't match
        nLines=`wc -l col1 | awk '{print $1'}`
        for j in {2..4}; do
            nLines_j=`wc -l col2 | awk '{print $1'}`
            if [ $nLines > $nLines_j ]; then
                extra=$(($nLines - nLines_j))
                for j in $(seq 0 $extra); do
                    echo "0" >> col$j
                done
            fi
        done
        paste -d " " col1 col2 col3 col4 > replyc_issdm-$MDS
        
        rm replyl_issdm-$MDS replyt_issdm-$MDS reply_issdm-$MDS col1 col2 col3 col4
        nMDS=$(($nMDS+1))
    done
   
    cd $WORKDIR 
    if [ ! -d "./data" ]; then
        mkdir ./data
    fi

    echo -e "\tConcatenating all MDS throughputs into run$0-thruput"
    nMDS=0
    cols="colDate colTime "
    nLines=0
    for MDS in $MDSs; do
        if [ $nMDS -eq 0 ]; then
            if grep -Fxq "NULLTIME" run$i/perf/replyc_issdm-$MDS; then
                cat run$i/perf/replyc_issdm-$MDS | awk '{print $2}' > colTime
            else
                cat run$i/perf/mds-issdm-$MDS.timing | awk '{print $2}' > colTime
            fi
            cat run$i/perf/replyc_issdm-$MDS | awk '{print $1}' > colDate
            nLines=`wc -l colTime | awk '{print $1}'`
        fi
        cat run$i/perf/replyc_issdm-$MDS | awk '{print $4}' > col$MDS
        nLines_j=`wc -l col$MDS | awk '{print $1}'`
        if [ $nLines -lt $nLines_j ]; then
            extra=$(($nLines - nLines_j))
            for j in $(seq 0 $extra); do
                echo "0" >> col$MDS
            done
        fi
        cols="$cols col$MDS"
    done
    paste -d " " $cols > data/run$i-thruput
    rm -r $cols run$i
done

gnuplot config/gnuplot.sh
#rm -r data/run*-thruput
