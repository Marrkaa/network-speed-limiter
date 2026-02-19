#!/bin/bash

TC=/sbin/tc
IF=enp1s0
DNLD=1mbit
UPLD=1mbit
IP=192.168.1.248
LTN=400ms
BRT=32kbit

start() {
	$TC qdisc add dev $IF root tbf rate $UPLD burst $BRT latency $LTN

	if test -z "$(lsmod | grep ifb)"; then
		modprobe ifb
	fi

	if test -z "$(ip link | grep ifb0)"; then
		ip link add name ifb0 type ifb
		ip link set dev ifb0 up
	fi

	$TC qdisc add dev ifb0 root handle 1: htb r2q 1
	$TC class add dev ifb0 parent 1: classid 1:1 htb rate $DNLD
	$TC filter add dev ifb0 parent 1: matchall flowid 1:1

	$TC qdisc add dev $IF ingress
	$TC filter add dev $IF ingress matchall action \
		mirred egress redirect dev ifb0
}

stop() {
	$TC qdisc del dev $IF root
	$TC qdisc del dev $IF ingress
	$TC qdisc del dev ifb0 root
}

restart() {
	stop
	sleep 1
	start
}

show() {
	$TC -s qdisc ls dev $IF
}

case "$1" in
  start)
	echo -n "Starting bandwidth shaping: "
	start
	echo "done"
	;;
  stop)
	echo -n "Stopping bandwidth shaping: "
	stop
	echo "done"
	;;
  restart)
	echo -n "Restarting bandwidth shaping: "
	restart
	echo "done"
	;;
  show)
	echo "Bandwidth shaping status for $IF:"
	show
	echo ""
	;;
  *)
	pwd=$(pwd)
	echo "Usage: tc.bash {start|stop|restart|show}"
	;;
esac

exit 0