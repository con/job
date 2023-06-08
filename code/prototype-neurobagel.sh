#!/bin/sh

set -eux

neurobagel_annotations=../openneuro-annotations
code_path=../../CON/job/code/

# TODO: replace with the variables
upstream_remote_name=upstream  # could be openneuro to be more descriptive
orig_org=OpenNeuroDatasets
our_org=$orig_org-JSONLD

ds="$1"

repo_exists(){
    response=$(curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/repos/$1")
    case "$response" in
      404)
        return 1;;
      200)
        return 0;;
      *)
        echo "Unknown response upon check: $response"
        return $response ;;
    esac
}

# Once

if [ ! -e $ds ]; then
(
# 1. fork https://github.com/OpenNeuroDatasets to https://github.com/OpenNeuroDatasets-JSONLD
set +e
repo_exists "OpenNeuroDatasets-JSONLD/$ds" 
case $? in
  1)
    gh repo fork --org OpenNeuroDatasets-JSONLD OpenNeuroDatasets/$ds --clone=false;;
  0)
    ;;
  *)
    echo "Unknown response upon check: $response"
    exit 1 ;;
esac
set -e
git clone https://github.com/OpenNeuroDatasets/$ds
)
fi

# Add our remote
(
cd $ds
if ! git remote | grep -q jsonld; then 
    while !repo_exists "OpenNeuroDatasets-JSONLD/$ds"; do
        echo "waiting for the fork to come into our embrace"
        sleep 1
    done
    git remote add --fetch jsonld https://github.com/OpenNeuroDatasets-JSONLD/$ds
fi
)


# Every time
(
cd $ds

# Update our jsonld fork, to be done regularly
git fetch origin
if [ ! -e .git/refs/heads/upstream/master ]; then
    # TODO: just update-ref, no need for checkout
    git checkout -b upstream/master --track origin/master
    if [ ! -e .git/refs/heads/jsonld/upstream/master ] || git diff upstream/master^..jsonld/upstream/master | grep -q .; then
        git push -u jsonld upstream/master
    fi
else
    git checkout upstream/master
    # may be not --ff-only -- may be just  reset --hard.
    # For now get alerted when isn't possible
    git merge --ff-only origin/master
    git push jsonld upstream/master
fi

# KISS attempt #1: just embed results from the neurobagel tool which were pre-generated
git checkout master
# We need to update to the state of the upstream/master entirely, and only enhance one file
git merge -s ours --no-commit upstream/master && git read-tree -m -u upstream/master
# Run our super command
if [ -e participants.json ]; then
    action="Updated"
else
    action="Added"
fi

$code_path/update_json participants.json $neurobagel_annotations/${ds}.json
git add .
if [ -z "$(git status --porcelain)" ]; then
    echo "Clean -- no changes, boring"
else
    git commit -m "$action participants.json"
    git push jsonld master
fi
)
