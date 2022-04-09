#!/bin/bash

usage () {
  echo "USAGE: sh taxtran.sh [OPTIONS]"
  echo ""
  echo "OPTIONS"
  echo "  -y        4-digit year for transactions"
  echo "  -d        directory to store output file"
  echo "  -f        output filename"
  echo ""
  echo "Example:  taxtran -y 2021 -d ~/mytaxes -f transactions.csv"
  echo ""
}

year="all"
dir=`pwd`
file="xch_transactions.csv"

while [ -n "$1" ]
do

  case "$1" in
    -h) usage
         exit 1
         ;;
    -y) year=$2
        shift ;;
    -d) dir=$2
        shift ;;
    -f) file=$2
        shift ;;
    --) shift
        break ;;
    *)  ;;
  esac
shift
done

path="$dir/$file"

curl -s -X POST --insecure --cert ~/.chia/mainnet/config/ssl/wallet/private_wallet.crt --key ~/.chia/mainnet/config/ssl/wallet/private_wallet.key -H "Accept: application/json" -H "Content-Type: application/json" "https://localhost:9256/get_transactions" -d '{"wallet_id":1,"start":0,"end":99999}' | python3 -m json.tool | grep -E 'name' | cut --fields 4 --delimiter=\" | cut -c 3- > $dir/trans_id_list.txt

cnt=`cat $dir/trans_id_list.txt | wc -l`

# Write a header to the output file
echo "DateTime,Name,Amount,CurrentPrice,Type" >$path

while read t; do
  bash $dir/chiatx.sh $t $path $year $cnt
  cnt=$((cnt-1))
done <$dir/trans_id_list.txt
