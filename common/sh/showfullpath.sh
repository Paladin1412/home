#!/bin/bash

source $SH/mycommon.sh

function my_entry {
	path_tocheck=$1
	if [[ -z $path_tocheck ]]; then
		echo "Usage:   ${0##*/} <path>"
		exit 1;
	fi


	cd $path_tocheck
	pwd -P
}

main $@
