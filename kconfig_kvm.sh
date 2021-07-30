#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# It's a tool which could convert any kconfig file for QEMU or syzkaller test

FILE_SRC=$1
CONFIG_ITEM=$2
CONFIG_CHANGE=$3
FILE_KVM="${FILE_SRC}_kvm"
FIND_CONFIG_LINE=""

usage(){
  cat <<__EOF
  usage: ./${0##*/}  [kconfig_file]
__EOF
  exit 2
}

find_config_line() {
  local config_item=$1
  local find_item=""
  local num=""

  FIND_CONFIG_LINE=""
  find_item=$(cat $FILE_SRC | grep "${config_item}=" | head -n 1)
  if [[ -n "$find_item" ]]; then
    num=$(cat $FILE_SRC | grep "${config_item}=" | wc -l)
    [[ "$num" == "1" ]] || \
      echo "WARN: find ${config_item}= nums not 1:$num"
  else
    find_item=$(cat $FILE_SRC | grep "${config_item} is" | head -n 1)
    if [[ -n "$find_item" ]]; then
      num=$(cat $FILE_SRC | grep "${config_item} is" | wc -l)
      [[ "$num" == "1" ]] || \
        echo "WARN: find '${config_item} is' nums not 1:$num"
    else
        echo "WARN: could not find $config_item in $FILE_SRC"

    fi
  fi
  FIND_CONFIG_LINE=$find_item
}

change_kconfig() {
  local config_item=$1
  local config_target=$2
  local config_item_solve=""

  if [[ "$config_item" == *"="* ]]; then
    echo "$config_item contain ="
    config_item_solve=$(echo $config_item | cut -d '=' -f 1)
  else
    config_item_solve=$config_item
  fi

  find_config_line "$config_item_solve"
  if [[ -z "$FIND_CONFIG_LINE" ]]; then
    echo "echo $config_target >> $FILE_KVM"
    echo "$config_target" >> $FILE_KVM
  else
    if [[ "$FIND_CONFIG_LINE" == "$config_target" ]]; then
      echo "|$FIND_CONFIG_LINE| is same as target |$config_target|"
    else
      echo "sed -i 's/${FIND_CONFIG_LINE}/${config_target}/g' $FILE_KVM"
      sed -i s/"${FIND_CONFIG_LINE}"/"${config_target}"/g $FILE_KVM
    fi
  fi
}

convert_kconfig() {
  diff_content=""

  [[ -z "$FILE_SRC" ]] && usage
  [[ -e "$FILE_SRC" ]] || {
    echo "No FILE_SRC:$FILE_SRC exist"
    usage
  }
  echo "cp -rf $FILE_SRC $FILE_KVM"
  cp -rf $FILE_SRC $FILE_KVM

  if [[ -n "$CONFIG_CHANGE" ]]; then
    change_kconfig "$CONFIG_ITEM" "$CONFIG_CHANGE"
  else
    # syzkaller coverage collection
    change_kconfig "CONFIG_KCOV" "CONFIG_KCOV=y"
    change_kconfig "CONFIG_KCOV_INSTRUMENT_ALL" "CONFIG_KCOV_INSTRUMENT_ALL=y"
    change_kconfig "CONFIG_KCOV_ENABLE_COMPARISONS" "CONFIG_KCOV_ENABLE_COMPARISONS=y"
    change_kconfig "CONFIG_DEBUG_FS" "CONFIG_DEBUG_FS=y"
    change_kconfig CONFIG_CONFIGFS_FS	"CONFIG_CONFIGFS_FS=y"
    change_kconfig CONFIG_SECURITYFS	"CONFIG_SECURITYFS=y"
    # set boot cmdline net.ifnames=0
    change_kconfig CONFIG_CMDLINE_BOOL	"CONFIG_CMDLINE_BOOL=y"
    change_kconfig CONFIG_CMDLINE "CONFIG_CMDLINE=\"net.ifnames=0\""
    change_kconfig CONFIG_RANDOMIZE_BASE "# CONFIG_RANDOMIZE_BASE is not set"
    # syzkaller reduce false positive rate
    change_kconfig CONFIG_DEFAULT_HUNG_TASK_TIMEOUT	"CONFIG_DEFAULT_HUNG_TASK_TIMEOUT=140"
    change_kconfig CONFIG_RCU_CPU_STALL_TIMEOUT	"CONFIG_RCU_CPU_STALL_TIMEOUT=100"
    # Some disk issue for bzImage
    change_kconfig CONFIG_BLK_DEV_RAM	"CONFIG_BLK_DEV_RAM=y"
    change_kconfig CONFIG_NFS_FS	"CONFIG_NFS_FS=y"
    change_kconfig CONFIG_NFS_V2	"CONFIG_NFS_V2=y"
    change_kconfig CONFIG_NFS_V3	"CONFIG_NFS_V3=y"
    change_kconfig CONFIG_NFS_V4	"CONFIG_NFS_V4=y"
    change_kconfig CONFIG_ROOT_NFS	"CONFIG_ROOT_NFS=y"
    change_kconfig CONFIG_9P_FS		"CONFIG_9P_FS=y"
    change_kconfig CONFIG_EXT4_FS	"CONFIG_EXT4_FS=y"
    change_kconfig CONFIG_VIRTIO_BLK	"CONFIG_VIRTIO_BLK=y"
    change_kconfig CONFIG_VIRTIO_PCI	"CONFIG_VIRTIO_PCI=y"
    change_kconfig CONFIG_X86_CPUID		"CONFIG_X86_CPUID=y"
    # QEMU net work for bzImage
    change_kconfig CONFIG_E100		"CONFIG_E100=y"
    change_kconfig CONFIG_E1000		"CONFIG_E1000=y"
    change_kconfig CONFIG_E1000E	"CONFIG_E1000E=y"
    change_kconfig CONFIG_8139TOO	"CONFIG_8139TOO=y"
    change_kconfig CONFIG_R8169		"CONFIG_R8169=y"
    change_kconfig CONFIG_REALTEK_PHY	"CONFIG_REALTEK_PHY=y"
    change_kconfig CONFIG_USB_NET_DRIVERS	"CONFIG_USB_NET_DRIVERS=y"
    change_kconfig CONFIG_MOUSE_PS2		"CONFIG_MOUSE_PS2=y"
    change_kconfig CONFIG_FRAME_WARN	"CONFIG_FRAME_WARN=2048"
    # Solve "Failed to mount /proc/sys/fs/binfmt_misc." issue in bzImage
    change_kconfig CONFIG_BINFMT_MISC "CONFIG_BINFMT_MISC=y"
    change_kconfig CONFIG_QFMT_V2 "CONFIG_QFMT_V2=y"
    # mark kernel as kvm for syzkaller or kvm test
    change_kconfig CONFIG_LOCALVERSION "CONFIG_LOCALVERSION=\"-kvm\""
  fi
  echo "diff $FILE_SRC $FILE_KVM"
  diff_content=$(diff $FILE_SRC $FILE_KVM 2>/dev/null)
  echo "$diff_content"
}

convert_kconfig
