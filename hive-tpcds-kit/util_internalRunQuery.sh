#!/bin/bash

INTERNAL_DATABASE=$1
INTERNAL_SETTINGSPATH=$2
INTERNAL_QUERYPATH=$3
INTERNAL_LOG_PATH=$4
INTERNAL_QID=$5
INTERNAL_CSV=$6

TIME_TO_TIMEOUT=120m
MODE='default'

# Beeline command to execute
START_TIME="$(date +%s.%N)"

if [[ "${MODE}" == 'default' ]]; then
    timeout "${TIME_TO_TIMEOUT}" beeline -u "jdbc:hive2://<HIVESERVER>:10000/${INTERNAL_DATABASE};ssl=true;sslTrustStore=<Truststore_Details>;trustStorePassword=<Password>;principal=hive/_HOST@OLYMPUS.CLOUDERA.COM" -i "${INTERNAL_SETTINGSPATH}" -f "${INTERNAL_QUERYPATH}" &>> "${INTERNAL_LOG_PATH}"
    RETURN_VAL=$?
else
    echo "MODE must be 'default' "
    exit 1
fi

END_TIME="$(date +%s.%N)"

if [[ "${RETURN_VAL}" == 0 ]]; then
    secs_elapsed="$(echo "$END_TIME - $START_TIME" | bc -l)"
    echo "${INTERNAL_QID}, ${secs_elapsed}, SUCCESS" >> "${INTERNAL_CSV}"
    echo "query${INTERNAL_QID}: SUCCESS"
else
    echo "${INTERNAL_QID}, , FAILURE" >> "${INTERNAL_CSV}"
    echo "query${INTERNAL_QID}: FAILURE"
    echo "Status code was: ${RETURN_VAL}"
fi

# Misc recovery for system
sleep 20
