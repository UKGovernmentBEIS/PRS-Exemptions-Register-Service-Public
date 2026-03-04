#!/bin/bash

#Run this if you don't have permission
#chmod +x ./scripts/shell/insertLocalAuthorityAccounts.sh

sf data import bulk --file ./scripts/shell/LocalAuthorityAccounts.csv --sobject Account  --wait 10