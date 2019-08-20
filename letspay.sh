#!/bin/bash
my_addr=$1
private_key=$2
payeesfile=$3
config=$4

source $config
#every $next_payment_delay
while [ 1 ]; do
	#send some REV to random address (from known network users) via every validator
	for i in $( seq 1 $VALIDATORS_NUM ); do
		i=$((i-1))
		payee=$(eval "shuf -n 1 $payeesfile")
		payee_tuple=($payee)
		address_to=${payee_tuple[2]}
		validator_url=$VALIDATOR_NAME_PRE$i$VALIDATOR_NAME_POST #validator url
		echo "----Deploying payment to" $address_to "to" $validator_url "..."
		echo "----./sendrev.sh $validator_url $my_addr $address_to 2 $private_key $log_marker"
		./sendrev.sh $validator_url $my_addr $address_to 2 $private_key $log_marker
		echo "----Done..."
		echo ""
	done
	echo "Sleep $next_payment_delay..."
	sleep $next_payment_delay
done
