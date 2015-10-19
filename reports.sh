#!/bin/bash
## change it to location of reports.config
source /etc/zabbix/reports/config
function catch_input() {
case $2 in
	text)
		echo -ne "${1} "
		read -r text
		[[ "${text}" == "" ]] && return 1 || return 0	
	;;
	password)
		echo -ne "${1}"
		read -rs password
		[[ "${password}" == "" ]] && return 1 || return 0
	;;
	*)
		echo -ne "${1}"
		read -r decision
		case $decision in
			[Yy]) return 0;;
			*) return 1;;
		esac
	;;

esac
}
export -f catch_input
function usage {
export silent=1
cookie check
case $? in
        0) echo "usage $0: [ generate | checkcookie | cookie ]";;
        1) catch_input "No cookie file was found!\nDo you want to get cookie now?\t [Y/n]\t" && cookie get||echo "Bye";; 
        2) catch_input "No cookie in file!\nDo you want to get cookie now?\t [Y/n]\t" && cookie get||echo "Bye";;
esac
}

function get_graph {
wget -4 --load-cookies=${cookieFile} -O ${tempdir}/${1}.jpg "${ZabbixHost}/chart2.php?graphid=${1}&width=${2}&period=$(eval echo \$${Period})" 1>/dev/null 2>&1
}

function main {
export silent=1
cookie check
case $? in
	1) echo "no file, aborting" && exit 1;;
	2) echo "no cookie in file" && exit 2;;
esac
exit 0
for ReportName in `ls ${basedir}/enabled`; do
	source ${basedir}/enabled/${ReportName};

##Check type of reports and skip it if need##

	case ${Type} in
		weekly) [[ $(date '+%u') -ne '1' ]] && continue;;
		monthly) [[ $(date '+%d') -ne $(date -d "-$(date +%d) days  month" +%d) ]] && continue;;
		custom) [[ $(( $(date '+%d') % ${Cycle} )) = 0 ]] || continue;;
	esac

## donload images if they need ##

	for graphid in ${Graphs}; do
	get_graph `echo ${graphid}|awk -F\: '{ print $1" "(length($2)<"2"?"900":$2)" "(length($3)<"2"?"150":$3)}'` 
	done

## Processing email ##
source ${templates}/${Body}
MakeBody|${SendMail}
	unset -v Type Graphs From SendTo Subject Body Period Cycle
done
}

case ${1} in
	generate) main;;
	checkcookie)	check_cookie;;
	cookie)	cookie ${2} ${3};;
	*) usage;;
esac
