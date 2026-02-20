#!/bin/sh

CONFIG="network_limiter"
SECTION="main"

load_config() {
	TC=$(uci get ${CONFIG}.${SECTION}.tc)
	IF=$(uci get ${CONFIG}.${SECTION}.interface)
	DNLD=$(uci get ${CONFIG}.${SECTION}.download)
	UPLD=$(uci get ${CONFIG}.${SECTION}.upload)
	LTN=$(uci get ${CONFIG}.${SECTION}.latency)
	BRT=$(uci get ${CONFIG}.${SECTION}.burst)
	IFB=$(uci get ${CONFIG}.${SECTION}.ifb)
}

start() {

	tc qdisc del dev $IF root 2>/dev/null
	tc qdisc del dev $IF ingress 2>/dev/null
	tc qdisc del dev $IFB root 2>/dev/null

	$TC qdisc add dev $IF root tbf rate $UPLD burst $BRT latency $LTN

	if test -z "$(lsmod | grep ifb)"; then
		modprobe ifb
	fi

	if test -z "$(ip link | grep $IFB)"; then
		ip link add name $IFB type ifb
		ip link set dev $IFB up
	fi

	$TC qdisc add dev $IFB root handle 1: htb r2q 1
	$TC class add dev $IFB parent 1: classid 1:1 htb rate $DNLD
	$TC filter add dev $IFB parent 1: matchall flowid 1:1

	$TC qdisc add dev $IF ingress
	$TC filter add dev $IF ingress matchall action \
		mirred egress redirect dev $IFB
}

stop() {
	$TC qdisc del dev $IF root
	$TC qdisc del dev $IF ingress
	$TC qdisc del dev $IFB root
}

restart() {
	stop
	sleep 1
	start
}

show() {
	$TC -s qdisc show dev $IF
	$TC -s class show dev $IF
	$TC -s filter show dev $IF
	$TC -s class show dev $IFB
	$TC -s class show dev $IFB
	$TC -s class show dev $IFB
}

load_config

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
	echo "Bandwidth shaping status for $IF and $IFB:"
	show
	echo ""
	;;
  *)
	pwd=$(pwd)
	echo "Usage: tc.bash {start|stop|restart|show}"
	;;
esac

exit 0