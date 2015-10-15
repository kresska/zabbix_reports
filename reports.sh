#!/bin/bash
## change it to location of reports.config
source /etc/zabbix/reports/config

function cookie {
${bindir}/zcookie $@
}

function get_graph {
wget -4 --load-cookies=${cookieFile} -O ${tempdir}/${1}.jpg "${ZabbixHost}/chart2.php?graphid=${1}&width=${2}&period=$(eval echo \$${Period})" 1>/dev/null 2>&1
}

function main {
cd ${tempdir}
for ReportName in `ls ${basedir}/enabled`; do
	source ${basedir}/enabled/${ReportName};

##Check type of reports and skip it if need##

	case ${Type} in
		weekly) [[ $(date '+%u') -ne '1' ]] && continue;;
		monthly) [[ $(date '+%d') -ne $(date -d "-$(date +%d) days  month" +%d) ]] && continue;;
		custom) [[ $(( $(date '+%d') % ${Cycle} )) = 0 ]] || continue;;
	esac

## donload images if they need ##

	for graphid in {$Graphs}; do
	get_graph `echo ${graphid}|awk -F\: '{ print $1" "(length($2)<"2"?"900":$2)" "(length($3)<"2"?"150":$3)}'` 
	done

## create mail body and sendit! ##
echo start
source ${templates}/${Body}
echo "here we are!"
MakeBody|SendMail
echo end
	unset -v Type Graphs SendTo Subject Body Period Cycle
done
}

case ${1} in
	generate) main;;
	checkcookie)	check_cookie;;
	cookie)	cookie ${2} ${3};;
esac
