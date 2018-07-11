#!/usr/bin/env bash
set -e
set -x

# Remove $T
TARGET_USER="${T:cboudjna-osiotest1}"
REPO="https://github.com/chmouel/nodejs-health-check"

FILTERSCRIPT=$HOME/GIT/gist/os-template-filter-type/os-template-filter-type.py
APPLICATION_NAME=$(basename ${REPO})
APPLICATION_YAML=https://raw.githubusercontent.com/$(expr "${REPO}" : '.*/\([^/]*/[^/]*\)$')/master/.openshiftio/application.yaml

TMPFILE=$(mktemp /tmp/.osioev.XXXXXX)
cleanup(){ rm -f ${TMPFILE} ;}
trap cleanup EXIT

reset() {
    for i in ${TARGET_USER} ${TARGET_USER}-{run,stage};do
        oc delete all --all -n $i
    done
}

#reset

gsed 's/^/          /' Jenkinsfile > $TMPFILE
gsed -e "/@JENKINSFILE@/{r ${TMPFILE}" -e 's/^/#/' -e ';d;}' osio-pipeline-build.yaml | \
    oc process -f- APPLICATION_NAME=${APPLICATION_NAME} TARGET_USER=${TARGET_USER} | oc apply -f- -n ${T}

# Download Application yaml
curl -s -o/tmp/application.yaml -C- ${APPLICATION_YAML}

oc process -f/tmp/application.yaml SOURCE_REPOSITORY_URL=${REPO} -o json|${FILTERSCRIPT} bc is=runtime is=nodejs-health-check|oc apply -f- -n $TARGET_USER
for env in stage run;do
    oc process -f/tmp/application.yaml SOURCE_REPOSITORY_URL=${REPO} -o json|${FILTERSCRIPT} dc Route Service|oc apply -f- -n $TARGET_USER-${env}

    #We need something better
    oc delete is --all -n ${TARGET_USER}-${env}
    cat <<EOF|oc apply -f- -n ${TARGET_USER}-${env}
apiVersion: v1
kind: ImageStream
metadata:
  name: ${APPLICATION_NAME}
spec:
  tags:
    - from:
        kind: ImageStreamTag
        name: ${APPLICATION_NAME}:latest
        namespace: ${TARGET_USER}
      name: latest
EOF
    set +v
done
