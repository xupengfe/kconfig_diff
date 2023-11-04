#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# It's a tool which could show difference between 2 kconfig files

FILE1=$1
FILE2=$2

ONLY1="only1"
ONLY2="only2"
CHANGE12="change12"
DIFF_FILE12="diff_file1_file2"
DIFF1="diff1"
DIFF2="diff2"
ERR_LOG="error.log"

usage(){
  cat <<__EOF
  usage: ./${0##*/}  [kconfig1_file] [kconfig2_file]
__EOF
  exit 2
}

compare_diff2() {
  local obj=$1
  local target=$2
  local fil_diff2=""
  local fil_diff2_eq=""
  local fil_diff2_is=""
  local check_same=""

  # If diff1 and diff2 have all the same item, will remove it in only2 and return
  check_same=$(cat $DIFF2 | grep ^"$obj")
  [[ -z "$check_same" ]] || {
    sed -i "s/^$obj//g" $ONLY2
    return 0
  }

  # obj: "CONFIG_XX=X"  or "# CONFIG_XX is not set", target: "CONFIG_XX"
  fil_diff2=$(cat $DIFF2 | grep "$target")
  fil_diff2_eq=$(echo "$fil_diff2" | grep "${target}=")

  if [[ -z "$fil_diff2" ]]; then
    echo "$obj" >> $ONLY1
  else
    if [[ -n "$fil_diff2_eq" ]]; then
      # echo "find fil_diff2_eq:$fil_diff2_eq in diff2"
      echo "$obj -> $fil_diff2_eq" >> $CHANGE12
      # echo "sed -i s/^$fil_diff2_eq\n//g $ONLY2"
      sed -i "s/^$fil_diff2_eq//g" $ONLY2
    else
      fil_diff2_is=$(echo "$fil_diff2" | grep "${target} is")
      if [[ -n "$fil_diff2_is" ]]; then
        # echo "find fil_diff2_is:$fil_diff2_is in diff2"
        echo "$obj -> $fil_diff2_is" >> $CHANGE12
        sed -i "s/^$fil_diff2_is//g" $ONLY2
      else
        # echo "Find $target in diff2 but not include 'is' or '=':$fil_diff2."
        echo "$obj" >> $ONLY1
      fi
    fi
  fi
}

show_diff() {
  local all_diff=""
  local items=""
  local item=""
  local it=""
  local num=""
  local err_num=0

  [[ -z "$FILE1" ]] || [[ -z "$FILE2" ]] && usage
  [[ -e "$FILE1" ]] || {
    echo "No FILE1:$FILE1 exist"
    usage
  }
  [[ -e "$FILE2" ]] || {
    echo "No FILE2:$FILE2 exist"
    usage
  }

  cat /dev/null > $ONLY1
  cat /dev/null > $ONLY2
  cat /dev/null > $CHANGE12
  cat /dev/null > $ERR_LOG

  diff "$FILE1" "$FILE2" > "$DIFF_FILE12"
  all_diff=$(cat "$DIFF_FILE12")
  [[ -n "$all_diff" ]] || {
    echo "$FILE1 $FILE2 all the same, no diff:$all_diff"
    exit 0
  }

  grep "^<" "$DIFF_FILE12" \
    | grep "CONFIG" \
    | awk -F "< " '{print $2}' \
    > $DIFF1
  # sed -i 's/^# //g' $DIFF1

  grep "^>" "$DIFF_FILE12" \
    | grep "CONFIG" \
    | awk -F "> " '{print $2}' \
    > $DIFF2
  # sed -i 's/^# //g' $DIFF2
  cp -rf $DIFF2 $ONLY2

  items=$(cat "$DIFF1")

  IFS=$'\n'
  for item in $items; do
    it=""
    [[ "$item" == *"="* ]] && {
      it=$(echo "$item" | cut -d '=' -f 1)
      compare_diff2 "$item" "$it"
      continue
    }

    [[ "$item" == *"is not"* ]] && {
      it=$(echo "$item" \
        | awk -F " is not set" '{print $1}' \
        | awk -F "# " '{print $NF}')
      compare_diff2 "$item" "$it"
      continue
    }
    echo "ERROR: No keyword 'is not' or '=' in item:$item" && ((err_num++))
    echo "ERROR: No keyword 'is not' or '=' in item:$item" >> "$ERR_LOG"
  done

  sed -i "/^[  ]*$/d" $ONLY2
  echo "ONLY1:"
  cat "$ONLY1"
  echo "$CHANGE12:"
  cat "$CHANGE12"
  echo "$ONLY2:"
  cat "$ONLY2"

  echo "--------------Summary--------------"
  num=$(cat $ONLY1 | wc -l)
  echo "Only exist in \"$FILE1\" items in \"$ONLY1\": $num items."
  num=$(cat $CHANGE12 | wc -l)
  echo "\"$FILE1\" changed to \"$FILE2\" in \"$CHANGE12\": $num items."
  num=$(cat $ONLY2 | wc -l)
  echo "Only exist in \"$FILE2\" items in \"$ONLY2\": $num items."
  [[ "$err_num" -eq 0 ]] || {
    echo "There is unexpected error! err_num:$err_num, please check $ERR_LOG!"
    exit 1
  }
}

show_diff
