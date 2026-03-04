#!/bin/bash

#Run this if you don't have permission
#chmod +x ./scripts/shell/upsertExemptionTypes.sh

sf data upsert bulk --file ./scripts/shell/ExemptionTypes.csv --sobject Exemption_Type__c -i Code__c  --wait 10