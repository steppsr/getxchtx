<<<<<<< HEAD
#!/bin/bash

path=~/sourcecode/taxtran

curl -s -X POST --insecure --cert ~/.chia/mainnet/config/ssl/wallet/private_wallet.crt --key ~/.chia/mainnet/config/ssl/wallet/private_wallet.key -H "Accept: application/json" -H "Content-Type: application/json" "https://localhost:9256/get_transactions" -d '{"wallet_id":1,"start":0,"end":99999}' | python3 -m json.tool | grep -E 'name' | cut --fields 4 --delimiter=\" | cut -c 3- > trans_id_list.txt

=======
#/!bin/bash

path=~/sourcecode/taxtran

# get a list of transaction ids
curl -s -X POST --insecure --cert ~/.chia/mainnet/config/ssl/wallet/private_wallet.crt --key ~/.chia/mainnet/config/ssl/wallet/private_wallet.key -H "Accept: application/json" -H "Content-Type: application/json" "https://localhost:9256/get_transactions" -d '{"wallet_id":1,"start":0,"end":99999}' | python3 -m json.tool | grep -E 'name' | cut --fields 4 --delimiter=\" | cut -c 3- >$path/trans_id_list.txt
>>>>>>> Initial commit
cnt=`cat $path/trans_id_list.txt | wc -l`

while read t; do
  $path/chiatx.sh $t $cnt
  cnt=$((cnt-1))
done <$path/trans_id_list.txt
<<<<<<< HEAD
=======

cat $path/transactions.csv

>>>>>>> Initial commit
