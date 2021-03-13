#!/bin/bash

function main(){
	if [[ ${#@} -ne 2 ]];then
		printf "USAGE: $0 [IP_ADDRESS or DOMAIN_NAME] [PORT_RANGE: N1,N2]"
		exit 1
	fi

	lport=$(echo $2 | cut -d "," -f 1)
	hport=$(echo $2 | cut -d "," -f 2)
	dserver=$1

	for port in $(seq $lport $hport);do
		printf "$(nc -z -v -w 1 $dserver $port)"
	done

}

main ${@}
