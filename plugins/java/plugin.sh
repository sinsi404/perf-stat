#!/bin/bash

function java_startup () {
  local CONF_DIR=${1}
  local PLUGIN_DIR=${2}
  local WORK_DIR=${3}

  . ${CONF_DIR}/java.conf

  for ((i=0;i<${#JAVA_NAME[@]};i++))
  do
    date "+%Y %m %d %H %M %S" > ${WORK_DIR}/${JAVA_NAME[i]}.jstat.stime
    ${JSTAT} -gc -t $(pgrep -f ${JAVA_PGREP[i]}) ${JAVA_INTERVAL} > ${WORK_DIR}/${JAVA_NAME[i]}.jstat &
    echo $! > ${WORK_DIR}/${JAVA_NAME[i]}.jstat.pid
  done
}

function java_shutdown () {
  local CONF_DIR=${1}
  local PLUGIN_DIR=${2}
  local WORK_DIR=${3}

  for ((i=0;i<${#JAVA_NAME[@]};i++))
  do
    KILLPID=$(cat ${WORK_DIR}/${JAVA_NAME[i]}.jstat.pid)
    kill -KILL ${KILLPID}
    wait ${KILLPID} 2> /dev/null
  done
}

function java_collect () {
  local CONF_DIR=${1}
  local PLUGIN_DIR=${2}
  local WORK_DIR=${3}
  local STAT_DIR=${4}
  local START_TIME=${5}
  local END_TIME=${6}

  START_TIME=${START_TIME:8:2}:${START_TIME:10:2}:${START_TIME:12:2}
  END_TIME=${END_TIME:8:2}:${END_TIME:10:2}:${END_TIME:12:2}

  for ((i=0;i<${#JAVA_NAME[@]};i++))
  do
    JSTAT_FILE=${WORK_DIR}/${JAVA_NAME[i]}.jstat
    JSTAT_START=$(head -2 ${JSTAT_FILE}| awk 'NR==2 {print $1}')
    JSTAT_START_TIME=$(cat ${WORK_DIR}/${JAVA_NAME[i]}.jstat.stime)
    awk -v js_start=${JSTAT_START} -v js_start_time="${JSTAT_START_TIME}" \
      -v start_time=${START_TIME} -v end_time=${END_TIME} \
      '
        NR==1 {
          $1 = "time"
          print $0
        }
        NR>=2 {
          delta = int($1 - js_start)
          mt = mktime(js_start_time) + delta
          t = strftime("%H:%M:%S", mt)
          if (start_time <= t && t <= end_time) {
            $1 = t
            print $0
          }
        }
      ' ${JSTAT_FILE} > ${STAT_DIR}/${JAVA_NAME[i]}_gc.log

      awk \
        '
          NR==1 {
            print "time", "heap_size", "used_heap"
          }
          NR>=2 {
            heap_size=$2+$3+$6+$8+$10
            used_heap=$4+$5+$7+$9
            print $1, heap_size, used_heap
          }
        ' ${STAT_DIR}/${JAVA_NAME[i]}_gc.log > ${STAT_DIR}/${JAVA_NAME[i]}_heap.log
  done

  print_average ${STAT_DIR} > ${STAT_DIR}/average.txt
}

function java_summary () {
  local CONF_DIR=${1}
  local PLUGIN_DIR=${2}
  local WORK_DIR=${3}
  local STAT_DIR=${4}

  cat ${STAT_DIR}/average.txt
}
