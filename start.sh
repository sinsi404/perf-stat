#!/bin/bash

WARMUP=2
DURATION=2
RESULT_ROOT=./results
PLUGIN_DIR=./plugins
PLUGINS="system java"

function proc_stage () {
  local STAGE_NAME=${1}
  local CONF_DIR=${2}
  local WORK_DIR=${3}
  local STAT_DIR=${4}
  local START_TIME=${5}
  local END_TIME=${6}

  for plugin_name in ${PLUGINS}
  do
    if [ $? -eq 0 ];then
      . ${PLUGIN_DIR}/${plugin_name}/plugin.sh
      mkdir -p ${WORK_DIR}/${plugin_name}
      mkdir -p ${STAT_DIR}/${plugin_name}
      eval ${plugin_name}_${STAGE_NAME} \
        ${CONF_DIR} \
        ${PLUGIN_DIR}/${plugin_name} \
        ${WORK_DIR}/${plugin_name} \
        ${STAT_DIR}/${plugin_name} \
        ${START_TIME} \
        ${END_TIME}
    fi
  done

}

CONF_DIR=${1}
TEST_NAME=${2}

TEST_NAME=$(date +%Y%m%d%H%M%S)_${TEST_NAME}
RESULT_DIR=${RESULT_ROOT}/${TEST_NAME}
WORK_DIR=${RESULT_ROOT}/${TEST_NAME}/work
STAT_DIR=${RESULT_ROOT}/${TEST_NAME}/stat

# Init
#mkdir -p ${WORK_DIR}
. lib/common.sh

# Warmup
echo Warmup ${WARMUP} sec start!
sleep ${WARMUP}
echo Warmup finished!

# Startup
proc_stage startup ${CONF_DIR} ${WORK_DIR} ${STAT_DIR} ${START_TIME} ${END_TIME}

# Begin test
START_TIME=$(date +%Y%m%d%H%M%S)
echo Test ${DURATION} sec start!

sleep ${DURATION}

# End test
END_TIME=$(date +%Y%m%d%H%M%S)
echo Test finished!

# Shutdown
proc_stage shutdown ${CONF_DIR} ${WORK_DIR} ${STAT_DIR} ${START_TIME} ${END_TIME}

# Collect
proc_stage collect ${CONF_DIR} ${WORK_DIR} ${STAT_DIR} ${START_TIME} ${END_TIME}

# Summary
echo "-----Test Summary-----"
proc_stage summary ${CONF_DIR} ${WORK_DIR} ${STAT_DIR} ${START_TIME} ${END_TIME}
