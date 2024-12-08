# Sets workspace ENV variables
#
SCRIPTPATH=$(dirname $(realpath "${BASH_SOURCE[0]}"))

export WORKSPACE_BASE=$SCRIPTPATH
export TOOLS_BASE=$WORKSPACE_BASE/common/tools
#export ZEPHYR_SDK_INSTALL_DIR=~/.local/opt/zephyr-sdk-0.16.8
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr

echo "Set WORKSPACE_BASE=$WORKSPACE_BASE"
echo "Set TOOLS_BASE=$TOOLS_BASE"
