# Sets workspace ENV variables
#
SCRIPTPATH=$(dirname $(realpath "${BASH_SOURCE[0]}"))

# Set ENV variables
export WORKSPACE_BASE=$SCRIPTPATH
export SCRIPTS_BASE=$WORKSPACE_BASE/common/scripts
export COMMON_MAKE_SCRIPTS=$SCRIPTS_BASE/make
export PROTO_BASE=$WORKSPACE_BASE/proto
export NANOPB_BASE=$WORKSPACE_BASE/deps/optional/nanopb

# Can use the below to select a specific version of the sdk to use.
#export ZEPHYR_SDK_INSTALL_DIR=~/.local/opt/zephyr-sdk-0.17.0
#export ZEPHYR_TOOLCHAIN_VARIANT=zephyr

echo "Set WORKSPACE_BASE=$WORKSPACE_BASE"
echo "Set SCRIPTS_BASE=$SCRIPTS_BASE"
echo "Set COMMON_MAKE_SCRIPTS=$COMMON_MAKE_SCRIPTS"
echo "Set PROTO_BASE=$PROTO_BASE"
echo "Set NANOPB_BASE=$NANOPB_BASE"
