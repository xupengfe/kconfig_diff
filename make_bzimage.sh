#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# Make the bzImage script

set -e
KERNEL_PATH="/tmp/kernel"
KCONFIG_NAME="kconfig"
RESULT=""
STATUS=""
TIME_FMT="%m%d_%H%M%S"
KCONFIG="https://raw.githubusercontent.com/xupengfe/kconfig_diff/main/config-5.13i_kvm"

usage() {
  cat <<__EOF
  usage: ./${0##*/}  [-k KERNEL][-m COMMIT][-c KCONFIG][-d DEST][-h]
  -k  KERNEL source folder
  -m  COMMIT ID which will be used
  -c  Kconfig(optional) which will be used
  -d  Destination where bzImage will be copied
  -h  show this
__EOF
  exit 1
}

print_log(){
  local log_info=$1

  echo "|$(date +"$TIME_FMT")|$log_info|"
}

print_err(){
  local log_info=$1

  echo "|$(date +"$TIME_FMT")|FAIL|$log_info|"
  echo "|$(date +"$TIME_FMT")|FAIL|$log_info|" >> $STATUS
}

do_cmd() {
  local cmd=$*
  local result=""

  print_log "CMD=$cmd"

  eval "$cmd"
  result=$?
  if [[ $result -ne 0 ]]; then
    print_log "$CMD FAIL. Return code is $RESULT"
    print_log "$CMD FAIL. Return code is $RESULT" >> $STATUS
    exit $result
  fi
}

fill_parm() {
  local result=0

  print_log "KERNEL_SRC:$KERNEL_SRC"
  [[ -n "$KERNEL_SRC" ]] && [[ -n "$COMMIT" ]] && [[ -n "$DEST" ]] && result=1
  print_log "result:$result"
  if [[ "$result" == 1 ]]; then
    print_log "Get parm: KERNEL_SRC=$KERNEL_SRC COMMIT=$COMMIT DEST=$DEST"
  else
    while getopts :k:m:c:d:h arg; do
      case $arg in
        k)
          KERNEL_SRC=$OPTARG
          ;;
        m)
          COMMIT=$OPTARG
          ;;
        c)
          KCONFIG=$OPTARG
          ;;
        d)
          DEST=$OPTARG
          ;;
        h)
          usage
          ;;
        *)
          usage
          ;;
      esac
    done
  fi
}

parm_check() {
  [[ -d "$DEST" ]]  || {
    print_log "DEST:$DEST folder does not exist!"
    usage
  }
  STATUS="${DEST}/status"
  cat /dev/null > $STATUS

  [[ -d "$KERNEL_SRC/.git" ]] || {
    print_err "$KERNEL_SRC doesn't contain .git folder"
    usage
  }
  [[ -n  "$COMMIT" ]] || {
    print_err "commit:$COMMIT is null."
    usage
  }
}

prepare_kernel() {
  local kernel_folder=""

  [[ -d "$KERNEL_SRC" ]] || {
    print_err "FAIL:KERNEL_SRC:$KERNEL_SRC folder does not exist"
    usage
  }
  [[ -d "$KERNEL_PATH" ]] || {
    do_cmd "rm -rf $KERNEL_PATH"
    do_cmd "mkdir -p $KERNEL_PATH"
  }

  do_cmd "cp -rf $KERNEL_SRC $KERNEL_PATH"
  # Get last kernel source like /usr/src/os.linux.intelnext.kernel/
  kernel_folder=$(echo $KERNEL_SRC | awk -F "/" '{print $NF}')
  [[ -n "$kernel_folder" ]] || {
    kernel_folder=$(echo $KERNEL_SRC | awk -F "/" '{print $(NF-1)}')
    [[ -n "$kernel_folder" ]] || {
      print_err "FAIL: kernel_folder is null:$kernel_folder"
      usage
    }
  }
  KERNEL_PATH="${KERNEL_PATH}/${kernel_folder}"
}

prepare_kconfig() {
  do_cmd "cd $KERNEL_PATH"
  do_cmd "wget $KCONFIG -O $KCONFIG_NAME"
  do_cmd "cp -rf $KCONFIG_NAME .config"
  do_cmd "git checkout -f $COMMIT"
  do_cmd "make olddefconfig"
}

make_bzimage() {
  local cpu_num=""

  cpu_num=$(cat /proc/cpuinfo | grep processor | wc -l)
  do_cmd "cd $KERNEL_PATH"
  do_cmd "make -j${cpu_num} bzImage"
  do_cmd "cp -rf ${KERNEL_PATH}/arch/x86/boot/bzImage $DEST"
  print_log "PASS: make bzImage pass"
  print_log "PASS: make bzImage pass" >> $STATUS
  echo "source_kernel:$KERNEL_SRC" >> $STATUS
  echo "target_kernel:$KERNEL_PATH" >> $STATUS
  echo "commit:$COMMIT" >> $STATUS
  echo "kconfig_source:$KCONFIG" >> $STATUS
  echo "Destination:$DEST" >> $STATUS
}

main() {
  fill_parm
  parm_check
  prepare_kernel
  prepare_kconfig
  make_bzimage
}

main
