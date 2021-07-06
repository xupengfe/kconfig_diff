#!/bin/bash

echo "KERNEL_SRC='/usr/src/os.linux.intelnext.kernel/'; COMMIT="b4019cd2af8b57528c4b9fc5999c1636ed4cc5ea";DEST="/root/target"; ./make_bzimage.sh"
export KERNEL_SRC="/usr/src/os.linux.intelnext.kernel/"; export COMMIT="b4019cd2af8b57528c4b9fc5999c1636ed4cc5ea"; export DEST="/root/target";echo "DEST:$DEST";./make_bzimage.sh
