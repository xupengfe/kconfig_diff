#!/bin/bash

BASE_PATH=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
export PATH="${PATH}:${BASE_PATH}"

SET_FAIL_LOG="set_kconfig_fail.log"

usage(){
  cat <<__EOF
  usage: ./${0##*/}  [-f kconfig_file] [-l KCONFIG list need to change]
  -f  Kconfig_file
  -k  KERNEL source folder(optional, if NA, will not double check)
  -l  KCONFIG list need to change, content like "CONFIG_ARCH_TEGRA=y"
  -h  show this
__EOF
  exit 2
}

change_kconfigs() {
  local klists=""
  local kconfig=""

  [[ -e "$FILE_SRC" ]] || {
    usage
  }
  [[ -e "$KLIST_FILE" ]] || {
    usage
  }

  mv $SET_FAIL_LOG "${SET_FAIL_LOG}_bak"
  klists=$(cat $KLIST_FILE)

  for kconfig in $klists; do
    if [[ -z "$KER_SRC" ]]; then
      echo "kconfig_change.sh -f $FILE_SRC -t $kconfig"
      kconfig_change.sh -f "$FILE_SRC" -t "$kconfig"
    else
      echo "kconfig_change.sh -f $FILE_SRC -k $KER_SRC -t $kconfig"
      kconfig_change.sh -f "$FILE_SRC" -k "$KER_SRC" -t "$kconfig"
    fi
    ret=$?
    if [[ "$ret" -ne 0 ]]; then
      echo "  -> [FAIL] Set $kconfig failed!!!!"
      echo "$kconfig failed" >>  "$SET_FAIL_LOG"
    else
      echo "  -> [PASS] Set $kconfig PASS!!!!"
    fi
    cp -rf "$FILE_CHANGE" "$FILE_SRC"
    echo " ----- end -----"
  done
}

while getopts :f:k:l:h arg; do
  case $arg in
    f)
      FILE_SRC=$OPTARG
      ;;
    k)
      # KER_SRC is optional, if it's null, this script will not double check
      KER_SRC=$OPTARG
      ;;
    l)
      KLIST_FILE=$OPTARG
      ;;
    h)
      usage
      ;;
    *)
      usage
      ;;
  esac
done

FILE_CHANGE="${FILE_SRC}_change"

change_kconfigs
