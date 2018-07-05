#!/bin/bash
set -e
set -x

TARGET_USER="cboudjna-osiotest1"
REPO="https://github.com/chmouel/nodejs-ex"

reset() {
    for i in ${TARGET_USER} ${TARGET_USER}-run ${TARGET_USER}-stage;do
        oc delete all --all -n $i
    done
}

reset

oc process -f osio-pipeline-build.yaml SOURCE_REPOSITORY_URL=${REPO}|oc create -n ${TARGET_USER} -f-

oc process -f osio-pipeline-run.yaml AUTOMATIC_DEPLOY=true|oc create -n ${TARGET_USER}-stage -f-

oc process -f osio-pipeline-run.yaml AUTOMATIC_DEPLOY=false|oc create -n ${TARGET_USER}-run -f-
