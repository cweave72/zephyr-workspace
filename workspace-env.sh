# Sets workspace ENV variables
#
SCRIPTPATH=$(dirname $(realpath "${BASH_SOURCE[0]}"))

# Set ENV variables
export WORKSPACE_BASE=$SCRIPTPATH
export TOOLS_BASE=$WORKSPACE_BASE/common/tools
export PROTO_BASE=$WORKSPACE_BASE/proto

# Can use the below to select a specific version of the sdk to use.
#export ZEPHYR_SDK_INSTALL_DIR=~/.local/opt/zephyr-sdk-0.17.0
#export ZEPHYR_TOOLCHAIN_VARIANT=zephyr

echo "Set WORKSPACE_BASE=$WORKSPACE_BASE"
echo "Set TOOLS_BASE=$TOOLS_BASE"
echo "Set PROTO_BASE=$PROTO_BASE"
