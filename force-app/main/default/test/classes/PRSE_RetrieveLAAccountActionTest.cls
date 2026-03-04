@isTest
private class PRSE_RetrieveLAAccountActionTest {

    @isTest
    static void getAccounts_withNullLocalCustodianCodes_returnsEmptyAccountList() {
        //Arrange
        List<String> localcustodianCodes = null;

        //Act
        List<Account> accounts = PRSE_RetrieveLocalAuthorityAccountAction.getAccounts(localcustodianCodes);

        //Assert
        Assert.areEqual(0, accounts.size(), 'Incorrect number of accounts returned');
    }

    @isTest
    static void getAccounts_withEmptyLocalCustodianCodes_returnsEmptyAccountList() {
        //Arrange
        List<String> localcustodianCodes = new List<String>();

        //Act
        List<Account> accounts = PRSE_RetrieveLocalAuthorityAccountAction.getAccounts(localcustodianCodes);

        //Assert
        Assert.areEqual(0, accounts.size(), 'Incorrect number of accounts returned');
    }

    @isTest
    static void getAccounts_withNoLocalAuthorityRecordsTypes_returnsEmptyAccountList() {
        //Arrange
        List<String> localcustodianCodes = new List<String>{ '5990' };
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.privilegedInstance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.query(
                'SELECT Id, Name, SOBjectType ' +
                'FROM RecordType WHERE SOBjectType = \'Account\' AND Name = \'Local Authority\' LIMIT 1'
            )
        ).thenReturn(null);

        //Act
        List<Account> accounts = PRSE_RetrieveLocalAuthorityAccountAction.getAccounts(localcustodianCodes);

        //Assert
        Assert.areEqual(0, accounts.size(), 'Incorrect number of accounts returned');
    }

    @isTest
    static void getAccounts_withLocalAuthorityRecordsTypeButNoAccounts_returnsEmptyAccountList() {
        //Arrange
        List<String> localcustodianCodes = new List<String>{ '5990' };
        RecordType mockRecordType = new RecordType();
        mockRecordType.Id = SObjectUtil.generateIdForType('RecordType');
        mockRecordType.DeveloperName = 'Local_Authority';
        mockRecordType.Name = 'Local Authority';
        List<RecordType> recordTypesToReturn = new List<RecordType>{ mockRecordType };

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.privilegedInstance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.query(
                'SELECT Id, Name, SOBjectType ' +
                'FROM RecordType WHERE SOBjectType = \'Account\' AND Name = \'Local Authority\' LIMIT 1'
            )
        ).thenReturn(recordTypesToReturn);
        Map<String, Object> bindMap = new Map<String, Object> { 
            'localAuthorityRecordTypeId' => mockRecordType.Id,
            'localCustodianCode' => localCustodianCodes[0]
        };
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Name, Local_Custodian_Code__c, DomesticNotificationsMailbox__c, NonDomesticNotificationsMailbox__c ' +
                'FROM Account ' +
                'WHERE RecordTypeId = :localAuthorityRecordTypeId ' +
                'AND Local_Custodian_Code__c = :localCustodianCode',
                bindMap
            )
        ).thenReturn(new List<Account>());

        //Act
        List<Account> accounts = PRSE_RetrieveLocalAuthorityAccountAction.getAccounts(localcustodianCodes);

        //Assert
        Assert.areEqual(0, accounts.size(), 'Incorrect number of accounts returned');
    }

    @isTest
    static void getAccounts_withLocalAuthorityRecordsTypeAndMatchingAccounts_returnsAccountList() {
        //Arrange
        List<String> localcustodianCodes = new List<String>{ '5990' };
        RecordType mockRecordType = new RecordType();
        mockRecordType.Id = SObjectUtil.generateIdForType('RecordType');
        mockRecordType.DeveloperName = 'Local_Authority';
        mockRecordType.Name = 'Local Authority';
        List<RecordType> recordTypesToReturn = new List<RecordType>{ mockRecordType };
        List<Account> accountsToReturn = new List<Account>{ 
            new Account(
                Id = SObjectUtil.generateIdForType('Account'),
                Name = 'Test Account',
                Local_Custodian_Code__c = '5990',
                DomesticNotificationsMailbox__c = 'test@test1.com',
                NonDomesticNotificationsMailbox__c = 'test@test2.com'
            )
         };

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.privilegedInstance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.query(
                'SELECT Id, Name, SOBjectType ' +
                'FROM RecordType WHERE SOBjectType = \'Account\' AND Name = \'Local Authority\' LIMIT 1'
            )
        ).thenReturn(recordTypesToReturn);
        Map<String, Object> bindMap = new Map<String, Object> { 
            'localAuthorityRecordTypeId' => mockRecordType.Id,
            'localCustodianCode' => localCustodianCodes[0]
        };
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Name, Local_Custodian_Code__c, DomesticNotificationsMailbox__c, NonDomesticNotificationsMailbox__c ' +
                'FROM Account ' +
                'WHERE RecordTypeId = :localAuthorityRecordTypeId ' +
                'AND Local_Custodian_Code__c = :localCustodianCode',
                bindMap
            )
        ).thenReturn(accountsToReturn);

        //Act
        List<Account> accounts = PRSE_RetrieveLocalAuthorityAccountAction.getAccounts(localcustodianCodes);

        //Assert
        Assert.areEqual(1, accounts.size(), 'Incorrect number of accounts returned');
        Account localAuthorityAccount = accounts[0];
        Assert.areEqual('Test Account', localAuthorityAccount.Name, 'Incorrect name for local authority account');
        Assert.areEqual('5990', localAuthorityAccount.Local_Custodian_Code__c, 'Incorrect local custodian code for local authority account');
        Assert.areEqual('test@test1.com', localAuthorityAccount.DomesticNotificationsMailbox__c, 'Incorrect domestic email for local authority account');
        Assert.areEqual('test@test2.com', localAuthorityAccount.NonDomesticNotificationsMailbox__c, 'Incorrect non-domestic email for local authority account');
    }
}