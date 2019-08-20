#!/bin/bash
config=$1
if [[ -z $config ]] ; then
  echo 'Error: please provide configuration file path as input argument.'; 
  exit 1;
fi
source $config

private_key=27f7d60642be28c337ddf688e72711b98af9b2f152d3fb7e9d1f4baca1be1b9a
payees_list=accounts/all.accounts
validator=$VALIDATOR_NAME_PRE$(($VALIDATORS_NUM-1))$VALIDATOR_NAME_POST
echo "Checking balances..."
deploy_filename="tmp/get_batch_balances.rho"
[ -e $deploy_filename ] && rm $deploy_filename
i=0
while read user; do
  i=$((i+1))
  stringarray=($user)
  privkey=${stringarray[0]}
  pubkey=${stringarray[1]}
  wallet=${stringarray[2]}
  sed 's/\%address\%/'$wallet'/g;s/\%log_marker\%/'$log_marker'/g;s/\%validator\%/'$validator'/g;s/\%now\%/'$(date -u +%d-%T)'/g' rho_templates/get_balance.rho  >> $deploy_filename
  echo '|' >> $deploy_filename
done < $payees_list
sed -i '' -e '$ d' $deploy_filename
#sed -i '$d' $deploy_filename
rnode --grpc-host $validator deploy --private-key=$private_key --phlo-limit 10000000000000 --phlo-price 1 $deploy_filename
#rnode --grpc-host $validator propose
