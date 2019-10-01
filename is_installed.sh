#! /bin/bash

while true; do \
	kubectl -n default get installation/kyma-installation -o jsonpath="{'Status: '}{.status.state}{', description: '}{.status.description}"; echo; \
	sleep 5; \
done
