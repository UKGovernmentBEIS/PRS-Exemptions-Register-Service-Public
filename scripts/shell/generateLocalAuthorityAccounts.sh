#!/bin/bash

echo "Querying RecordTypeId"
RECORD_TYPE_ID=$(sf data query --file scripts/soql/recordType.soql --json | grep '"Id"' | head -1 | sed -E 's/.*"Id": ?"([^"]+)".*/\1/')

INPUT_FILE="./scripts/shell/addressbase-local-custodian-codes.csv"
OUTPUT_FILE="./scripts/shell/LocalAuthorityAccounts.csv"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "❌ File not found: $INPUT_FILE"
  exit 1
fi

echo "📄 Reading: $INPUT_FILE"

HEADER=$(head -n 1 "$INPUT_FILE" | sed 's/\r//g' | sed 's/^\xEF\xBB\xBF//')

AUTH_COL=$(echo "$HEADER" | awk -F',' '{
  for(i=1;i<=NF;i++){
    gsub(/^[ \t"]+|[ \t"]+$/, "", $i);
    if($i=="AUTH_CODE"){print i}
  }
}')

NAME_COL=$(echo "$HEADER" | awk -F',' '{
  for(i=1;i<=NF;i++){
    gsub(/^[ \t"]+|[ \t"]+$/, "", $i);
    if($i=="ACCOUNT_NAME"){print i}
  }
}')

if [[ -z "$AUTH_COL" || -z "$NAME_COL" ]]; then
  echo "❌ Could not find AUTH_CODE or ACCOUNT_NAME columns."
  exit 1
fi

echo "🔍 Found AUTH_CODE at column $AUTH_COL, ACCOUNT_NAME at column $NAME_COL"
echo "🔍 Using RecordTypeId: $RECORD_TYPE_ID"

# Write header with CRLF
printf "Name,Local_Custodian_Code__c,RecordTypeId\r\n" > "$OUTPUT_FILE"

# Process rows and add the RecordTypeId
awk -v auth_col="$AUTH_COL" -v name_col="$NAME_COL" -v record_type_id="$RECORD_TYPE_ID" -F',' '
NR>1 {
  gsub(/\r/,"",$0);
  auth=$auth_col; name=$name_col;
  gsub(/^"|"$/,"",auth);
  gsub(/^"|"$/,"",name);
  gsub(/"/,"\"\"",name);
  if(auth!="" && name!="")
    printf "\"%s\",\"%s\",\"%s\"\r\n", name, auth, record_type_id
}' "$INPUT_FILE" >> "$OUTPUT_FILE"

echo "✅ Created $OUTPUT_FILE with CRLF line endings for Salesforce"