#!/bin/bash

FILE1=$1
FILE2=$2
DEF_ITEM=$3

usage() {
  cat <<__EOF
  usage: ./${0##*/}  [file1] [file2] [column_num(optional)]
  column_num: (optional) default num is 1
__EOF
  exit 2
}

[[ -z "$DEF_ITEM" ]] && DEF_ITEM=1

diff_cases() {
  local file1_ori=$1
  local file2_ori=$2
  local column=$3
  local file_a="${file1_ori}_1st.log"
  local file_b="${file2_ori}_2nd.log"
  local file_ab="${file1_ori}_${file2_ori}.log"
  local file_ab_s="${file1_ori}_${file2_ori}_s.log"
  local cases=""
  local case=""
  local check=""
  local num=0

  [[ -e "$file1_ori" ]] || {
    echo "No file:$file1_ori exist"
    usage
  }
  [[ -e "$file2_ori" ]] || {
    echo "No compared file:$file2_ori exist"
    usage
  }

  echo "Check $file1_ori has but $file2_ori doesn't have items."
  awk -F " " '{print $'$column'}' "$file1_ori" | grep -v "-" > "$file_a"
  awk -F " " '{print $'$column'}' "$file2_ori" | grep -v "-" > "$file_b"
  cat /dev/null > "$file_ab"
  cases=$(cat "$file_a")
  for case in $cases; do
    check=$(grep "$case"$ "$file_b")
    if [[ -z "$check" ]]; then
      echo "$case | $file1_ori($file_a) contains, $file2_ori($file_b) doesn't contain"
      echo "$case | $file1_ori($file_a) contains, $file2_ori($file_b) doesn't contain" >> "$file_ab"
      ((num++))
    fi
  done
  cut -d " " -f 1 "$file_ab" > "$file_ab_s"
  echo "$num cases in total changed, please check $file_ab or $file_ab_s"
  cat "$file_ab_s" | tr '\n' ' '
  #cat "$file_ab_s"
  echo
  echo "------ Done ------"
  echo
}

diff_cases "$FILE1" "$FILE2" "$DEF_ITEM"
diff_cases "$FILE2" "$FILE1" "$DEF_ITEM"
