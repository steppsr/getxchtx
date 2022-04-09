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

**Notes**<br>
**1.** Since this is pulling historical transactions, the current price column is set to 0. You will need to populate that column manually.<br>*Let me know if there is a free API that can pull historical pricing for XCH.*<br>
**2.** Each transaction takes about 1 second to process, so it may take quite a while to finish creating the file.<br>
**3.** You will need to modify the "path" at the top of each script to be the location you place these files. I suggest creating a directory under home and running from within that directory.<br>
**4.** ***python3*** must be installed. Run the following command to see if you have it installed.

```
python3 --version
```
**5.** ***xargs*** must be install. Run the following command to see if you have it installed.

```
xargs --version
```
