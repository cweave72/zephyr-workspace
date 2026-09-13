# List of workspace repositories that init_workspace.sh operates on.
#
# init_workspace.sh sources this file. Add a repository here when the
# workspace manifest gains one. Each entry is a path relative to the
# workspace root.
#
# This file supplies a list only. Do not run it.

MAIN_REPOS=(
    applications
    common
    proto
    python
)
