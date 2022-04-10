# getxchtx  
(_formerly taxtran_)

Generate a list of transactions for Chia (XCH) into a CSV file.

---

**getxchtx.sh** - you must run this script from the command line. This script pulls all your transactions into a json file by querying the wallet db, then loops through each transaction builds a CSV file. Note: the query actually pulls from 0 to 99999, so if you have more transactions than 99,999 you may need to edit the script prior to running.

COMMAND OPTIONS<br>
```
USAGE: bash getxchtx.sh [OPTIONS]

OPTIONS
  -y YEAR         transactions only for given 4-digit year      Default: all transactions
  -v              verbose output
  -h              help

  Example:    bash getxchtx.sh -y 2021 -v


Save to file with redirection

   Example:   bash getxchtx.sh -y 2021 >tx_list.csv
```

---

**Notes**<br>
**1.** Since this is pulling historical transactions, the current price column is set to 0. You will need to populate that column manually. *Let me know if there is a free API that can pull historical pricing for XCH.*

**2.** ***python3*** must be installed. Run the following command to see if you have it installed.

```
python3 --version
```
**3.** ***xargs*** must be install. Run the following command to see if you have it installed.

```
xargs --version
```
