
# Search up through directory tree for init script.
# args: $1 : init script name
function init_ws {
    found_init=0
    start_dir=$(pwd)
    current_dir=$(pwd)
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/$1" ]]; then
            echo "Found $1 at $current_dir, sourcing."
            source $current_dir/$1
            found_init=1
            cd $start_dir
            break
        fi
        # Move 1 directory up.
        cd ..
        #current_dir=$(dirname "$current_dir")
        current_dir=$(pwd)
    done

    if [[ $found_init == 0 ]]; then
        echo "Could not find $1 in directory tree".
        exit
    fi
}
