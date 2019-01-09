#!/bin/bash

###############################################
# Set bash global option
###############################################
set -o posix
set -o pipefail
shopt -s expand_aliases
shopt -s extglob
shopt -s xpg_echo
shopt -s extdebug

###############################################
# global variables
typeset g_appname

##############################################
function DBG {
	[[ "${MYDBG^^}" != "DEBUG" ]] && return 0
	typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
	printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${arg}" >&2
}
function LOG {
	typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
	printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${arg}"
}
function ERR {
	typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
	printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "ERROR: ${arg}" >&2
}
function WARN {
	typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
	printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "WARN: ${arg}" >&2
}
function MSG {
	typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
	printf "%s\n" "${arg}"
}
##############################################
alias BCS_CHK_RC0='{ 
	#### function check RC Block Begin #####
	RET=$?
	if [[ ${RET} -ne 0 ]]; then
		MSG=$(cat -); ERR "${MSG}, RET=${RET}"; return "${RET}"
	fi
	#### function check RC Block End #####
}<<<' 
alias BCS_CHK_ACT_RC0='{
    #### function check RC Block Begin #####
    RET=$?; INPUTSTR=$(cat -); MSG="${INPUTSTR%%&&&*}"; ACT=""
    [[ "${MSG}" != "${INPUTSTR}" ]] && ACT="${INPUTSTR##*&&&}"
	NGACT="${ACT%%|||*}"; OKACG=""
    [[ "${NGACT}" != "${ACT}" ]] && OKACG="${ACT##*|||}"
    if [[ ${RET} -ne 0 ]]; then
        eval "${NGACT}"
        ERR "${MSG}, RET=${RET}"
		return ${RET}
    else
        eval "${OKACT}"
    fi
    #### function check RC Block End #####
}<<<' 
alias BCS_WARN_RC0='{ 
	#### function check RC Block Begin #####
	RET=$?
	if [[ ${RET} -ne 0 ]]; then
		MSG=$(cat -)
		WARN "${MSG}, RET=${RET}"
	fi
	#### function check RC Block End #####
}<<<'
alias BCS_WARN_ACT_RC0='{
    #### function check RC Block Begin #####
    RET=$?; INPUTSTR=$(cat -); MSG="${INPUTSTR%%&&&*}"; ACT=""
    [[ "${MSG}" != "${INPUTSTR}" ]] && ACT="${INPUTSTR##*&&&}"
	NGACT="${ACT%%|||*}"; OKACG=""
    [[ "${NGACT}" != "${ACT}" ]] && OKACG="${ACT##*|||}"
    if [[ ${RET} -ne 0 ]]; then
        eval "${NGACT}"
        WARN "${MSG}, RET=${RET}"
    else
        eval "${OKACT}"
    fi
    #### function check RC Block End #####
}<<<' 
##############################################

function show_usage {
	cat - <<EOF
Usage: ${g_appname##*/} [-d] [-l <PCAR_URL>]
	-l : URL for pcar
	-d : Debug mode
Example:
	${g_appname##*/} -l http://xxxxx/xxxx/xxx.pcar
EOF
}

function sendmsg_block {
	[[ "$MYDBG" != "block" ]] && return 1
	typeset msg
	[[ -z "$1" ]] && msg="All actions have been done." || msg="$1"
	msg="[$(date +'%Y%m%d_%H%M%S')] ${msg}"
	#cmd /c msg \* /time:3 $msg
	cmd /c msg \* /V /W /time:0 "${msg}"
	return 0
}

############################################################
function main {
	DBG "BASH_SOURCE: ${BASH_SOURCE[*]}"
	DBG "BASH_ARGV: ${BASH_ARGV[*]}"
	############################################
	if [[ "$0" =~ ^(/bin/bash|/bin/sh|\-bash)$ && -n "${BASH_SOURCE[0]}" ]]; then
		DBG "in shell source mode: $0 $@"
	else
		DBG "in normal mode: [$0] $@"
		#export SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"
	fi
	export SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	export g_apppath=${SCRIPTDIR}
	export g_appname=$(basename ${BASH_SOURCE[0]})

	# set debug
	unset OPTIND
	while getopts :l:n:N:T:dh ch; do
		DBG "ch=$ch"
		case $ch in
		"d") export MYDBG=DEBUG;;
		"n") export STACKNAME="${OPTARG}";;
		"N") export OLDSTACKNAME="${OPTARG}";;
		"T") export ACT_SCOPE="${OPTARG}";; ##debug purpose
		"l") export PCARURL="${OPTARG}";;
		"h") show_usage; return 0;;
		*) LOG "wrong parameter $ch"; return 1;;
		esac
	done
	shift $((OPTIND-1))
	DBG "g_appname=$g_appname"
	DBG "g_apppath=$g_apppath"
	DBG "\$@=$@"
	############################################
	export MYDBG="block"
	#param="bcsmats0808 bej301167"
	#param="bcsmats0808 slc15sfu"
	#param="dh0903wade slc15sfu_pod"
	param="dh0903wadepod05 slc15sfu_pod"
	typeset expect_status="INITIALIZING"
	#typeset expect_status="TERMINATING"
	#typeset expect_status="STARTING"
	psmhost=${param##* }
	typeset stack_name=${param%% *}
	while true; do
		st=$(ssh bej301712 "cd /nfs/users/zhaozhan/bcs/psmenv.cvs; . ./setenv.prov.sh ${stack_name} ${psmhost}; ./bcs.sh stk info status" | tail -1)
		LOG "st=$st"
		[[ "${st}" != "${expect_status}" ]] && sendmsg_block "provision finished with status=${st}" && return 0
		sleep 30
	done
	############################################ 
	return $RET
} 

###########################################
main ${@:+"$@"}

