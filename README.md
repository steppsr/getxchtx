# XCH Transaction Exporter : getxchtx [Bash Edition] 

Generate a list of transactions for Chia (XCH) into a CSV file.

---

**getxchtx.sh** - You must run this script from the command line. The script pulls all your transactions into a json file by querying the wallet db, then loops through each transaction building a CSV file. Note: You must use the '**bash**' command and _not_ '**sh**'.

COMMAND OPTIONS<br>
```
USAGE: bash getxchtx.sh [OPTIONS]

OPTIONS
  -y YEAR         transactions only for given 4-digit year      Default: all transactions
  -i INTERGER     Id of the wallet to use                       Default: 1
  -s INTERGER     Index of starting transaction                 Default: 0
  -e INTERGER     Index of ending transaction                   Default: 999999
  -o INTERGER     0 for ascending, 1 for descending             Default: 0
  -min AMOUNT     Only transactions greater than AMOUNT         Default: 0
  -max AMOUNT     Only transactions less than AMOUNT            Default: 999999
  -t INTERGER     -1 for all transaction types                  Default: -1
                    0 for INCOMING_TX
                    1 for OUTGOING_TX
                    2 for COINBASE_REWARD
                    3 for FEE_REWARD
                    4 for INCOMING_TRADE
                    5 for OUTGOING_TRADE
  -b              basic output (fewer fields)
  -v              verbose output
  -h              help

  Example:
      bash getxchtx.sh -y 2021 -v

  Example for saving to file:
      bash getxchtx.sh -y 2021 > tx_list.csv

```

---

**Notes:**

**1.** Since this is pulling historical transactions, the current price column is set to 0. You will need to populate that column manually. *Let me know if there is a free API that can pull historical pricing for XCH.*

---

**Prerequisites:**

***curl*** must be installed. Run the following command to see if you have it installed.

```
curl --version
```
***jq*** must be installed. Run the following command to see if you have it installed.

```
jq --version
```

Disclaimer: For educational purposes only.
