#!/usr/bin/env bash

SCRIPT_NAME=$(basename "$0")

function usage()
{
  echo "$SCRIPT_NAME [-h] [-n]"
  echo
  echo "  arguments:"
  echo "   -h: show this help text"
  echo "   -n: dry run mode"
  echo "       (default: run commands)"
  echo
  echo " env vars:"
  echo "   required:"
  echo "   TOR_FULL_GIT_PATH: where the git repository directories reside."
  echo "       You must set this env var, we recommend \$HOME/git/"
  echo "       (default: fail if this env var is not set;"
  echo "       current: $GIT_PATH)"
  echo
  echo "   optional:"
  echo "   TOR_MASTER: the name of the directory containing the tor.git clone"
  echo "       The tor master git directory is \$GIT_PATH/\$TOR_MASTER"
  echo "       (default: tor; current: $TOR_MASTER_NAME)"
  echo "   TOR_WKT_NAME: the name of the directory containing the tor"
  echo "       worktrees. The tor worktrees are:"
  echo "       \$GIT_PATH/\$TOR_WKT_NAME/{maint-*,release-*}"
  echo "       (default: tor-wkt; current: $TOR_WKT_NAME)"
  echo "   we recommend that you set these env vars in your ~/.profile"
}

#################
# Configuration #
#################

# Don't change this configuration - set the env vars in your .profile

# Where are all those git repositories?
GIT_PATH=${TOR_FULL_GIT_PATH:-"FULL_PATH_TO_GIT_REPOSITORY_DIRECTORY"}
# The tor master git repository directory from which all the worktree have
# been created.
TOR_MASTER_NAME=${TOR_MASTER_NAME:-"tor"}
# The worktrees location (directory).
TOR_WKT_NAME=${TOR_WKT_NAME:-"tor-wkt"}

##########################
# Git branches to manage #
##########################

# Configuration of the branches that need pulling. The values are in order:
#   (1) Branch name to pull (update).
#   (2) Full path of the git worktree.
#
# As an example:
#   $ cd <PATH/TO/WORKTREE> (3)
#   $ git checkout maint-0.3.5 (1)
#   $ git pull
#
# First set of arrays are the maint-* branch and then the release-* branch.
# New arrays need to be in the WORKTREE= array else they aren't considered.
MAINT_029=( "maint-0.2.9" "$GIT_PATH/$TOR_WKT_NAME/maint-0.2.9" )
MAINT_035=( "maint-0.3.5" "$GIT_PATH/$TOR_WKT_NAME/maint-0.3.5" )
MAINT_040=( "maint-0.4.0" "$GIT_PATH/$TOR_WKT_NAME/maint-0.4.0" )
MAINT_041=( "maint-0.4.1" "$GIT_PATH/$TOR_WKT_NAME/maint-0.4.1" )
MAINT_042=( "maint-0.4.2" "$GIT_PATH/$TOR_WKT_NAME/maint-0.4.2" )
MAINT_MASTER=( "master" "$GIT_PATH/$TOR_MASTER_NAME" )

RELEASE_029=( "release-0.2.9" "$GIT_PATH/$TOR_WKT_NAME/release-0.2.9" )
RELEASE_035=( "release-0.3.5" "$GIT_PATH/$TOR_WKT_NAME/release-0.3.5" )
RELEASE_040=( "release-0.4.0" "$GIT_PATH/$TOR_WKT_NAME/release-0.4.0" )
RELEASE_041=( "release-0.4.1" "$GIT_PATH/$TOR_WKT_NAME/release-0.4.1" )
RELEASE_042=( "release-0.4.2" "$GIT_PATH/$TOR_WKT_NAME/release-0.4.2" )

# The master branch path has to be the main repository thus contains the
# origin that will be used to fetch the updates. All the worktrees are created
# from that repository.
ORIGIN_PATH="$GIT_PATH/$TOR_MASTER_NAME"

# SC2034 -- shellcheck thinks that these are unused.  We know better.
ACTUALLY_THESE_ARE_USED=<<EOF
${MAINT_029[0]}
${MAINT_035[0]}
${MAINT_040[0]}
${MAINT_041[0]}
${MAINT_042[0]}
${MAINT_MASTER[0]}
${RELEASE_029[0]}
${RELEASE_035[0]}
${RELEASE_040[0]}
${RELEASE_041[0]}
${RELEASE_042[0]}
EOF

###########################
# Git worktrees to manage #
###########################

# List of all worktrees to work on. All defined above. Ordering is important.
# Always the maint-* branch first then the release-*.
WORKTREE=(
  MAINT_029[@]
  RELEASE_029[@]

  MAINT_035[@]
  RELEASE_035[@]

  MAINT_040[@]
  RELEASE_040[@]

  MAINT_041[@]
  RELEASE_041[@]

  MAINT_042[@]
  RELEASE_042[@]

  MAINT_MASTER[@]
)
COUNT=${#WORKTREE[@]}

#######################
# Argument processing #
#######################

# Controlled by the -n option. The dry run option will just output the command
# that would have been executed for each worktree.
DRY_RUN=0

while getopts "hn" opt; do
  case "$opt" in
    h) usage
       exit 0
       ;;
    n) DRY_RUN=1
       echo "    *** DRY DRUN MODE ***"
       ;;
    *)
       echo
       usage
       exit 1
       ;;
  esac
done

#############
# Constants #
#############

# Control characters
CNRM=$'\x1b[0;0m'   # Clear color

# Bright color
BGRN=$'\x1b[1;32m'
BBLU=$'\x1b[1;34m'
BRED=$'\x1b[1;31m'
BYEL=$'\x1b[1;33m'
IWTH=$'\x1b[3;37m'

# Strings for the pretty print.
MARKER="${BBLU}[${BGRN}+${BBLU}]${CNRM}"
SUCCESS="${BGRN}ok${CNRM}"
FAILED="${BRED}failed${CNRM}"

####################
# Helper functions #
####################

# Validate the given returned value (error code), print success or failed. The
# second argument is the error output in case of failure, it is printed out.
# On failure, this function exits.
function validate_ret
{
  if [ "$1" -eq 0 ]; then
    printf "%s\\n" "$SUCCESS"
  else
    printf "%s\\n" "$FAILED"
    printf "    %s" "$2"
    exit 1
  fi
}

# Switch to the given branch name.
function switch_branch
{
  local cmd="git checkout $1"
  printf "  %s Switching branch to %s..." "$MARKER" "$1"
  if [ $DRY_RUN -eq 0 ]; then
    msg=$( eval "$cmd" 2>&1 )
    validate_ret $? "$msg"
  else
    printf "\\n      %s\\n" "${IWTH}$cmd${CNRM}"
  fi
}

# Pull the given branch name.
function merge_branch
{
  local cmd="git merge --ff-only origin/$1"
  printf "  %s Merging branch origin/%s..." "$MARKER" "$1"
  if [ $DRY_RUN -eq 0 ]; then
    msg=$( eval "$cmd" 2>&1 )
    validate_ret $? "$msg"
  else
    printf "\\n      %s\\n" "${IWTH}$cmd${CNRM}"
  fi
}

# Go into the worktree repository.
function goto_repo
{
  if [ ! -d "$1" ]; then
    echo "  $1: Not found. Stopping."
    exit 1
  fi
  cd "$1" || exit
}

# Fetch the origin. No arguments.
function fetch_origin
{
  local cmd="git fetch origin"
  printf "  %s Fetching origin..." "$MARKER"
  if [ $DRY_RUN -eq 0 ]; then
    msg=$( eval "$cmd" 2>&1 )
    validate_ret $? "$msg"
  else
    printf "\\n      %s\\n" "${IWTH}$cmd${CNRM}"
  fi
}

# Fetch tor-github pull requests. No arguments.
function fetch_tor_github
{
  local cmd="git fetch tor-github"
  printf "  %s Fetching tor-github..." "$MARKER"
  if [ $DRY_RUN -eq 0 ]; then
    msg=$( eval "$cmd" 2>&1 )
    validate_ret $? "$msg"
  else
    printf "\\n      %s\\n" "${IWTH}$cmd${CNRM}"
  fi
}

###############
# Entry point #
###############

# First, fetch tor-github.
goto_repo "$ORIGIN_PATH"
fetch_tor_github

# Then, fetch the origin.
fetch_origin

# Go over all configured worktree.
for ((i=0; i<COUNT; i++)); do
  current=${!WORKTREE[$i]:0:1}
  repo_path=${!WORKTREE[$i]:1:1}

  printf "%s Handling branch %s\\n" "$MARKER" "${BYEL}$current${CNRM}"

  # Go into the worktree to start merging.
  goto_repo "$repo_path"
  # Checkout the current branch
  switch_branch "$current"
  # Update the current branch by merging the origin to get the latest.
  merge_branch "$current"
done
