#!/bin/bash

usage () {
  echo "USAGE: bash getxchtx.sh [OPTIONS]"
  echo ""
  echo "OPTIONS"
  echo "  -y YEAR         transactions only for given 4-digit year      Default: all transactions"
  echo "  -v              verbose output"
  echo "  -h              help"
  echo ""
  echo "  Example:    bash getxchtx.sh -y 2021 -v"
  echo ""
  echo ""
  echo "Save to file with redirection"
  echo ""
  echo "   Example:   bash getxchtx.sh -y 2021 >tx_list.csv"
  echo ""
}

mojo2xch () {
	local mojo=$tx_amount
	xch=""
	
	# cant do floating division in Bash but we know xch is always mojo/10000000000 
	# so we can use string manipulation to build the xch value from mojo
	mojolength=`expr length $mojo`
	if [ $mojolength -eq 12 ]; then
		xch="0.$mojo"
	elif [ $mojolength -lt 12 ]; then
		temp=`printf "%012d" $mojo`
		xch="0.$temp"
	else
		off=$(($mojolength - 12))
		off2=$(($off + 1))
		temp1=`echo $mojo | cut -c1-$off`
		temp2=`echo $mojo | cut -c$off2-$mojolength`
		xch="$temp1.$temp2"
	fi    
}

year="all"
verbose=0

# Handle the command line options. Set variable based on input
while [ -n "$1" ]
do
  case "$1" in
    -h) usage & exit 1 ;;
    -y) year=$2 & shift ;;
	-v) verbose=1 & shift ;;
    --) shift & break ;;
    *)  ;;
  esac
shift
done

# Make a call against the chia wallet_rpc_api to get transactions, then use jq to write the json to a file
curl -s -X POST --insecure \
	--cert ~/.chia/mainnet/config/ssl/wallet/private_wallet.crt \
	--key ~/.chia/mainnet/config/ssl/wallet/private_wallet.key \
	-H "Accept: application/json" \
	-H "Content-Type: application/json" \
	"https://localhost:9256/get_transactions" \
	-d '{"wallet_id":1,"start":0,"end":999999,"reverse":0}' \
	| jq >alltxs.json

# Write out a header row
if [ "$verbose" == 1 ]; then
	header="tx_name,tx_datetime,tx_type,tx_amount,tx_additions,tx_confirmed,tx_confirmed_at_height,tx_fee_amount,tx_memos,tx_removals,tx_sent,tx_sent_to,tx_spend_bundle,tx_to_address,tx_to_puzzle_hash,tx_trade_id,tx_wallet_id"
else
	header="tx_name,tx_datetime,tx_type,tx_amount"
fi
echo "$header"

# Loop through all the transactions from the json file
jq -c '.transactions[]' alltxs.json | while read trx; do

	# pull out all the fields from the transaction
	tx_additions=`echo "$trx" | jq -r '.additions[] | (.amount|tostring) + "^" + (.parent_coin_info|tostring) + "^" + (.puzzle_hash|tostring)'`
    tx_amount=`echo "$trx" | jq -r '.amount'`
    tx_confirmed=`echo "$trx" | jq -r '.confirmed'`
    tx_confirmed_at_height=`echo "$trx" | jq -r '.confirmed_at_height'`
    tx_created_at_time=`echo "$trx" | jq -r '.created_at_time'`
    tx_fee_amount=`echo "$trx" | jq -r '.fee_amount'`
    # TODO memos -- haven't seen any txs with memos. empty for now so we have a placeholder for future
    tx_memos="{}"
    tx_name=`echo "$trx" | jq -r '.name'`
	tx_removals=`echo "$trx" | jq -r '.removals[] | (.amount|tostring) + "^" + (.parent_coin_info|tostring) + "^" + (.puzzle_hash|tostring)'`
    tx_sent=`echo "$trx" | jq -r '.sent'`
    tx_sent_to=`echo "$trx" | jq -r '.sent_to'`
    tx_spend_bundle=`echo "$trx" | jq -r '.spend_bundle'`
    tx_to_address=`echo "$trx" | jq -r '.to_address'`
    tx_to_puzzle_hash=`echo "$trx" | jq -r '.to_puzzle_hash'`
    tx_trade_id=`echo "$trx" | jq -r '.trade_id'`
    tx_type=`echo "$trx" | jq -r '.type'`
    tx_wallet_id=`echo "$trx" | jq -r '.wallet_id'`

    # call function to switch amount from mojo to xch
    mojo2xch & tx_amount=$xch

	# build datetime from epoch
	tx_datetime=$(date --date=@$tx_created_at_time +"%Y-%m-%d %T")
	tx_year=`echo $tx_datetime | cut -c1-4`
	
	# set a good description for the transaction type
	case $tx_type in
		0) tx_typedesc="INCOMING_TX" ;;
		1) tx_typedesc="OUTGOING_TX" ;;
		2) tx_typedesc="COINBASE_REWARD" ;;
		3) tx_typedesc="FEE_REWARD" ;;
		4) tx_typedesc="INCOMING_TRADE" ;;
		5) tx_typedesc="OUTGOING_TRADE" ;;
	esac
	
	# Need to evaluate if Transaction Type is OUTGOING_TX, if so we need to sum up the Removal Amounts and use instead of just tx_amount.
	ubound=""
	if [ "$tx_typedesc" == "OUTGOING_TX" ]; then
	
		# pull all fields from removals into an array that we loop through to add up 
		# amounts to remove (coins spent, change will come back in a separate transaction)
		newamount=0
		IFS='^' read -r -a array <<< "$tx_removals"
		for index in "${!array[@]}"
		do
			if [ $(expr $index % 3) == "0" ]; then
				# use modulus to make sure we only get the amount field which is every third
				newamount=$(($newamount + ${array[index]}))
			fi
		done
		tx_amount="$newamount"
		
		# call function to switch from mojo to xch
		mojo2xch & tx_amount=$xch
	fi
		
	# If year is passed in as an option we only want to print that year
	if [ "$year" == "all" ] || [ "$year" == "$tx_year" ]; then

		# write out to screen
		# to save to file the user must use redirection on the command line
		if [ "$verbose" == 1 ]; then
			row="$tx_name,$tx_datetime,$tx_typedesc,$tx_amount,$tx_additions,$tx_confirmed,$tx_confirmed_at_height,$tx_fee_amount,$tx_memos,$tx_removals,$tx_sent,$tx_sent_to,$tx_spend_bundle,$tx_to_address,$tx_to_puzzle_hash,$tx_trade_id,$tx_wallet_id"
		else
			row="$tx_name,$tx_datetime,$tx_typedesc,$tx_amount"
		fi
		echo "$row"
	fi
done
