#!/bin/sh

UART_DEVICE=/dev/ttySAC1
UART_SPEED=3000000
BT_CHIP_TYPE=bcm43xx

function gen_bd_addr {
	[ -d /opt/.bd_addr ] || rm -f /opt/.bd_addr

	macaddr=$(dd if=/dev/urandom bs=1024 count=1 2>/dev/null|md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/00:\1:\2:\3:\4:\5/')
	echo $macaddr > /opt/.bd_addr
	chmod 400 /opt/.bd_addr
	sync
}

for x in $(cat /proc/cmdline); do
	case $x in
	bd_addr=*)
		BD_ADDR=${x#bd_addr=}
		;;
	esac
done

if [ "$BD_ADDR" == "" ]; then
	if [ ! -f "/opt/.bd_addr" ]; then
		gen_bd_addr ${ARTIK_DEV}
	fi

	BD_ADDR=`cat /opt/.bd_addr`
	if [ "$BD_ADDR" == "" ]; then
		gen_bd_addr ${ARTIK_DEV}
		BD_ADDR=`cat /opt/.bd_addr`
	fi
fi

pushd `dirname $0`

./brcm_patchram_plus --patchram BCM4345C0_003.001.025.0111.0205.hcd \
	--no2bytes --baudrate $UART_SPEED \
	--use_baudrate_for_download $UART_DEVICE \
	--enable_lpm \
	> /dev/null

/usr/bin/hciattach $UART_DEVICE -s $UART_SPEED $BT_CHIP_TYPE $UART_SPEED flow
