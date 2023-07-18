# kconfig_diff
It could check kconfig difference between kconfig1 and kconfig2, which better
than diff file1 file2 results.
config_kvm_i is config_itest!

# ./kconfig_diff.sh config1 config_kvm

Command manually test:
./kconfig_kvm.sh   config_thomas  CONFIG_LOCALVERSION CONFIG_LOCALVERSION=\"-aaa\"
Script way:
./kconfig_kvm.sh config_thomas \"CONFIG_LOCALVERSION\" CONFIG_LOCALVERSION=\\\"-${commit_short}\\\"

...
--------------Summary--------------
Only exist in config1 items in only1, 5423 items.
config1 changed to config_kvm in change12, 2164 items.
Only exist in config_kvm items in only2, 69 items.
