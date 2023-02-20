#!/bin/sh
set -eu
verbose=${verbose-''}

if [ "${verbose}" = "yes" ]; then
        set -x
fi

interface="eth1"
sync_wait_stop=5
sync_wait_start=1
this_host=$(hostname)
host=${this_host}

function usage () {
    cat <<EOF >/dev/stderr
Usage:
    $0 --start -i <ethX> [--host <hostname>]
    $0 --stop [--host <hostname>]
    $0 --kill [--host <hostname>]
Start tcpdump saving output to /tmp/
Stop tcpdump and dump captured output to the console
Kill tcpdump
Specify --host to only run on <hostname>.
EOF
}

if test $# -lt 1; then
	usage
	exit 1
fi

OPTIONS=$(getopt -o h,i: --long help,host:,start,stop,kill -- "$@")
if (( $? != 0 )); then
    err 4 "Error calling getopt"
fi

eval set -- "$OPTIONS"

while true; do
	case "$1" in
		-h | --help )
                        usage
                        exit 0
                        shift
                        ;;
		--host )
			host=$2
			shift 2
			;;
		-i )
			interface=$2
			shift 2
			;;
		--start )
			action="start"
			shift
			;;
		--stop )
			action="stop"
			shift
			;;
		--kill )
			action="kill"
			shift
			;;
		* )
			shift
			break
			;;
	esac
done

function set_file_names()
{
	tmp_dir=/tmp
	testname=$(basename ${PWD})
	out_path="${tmp_dir}/${host}.${testname}.tcpdump.pcap"
	log_path="${tmp_dir}/${host}.${testname}.tcpdump.log"
	pid_path="${tmp_dir}/${host}.${testname}.tcpdump.pid"
}

function start_tcpdump()
{
	# call stop if there are any previous runawy tcpdump
	stop_tcpdump
	rm -f ${out_path}
	rm -f ${log_path}
	rm -f ${pid_path}
	tcpdump -s 0 -i ${interface} -w ${out_path} > ${log_path} 2>&1 &
	echo $! > ${pid_path}
	sleep ${sync_wait_start}
	echo tcpdump started
}

function stop_tcpdump()
{
    if test -r ${pid_path} ; then
	pid=$(cat ${pid_path})
	if kill -TERM ${pid} ; then
	    # wait for tcpudump output to write and sync
	    sleep 1
	    while kill -0 ${pid} > /dev/null 2>&1 ; do
		sleep 1
	    done
	    cp ${out_path} OUTPUT/
	    cp ${log_path} OUTPUT/
	    rm -f ${pid_path}
	    echo tcpdump stopped
	fi
    else
	echo tcpdump is not running
    fi
}

if [ "${host}" != "${this_host}" ]; then
	exit 0
fi

set_file_names

case "${action}" in
    start)
	start_tcpdump
	;;
    stop)
	stop_tcpdump
	tcpdump -n -r ${out_path} not arp and not icmp6 and not stp
	;;
    kill)
	stop_tcpdump
	;;
esac
