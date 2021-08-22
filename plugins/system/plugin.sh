#!/bin/bash

function system_startup () {
  local CONF_DIR=${1}
  local PLUGIN_DIR=${2}
  local WORK_DIR=${3}

  . ${CONF_DIR}/system.conf

  ${SAR} -o ${WORK_DIR}/datafile ${SYSTEM_INTERVAL} > /dev/null &
  echo $! > ${WORK_DIR}/sar.pid
}

function system_shutdown () {
  local CONF_DIR=${1}
  local PLUGIN_DIR=${2}
  local WORK_DIR=${3}

  KILLPID=$(cat ${WORK_DIR}/sar.pid)
  kill -KILL ${KILLPID}
  wait ${KILLPID} 2> /dev/null
}

function system_collect () {
  local CONF_DIR=${1}
  local PLUGIN_DIR=${2}
  local WORK_DIR=${3}
  local STAT_DIR=${4}
  local START_TIME=${5}
  local END_TIME=${6}

  START_TIME=${START_TIME:8:2}:${START_TIME:10:2}:${START_TIME:12:2}
  END_TIME=${END_TIME:8:2}:${END_TIME:10:2}:${END_TIME:12:2}

  # CPU
  system_collect_common_extract_detail "-P ALL" cpu.log

  # CPC run-queue
  system_collect_common -q cpu_runq.log

  # Memory utilization
  system_collect_common -r mem_util.log

  # Paging
  system_collect_common -B mem_page.log

  # Huge page
  system_collect_common -W mem_huge_page.log

  # Swap space
  system_collect_common -S mem_swap_space.log

  # Swap
  system_collect_common -W mem_swap.log

  # Filesystem
  system_collect_common -v fs.log

  # Disk
  system_collect_common_extract_detail -d disk.log

  # Network
  system_collect_common "-n DEV" net.log

  # Network Error
  system_collect_common "-n EDEV" net_err.log

  # IP
  system_collect_common "-n IP" net_ip.log

  # IP erorr
  system_collect_common "-n EIP" net_ip_err.log

  # TCP
  system_collect_common "-n TCP" net_tcp.log

  # TCP error
  system_collect_common "-n ETCP" net_tcp_err.log

  # Socket
  system_collect_common "-n SOCK" net_sock.log


}

function system_collect_common () {
  local OPT=${1}
  local FILE_NAME=${2}
  ${SAR} -f ${WORK_DIR}/datafile -s ${START_TIME} -e ${END_TIME} ${OPT} \
    | awk '
      NR==3 {
        $1="time"
        print $0
      }
      NR>3 && $1 != "Average:" {
        print $0
      }' > ${STAT_DIR}/${FILE_NAME}
}

function system_collect_common_extract_detail () {
  local OPT=${1}
  local FILE_NAME=${2}

  BASE=${FILE_NAME%.*}
  EXT=${FILE_NAME#*.}

  ${SAR} -f ${WORK_DIR}/datafile -s ${START_TIME} -e ${END_TIME} ${OPT} > ${WORK_DIR}/${FILE_NAME}
  DETAIL_NAMES=$(awk 'NR>3 {print $2}' ${WORK_DIR}/${FILE_NAME} | sort | uniq)
  for detail_name in ${DETAIL_NAMES}
  do
    ${SAR} -f ${WORK_DIR}/datafile -s ${START_TIME} -e ${END_TIME} ${OPT} \
      | awk -v detail_name=${detail_name} '
        NR==3 {
          $1="time"
          $2=""
          print $0
        }
        $2 == detail_name && $1 != "Average:" {
          $2=""
          print $0
        }' > ${STAT_DIR}/${BASE}-${detail_name}.${EXT}
  done
  rm -rf ${WORK_DIR}/${FILE_NAME}

  print_average ${STAT_DIR} > ${STAT_DIR}/average.txt
}

function system_summary () {
  local CONF_DIR=${1}
  local PLUGIN_DIR=${2}
  local WORK_DIR=${3}
  local STAT_DIR=${4}

  cat ${STAT_DIR}/average.txt
}
