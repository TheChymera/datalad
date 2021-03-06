#!/bin/sh

set -e

# BOILERPLATE

BOBS_HOME=$(readlink -f $(mktemp -d datalad_demo.XXXX))
ALICES_HOME=$(readlink -f $(mktemp -d datalad_demo.XXXX))

#% EXAMPLE START
#
# A typical data management workflow
# **********************************

# In this demo we will look at how datalad can be used in a rather common data
# management workflow: A 3rd-party dataset is obtained to serve as input for an
# analysis. The data processing is then collaboratively performed by two
# colleagues. Upon completion the results are published alongside the original
# data for further consumption.
#
# Build atop 3rd-party data
# =========================
#
# Now, meet Bob. Bob has just started in the lab and has never used the version
# control system Git_ before. The first thing he does, is to configure his
# identity as it will be used to track changes in the datasets he will be
# working with.  This step only needs to be done once on his first day in the
# lab.
#%

# enter Bob's home directory
HOME=$BOBS_HOME
cd ~
git config --global --add user.name Bob
git config --global --add user.email bob@example.com

#%
# After this initial setup, Bob is ready to go and can create his first
# :term:`dataset`.
#%

datalad create myanalysis --description "my phd in a day"
cd myanalysis

#%
# A datalad dataset can contain other datasets. As any content of a dataset is
# tracked and its precise state is recorded, this is a powerful method to
# specify and later resolve data dependencies. In this example, Bob wants to
# work with structural MRI data from the `studyforrest project`_, a public
# brain imaging data resource. These data are made available through GitHub_,
# so Bob can simply install the relevant dataset from this service and into
# his own dataset.
#
# .. _studyforrest project: http://studyforrest.org
# .. _github: https://github.com
#%

datalad install --source https://github.com/psychoinformatics-de/studyforrest-data-structural.git src/forrest_structural
#datalad install --source /tmp/studyforrest-data-structural src/forrest_structural

#%
# Bob has decided to collect all data inputs for his project in a subdirectory
# ``src/``, to make it obvious which parts of his analysis steps and code
# require 3rd-party data. Upon completion of the above command, Bob has now
# access to the entire dataset content. However, no data was actually
# downloaded (yet). Datalad datasets primarily contain information on a
# dataset's content and where to obtain it, hence the installation above was
# done rather quickly, and will still be relatively lean even for a dataset
# that contains several hundred GBs of data.
#
# For his first steps Bob just needs a single file of the dataset. In order to
# make it available locally, Bob can use the install command again, and datalad
# will obtain it from a remote data provider.
#%

datalad install src/forrest_structural/sub-01/anat/sub-01_T1w.nii.gz
# just test data for now, could be
#datalad install src/forrest_structural/sub-*/anat/sub-*_T1w.nii.gz

#%
# Although we originally installed the dataset from Github, the actual data is
# hosted elsewhere. Datalad supports multiple redundant data providers per each
# file in a dataset, and will transparently attempt to obtain data from an
# alternative location if a particular data provider is not available.
#
# Bob wants his analysis to be easily reproducible, and therefore manages his
# analysis scripts in the same dataset repository as the input data. Managing
# input data, analysis code, and results the same version control system
# creates a precise record of what version of code and input data was used to
# create which particular results. Datalad datasets are regular Git_
# repositories and therefore provide the same powerful source code management
# features, as any other Git_ repository, and make them available for data too.
#
# .. _Git: https://git-scm.com
#
# Bob decided to adopt the convention to collect all of his analysis code in a
# subdirectory ``code/`` in the root of his dataset. His first "analysis" script
# is rather simple:
#%

mkdir code
echo "nib-ls src/forrest_structural/sub-*/anat/sub-*_T1w.nii.gz > result.txt" > code/run_analysis.sh

#%
# In order to, definitively, document which data file his analysis needs at this point, Bob creates a second script that can (re-)obtain the required files.
#%

echo "datalad install src/forrest_structural/sub-01/anat/sub-01_T1w.nii.gz" > code/get_required_data.sh

#%
# In the future, this won't be necessary anymore as datalad itself will be able
# to record this information upon request.
#
# At this point Bob is satisfied with his initial progress. He wants to record
# this precise state. In order to do that, Bob needs to make his just created
# scripts a part of his dataset. Again the ``install`` command is used for this
# purpose. However, Bob doesn't just want datalad to track these files and
# facilitate future downloads. He wants all Git_ features for working with
# them, so he adds them directly to the Git repository underlying his dataset.
#%

# add all content in the code/ directory
datalad install --recursive yes --add-data-to-git code

#%
# At this point, datalad is aware of all changes that were made to the dataset
# and Bob wants to record. Specifically, this is the input dataset, and the
# scripts in ``code/``. Bob can now save the dataset state and assign a
# human-readable message to it, in order to document the purpose of the changes
# he made.
#%

datalad save -m "Initial analysis setup"

#%
# As Bob's analysis is completely scripted, he can now run it in full, and
# also add the generated results to the dataset.
#%

bash code/get_required_data.sh
bash code/run_analysis.sh

# add generated results to dataset
datalad install result.txt

datalad save -m "First analysis results"

#%
# Local collaboration
# ===================
#
# Some time later, Bob needs help with his analysis. He turns to his colleague
# Alice for help. Alice and Bob both work on the same computing server. Alice
# initially went through a similar configuration procedure of her Git identity
# as Bob.
#% 

HOME=$ALICES_HOME
cd
git config --global --add user.name Alice
git config --global --add user.email alice@example.com

#%
# Bob has told Alice in which directory he keeps his analysis dataset. The
# colleagues' directories are configured to have permissions that allow for
# read-access for all lab-member, so Alice can obtain Bob's work directly
# from his home directory.
#%
# TODO: needs to get --description to avoid confusion
datalad install --source $BOBS_HOME/myanalysis bobs_analysis

#%
# At this point, Alice has a complete copy of Bob's entire dataset in the exact
# same state that Bob last saved. She is free to make any changes without
# affecting Bob's version of the dataset. Initially, the dataset is as
# lightweight as possible. For example, the studyforrest-structural dataset
# is empty. Alice can tell datalad to make this :term:`subdataset` available.
# For this step, Alice doesn't need to know that Bob originally got it from
# Github, datalad manages this automatically.
#%

cd bobs_analysis
# make all subdatasets available
datalad install --recursive yes .

#%
# With the script Bob created, Alice can obtain all required data content. Datalad
# knows that necessary file is available in Bob's version of the dataset on the same machine, so it won't even attempt to download it from its original location.
#%

bash code/get_required_data.sh

#%
# Likewise, Alice can use datalad to obtain the results that Bob had generated.
#%

datalad install result.txt
#cat result.txt

#%
# She can modify Bob's code to help him with his analysis...
#%

echo "file -L src/forrest_structural/sub-*/anat/sub-*_T1w.nii.gz > result.txt" > code/run_analysis.sh

#%
# ... and execute it.
#%
# `|| true` is only there for the purpose of testing this script
bash code/run_analysis.sh || true

#%
# However, when she performs actions that attempt to modify data files managed by
# datalad she will get an error. Datalad, by default, prevents modification of
# data file. If modification is desired (as in this case), datalad can *unlock*
# individual files, or the entire dataset. Afterwards modifications are
# possible.
#%

# unlock the entire dataset
datalad unlock
bash code/run_analysis.sh

#%
# Once Alice is satisfied with her modifications she can save the new state.
#%
# -a make datalad auto-detect modifications
datalad save -a -m "Alice always helps"

#%
# Full circle
# ===========

# Now that Alice has improved Bob's analysis, Bob wants to obtain the changes
# she made. To achieve that, he registers Alice's version of the dataset as a
# :term:`sibling`. As  both are working on the same machine, Bob can just point
# to the respective directory, but it would also be possible to refer to a
# dataset via an http URL, or an SSH login and path.
#%

HOME=$BOBS_HOME
cd ~/myanalysis
datalad add-sibling alice $ALICES_HOME/bobs_analysis

#%
# Once registered, Bob can update his dataset based on Alice's version, and merge
# here changes with his own.
#%

datalad update alice --merge

#%
# He can, once again, use the ``install`` command to obtain the latest version
# of data files to get access to data contributed by Alice.
#%

datalad install result.txt

#%
# Going public
# ============

# Lastly, let's assume that Bob completed his analysis and he is ready to share
# the results with the world, or a remote collaborator. One way to make
# datasets available, is to upload them to a webserver via SSH. Datalad
# supports this by creating a :term:`sibling` for the dataset on the server,
# to which the dataset can by published (repeatedly).
#%

# Fake an SSH server on this machine for the purpose of this demo
SERVER_URL="localhost:$(readlink -f $(mktemp --tmpdir -u -d datalad_demo_testpub.XXXX))"
# this generated sibling for the dataset and all subdatasets
datalad create-publication-target-sshwebserver --recursive $SERVER_URL public

#%
# Once the remote sibling is created and registered under the name "public",
# Bob can publish his version to it.
#%

datalad publish -r --to public .

#%
# This command can be repeated as often as desired. Datalad checks the state
# of both the local and the remote sibling and transmits the changes.
#%

#% EXAMPLE END

testEquality() {
  assertEquals 1 1
}

[ -n "$DATALAD_RUN_CMDLINE_TESTS" ] && . shunit2 || true
