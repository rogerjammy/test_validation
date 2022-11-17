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
    timeout "${TIME_TO_TIMEOUT}" impala-shell -V -i neptune01.olympus.cloudera.com:21000 -d ${INTERNAL_DATABASE} -l -u pkatti --ssl --ca_cert /opt/cloudera/security/pki/chain.pem --ldap_password_cmd='echo -n @' -f "${INTERNAL_QUERYPATH}" &>> "${INTERNAL_LOG_PATH}"
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
