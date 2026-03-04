#!/bin/bash

#Run this if you don't have permission
#chmod +x ./scripts/shell/upsertPenaltyTypes.sh

sf data upsert bulk --file ./scripts/shell/PenaltyTypes.csv --sobject Penalty_Type__c -i Code__c  --wait 10