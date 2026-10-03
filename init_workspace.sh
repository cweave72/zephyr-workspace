#!/bin/bash
# This script is run once from a clean workspace to pull Zephyr source.
# Source init_venv.sh to activate the venv or recreate it.

SCRIPTPATH=$(dirname $(realpath "${BASH_SOURCE[0]}"))

# MAIN_REPOS comes from this file. Add a repository there, not here.
if [ ! -f "$SCRIPTPATH/main_repos.sh" ]; then
    echo "Error: $SCRIPTPATH/main_repos.sh not found."
    exit 1
fi
source "$SCRIPTPATH/main_repos.sh"

help() {
  cat << EOF
usage: $0 [OPTIONS]
    Initialize the workspace after a clean checkout or --reset.

    Options:
    -h, --help           Show this message
    --init               Run init steps.
    --venv               Update the python virtualenv.
    -m, --main           Switch the workspace repos to the main branch.
    -r, --reset          Reset the venv, the west metadata, and generated files.
                         Does not delete deps/ or any repo.
    --reset-deps         Delete deps/. west clones the external code again.
EOF
}

ask() {
  while true; do
    read -p "$1 ([y]/n) " -r
    REPLY=${REPLY:-"y"}
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      return 1
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
      return 0
    fi
  done
}

function init_venv {
    # The python packages build their protobuf bindings and need PROTO_BASE.
    source "$SCRIPTPATH/workspace-env.sh" >/dev/null
    source init_venv.sh
    if [ ! $? -eq 0 ]; then
        echo "Exiting after error."
        return 1
    fi
}

# The full venv needs python/ (a path dependency), and west clones python/.
# Install only west first, so west can clone the repos. init_venv then syncs
# everything.
function bootstrap_west {
    if [ ! -d "$SCRIPTPATH/.venv" ]; then
        uv venv --python ">=3.10" || { echo "Error creating virtual env."; return 1; }
    fi
    uv pip install --python "$SCRIPTPATH/.venv/bin/python" "west>=0.14.0" || return 1
    source "$SCRIPTPATH/.venv/bin/activate"
}

function west_steps {
    echo "Running west init"
    west init --local manifest-repo || {
        echo "Error: 'west init' failed. Stopping."; return 1; }

    echo "Running west update"
    west update || {
        echo "Error: 'west update' failed. Stopping."; return 1; }

    echo "Running west zephyr-export"
    west zephyr-export || {
        echo "Error: 'west zephyr-export' failed. Stopping."; return 1; }
}

# Needs the full venv (requests), so run it after init_venv.
function fetch_blobs {
    echo "Fetching esp32 blobs."
    west blobs fetch hal_espressif || {
        echo "Error: 'west blobs fetch' failed. Stopping."; return 1; }
}

# Reports uncommitted changes and unpushed commits in each workspace repo.
# Returns 1 when it finds either one.
function check_repos {
    local found=0
    local repo changes unpushed count

    for repo in "${MAIN_REPOS[@]}"; do
        if [ ! -d "$SCRIPTPATH/$repo/.git" ]; then
            continue
        fi

        changes=$(git -C "$SCRIPTPATH/$repo" status --porcelain 2>/dev/null)
        if [ -n "$changes" ]; then
            count=$(echo "$changes" | wc -l)
            echo "  $repo: $count uncommitted file(s)"
            found=1
        fi

        # Fails when the branch has no upstream. Discard that error.
        unpushed=$(git -C "$SCRIPTPATH/$repo" log --oneline @{u}.. 2>/dev/null)
        if [ -n "$unpushed" ]; then
            count=$(echo "$unpushed" | wc -l)
            echo "  $repo: $count unpushed commit(s)"
            found=1
        fi
    done

    return $found
}

function reset {
    echo "Deleting:"
    echo "    .venv/     (--init or init_venv.sh creates it again)"
    echo "    .west/     (--init creates it again)"
    echo "    cscope.*, tags, *.log"
    rm -rf .venv/ .west/
    rm -f cscope.* tags *.log
    echo "Reset complete. Run '$0 --init' to build the workspace again."
}

function reset_deps {
    echo "Deleting deps/. west clones the external code again, which is slow."
    rm -rf deps/
    echo "Run '$0 --init' to clone the external code again."
}

function switch_main {
    local failed=()
    local repo

    for repo in "${MAIN_REPOS[@]}"; do
        if [ ! -d "$SCRIPTPATH/$repo/.git" ]; then
            echo "Skipping $repo: not a git repository."
            continue
        fi

        echo "Switching $repo to main."
        if ! git -C "$SCRIPTPATH/$repo" fetch; then
            echo "  Error: fetch failed."
            failed+=("$repo")
            continue
        fi
        if ! git -C "$SCRIPTPATH/$repo" checkout main; then
            echo "  Error: checkout failed. The repo may have local changes."
            failed+=("$repo")
        fi
    done

    if [ ${#failed[@]} -ne 0 ]; then
        echo "These repos are not on main: ${failed[*]}"
        return 1
    fi

    echo "All repos are on the main branch."
}

do_init=0
do_reset=0
reset_wks=0
reset_deps_opt=0
do_main=0
do_update_venv=0

# Handle script arguments and options.
leftoverargs=()
for arg in "$@"; do
    case $arg in
        --init)
            do_init=1
            ;;
        --venv)
            do_update_venv=1
            ;;
        -r|--reset)
            reset_wks=1
            ;;
        --reset-deps)
            reset_deps_opt=1
            ;;
        -m|--main)
            do_main=1
            ;;
        -h|--help)
            help
            exit 0
            ;;
        *)
            leftoverargs+=("$arg")
            shift
            ;;
    esac
done

if [[ $reset_wks == 1 || $reset_deps_opt == 1 ]]; then
    echo "This does not delete any repo: ${MAIN_REPOS[*]}"
    echo "Checking those repos for work that is not saved:"
    if check_repos; then
        echo "    None found."
    fi
    echo ""
    ask "Do you really want to reset the workspace?"
    do_reset=$?
fi

if [[ $do_reset == 1 ]]; then
    if [[ $reset_wks == 1 ]]; then
        reset
    fi
    if [[ $reset_deps_opt == 1 ]]; then
        reset_deps
    fi
fi

if [[ $do_init == 1 ]]; then
    ask "Do you really want to init the workspace?"
    if [[ $? == 1 ]]; then
        bootstrap_west && west_steps && init_venv && fetch_blobs
    fi
fi

if [[ $do_update_venv == 1 ]]; then
    echo "Updating python virtual env."
    rm -rf .venv/
    init_venv
fi

if [[ $do_main == 1 ]]; then
    switch_main
fi
