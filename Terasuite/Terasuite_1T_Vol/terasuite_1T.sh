#!/bin/bash
source ./parameters_1T.sh

function getHourMinSec() {
    seconds=$1
    hr=$((seconds/3600))
    tmp=$((seconds % 3600 ))
    min=$((tmp / 60))
    sec=$((seconds % 60))
    echo " ${hr}hr ${min}mins ${sec}secs "
}

echo "......................................................................"
printf "\n Starting Terasuite test as part of CDP Validation. \n"

echo "Setting the parameter values for 1T test."

## Set the values for 1T terasuite
hdfs_bin=/usr/bin/hdfs
DATA_VOL=10000000000
INPUT="/tmp/CDP_Validate/teragen_1T"
OUTPUT="/tmp/CDP_Validate/terasort_1T"
REPORT="/tmp/CDP_Validate/teravalidate_1T"
CDP_DIR="/opt/cloudera/parcels/CDH/lib/hadoop-mapreduce"
BLOCK_SIZE=134217728

## Create HDFS directory if not exists
$hdfs_bin dfs -mkdir -p /tmp/CDP_Validate

printf "\n Cleaning the directories if exist. \n"
## Clean the HDFS directories
$hdfs_bin dfs -rm -r -skipTrash $INPUT;
$hdfs_bin dfs -rm -r -skipTrash $OUTPUT;
$hdfs_bin dfs -rm -r -skipTrash $REPORT;


echo "................................................."
printf "Starting with Teragen for generating 1T data.\n"
echo "................................................."

cmd="time yarn jar $CDP_DIR/hadoop-mapreduce-examples.jar teragen -Ddfs.replication=$REPLICATION -Ddfs.client.block.write.locateFollowingBlock.retries=15 -Dyarn.app.mapreduce.am.job.cbd-mode.enable=false -Ddfs.blocksize=$BLOCK_SIZE -Dyarn.app.mapreduce.am.job.map.pushdown=false -Dmapreduce.map.memory.mb=$MAP_MEMORY -Dmapreduce.job.maps=$NUM_MAPPERS $DATA_VOL $INPUT"

printf "${cmd} \n"

START_TIME="$(date +%s.%N)"
$cmd
END_TIME="$(date +%s.%N)"

RETURN_VAL=$?

if [[ "${RETURN_VAL}" == 0 ]]; then
  echo "Teragen ran successfully. "
  secs_elapsed="$(echo "$END_TIME - $START_TIME" | bc -l)"
  secs_new=$( echo $secs_elapsed | awk '{print ($0-int($0)<0.499)?int($0):int($0)+1}' )
  time=$(getHourMinSec ${secs_new})
  echo "____________________________________"
  echo "Total runtime for teragen test:-"
  echo $time
  echo "____________________________________"
else
    echo "......................................................................"
    echo "Teragen did not run successfully. Skipping the remaining tests as well."
    echo "Status code was: ${RETURN_VAL}"
    exit ${RETURN_VAL}
fi

sleep 5
echo "......................................................................"
printf "Teragen is completed.\n"
echo "......................................................................"

echo "......................................................................"
printf "\n Starting with Terasort of 1T data. \n"
echo "......................................................................"

cmd="time yarn jar $CDP_DIR/hadoop-mapreduce-examples.jar terasort -Ddfs.replication=$REPLICATION \
-Ddfs.client.block.write.locateFollowingBlock.retries=15 -Dyarn.app.mapreduce.am.job.cbd-mode.enable=false \
-Ddfs.blocksize=$BLOCK_SIZE -Dyarn.app.mapreduce.am.job.map.pushdown=false -Dmapreduce.map.memory.mb=$MAP_MEMORY \
-Dmapreduce.job.maps=$NUM_MAPPERS -Dmapreduce.job.reduces=$NUM_REDUCERS -Dmapreduce.reduce.memory.mb=$REDUCE_MEMORY $INPUT $OUTPUT"

printf "${cmd} \n"

START_TIME="$(date +%s.%N)"
$cmd
END_TIME="$(date +%s.%N)"

RETURN_VAL=$?

if [[ "${RETURN_VAL}" == 0 ]]; then
  echo "Terasort ran successfully. "
  secs_elapsed="$(echo "$END_TIME - $START_TIME" | bc -l)"
  secs_new=$( echo $secs_elapsed | awk '{print ($0-int($0)<0.499)?int($0):int($0)+1}' )
  time=$(getHourMinSec ${secs_new})
  echo "____________________________________"
  echo "Total runtime for terasort test:-"
  echo $time
  echo "____________________________________"
else
    echo "Terasort did not run successfully. Skipping the remaining test as well."
    echo "Status code was: ${RETURN_VAL}"
    exit ${RETURN_VAL}
fi

sleep 5
echo "......................................................................"
printf "\n Terasort is completed. \n"

printf "\n Starting with Teravalidate of the sorted data. \n"
echo "......................................................................"


cmd="time yarn jar $CDP_DIR/hadoop-mapreduce-examples.jar teravalidate -Ddfs.replication=$REPLICATION \
-Ddfs.client.block.write.locateFollowingBlock.retries=15 -Dyarn.app.mapreduce.am.job.cbd-mode.enable=false \
-Ddfs.blocksize=$BLOCK_SIZE -Dyarn.app.mapreduce.am.job.map.pushdown=false -Dmapreduce.job.maps=$NUM_MAPPERS \
-Dmapreduce.map.memory.mb=$MAP_MEMORY $OUTPUT $REPORT"

printf "${cmd} \n"

START_TIME="$(date +%s.%N)"
$cmd
END_TIME="$(date +%s.%N)"

RETURN_VAL=$?

if [[ "${RETURN_VAL}" == 0 ]]; then
  echo "Teravalidate ran successfully. "
  secs_elapsed="$(echo "$END_TIME - $START_TIME" | bc -l)"
  secs_new=$( echo $secs_elapsed | awk '{print ($0-int($0)<0.499)?int($0):int($0)+1}' )
  time=$(getHourMinSec ${secs_new})
  echo "____________________________________"
  echo "Total runtime for teravalidate test:-"
  echo $time
  echo "____________________________________"
else
    echo "Teravalidate did not run successfully. Check for the errors and rerun only Teravalidate. "
    echo "Status code was: ${RETURN_VAL}"
    exit ${RETURN_VAL}
fi

sleep 5
echo "..................................."
printf "\n TERASUITE TEST RAN SUCCESSFULLY. \n"
