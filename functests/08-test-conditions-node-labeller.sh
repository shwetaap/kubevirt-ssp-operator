#!/bin/bash

SCRIPTPATH=$( dirname $(readlink -f $0) )
source ${SCRIPTPATH}/testlib.sh

[ -z ${KV_NAMESPACE} ] && exit 127

RET=0
TEST_NS="${KV_NAMESPACE}"

oc create -n ${TEST_NS} -f "${SCRIPTPATH}/node-labeller-unversioned-cr.yaml" || exit 2
# TODO: SSP-operator needs to improve its feedback mechanism
# fetching node-labeller images may take a while

wait_node_labeller_running ${TEST_NS} 5 60

#wait for ssp operator to set proper conditions
sleep 15s

if [ $(oc get KubevirtNodeLabellerBundle -o json | jq  '.items[0].status.conditions[] | select((.type=="Progressing") and (.status="False")) | .type' | wc -l) -eq 0 ]; then
	echo "Progressing condition is not set to false"
	RET=1
	exit $RET
fi

if [ $(oc get KubevirtNodeLabellerBundle -o json | jq  '.items[0].status.conditions[] | select((.type=="Available") and (.status="True")) | .type' | wc -l) -eq 0 ]; then
	echo "Available condition is not set to true"
	RET=1
	exit $RET
fi

oc delete -n ${TEST_NS} -f "${SCRIPTPATH}/node-labeller-unversioned-cr.yaml" || exit 2

exit $RET
