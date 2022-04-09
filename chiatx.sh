#!/bin/bash

binpath=~/chia-blockchain/venv/bin

# Parameter 1 is required. Chia transaction ID. Exit if the paramater is empty.
# Parameter 2 is required. Path and Filename to use for the output file.
# Parameter 3 is required. The year for the selection of transaction. "all" is all transactions.
# Parameter 4 is optional. Countdown value is printed on screen before the transaction detail.

id=$1
filepath=$2
year=$3
cnt=$4

if [ -z "$id" ]; then
    echo "Transaction ID is missing."
    exit 1
fi
if [ -z "$filepath" ]; then
    echo "Path and filename are missing."
    exit 1
fi

json=`$binpath/chia wallet get_transaction -v -tx $id`

# Fields to put into CSV file
# DateTime    Name    Transaction Amount    Current Price    Transaction Type
name=$(echo "$json" | grep "name" | cut --fields 4 --delimiter=\' )
mojo=$(echo "$json" | grep " 'amount" | grep -v "additions" | grep -v "fee_amount" | cut --fields 2 --delimiter=: | xargs)
mojo=${mojo%?}
type=$(echo "$json" | grep "type" | cut --fields 2 --delimiter=: | xargs)
type=${type%?}

case $type in
    0)
        typedesc="INCOMING_TX"
        ;;

    1)
        typedesc="OUTGOING_TX"
        ;;

    2)
        typedesc="COINBASE_REWARD"
        ;;

    3)
        typedesc="FEE_REWARD"
        ;;

    4)
        typedesc="INCOMING_TRADE"
        ;;

    5)
        typedesc="OUTGOING_TRADE"
        ;;
esac

# Get the date

# Use this section if running this script on each new transaction as it comes in.
#today=$(date +"%Y-%m-%d %T")
#transday=$(date --date=@$created_at_time +"%Y-%m-%d %T")

# Use this section if running for historical transactions
transday=$(echo "$json" | grep "created_at_time" | cut --fields 2 --delimiter=: | xargs)
transday=${transday%?}
transday=$(date -d @"$transday" +"%F %r")
transyear=`echo $transday | cut -c1-4`

# cant do floating division in Bash but we know xch is always mojo/10000000000 so we can use string manipulation to build the xch value from mojo
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

# Getting the Current Price of XCH

# Old way - Scrape current XCH price from coinmarketcap website
#content=`curl -s https://coinmarketcap.com/currencies/chia-network/`
#curusd=`echo $content | cut -d '$' -f 6`
#curusd=`echo $curusd | cut -d '<' -f 1`

# New way - use CoinMarketcap API to get current XCH price -- you'll need to get an API key with CoinMarketcap 
# Note to self: probably should get the current price separate from processing the transaction. Change to pull from file or db instead.
# if you are a target of a dust storm, you to go over your allow number of API calls really quickly.
#content=`curl -s -H "X-CMC_PRO_API_KEY: your_coinmarketcap_api_key" -H "Accept: application/json" -d "symbol=XCH" -G https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest`
#curusd=`echo $content | jq '.data.XCH.quote.USD.price'`

# Since we are pulling historical transactions, we shouldn't use the current price. 
curusd=0

if [ "$year" == "all" ]; then
  # any year
  echo "\"$transday\",\"$name\",$xch,$curusd,\"$typedesc\""  >>$filepath
  echo "$cnt: \"$transday\",\"$name\",$xch,$curusd,\"$typedesc\""
elif [ "$year" == "$transyear" ]; then
  echo "\"$transday\",\"$name\",$xch,$curusd,\"$typedesc\""  >>$filepath
  echo "$cnt: \"$transday\",\"$name\",$xch,$curusd,\"$typedesc\""
else
  echo "$cnt: Year is $transyear - skipping..."
fi
