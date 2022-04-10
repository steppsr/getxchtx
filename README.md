# XCH Transaction Exporter : getxchtx  
(_formerly taxtran_)

Generate a list of transactions for Chia (XCH) into a CSV file.

---

**getxchtx.sh** - You must run this script from the command line. The script pulls all your transactions into a json file by querying the wallet db, then loops through each transaction building a CSV file. _Note_: the query actually pulls from 0 to 999999, so if you have more transactions than 999,999 you may need to edit the script prior to running. Also, you must use the '**bash**' command and _not_ '**sh**'.

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

**Notes:**

**1.** Since this is pulling historical transactions, the current price column is set to 0. You will need to populate that column manually. *Let me know if there is a free API that can pull historical pricing for XCH.*

**2.** ***curl*** must be installed. Run the following command to see if you have it installed.

```
curl --version
```
**3.** ***jq*** must be installed. Run the following command to see if you have it installed.

```
jq --version
```
