# taxtran
Generate a list of transactions for Chia (XCH) into a CSV file.

There two scripts used when creating the CSV file with XCH transactions.

**taxtran.sh** - this is the main script and the one that you will run from the command line. This script creates a list of all your transactions ids into a file by querying the wallet db, then loops through each transaction and calls the second script (chiatx.sh) with that transaction number. Note: the query actually pulls from 0 to 99999, so if you have more transactions than 99,999 you may need to edit the script prior to running.

INPUT PARAMETERS: None<br>
OUTPUT: CSV File named 'transactions.csv'

```
sh taxtran.sh
```

**chiatx.sh** - this script will accept a transaction id as input, then run a Chia Wallet command to get the details of the transaction. The details are parsed and formatted then printed to a CSV file, and also to the screen. The screen output also includes a countdown counter on each line. *This script is called from taxtran.sh*

INPUT PARAMETERS: Transaction ID, Counter (optional)<br>
OUTPUT: transaction data appended to 'transaction.csv' and to screen.

**Note:** Each transaction takes about 1 second to process, so it may take quite a while to finish creating the file.
