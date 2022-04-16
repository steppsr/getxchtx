#!/bin/bash

usage () {
  echo "USAGE: bash getxchtx.sh [OPTIONS]"
  echo ""
  echo "OPTIONS"
  echo "  -y YEAR         transactions only for given 4-digit year      Default: all transactions"
  echo "  -i INTERGER     Id of the wallet to use                       Default: 1"
  echo "  -s INTERGER     Index of starting transaction                 Default: 0"
  echo "  -e INTERGER     Index of ending transaction                   Default: 999999"
  echo "  -o INTERGER     0 for ascending, 1 for descending             Default: 0"
  echo "  -min AMOUNT     Only transactions greater than AMOUNT         Default: 0"
  echo "  -max AMOUNT     Only transactions less than AMOUNT            Default: 999999"
  echo "  -t INTERGER     -1 for all transaction types                  Default: -1"
  echo "                    0 for INCOMING_TX"
  echo "                    1 for OUTGOING_TX"
  echo "                    2 for COINBASE_REWARD"
  echo "                    3 for FEE_REWARD"
  echo "                    4 for INCOMING_TRADE"
  echo "                    5 for OUTGOING_TRADE"
  echo "  -v              verbose output"
  echo "  -h              help"
  echo ""
  echo "  Example:"
  echo "      bash getxchtx.sh -y 2021 -v"
  echo ""
  echo "  Example for saving to file:"
  echo "      bash getxchtx.sh -y 2021 > tx_list.csv"
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
verbose="false"
wallet_id=1
trx_start=0
trx_end=999999
trx_order=0
desired_type=-1
trx_max=999999
trx_min=0

# Handle the command line options. Set variable based on input
# be sure not to shift after an option that is only has one term
while [ -n "$1" ]
do
  case "$1" in
    -i) wallet_id=$2 && shift ;;
    -y) year=$2 && shift ;;
    -s) trx_start=$2 && shift ;;
    -e) trx_end=$2 && shift ;;
    -o) trx_order=$2 && shift ;;
    -t) desired_type=$2 && shift ;;
    -min) trx_min=$2 && shift ;;
    -max) trx_max=$2 && shift ;;
    -v) verbose="true" ;;
    -h) usage && exit 1 ;;
    --) shift && break ;;
    *)  ;;
  esac
shift
done

# Make a call against the chia wallet_rpc_api to get transactions, then use jq to write the json to a file
query_parameters="{\"wallet_id\":$wallet_id,\"start\":$trx_start,\"end\":$trx_end,\"reverse\":$trx_order}"
curl -s -X POST --insecure \
    --cert ~/.chia/mainnet/config/ssl/wallet/private_wallet.crt \
    --key ~/.chia/mainnet/config/ssl/wallet/private_wallet.key \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    "https://localhost:9256/get_transactions" \
    -d $query_parameters \
    | jq >alltxs.json

# Write out a fileheader & header row
if [ "$verbose" == "true" ]; then
    header="tx_name,tx_datetime,tx_type,tx_amount,current_price,tx_additions,tx_confirmed,tx_confirmed_at_height,tx_fee_amount,tx_memos,tx_removals,tx_sent,tx_sent_to,tx_spend_bundle,tx_to_address,tx_to_puzzle_hash,tx_trade_id,tx_wallet_id"
else
    header="tx_name,tx_datetime,tx_type,tx_amount,current_price"
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

    # If there was a desired type, lets limit the results down to only that transaction type
    if [[ $desired_type -ge 0 ]] && [[ $desired_type -ne $tx_type ]]; then
        continue
    fi

    # placeholder for the current price of XCH
    current_price=0

    # call function to switch amount from mojo to xch
    mojo2xch && tx_amount=$xch

    # filter based on min/max
    if [[ "$tx_amount" > "$trx_max" ]] || [[ "$tx_amount" < "$trx_min" ]]; then
        continue
    fi
    
    # build datetime from epoch
    tx_datetime=$(date --date=@$tx_created_at_time +"%Y-%m-%d %T")
    tx_year=`echo $tx_datetime | cut -c1-4`

    # jump to next record if we want a specific year and the transaction doesn't match
    if [ "$year" != "all" ] && [ "$year" != "$tx_year" ]; then
        continue
    fi

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
        # amounts to remove (these are the coins spent, change will come back in a separate transaction)
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
        mojo2xch && tx_amount=$xch
    fi

    # write out to screen
    # to save to file the user must use redirection on the command line
    if [ "$verbose" == "true" ]; then
        row="$tx_name,$tx_datetime,$tx_typedesc,$tx_amount,$current_price,$tx_additions,$tx_confirmed,$tx_confirmed_at_height,$tx_fee_amount,$tx_memos,$tx_removals,$tx_sent,$tx_sent_to,$tx_spend_bundle,$tx_to_address,$tx_to_puzzle_hash,$tx_trade_id,$tx_wallet_id"
    else
        row="$tx_name,$tx_datetime,$tx_typedesc,$tx_amount,$current_price"
    fi
    echo "$row"

done

# Version History
#
# v0.1.0 - Initial Release:
#            - Basic functionality. Will generate a list of transactions for Chia (XCH) and
#                put into a CSV file. Pulls only a list of transaction ids from wallet then looped on those
#                ids and used Chia commands to get more details for each transaction.
#            - Output was sent to the screen and also saved to a file. This required defaults for path & 
#                filenames and also command options from user to specify each as well.
# 
# v0.2.0 - Changes:
#            - Rebuilt the query against the wallet db to pull all the transaction data and write into a
#                json file that can be used in the rest of the script without having to run Chia commands.
#            - Changed output to screen only and updated Usage to tell user how to redirect to a file from
#               the command line. 
#          New features:
#            - Added command option to specify a year for the transactions. If the transacion year doesn't 
#                match the value from the command option, then it doesn't get writtent to the CSV.
#            - Added command option for verbose which will include all fields in the CSV. The default is now
#               a condensed version with fewer fields.
#
# v0.3.0 - New features:
#            - Add a command option for sorting. Either ASC for ascending (oldest to newest) or DESC for 
#                descending (newest to oldest).
#            - Add a command option for selecting wallet id to pull transactions from.
#            - Add a command option for start & end indexes for transactions to pull out of the wallet db.
#            - Add a command option for selecting a specific Transaction Type to filter the list by.
#
# v0.3.1 - Changes
#            - Rewrite so filters are not in a big nested if statement. Use continue to jump to next iteration instead.
#          New features:
#            - Add a command option for filtering based on transaction amount.
