#!/bin/bash
validator=$1
address_from=$2
address_to=$3
amt=$4
private_key=$5
log_marker=$6
if [[ -z $validator ]] || [[ -z $address_from ]] || [[ -z $address_to ]] || [[ -z $amt ]] || [[ -z $private_key ]] || [[ -z $log_marker ]]; then
	echo 'Error: please provide 6 args: validator URL, sender REV address, recepient REV address, amount of REV, sender private key, log marker'; 
	exit 1;
fi
now=$(date -u +%d-%T)
mkdir -p 'tmp/'$address_from
contract_path='tmp/'$address_from'/'$now'_deploy.rho'
deploy_result_path='tmp/'$address_from'/'$now'_deploy.result'
echo '--------Preparing script...'
echo '--------Sending' $amt 'REV from' $address_from 'to' $address_to 'via' $validator
cp rho_templates/send_rev.rho $contract_path
sed -i '' -e 's/\%to%/'$address_to'/g' $contract_path
sed -i '' -e 's/\%from%/'$address_from'/g' $contract_path
sed -i '' -e 's/\%amount\%/'$amt'/g' $contract_path
sed -i '' -e 's/\%log_marker\%/'$log_marker'/g' $contract_path
sed -i '' -e 's/\%validator\%/'$validator'/g;s/\%now\%/'$(date -u +%d-%T)'/g' $contract_path
echo '--------rnode --grpc-host' $validator 'deploy --phlo-limit 10000000000 --phlo-price 1 --private-key' $private_key $contract_path
rnode --grpc-host $validator deploy --phlo-limit 10000000000 --phlo-price 1 --private-key $private_key $contract_path > $deploy_result_path
if grep 'Response: Success!' $deploy_result_path; then
	echo '--------Succesfully deployed'
	curl -s 127.0.0.1:3000/transfer/$address_from/$address_to/$amt
    echo '--------Published TX offchain'
fi
#rnode --grpc-host $validator propose
