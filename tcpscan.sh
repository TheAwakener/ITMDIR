#!/bin/bash
function main(){
	if [[ ${#@} -ne 2 ]];then
		printf "USAGE: $0 [IP_ADDRESS or DOMAIN_NAME] [SINGLE_PORT:P or PORT_LIST: P1,P2,P3...PN]\n"
		exit 1
	fi

	dserver=$1
	port_list=$2
	IFS=","
	for port in $port_list;do
		printf "$(nc -z -v -w 1 $dserver $port)"
	done

}

main ${@}
