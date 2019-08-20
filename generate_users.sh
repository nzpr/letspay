users_qty=$1
keys_list=$2
echo "Generating" $users_qty "keys..."
python3.7 genkey.py $users_qty > $keys_list
echo "Done."
