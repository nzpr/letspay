#!/bin/bash
config=$1
if [[ -z $config ]] ; then
  echo 'Error: please provide configuration file path as input argument.'; 
  exit 1;
fi
source $config

#Validator to deploy genesis vaults creation
validator=$VALIDATOR_NAME_PRE$(($VALIDATORS_NUM-1))$VALIDATOR_NAME_POST
#private key to sign deploys (doesn't really matter which to use until cost accounting is finished)
private_key=bd2946a79be97625b86c09510a48aa037905c408a73fc672f19068dc58c550ee
#accounts file path. Account is a tuple <private key> <public key> <wallet>
all_list=accounts/all.accounts
#payers file path
payers_list=accounts/payers.accounts
#payees file path
payees_list=accounts/payees.accounts

#creating working folders
mkdir -p tmp
mkdir -p out
mkdir -p accounts
mkdir -p logs

echo "Starting LetsPay for" $payers_qty "payers and" $payees_qty "payees..."
echo "Creating users..."
#Generate keypairs
./generate_users.sh $users_qty $all_list

#Split accounts between payers and payees
head -$payers_qty $all_list > $payers_list
tail -$payees_qty $all_list > $payees_list

echo "Creating vaults with Revs for payers..."
[ -e offchain/offchain.db ] && rm offchain/offchain.db
offchain_sql="CREATE TABLE balances (address TEXT PRIMARY KEY, balance INT); Insert into balances(address,balance) values "
deploy_filename="tmp/batch_create_genesis_vault.rho"
[ -e $deploy_filename ] && rm $deploy_filename
i=0
while read user; do
	i=$((i+1))
	stringarray=($user)
	privkey=${stringarray[0]}
	pubkey=${stringarray[1]}
	wallet=${stringarray[2]}
	init_balance=100000
	offchain_sql=$offchain_sql"('$wallet',"$init_balance"),"
	sed 's/\%address\%/'$wallet'/g;s/\%balance\%/'$init_balance'/g;s/\%validator\%/'$validator'/g;s/\%now\%/'$(date -u +%d-%T)'/g;s/\%log_marker\%/'$log_marker'/g' rho_templates/create_genesis_vault.rho >> $deploy_filename
	echo '|' >> $deploy_filename
done < $payers_list
sed -i '' -e '$ d' $deploy_filename
#sed -i '$d' $deploy_filename
rnode --grpc-host $validator deploy --private-key=$private_key --phlo-limit 10000000000000 --phlo-price 1 $deploy_filename
#rnode --grpc-host $validator propose

echo ${offchain_sql%?}";" > tmp/offchain.sql
#echo ${offchain_sql::-1}";" > tmp/offchain.sql
touch offchain/offchain.db
sqlite3 offchain/offchain.db < tmp/offchain.sql

echo "Starting offchain analytics..."
tmux kill-session -t offchain
cd offchain; tmux new-session -d -s offchain npm start
echo "Sleeping $start_payments_delay before starting payments..."

sleep $start_payments_delay
cd ../
echo "Starting payers with delay $start_payer_delay..."
i=0
while read user; do
	i=$((i+1))
	stringarray=($user)
	privkey=${stringarray[0]}
	pubkey=${stringarray[1]}
 	wallet=${stringarray[2]}
	cmd="./letspay.sh $wallet $privkey $payees_list $config"
	sleep $start_payer_delay
	echo "Starting" $cmd
	tmux new-session -d -s $i $cmd
done < $payers_list
