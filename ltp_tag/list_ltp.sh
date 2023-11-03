#!/bin/bash

FILE=$1
OUTPUT_FILE="./ltp"

list_ltp_cases() {
  local file=$1
  local cases=""
  local case=""
  local real_case=""

  cat /dev/null > "$OUTPUT_FILE"

  [[ -e "$file" ]] || {
    echo "No cases file:$file"
    exit 1
  }
  echo "Check file:$file"
  cases=$(cat "$file")
  for case in $cases; do
    real_case=""
    real_case=$(grep -r "^${case} "  ./* | head -n 1 | awk -F ":"  '{print $2}')
    if [[ -z "$real_case" ]]; then
      real_case=$(grep -r "^${case}	"  ./* | head -n 1 | awk -F ":"  '{print $2}')
      if [[ -z "$real_case" ]]; then
        echo "[WARN] No case:$case"
        continue
      fi
    fi
    #echo  "$real_case >> $OUTPUT_FILE"
    echo "$real_case" >> "$OUTPUT_FILE"
  done

  echo "List all ltp cases into $OUTPUT_FILE, done."
}

list_ltp_cases "$FILE"
