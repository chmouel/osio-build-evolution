#!/bin/bash
set -e
set -x

# Remove $T
TARGET_USER="${T:cboudjna-osiotest1}"
#REPO="https://github.com/chmouel/nodejs-ex"
#REPO="https://github.com/chmouel/nodejs-health-check"
REPO="https://github.com/chmouel/node-todo"

reset() {
    for i in ${TARGET_USER} ${TARGET_USER}-run ${TARGET_USER}-stage;do
#        for t in configmap is pvc secrets bc service istag route dc;do
#            oc delete $t --all -n $i
#        done
        oc delete all --all -n $i
    done
}

#reset

oc process -f osio-pipeline-build.yaml TARGET_USER=$TARGET_USER \
   SOURCE_REPOSITORY_URL=${REPO}|oc apply -n ${TARGET_USER} -f-

oc process -f osio-pipeline-run.yaml TARGET_USER=$TARGET_USER \
   |oc apply -n ${TARGET_USER}-stage -f-

oc process -f osio-pipeline-run.yaml TARGET_USER=$TARGET_USER \
   |oc apply -n ${TARGET_USER}-run -f-
