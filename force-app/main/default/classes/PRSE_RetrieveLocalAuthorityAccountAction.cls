public without sharing class PRSE_RetrieveLocalAuthorityAccountAction {
    final static digitalmodus.SystemLogService errorLoggingService = new digitalmodus.SystemLogService('PRSE_RetrieveLocalAuthorityAccountAction');

    @InvocableVariable(label='Local Custodian Codes' required=true)
    public List<String> localCustodianCodes;

    @InvocableMethod(
        label='Fetch Local Authority Accounts'
        description='Returns Local Authority Accounts for a given Local Custodian Code.'
        category='PRS Exemption Register'
    )
    public static List<Account> getAccounts(List<String> localCustodianCodes) {
        List<Account> matchingAccounts = new List<Account>();
        if (localCustodianCodes == null || localCustodianCodes.isEmpty()) {
            return matchingAccounts;
        }
        try {
            String localCustodianCode = localCustodianCodes[0];
            Id localAuthorityRecordTypeId = ((List<RecordType>) DatabaseWrapper.getPrivilegedInstance()
                .query(
                    'SELECT Id, Name, SOBjectType FROM RecordType WHERE SOBjectType = \'Account\' AND Name = \'Local Authority\' LIMIT 1'
                ))[0]?.Id;
            if (localAuthorityRecordTypeId == null) {
                return matchingAccounts;
            }

            Map<String, Object> bindMap = new Map<String, Object> { 
                'localAuthorityRecordTypeId' => localAuthorityRecordTypeId,
                'localCustodianCode' => localCustodianCode
            };
            matchingAccounts = DatabaseWrapper.getPrivilegedInstance().queryWithBinds(
                'SELECT Id, Name, Local_Custodian_Code__c, DomesticNotificationsMailbox__c, NonDomesticNotificationsMailbox__c ' +
                'FROM Account ' +
                'WHERE RecordTypeId = :localAuthorityRecordTypeId ' +
                'AND Local_Custodian_Code__c = :localCustodianCode', 
                bindMap
            );
        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_RetrieveLocalAuthorityAccountAction')
                .setTriggeringAutomationName('getAccounts')
                .setMessage(e.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }

        return matchingAccounts;
    }
}