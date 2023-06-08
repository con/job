#!/bin/sh

neurobagel_annotations=.../TODO
code_path=../code

ds=ds000113

# Once

if [ ! -e $ds ]; then
(
# 1. fork https://github.com/OpenNeuroDatasets to https://github.com/OpenNeuroDatasets-JSONLD
if ! gh check-exists https://github.com/OpenNeuroDatasets-JSONLD/$ds; then
    gh fork https://github.com/OpenNeuroDatasets/$ds https://github.com/OpenNeuroDatasets-JSONLD/$ds
fi

git clone https://github.com/OpenNeuroDatasets/$ds
cd $ds
git remote add --fetch jsonld https://github.com/OpenNeuroDatasets-JSONLD/$ds
)
fi


# Every time
(
cd $ds

# Update our jsonld fork, to be done regularly
git fetch origin
if [ ! -e .git/refs/heads/upstream/master ]; then
    git checkout -b upstream/master --track origin/master
    git push -u jsonld upstream/master
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
$code_path/update_json participants.json $neurobagel_annotations/openneuro_${ds}.json
git add -r .
git commit -m 'Updated participants.json'
)
