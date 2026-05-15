@isTest(IsParallel=true)
private class PRSE_LADashboardControllerTest {

    @isTest
    static void getUserDisplayName_withPersonAccount_returnsPersonAccountName() {
        //Arrange
        String userId = UserInfo.getUserId();
        Id contactId = '003Pv000010KeNOIA0';
        Map<String, Object> userFields = new Map<String, Object>{
            'Id' => userId,
            'Name' => 'Test User',
            'ContactId' => contactId
        };
        User testUser = (User) SObjectUtil.makeSObject(User.SObjectType, userFields);
        List<User> userToReturn = new List<User>{ testUser };

        Map<String, Object> accountFields = new Map<String, Object>{
            'Id' => SObjectUtil.generateIdForType('Account'),
            'Name' => 'Test Account',
            'PersonContactId' => contactId
        };
        Account testAccount = (Account) SObjectUtil.makeSObject(Account.SObjectType, accountFields);
        List<Account> accountToReturn = new List<Account>{ testAccount };

        Map<String, Object> userBindMap = new Map<String, Object>{'userId' => userId};
        Map<String, Object> accountBindMap = new Map<String, Object>{'contactId' => contactId};
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds('SELECT Id, Name, ContactId FROM User WHERE Id = :userId', userBindMap)
        ).thenReturn(userToReturn);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds('SELECT Id, Name FROM Account WHERE PersonContactId = :contactId', accountBindMap)
        ).thenReturn(accountToReturn);

        //Act
        Test.startTest();
        String userDisplayName = PRSE_LocalAuthorityDashboardController.getUserDisplayName();
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(testAccount.Name, userDisplayName, 'Incorrect user display name returned');
    }

    @isTest
    static void getUserDisplayName_withoutPersonAccount_returnsUserName() {
        //Arrange
        String userId = UserInfo.getUserId();
        Id contactId = '003Pv000010KeNOIA0';
        Map<String, Object> userFields = new Map<String, Object>{
            'Id' => userId,
            'Name' => 'Test User',
            'ContactId' => contactId
        };
        User testUser = (User) SObjectUtil.makeSObject(User.SObjectType, userFields);
        List<User> userToReturn = new List<User>{ testUser };

        Map<String, Object> accountFields = new Map<String, Object>{
            'Id' => SObjectUtil.generateIdForType('Account'),
            'Name' => 'Test Account',
            'PersonContactId' => contactId
        };
        Account testAccount = (Account) SObjectUtil.makeSObject(Account.SObjectType, accountFields);
        List<Account> accountToReturn = new List<Account>{ testAccount };

        Map<String, Object> userBindMap = new Map<String, Object>{'userId' => userId};
        Map<String, Object> accountBindMap = new Map<String, Object>{'contactId' => contactId};
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds('SELECT Id, Name, ContactId FROM User WHERE Id = :userId', userBindMap)
        ).thenReturn(userToReturn);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds('SELECT Id, Name FROM Account WHERE PersonContactId = :contactId', accountBindMap)
        ).thenReturn(new List<Account>());

        //Act
        Test.startTest();
        String userDisplayName = PRSE_LocalAuthorityDashboardController.getUserDisplayName();
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(testUser.Name, userDisplayName, 'Incorrect user display name returned');
    }

    @isTest
    static void getUserDisplayName_withException_logsErrorAndReturnsEmptyName() {
        //Arrange
        String userId = UserInfo.getUserId();
        Id contactId = '003Pv000010KeNOIA0';
        Map<String, Object> userFields = new Map<String, Object>{
            'Id' => userId,
            'Name' => 'Test User',
            'ContactId' => contactId
        };
        User testUser = (User) SObjectUtil.makeSObject(User.SObjectType, userFields);
        List<User> userToReturn = new List<User>{ testUser };

        Map<String, Object> userBindMap = new Map<String, Object>{'userId' => userId};
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds('SELECT Id, Name, ContactId FROM User WHERE Id = :userId', userBindMap)
        ).thenThrow(new Exceptions.CustomException('An error has occured'));

        //Act
        Test.startTest();
        String userDisplayName = PRSE_LocalAuthorityDashboardController.getUserDisplayName();
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LocalAuthorityDashboardController', 'getUserDisplayName', 'An error has occured');
        Assert.areEqual('', userDisplayName, 'Incorrect user display name returned');
    }

    @isTest
    static void getAssociatedLocalAuthorities_withSingleLocalAuthority_returnsMapWithSingleEntry() {
        //Arrange
        String userId = UserInfo.getUserId();
        Id contactId = '003Pv000010KeNOIA0';
        Map<String, Object> userFields = new Map<String, Object>{
            'Id' => userId,
            'Name' => 'Test User',
            'ContactId' => contactId
        };
        User testUser = (User) SObjectUtil.makeSObject(User.SObjectType, userFields);
        List<User> usersToReturn = new List<User>{ testUser };

        RecordType mockRecordType = new RecordType();
        mockRecordType.Id = SObjectUtil.generateIdForType('RecordType');
        mockRecordType.DeveloperName = 'Local_Authority';
        mockRecordType.Name = 'Local Authority';
        List<RecordType> recordTypesToReturn = new List<RecordType>{ mockRecordType };

        Map<String, Object> bristolAccountFields = new Map<String, Object>{
            'Id' => SObjectUtil.generateIdForType('Account'),
            'Name' => 'BRISTOL CITY COUNCIL',
            'Local_Custodian_Code__c' => '116'
        };
        Account bristolCityCouncil = (Account) SObjectUtil.makeSObject(Account.SObjectType, bristolAccountFields);

        Map<String, Object> bristolCityCouncilRelationshipFields = new Map<String, Object>{
            'Id' => SObjectUtil.generateIdForType('AccountContactRelation'),
            'Name' => 'BRISTOL CITY COUNCIL',
            'AccountId' => bristolCityCouncil.Id,
            'Account' => bristolCityCouncil
        };
        AccountContactRelation bristolCityCouncilRelationship = (AccountContactRelation) SObjectUtil.makeSObject(
            AccountContactRelation.SObjectType, 
            bristolCityCouncilRelationshipFields
        );
        List<AccountContactRelation> accountContactRelationsToReturn = new List<AccountContactRelation> { bristolCityCouncilRelationship };

        Map<String, Object> userBindMap = new Map<String, Object> { 'userId' => userId };
        Map<String, Object> accountContractRelationBindMap = new Map<String, Object> { 
            'contactId' => contactId,
            'localAuthorityRecordTypeId' => mockRecordType.Id
        };
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.privilegedInstance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds('SELECT ContactId FROM User WHERE Id = :userId', userBindMap)
        ).thenReturn(usersToReturn);
        mockProvider.when(
            mockDatabaseWrapper.query('SELECT Id, Name, SOBjectType FROM RecordType WHERE SOBjectType = \'Account\' AND Name = \'Local Authority\' LIMIT 1')
        ).thenReturn(recordTypesToReturn);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Account.Name, Account.Local_Custodian_Code__c FROM AccountContactRelation WHERE ContactId = :contactId AND Account.RecordTypeId = :localAuthorityRecordTypeId', 
                accountContractRelationBindMap
            )
        ).thenReturn(accountContactRelationsToReturn);

        //Act
        Test.startTest();
        Map<String, String> localAuthorities = PRSE_LocalAuthorityDashboardController.getAssociatedLocalAuthorities();
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(1, localAuthorities.keySet().size(), 'Incorrect number of local authorities returned');
        Assert.isTrue(
            localAuthorities.keySet().contains(bristolCityCouncilRelationship.Account.Local_Custodian_Code__c), 
            'Expected local authority code to be present in the map.'
        );
        Assert.areEqual(
            bristolCityCouncilRelationship.Account.Name, 
            localAuthorities.get(bristolCityCouncilRelationship.Account.Local_Custodian_Code__c), 
            'Incorrect local authority name returned.'
        );
    }

    @isTest
    static void getAssociatedLocalAuthorities_withMultipleLocalAuthorities_returnsMapWithMultipleEntries() {
        //Arrange
        String userId = UserInfo.getUserId();
        Id contactId = '003Pv000010KeNOIA0';
        Map<String, Object> userFields = new Map<String, Object>{
            'Id' => userId,
            'Name' => 'Test User',
            'ContactId' => contactId
        };
        User testUser = (User) SObjectUtil.makeSObject(User.SObjectType, userFields);
        List<User> usersToReturn = new List<User>{ testUser };

        RecordType mockRecordType = new RecordType();
        mockRecordType.Id = SObjectUtil.generateIdForType('RecordType');
        mockRecordType.DeveloperName = 'Local_Authority';
        mockRecordType.Name = 'Local Authority';
        List<RecordType> recordTypesToReturn = new List<RecordType>{ mockRecordType };

        Map<String, Object> coventryAccountFields = new Map<String, Object>{
            'Id' => SObjectUtil.generateIdForType('Account'),
            'Name' => 'COVENTRY CITY COUNCIL',
            'Local_Custodian_Code__c' => '4610'
        };
        Account coventryCityCouncil = (Account) SObjectUtil.makeSObject(Account.SObjectType, coventryAccountFields);

        Map<String, Object> bristolAccountFields = new Map<String, Object>{
            'Id' => SObjectUtil.generateIdForType('Account'),
            'Name' => 'BRISTOL CITY COUNCIL',
            'Local_Custodian_Code__c' => '116'
        };
        Account bristolCityCouncil = (Account) SObjectUtil.makeSObject(Account.SObjectType, bristolAccountFields);

        Map<String, Object> greenwichAccountFields = new Map<String, Object>{
            'Id' => SObjectUtil.generateIdForType('Account'),
            'Name' => 'ROYAL BOROUGH OF GREENWICH',
            'Local_Custodian_Code__c' => '5330'
        };
        Account greenwichCityCouncil = (Account) SObjectUtil.makeSObject(Account.SObjectType, greenwichAccountFields);

        Map<String, Object> bristolCityCouncilRelationshipFields = new Map<String, Object>{
            'Id' => SObjectUtil.generateIdForType('AccountContactRelation'),
            'Name' => 'BRISTOL CITY COUNCIL',
            'AccountId' => coventryCityCouncil.Id,
            'Account' => coventryCityCouncil
        };
        AccountContactRelation bristolCityCouncilRelationship = (AccountContactRelation) SObjectUtil.makeSObject(
            AccountContactRelation.SObjectType, 
            bristolCityCouncilRelationshipFields
        );

        Map<String, Object> greenwichCityCouncilRelationshipFields = new Map<String, Object>{
            'Id' => SObjectUtil.generateIdForType('AccountContactRelation'),
            'Name' => 'ROYAL BOROUGH OF GREENWICH',
            'AccountId' => greenwichCityCouncil.Id,
            'Account' => greenwichCityCouncil
        };
        AccountContactRelation greenwichCityCouncilRelationship = (AccountContactRelation) SObjectUtil.makeSObject(
            AccountContactRelation.SObjectType, 
            greenwichCityCouncilRelationshipFields
        );
        List<AccountContactRelation> accountContactRelationsToReturn = new List<AccountContactRelation> { 
            bristolCityCouncilRelationship, 
            greenwichCityCouncilRelationship 
        };

        Map<String, Object> userBindMap = new Map<String, Object> { 'userId' => userId };
        Map<String, Object> accountContractRelationBindMap = new Map<String, Object> { 
            'contactId' => contactId,
            'localAuthorityRecordTypeId' => mockRecordType.Id
        };
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.privilegedInstance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds('SELECT ContactId FROM User WHERE Id = :userId', userBindMap)
        ).thenReturn(usersToReturn);
        mockProvider.when(
            mockDatabaseWrapper.query('SELECT Id, Name, SOBjectType FROM RecordType WHERE SOBjectType = \'Account\' AND Name = \'Local Authority\' LIMIT 1')
        ).thenReturn(recordTypesToReturn);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Account.Name, Account.Local_Custodian_Code__c FROM AccountContactRelation WHERE ContactId = :contactId AND Account.RecordTypeId = :localAuthorityRecordTypeId', 
                accountContractRelationBindMap
            )
        ).thenReturn(accountContactRelationsToReturn);

        //Act
        Test.startTest();
        Map<String, String> localAuthorities = PRSE_LocalAuthorityDashboardController.getAssociatedLocalAuthorities();
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(2, localAuthorities.keySet().size(), 'Incorrect number of local authorities returned');
        Assert.isTrue(
            localAuthorities.keySet().contains(bristolCityCouncilRelationship.Account.Local_Custodian_Code__c), 
            'Expected local authority code to be present in the map.'
        );
        Assert.areEqual(
            bristolCityCouncilRelationship.Account.Name, 
            localAuthorities.get(bristolCityCouncilRelationship.Account.Local_Custodian_Code__c), 
            'Incorrect local authority name returned.'
        );

        Assert.isTrue(
            localAuthorities.keySet().contains(greenwichCityCouncilRelationship.Account.Local_Custodian_Code__c), 
            'Expected local authority code to be present in the map.'
        );
        Assert.areEqual(
            greenwichCityCouncilRelationship.Account.Name, 
            localAuthorities.get(greenwichCityCouncilRelationship.Account.Local_Custodian_Code__c), 
            'Incorrect local authority name returned.'
        );
    }

    @isTest
    static void getAssociatedLocalAuthorities_withNoLocalAuthorities_returnsEmptyMap() {
        //Arrange
        String userId = UserInfo.getUserId();
        Id contactId = '003Pv000010KeNOIA0';
        Map<String, Object> userFields = new Map<String, Object>{
            'Id' => userId,
            'Name' => 'Test User',
            'ContactId' => contactId
        };
        User testUser = (User) SObjectUtil.makeSObject(User.SObjectType, userFields);
        List<User> usersToReturn = new List<User>{ testUser };

        RecordType mockRecordType = new RecordType();
        mockRecordType.Id = SObjectUtil.generateIdForType('RecordType');
        mockRecordType.DeveloperName = 'Local_Authority';
        mockRecordType.Name = 'Local Authority';
        List<RecordType> recordTypesToReturn = new List<RecordType>{ mockRecordType };

        Map<String, Object> userBindMap = new Map<String, Object> { 'userId' => userId };
        Map<String, Object> accountContractRelationBindMap = new Map<String, Object> { 
            'contactId' => contactId,
            'localAuthorityRecordTypeId' => mockRecordType.Id
        };
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.privilegedInstance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds('SELECT ContactId FROM User WHERE Id = :userId', userBindMap)
        ).thenReturn(usersToReturn);
        mockProvider.when(
            mockDatabaseWrapper.query('SELECT Id, Name, SOBjectType FROM RecordType WHERE SOBjectType = \'Account\' AND Name = \'Local Authority\' LIMIT 1')
        ).thenReturn(recordTypesToReturn);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Account.Name, Account.Local_Custodian_Code__c FROM AccountContactRelation WHERE ContactId = :contactId AND Account.RecordTypeId = :localAuthorityRecordTypeId', 
                accountContractRelationBindMap
            )
        ).thenReturn(new List<AccountContactRelation>());

        //Act
        Test.startTest();
        Map<String, String> localAuthorities = PRSE_LocalAuthorityDashboardController.getAssociatedLocalAuthorities();
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.isTrue(localAuthorities.isEmpty(), 'Expected no local authorities to be returned');
    }

    @isTest
    static void getAssociatedLocalAuthorities_withException_logsErrorAndReturnsEmptyMap() {
        //Arrange
        String userId = UserInfo.getUserId();
        Id contactId = '003Pv000010KeNOIA0';
        Map<String, Object> userFields = new Map<String, Object>{
            'Id' => userId,
            'Name' => 'Test User',
            'ContactId' => contactId
        };
        User testUser = (User) SObjectUtil.makeSObject(User.SObjectType, userFields);
        List<User> usersToReturn = new List<User>{ testUser };

        RecordType mockRecordType = new RecordType();
        mockRecordType.Id = SObjectUtil.generateIdForType('RecordType');
        mockRecordType.DeveloperName = 'Local_Authority';
        mockRecordType.Name = 'Local Authority';
        List<RecordType> recordTypesToReturn = new List<RecordType>{ mockRecordType };

        Map<String, Object> coventryAccountFields = new Map<String, Object>{
            'Id' => SObjectUtil.generateIdForType('Account'),
            'Name' => 'COVENTRY CITY COUNCIL',
            'Local_Custodian_Code__c' => '4610'
        };
        Account coventryCityCouncil = (Account) SObjectUtil.makeSObject(Account.SObjectType, coventryAccountFields);

        Map<String, Object> bristolAccountFields = new Map<String, Object>{
            'Id' => SObjectUtil.generateIdForType('Account'),
            'Name' => 'BRISTOL CITY COUNCIL',
            'Local_Custodian_Code__c' => '116'
        };
        Account bristolCityCouncil = (Account) SObjectUtil.makeSObject(Account.SObjectType, bristolAccountFields);

        Map<String, Object> greenwichAccountFields = new Map<String, Object>{
            'Id' => SObjectUtil.generateIdForType('Account'),
            'Name' => 'ROYAL BOROUGH OF GREENWICH',
            'Local_Custodian_Code__c' => '5330'
        };
        Account greenwichCityCouncil = (Account) SObjectUtil.makeSObject(Account.SObjectType, greenwichAccountFields);

        Map<String, Object> bristolCityCouncilRelationshipFields = new Map<String, Object>{
            'Id' => SObjectUtil.generateIdForType('AccountContactRelation'),
            'Name' => 'BRISTOL CITY COUNCIL',
            'AccountId' => coventryCityCouncil.Id,
            'Account' => coventryCityCouncil
        };
        AccountContactRelation bristolCityCouncilRelationship = (AccountContactRelation) SObjectUtil.makeSObject(
            AccountContactRelation.SObjectType, 
            bristolCityCouncilRelationshipFields
        );

        Map<String, Object> greenwichCityCouncilRelationshipFields = new Map<String, Object>{
            'Id' => SObjectUtil.generateIdForType('AccountContactRelation'),
            'Name' => 'ROYAL BOROUGH OF GREENWICH',
            'AccountId' => greenwichCityCouncil.Id,
            'Account' => greenwichCityCouncil
        };
        AccountContactRelation greenwichCityCouncilRelationship = (AccountContactRelation) SObjectUtil.makeSObject(
            AccountContactRelation.SObjectType, 
            greenwichCityCouncilRelationshipFields
        );
        List<AccountContactRelation> accountContactRelationsToReturn = new List<AccountContactRelation> { 
            bristolCityCouncilRelationship, 
            greenwichCityCouncilRelationship 
        };

        Map<String, Object> userBindMap = new Map<String, Object> { 'userId' => userId };
        Map<String, Object> accountContractRelationBindMap = new Map<String, Object> { 
            'contactId' => contactId,
            'localAuthorityRecordTypeId' => mockRecordType.Id
        };
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.privilegedInstance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds('SELECT ContactId FROM User WHERE Id = :userId', userBindMap)
        ).thenReturn(usersToReturn);
        mockProvider.when(
            mockDatabaseWrapper.query('SELECT Id, Name, SOBjectType FROM RecordType WHERE SOBjectType = \'Account\' AND Name = \'Local Authority\' LIMIT 1')
        ).thenReturn(recordTypesToReturn);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Account.Name, Account.Local_Custodian_Code__c FROM AccountContactRelation WHERE ContactId = :contactId AND Account.RecordTypeId = :localAuthorityRecordTypeId', 
                accountContractRelationBindMap
            )
        ).thenThrow(new Exceptions.CustomException('An error has occured'));

        //Act
        Test.startTest();
        Map<String, String> localAuthorities = PRSE_LocalAuthorityDashboardController.getAssociatedLocalAuthorities();
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LocalAuthorityDashboardController', 'getAssociatedLocalAuthorities', 'An error has occured');
        Assert.isTrue(localAuthorities.isEmpty(), 'Expected no local authorities to be returned');
    }

    @isTest
    static void getAssociatedExemptionsCount_withNullLocalAuthorities_returnsZero() {
        //Arrange, Act
        Test.startTest();
        Integer exemptionCount = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsCount(
            null, 
            'Residential',
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, exemptionCount, 'Incorrect associated exemption count returned');
    }

    @isTest
    static void getAssociatedExemptionsCount_withEmptyLocalAuthorities_returnsZero() {
        //Arrange, Act
        Test.startTest();
        Integer exemptionCount = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsCount(
            new List<String>(), 
            'Residential',
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, exemptionCount, 'Incorrect associated exemption count returned');
    }

    @isTest
    static void getAssociatedExemptionsCount_withNullPropertyType_returnsZero() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        
        //Act
        Test.startTest();
        Integer exemptionCount = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsCount(
            localAuthorityCodes, 
            null,
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, exemptionCount, 'Incorrect associated exemption count returned');
    }

    @isTest
    static void getAssociatedExemptionsCount_withEmptyPropertyType_returnsZero() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = '';
        
        //Act
        Test.startTest();
        Integer exemptionCount = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsCount(
            localAuthorityCodes, 
            propertyType,
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, exemptionCount, 'Incorrect associated exemption count returned');
    }

    @isTest
    static void getAssociatedExemptionsCount_withWhitespacePropertyType_returnsZero() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = '   ';
        
        //Act
        Test.startTest();
        Integer exemptionCount = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsCount(
            localAuthorityCodes, 
            propertyType,
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, exemptionCount, 'Incorrect associated exemption count returned');
    }

    @isTest
    static void getAssociatedExemptionsCount_associatedExemptions_returnsCount() {
        //Arrange
        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Exemption_Type__c exemptionType1 = new Exemption_Type__c(
            Name = 'Type 1',
            Code__c = 'T001',
            IsCommercial__c = false
        );
        Exemption_Type__c exemptionType2 = new Exemption_Type__c(
            Name = 'Type 2',
            Code__c = 'T002',
            IsCommercial__c = false
        );
        insert new List<Exemption_Type__c> { exemptionType1, exemptionType2 };

        Exemption__c draftExemption = new Exemption__c(
            Status__c = 'Draft', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Draft exemption',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '5330'
        );
        Exemption__c receivedExemption1 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Received exemption 1',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '4610'
        );
        Exemption__c receivedExemption2 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Received exemption 2',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '4610'
        );
        Exemption__c updatedExemption = new Exemption__c(
            Status__c = 'Updated', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Updated exemption',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '4610'
        );
        insert new List<Exemption__c> { draftExemption, receivedExemption1, receivedExemption2, updatedExemption };

        Exemption_Type_Link__c exemption1childExemption1 = new Exemption_Type_Link__c(
            Exemption__c = draftExemption.Id,
            Exemption_Type__c = exemptionType1.Id
        );
        Exemption_Type_Link__c exemption1childExemption2 = new Exemption_Type_Link__c(
            Exemption__c = draftExemption.Id,
            Exemption_Type__c = exemptionType2.Id
        );
        Exemption_Type_Link__c exemption2childExemption = new Exemption_Type_Link__c(
            Exemption__c = receivedExemption1.Id,
            Exemption_Type__c = exemptionType1.Id
        );
        Exemption_Type_Link__c exemption3childExemption = new Exemption_Type_Link__c(
            Exemption__c = receivedExemption2.Id,
            Exemption_Type__c = exemptionType1.Id
        );
        Exemption_Type_Link__c exemption4childExemption = new Exemption_Type_Link__c(
            Exemption__c = updatedExemption.Id,
            Exemption_Type__c = exemptionType1.Id
        );
        Exemption_Type_Link__c exemption4childExemption2 = new Exemption_Type_Link__c(
            Exemption__c = updatedExemption.Id,
            Exemption_Type__c = exemptionType2.Id
        );
        insert new List<Exemption_Type_Link__c> { 
            exemption1childExemption1, exemption1childExemption2,  exemption2childExemption, 
            exemption3childExemption, exemption4childExemption, exemption4childExemption2
        };

        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';

        Map<String, Object> bindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes,
            'propertyType' => propertyType
        };
        
        //Act
        Test.startTest();
        Integer exemptionCount = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsCount(
            localAuthorityCodes, 
            propertyType,
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(3, exemptionCount, 'Incorrect associated exemption count returned');
    }

    @isTest
    static void getAssociatedExemptionsCount_associatedExemptionsWithFilters_returnsCount() {
        //Arrange
        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Exemption_Type__c exemptionType1 = new Exemption_Type__c(
            Name = 'Type 1',
            Code__c = 'T001',
            IsCommercial__c = false
        );
        Exemption_Type__c exemptionType2 = new Exemption_Type__c(
            Name = 'Type 2',
            Code__c = 'T002',
            IsCommercial__c = false
        );
        insert new List<Exemption_Type__c> { exemptionType1, exemptionType2 };

        Exemption__c draftExemption = new Exemption__c(
            Status__c = 'Draft', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Draft exemption',
            LandlordBusinessName__c = 'Frank\'s Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '5330'
        );
        Exemption__c receivedExemption1 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Received exemption 1',
            LandlordBusinessName__c = 'Frank\'s Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '4610'
        );
        Exemption__c receivedExemption2 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Received exemption 2',
            LandlordBusinessName__c = 'Frank\'s Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '4610'
        );
        Exemption__c updatedExemption = new Exemption__c(
            Status__c = 'Updated', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Updated exemption',
            LandlordBusinessName__c = 'Frank\'s Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '4610'
        );
        insert new List<Exemption__c> { draftExemption, receivedExemption1, receivedExemption2, updatedExemption };

        Exemption_Type_Link__c exemption1childExemption1 = new Exemption_Type_Link__c(
            Exemption__c = draftExemption.Id,
            Exemption_Type__c = exemptionType1.Id
        );
        Exemption_Type_Link__c exemption1childExemption2 = new Exemption_Type_Link__c(
            Exemption__c = draftExemption.Id,
            Exemption_Type__c = exemptionType2.Id
        );
        Exemption_Type_Link__c exemption2childExemption = new Exemption_Type_Link__c(
            Exemption__c = receivedExemption1.Id,
            Exemption_Type__c = exemptionType1.Id
        );
        Exemption_Type_Link__c exemption3childExemption = new Exemption_Type_Link__c(
            Exemption__c = receivedExemption2.Id,
            Exemption_Type__c = exemptionType1.Id
        );
        Exemption_Type_Link__c exemption4childExemption = new Exemption_Type_Link__c(
            Exemption__c = updatedExemption.Id,
            Exemption_Type__c = exemptionType1.Id
        );
        Exemption_Type_Link__c exemption4childExemption2 = new Exemption_Type_Link__c(
            Exemption__c = updatedExemption.Id,
            Exemption_Type__c = exemptionType2.Id
        );
        insert new List<Exemption_Type_Link__c> { 
            exemption1childExemption1, exemption1childExemption2,  exemption2childExemption, 
            exemption3childExemption, exemption4childExemption, exemption4childExemption2
        };

        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';
        String filters = '{"statuses": ["Received", "Ended"], "exemptionTypeCodes": ["T001", "T002"], "searchTerm": "   Frank\'s   "}';

        Map<String, Object> bindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes,
            'propertyType' => propertyType,
            'statuses' => new List<String>{ 'Received', 'Ended' },
            'exemptionTypeCodes' => new List<String>{ 'T001', 'T002' },
            'searchTerm' => '%   Frank\'s   %',
            'trimmedSearchTerm' => '%Frank\'s%'
        };
        
        //Act
        Test.startTest();
        Integer exemptionCount = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsCount(
            localAuthorityCodes, 
            propertyType,
            filters
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(2, exemptionCount, 'Incorrect associated exemption count returned');
    }

    @isTest
    static void getAssociatedExemptionsCount_throwsError_returnsZero() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';

        Map<String, Object> bindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes,
            'propertyType' => propertyType
        };

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
            'SELECT COUNT_DISTINCT(Exemption__c) parentCount FROM Exemption_Type_Link__c WHERE Exemption__r.Local_Custodian_Code__c IN :localAuthorityCodes AND Exemption__r.PropertyType__c = :propertyType AND Exemption__r.Status__c != \'Draft\'', 
            bindMap
        )).thenThrow(new Exceptions.CustomException('An error has occured'));
        
        //Act
        Test.startTest();
        Integer exemptionCount = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsCount(
            localAuthorityCodes, 
            propertyType,
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LocalAuthorityDashboardController', 'getAssociatedExemptionsCount', 'An error has occured');
        Assert.areEqual(0, exemptionCount, 'Incorrect associated parent exemption count returned');
    }

    @isTest
    static void getAssociatedExemptionsNeedingReviewCount_withNullLocalAuthorities_returnsZero() {
        //Arrange, Act
        Test.startTest();
        Integer exemptionCount = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsNeedingReviewCount(
            null, 
            'Residential'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, exemptionCount, 'Incorrect associated exemptions needing review count returned');
    }

    @isTest
    static void getAssociatedExemptionsNeedingReviewCount_withEmptyLocalAuthorities_returnsZero() {
        //Arrange, Act
        Test.startTest();
        Integer exemptionCount = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsNeedingReviewCount(
            new List<String>(), 
            'Residential'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, exemptionCount, 'Incorrect associated exemptions needing review count returned');
    }

    @isTest
    static void getAssociatedExemptionsNeedingReviewCount_withNullPropertyType_returnsZero() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        
        //Act
        Test.startTest();
        Integer exemptionCount = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsNeedingReviewCount(
            localAuthorityCodes, 
            null
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, exemptionCount, 'Incorrect associated exemptions needing review count returned');
    }

    @isTest
    static void getAssociatedExemptionsNeedingReviewCount_withEmptyPropertyType_returnsZero() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = '';
        
        //Act
        Test.startTest();
        Integer exemptionCount = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsNeedingReviewCount(
            localAuthorityCodes, 
            propertyType
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, exemptionCount, 'Incorrect associated exemptions needing review count returned');
    }

    @isTest
    static void getAssociatedExemptionsNeedingReviewCount_withWhitespacePropertyType_returnsZero() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = '   ';
        
        //Act
        Test.startTest();
        Integer exemptionCount = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsNeedingReviewCount(
            localAuthorityCodes, 
            propertyType
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, exemptionCount, 'Incorrect associated exemptions needing review count returned');
    }

    @isTest
    static void getAssociatedExemptionsNeedingReviewCount_associatedExemptions_returnsCount() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';

        Map<String, Object> bindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes,
            'propertyType' => propertyType
        };

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
            'SELECT COUNT() FROM Exemption__c WHERE Local_Custodian_Code__c IN :localAuthorityCodes AND Status__c IN (\'Updated\', \'Received\') AND PropertyType__c = :propertyType', 
            bindMap
        )).thenReturn(2);
        
        //Act
        Test.startTest();
        Integer exemptionCount = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsNeedingReviewCount(
            localAuthorityCodes, 
            propertyType
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(2, exemptionCount, 'Incorrect associated exemptions needing review count returned');
    }

    @isTest
    static void getAssociatedExemptionsNeedingReviewCount_throwsError_returnsZero() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';

        Map<String, Object> bindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes,
            'propertyType' => propertyType
        };

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
            'SELECT COUNT() FROM Exemption__c WHERE Local_Custodian_Code__c IN :localAuthorityCodes AND Status__c IN (\'Updated\', \'Received\') AND PropertyType__c = :propertyType', 
            bindMap
        )).thenThrow(new Exceptions.CustomException('An error has occured'));
        
        //Act
        Test.startTest();
        Integer exemptionCount = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsNeedingReviewCount(
            localAuthorityCodes, 
            propertyType
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LocalAuthorityDashboardController', 'getAssociatedExemptionsNeedingReviewCount', 'An error has occured');
        Assert.areEqual(0, exemptionCount, 'Incorrect associated exemptions needing review count returned');
    }

    @isTest
    static void getAssociatedExemptionsForLocalAuthorities_withNullLocalAuthorities_returnsEmptyResult() {
        //Arrange, Act
        Test.startTest();
        PRSE_LocalAuthorityDashboardController.PaginatedResult result = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsForLocalAuthorities(
            null, 
            'Residential',
            30,
            1,
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, result.records.size(), 'Incorrect number of Exemptions on PaginatedResult');
        Assert.areEqual(0, result.totalRecords, 'Incorrect total records on PaginatedResult');
        Assert.areEqual(30, result.pageSize, 'Incorrect page size on PaginatedResult');
        Assert.areEqual(1, result.pageNumber, 'Incorrect page number on PaginatedResult');
    }

    @isTest
    static void getAssociatedExemptionsForLocalAuthorities_withEmptyLocalAuthorities_returnsEmptyResult() {
        //Arrange, Act
        Test.startTest();
        PRSE_LocalAuthorityDashboardController.PaginatedResult result = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsForLocalAuthorities(
            new List<String>(), 
            'Residential',
            30,
            1,
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, result.records.size(), 'Incorrect number of Exemptions on PaginatedResult');
        Assert.areEqual(0, result.totalRecords, 'Incorrect total records on PaginatedResult');
        Assert.areEqual(30, result.pageSize, 'Incorrect page size on PaginatedResult');
        Assert.areEqual(1, result.pageNumber, 'Incorrect page number on PaginatedResult');
    }

    @isTest
    static void getAssociatedExemptionsForLocalAuthorities_withNullPropertyType_returnsEmptyResult() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = null;
        
        //Act
        Test.startTest();
        PRSE_LocalAuthorityDashboardController.PaginatedResult result = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsForLocalAuthorities(
            localAuthorityCodes, 
            propertyType,
            30,
            1,
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, result.records.size(), 'Incorrect number of Exemptions on PaginatedResult');
        Assert.areEqual(0, result.totalRecords, 'Incorrect total records on PaginatedResult');
        Assert.areEqual(30, result.pageSize, 'Incorrect page size on PaginatedResult');
        Assert.areEqual(1, result.pageNumber, 'Incorrect page number on PaginatedResult');
    }

    @isTest
    static void getAssociatedExemptionsForLocalAuthorities_withEmptyPropertyType_returnsEmptyResult() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = '';
        
        //Act
        Test.startTest();
        PRSE_LocalAuthorityDashboardController.PaginatedResult result = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsForLocalAuthorities(
            localAuthorityCodes, 
            propertyType,
            30,
            1,
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, result.records.size(), 'Incorrect number of Exemptions on PaginatedResult');
        Assert.areEqual(0, result.totalRecords, 'Incorrect total records on PaginatedResult');
        Assert.areEqual(30, result.pageSize, 'Incorrect page size on PaginatedResult');
        Assert.areEqual(1, result.pageNumber, 'Incorrect page number on PaginatedResult');
    }

    @isTest
    static void getAssociatedExemptionsForLocalAuthorities_withWhitespacePropertyType_returnsEmptyResult() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = '   ';
        
        //Act
        Test.startTest();
        PRSE_LocalAuthorityDashboardController.PaginatedResult result = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsForLocalAuthorities(
            localAuthorityCodes, 
            propertyType,
            30,
            1,
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, result.records.size(), 'Incorrect number of Exemptions on PaginatedResult');
        Assert.areEqual(0, result.totalRecords, 'Incorrect total records on PaginatedResult');
        Assert.areEqual(30, result.pageSize, 'Incorrect page size on PaginatedResult');
        Assert.areEqual(1, result.pageNumber, 'Incorrect page number on PaginatedResult');
    }

    @isTest
    static void getAssociatedExemptionsForLocalAuthorities_withNoParentExemptions_returnsEmptyResult() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';

        Map<String, Object> countBindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes,
            'propertyType' => propertyType
        };
        Map<String, Object> parentExemptionBindMap = new Map<String, Object> {
            'propertyType' => propertyType,
            'localAuthorityCodes' => localAuthorityCodes,
            'pageSize' => 30,
            'offsetValue' => 0
        };
        Map<String, Object> childExemptionBindMap = new Map<String, Object> {
            'parentIds' => new Set<Id>()
        };

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
            'SELECT COUNT() ' +
            'FROM Exemption__c ' +
            'WHERE Id IN (SELECT Exemption__c ' +
                         'FROM Exemption_Type_Link__c ' +
                         'WHERE Exemption__r.Local_Custodian_Code__c IN :localAuthorityCodes ' +
                         'AND Exemption__r.PropertyType__c = :propertyType AND Exemption__r.Status__c != \'Draft\')',
            countBindMap
        )).thenReturn(0);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Ref_Number__c, LandlordFirstName__c, LandlordLastName__c, LandlordBusinessName__c, ' +
                'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyCountry__c, PropertyPostcode__c, ' +
                'PropertyType__c, Status__c, Registered_Date__c, Full_Property_Address__c, ' +
                '(SELECT Id, Exemption__c, Exemption_Type__r.Name FROM ExemptionTypeLinks__r) ' +
                'FROM Exemption__c WHERE PropertyType__c = :propertyType AND Local_Custodian_Code__c IN :localAuthorityCodes AND Status__c != \'Draft\' ' +
                'AND Id IN (SELECT Exemption__c FROM Exemption_Type_Link__c) ' +
                'ORDER BY Status__c DESC, Registered_Date__c DESC ' +
                'LIMIT :pageSize ' +
                'OFFSET :offsetValue', 
                parentExemptionBindMap
            )
        ).thenReturn(new List<Exemption__c>());
        
        //Act
        Test.startTest();
        PRSE_LocalAuthorityDashboardController.PaginatedResult result = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsForLocalAuthorities(
            localAuthorityCodes, 
            propertyType,
            30,
            1,
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, result.records.size(), 'Incorrect number of Exemptions on PaginatedResult');
        Assert.areEqual(0, result.totalRecords, 'Incorrect total records on PaginatedResult');
        Assert.areEqual(30, result.pageSize, 'Incorrect page size on PaginatedResult');
        Assert.areEqual(1, result.pageNumber, 'Incorrect page number on PaginatedResult');
    }

    @isTest
    static void getAssociatedExemptionsForLocalAuthorities_withNoChildExemptions_returnsResultWithNoExemptions() {
        //Arrange
        Map<Id, Exemption__c> mockExemptions = createMockExemptions(10, false);
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';

        Map<String, Object> countBindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes,
            'propertyType' => propertyType
        };
        Map<String, Object> parentExemptionBindMap = new Map<String, Object> {
            'propertyType' => propertyType,
            'localAuthorityCodes' => localAuthorityCodes,
            'pageSize' => 30,
            'offsetValue' => 0
        };
        Map<String, Object> childExemptionBindMap = new Map<String, Object> {
            'parentIds' => mockExemptions.keySet()
        };

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
            'SELECT COUNT() ' +
            'FROM Exemption__c ' +
            'WHERE Id IN (SELECT Exemption__c ' +
                         'FROM Exemption_Type_Link__c ' +
                         'WHERE Exemption__r.Local_Custodian_Code__c IN :localAuthorityCodes ' +
                         'AND Exemption__r.PropertyType__c = :propertyType AND Exemption__r.Status__c != \'Draft\')',
            countBindMap
        )).thenReturn(10);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Ref_Number__c, LandlordFirstName__c, LandlordLastName__c, LandlordBusinessName__c, ' +
                'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyCountry__c, PropertyPostcode__c, ' +
                'PropertyType__c, Status__c, Registered_Date__c, Full_Property_Address__c, ' +
                '(SELECT Id, Exemption__c, Exemption_Type__r.Name FROM ExemptionTypeLinks__r) ' +
                'FROM Exemption__c WHERE PropertyType__c = :propertyType AND Local_Custodian_Code__c IN :localAuthorityCodes AND Status__c != \'Draft\' ' +
                'AND Id IN (SELECT Exemption__c FROM Exemption_Type_Link__c) ' +
                'ORDER BY Status__c DESC, Registered_Date__c DESC ' +
                'LIMIT :pageSize ' +
                'OFFSET :offsetValue', 
                parentExemptionBindMap
            )
        ).thenReturn(mockExemptions.values());
        
        //Act
        Test.startTest();
        PRSE_LocalAuthorityDashboardController.PaginatedResult result = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsForLocalAuthorities(
            localAuthorityCodes, 
            propertyType,
            30,
            1,
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, result.records.size(), 'Incorrect number of Exemptions on PaginatedResult');
        Assert.areEqual(10, result.totalRecords, 'Incorrect total records on PaginatedResult');
        Assert.areEqual(30, result.pageSize, 'Incorrect page size on PaginatedResult');
        Assert.areEqual(1, result.pageNumber, 'Incorrect page number on PaginatedResult');
    }

    @isTest
    static void getAssociatedExemptionsForLocalAuthorities_withParentAndChildExemptions_returnsResultWithExemptions() {
        //Arrange
        Map<Id, Exemption__c> mockExemptions = createMockExemptions(10, true);
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';

        Map<String, Object> countBindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes,
            'propertyType' => propertyType
        };
        Map<String, Object> parentExemptionBindMap = new Map<String, Object> {
            'propertyType' => propertyType,
            'localAuthorityCodes' => localAuthorityCodes,
            'pageSize' => 30,
            'offsetValue' => 0
        };
        Map<String, Object> childExemptionBindMap = new Map<String, Object> {
            'parentIds' => mockExemptions.keySet()
        };

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
            'SELECT COUNT() ' +
            'FROM Exemption__c ' +
            'WHERE Id IN (SELECT Exemption__c ' +
                         'FROM Exemption_Type_Link__c ' +
                         'WHERE Exemption__r.Local_Custodian_Code__c IN :localAuthorityCodes ' +
                         'AND Exemption__r.PropertyType__c = :propertyType AND Exemption__r.Status__c != \'Draft\')',
            countBindMap
        )).thenReturn(10);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Ref_Number__c, LandlordFirstName__c, LandlordLastName__c, LandlordBusinessName__c, ' +
                'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyCountry__c, PropertyPostcode__c, ' +
                'PropertyType__c, Status__c, Registered_Date__c, Full_Property_Address__c, ' +
                '(SELECT Id, Exemption__c, Exemption_Type__r.Name FROM ExemptionTypeLinks__r) ' +
                'FROM Exemption__c WHERE PropertyType__c = :propertyType AND Local_Custodian_Code__c IN :localAuthorityCodes AND Status__c != \'Draft\' ' +
                'AND Id IN (SELECT Exemption__c FROM Exemption_Type_Link__c) ' +
                'ORDER BY Status__c DESC, Registered_Date__c DESC ' +
                'LIMIT :pageSize ' +
                'OFFSET :offsetValue', 
                parentExemptionBindMap
            )
        ).thenReturn(mockExemptions.values());
        
        //Act
        Test.startTest();
        PRSE_LocalAuthorityDashboardController.PaginatedResult result = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsForLocalAuthorities(
            localAuthorityCodes, 
            propertyType,
            30,
            1,
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(10, result.records.size(), 'Incorrect number of Exemptions on PaginatedResult');
        Assert.areEqual(10, result.totalRecords, 'Incorrect total records on PaginatedResult');
        Assert.areEqual(30, result.pageSize, 'Incorrect page size on PaginatedResult');
        Assert.areEqual(1, result.pageNumber, 'Incorrect page number on PaginatedResult');

        for(Integer i = 0; i < 10; i++) {
            PRSE_LocalAuthorityDashboardController.Exemption singleExemption = result.records[i];
            String expectedLandlordName = 'First Name ' + i + ' Last Name ' + i;
            String expectedPropertyAddress = 'Address  ' + i + ', City  ' + i + ', County  ' + i + ', Country  ' + i + ', Postcode  ' + i;
            String expectedRegisteredDate = Datetime.now().addDays(i).format('dd/M/yyyy');
            Assert.areEqual(expectedLandlordName, singleExemption.landlordName, 'Incorrect landlord name on Exemption');
            Assert.areEqual(expectedPropertyAddress, singleExemption.propertyAddress, 'Incorrect property address on Exemption');
            Assert.areEqual('Received', singleExemption.status, 'Incorrect status on Exemption');
            Assert.areEqual(expectedRegisteredDate, singleExemption.registeredDate, 'Incorrect registered date on Exemption');
            Assert.areEqual('High Cost, New landlord', singleExemption.exemptionTypes, 'Incorrect exemptionTypes on Exemption');
        }
    }

    @isTest
    static void getAssociatedExemptionsForLocalAuthorities_withFilters_returnsResultWithExemptions() {
        //Arrange
        Map<Id, Exemption__c> mockExemptions = createMockExemptions(10, true);
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';
        String filters = '{"statuses": ["Received", "Ended"], "exemptionTypeCodes": ["5990"], "searchTerm": "   James James"}';

        Map<String, Object> countBindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes,
            'propertyType' => propertyType,
            'statuses' => new List<String>{ 'Received', 'Ended' },
            'exemptionTypeCodes' => new List<String>{ '5990' },
            'searchTerm' => '%James James%',
            'trimmedSearchTerm' => '%JamesJames%'
        };

        Map<String, Object> parentExemptionBindMap = new Map<String, Object> {
            'propertyType' => propertyType,
            'localAuthorityCodes' => localAuthorityCodes,
            'pageSize' => 30,
            'offsetValue' => 0,
            'statuses' => new List<String>{ 'Received', 'Ended' },
            'exemptionTypeCodes' => new List<String>{ '5990' },
            'searchTerm' => '%James James%',
            'trimmedSearchTerm' => '%JamesJames%'
        };
        Map<String, Object> childExemptionBindMap = new Map<String, Object> {
            'parentIds' => mockExemptions.keySet()
        };

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;

        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
                'SELECT COUNT() ' +
                'FROM Exemption__c ' +
                'WHERE Id IN (SELECT Exemption__c ' +
                            'FROM Exemption_Type_Link__c ' +
                            'WHERE Exemption__r.Local_Custodian_Code__c IN :localAuthorityCodes AND ' +
                            'Exemption__r.PropertyType__c = :propertyType AND Exemption__r.Status__c IN :statuses ' +
                            'AND Exemption_Type_Code__c IN :exemptionTypeCodes AND ' +
                            '(Exemption__r.Ref_Number__c LIKE :searchTerm OR Exemption__r.Ref_Number__c LIKE :trimmedSearchTerm OR ' +
                            'Exemption__r.Name LIKE :searchTerm OR Exemption__r.Name LIKE :trimmedSearchTerm OR ' +
                            'Exemption__r.LandlordFullName__c LIKE :searchTerm OR Exemption__r.LandlordFullName__c LIKE :trimmedSearchTerm OR ' +
                            'Exemption__r.LandlordBusinessName__c LIKE :searchTerm OR Exemption__r.LandlordBusinessName__c LIKE :trimmedSearchTerm OR ' +
                            'Exemption__r.PropertyAddress__c LIKE :searchTerm OR Exemption__r.PropertyAddress__c LIKE :trimmedSearchTerm OR ' +
                            'Exemption__r.PropertyCity__c LIKE :searchTerm OR Exemption__r.PropertyCity__c LIKE :trimmedSearchTerm OR ' +
                            'Exemption__r.PropertyCounty__c LIKE :searchTerm OR Exemption__r.PropertyCounty__c LIKE :trimmedSearchTerm OR ' +
                            'Exemption__r.PropertyCountry__c LIKE :searchTerm OR Exemption__r.PropertyCountry__c LIKE :trimmedSearchTerm OR ' +
                            'Exemption__r.PropertyPostcode__c LIKE :searchTerm OR Exemption__r.PropertyPostcode__c LIKE :trimmedSearchTerm OR ' +
                            'Exemption__r.Full_Property_Address__c LIKE :searchTerm OR Exemption__r.Full_Property_Address__c LIKE :trimmedSearchTerm))',
            countBindMap
        )).thenReturn(10);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
            'SELECT ' +
            'Id, Ref_Number__c, LandlordFirstName__c, LandlordLastName__c, LandlordBusinessName__c, PropertyAddress__c, PropertyCity__c, ' +
            'PropertyCounty__c, PropertyCountry__c, PropertyPostcode__c, PropertyType__c, Status__c, Registered_Date__c, Full_Property_Address__c, ' +
            '(SELECT Id, Exemption__c, Exemption_Type__r.Name FROM ExemptionTypeLinks__r) ' +
            'FROM Exemption__c ' +
            'WHERE PropertyType__c = :propertyType AND Local_Custodian_Code__c IN :localAuthorityCodes AND Status__c IN :statuses  ' +
            'AND (Ref_Number__c LIKE :searchTerm OR Ref_Number__c LIKE :trimmedSearchTerm OR ' +
            'LandlordFullName__c LIKE :searchTerm OR LandlordFullName__c LIKE :trimmedSearchTerm OR ' +
            'LandlordBusinessName__c LIKE :searchTerm OR LandlordBusinessName__c LIKE :trimmedSearchTerm OR ' + 
            'PropertyAddress__c LIKE :searchTerm OR PropertyAddress__c LIKE :trimmedSearchTerm OR ' +
            'PropertyCity__c LIKE :searchTerm OR PropertyCity__c LIKE :trimmedSearchTerm OR ' +
            'PropertyCounty__c LIKE :searchTerm OR PropertyCounty__c LIKE :trimmedSearchTerm OR ' +
            'PropertyCountry__c LIKE :searchTerm OR PropertyCountry__c LIKE :trimmedSearchTerm OR ' +
            'PropertyPostcode__c LIKE :searchTerm OR PropertyPostcode__c LIKE :trimmedSearchTerm OR ' +
            'Full_Property_Address__c LIKE :searchTerm OR Full_Property_Address__c LIKE :trimmedSearchTerm OR ' +
            'Name LIKE :searchTerm OR Name LIKE :trimmedSearchTerm)AND Id IN ' +
            '(SELECT Exemption__c FROM Exemption_Type_Link__c WHERE Exemption_Type_Code__c IN :exemptionTypeCodes) ' +
            'ORDER BY Status__c DESC, Registered_Date__c DESC LIMIT :pageSize OFFSET :offsetValue', 
                parentExemptionBindMap
            )
        ).thenReturn(mockExemptions.values());
        
        //Act
        Test.startTest();
        PRSE_LocalAuthorityDashboardController.PaginatedResult result = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsForLocalAuthorities(
            localAuthorityCodes, 
            propertyType,
            30,
            1,
            filters
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(10, result.records.size(), 'Incorrect number of Exemptions on PaginatedResult');
        Assert.areEqual(10, result.totalRecords, 'Incorrect total records on PaginatedResult');
        Assert.areEqual(30, result.pageSize, 'Incorrect page size on PaginatedResult');
        Assert.areEqual(1, result.pageNumber, 'Incorrect page number on PaginatedResult');

        for(Integer i = 0; i < 10; i++) {
            PRSE_LocalAuthorityDashboardController.Exemption singleExemption = result.records[i];
            String expectedLandlordName = 'First Name ' + i + ' Last Name ' + i;
            String expectedPropertyAddress = 'Address  ' + i + ', City  ' + i + ', County  ' + i + ', Country  ' + i + ', Postcode  ' + i;
            String expectedRegisteredDate = Datetime.now().addDays(i).format('dd/M/yyyy');
            Assert.areEqual(expectedLandlordName, singleExemption.landlordName, 'Incorrect landlord name on Exemption');
            Assert.areEqual(expectedPropertyAddress, singleExemption.propertyAddress, 'Incorrect property address on Exemption');
            Assert.areEqual('Received', singleExemption.status, 'Incorrect status on Exemption');
            Assert.areEqual(expectedRegisteredDate, singleExemption.registeredDate, 'Incorrect registered date on Exemption');
            Assert.areEqual('High Cost, New landlord', singleExemption.exemptionTypes, 'Incorrect exemptionTypes on Exemption');
        }
    }

    @isTest
    static void getAssociatedExemptionsForLocalAuthorities_withExceptionInCountQuery_returnsResultWithNoExemptions() {
        //Arrange
        Map<Id, Exemption__c> mockExemptions = createMockExemptions(10, true);
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';

        Map<String, Object> countBindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes,
            'propertyType' => propertyType
        };
        Map<String, Object> parentExemptionBindMap = new Map<String, Object> {
            'propertyType' => propertyType,
            'localAuthorityCodes' => localAuthorityCodes,
            'pageSize' => 30,
            'offsetValue' => 0
        };
        Map<String, Object> childExemptionBindMap = new Map<String, Object> {
            'parentIds' => mockExemptions.keySet()
        };

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
            'SELECT COUNT() ' +
            'FROM Exemption__c ' +
            'WHERE Id IN (SELECT Exemption__c ' +
                         'FROM Exemption_Type_Link__c ' +
                         'WHERE Exemption__r.Local_Custodian_Code__c IN :localAuthorityCodes ' +
                         'AND Exemption__r.PropertyType__c = :propertyType AND Exemption__r.Status__c != \'Draft\')',
            countBindMap
        )).thenThrow(new Exceptions.CustomException('An error has occured'));
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Ref_Number__c, LandlordFirstName__c, LandlordLastName__c, LandlordBusinessName__c, ' +
                'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyCountry__c, PropertyPostcode__c, ' +
                'PropertyType__c, Status__c, Registered_Date__c, Full_Property_Address__c, ' +
                '(SELECT Id, Exemption__c, Exemption_Type__r.Name FROM ExemptionTypeLinks__r) ' +
                'FROM Exemption__c WHERE PropertyType__c = :propertyType AND Local_Custodian_Code__c IN :localAuthorityCodes AND Status__c != \'Draft\' ' +
                'AND Id IN (SELECT Exemption__c FROM Exemption_Type_Link__c) ' +
                'ORDER BY Status__c DESC, Registered_Date__c DESC ' +
                'LIMIT :pageSize ' +
                'OFFSET :offsetValue', 
                parentExemptionBindMap
            )
        ).thenReturn(mockExemptions.values());
        
        //Act
        Test.startTest();
        PRSE_LocalAuthorityDashboardController.PaginatedResult result = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsForLocalAuthorities(
            localAuthorityCodes, 
            propertyType,
            30,
            1,
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LocalAuthorityDashboardController', 'getAssociatedExemptionsForLocalAuthorities', 'An error has occured');
        Assert.areEqual(0, result.records.size(), 'Incorrect number of Exemptions on PaginatedResult');
        Assert.areEqual(0, result.totalRecords, 'Incorrect total records on PaginatedResult');
        Assert.areEqual(30, result.pageSize, 'Incorrect page size on PaginatedResult');
        Assert.areEqual(1, result.pageNumber, 'Incorrect page number on PaginatedResult');
    }

    @isTest
    static void getAssociatedExemptionsForLocalAuthorities_withExceptionInParentQuery_loggsErrorAndReturnsResultWithNoExemptions() {
        //Arrange
        Map<Id, Exemption__c> mockExemptions = createMockExemptions(10, true);
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';

        Map<String, Object> countBindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes,
            'propertyType' => propertyType
        };
        Map<String, Object> parentExemptionBindMap = new Map<String, Object> {
            'propertyType' => propertyType,
            'localAuthorityCodes' => localAuthorityCodes,
            'pageSize' => 30,
            'offsetValue' => 0
        };
        Map<String, Object> childExemptionBindMap = new Map<String, Object> {
            'parentIds' => mockExemptions.keySet()
        };

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
            'SELECT COUNT() ' +
            'FROM Exemption__c ' +
            'WHERE Id IN (SELECT Exemption__c ' +
                         'FROM Exemption_Type_Link__c ' +
                         'WHERE Exemption__r.Local_Custodian_Code__c IN :localAuthorityCodes ' +
                         'AND Exemption__r.PropertyType__c = :propertyType AND Exemption__r.Status__c != \'Draft\')',
            countBindMap
        )).thenReturn(10);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Ref_Number__c, LandlordFirstName__c, LandlordLastName__c, LandlordBusinessName__c, ' +
                'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyCountry__c, PropertyPostcode__c, ' +
                'PropertyType__c, Status__c, Registered_Date__c, Full_Property_Address__c, ' +
                '(SELECT Id, Exemption__c, Exemption_Type__r.Name FROM ExemptionTypeLinks__r) ' +
                'FROM Exemption__c WHERE PropertyType__c = :propertyType AND Local_Custodian_Code__c IN :localAuthorityCodes AND Status__c != \'Draft\' ' +
                'AND Id IN (SELECT Exemption__c FROM Exemption_Type_Link__c) ' +
                'ORDER BY Status__c DESC, Registered_Date__c DESC ' +
                'LIMIT :pageSize ' +
                'OFFSET :offsetValue', 
                parentExemptionBindMap
            )
        ).thenThrow(new Exceptions.CustomException('An error has occured'));
        
        //Act
        Test.startTest();
        PRSE_LocalAuthorityDashboardController.PaginatedResult result = PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsForLocalAuthorities(
            localAuthorityCodes, 
            propertyType,
            30,
            1,
            '{}'
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LocalAuthorityDashboardController', 'getAssociatedExemptionsForLocalAuthorities', 'An error has occured');
        Assert.areEqual(0, result.records.size(), 'Incorrect number of Exemptions on PaginatedResult');
        Assert.areEqual(0, result.totalRecords, 'Incorrect total records on PaginatedResult');
        Assert.areEqual(30, result.pageSize, 'Incorrect page size on PaginatedResult');
        Assert.areEqual(1, result.pageNumber, 'Incorrect page number on PaginatedResult');
    }

    @isTest
    static void getExemptionsByStatus_withLocalAuthorityCodesAndPropertyTypeNotMatchingDatabaseRecords_returnsZerosAsMapValues() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';

        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Exemption__c exemptionWithWrongLocalAuthorityCode = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 1',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '5300'
        );
        Exemption__c exemptionWithWrongPropertyType = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 1',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Commercial',
            Local_Custodian_Code__c = '5330'
        );
        insert new List<Exemption__c> { exemptionWithWrongLocalAuthorityCode, exemptionWithWrongPropertyType };

        //Act
        Test.startTest();
        Map<String, Integer> result = PRSE_LocalAuthorityDashboardController.getExemptionsByStatus(localAuthorityCodes, propertyType);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        for(String exemptionStatus :result.keySet()) {
            Assert.areEqual(0, result.get(exemptionStatus), 'Incorrect number of Exemptions returned for status ' + exemptionStatus);
        }
    }

    @isTest
    static void getExemptionsByStatus_withLocalAuthorityCodesAndPropertyType_returnsMapWithValues() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';

        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Exemption__c draftExemption = new Exemption__c(
            Status__c = 'Draft', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 1',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '5330'
        );
        Exemption__c receivedExemption1 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 1',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '4610'
        );
        Exemption__c receivedExemption2 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 1',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '4610'
        );
        Exemption__c updatedExemption = new Exemption__c(
            Status__c = 'Updated', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 1',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '4610'
        );
        insert new List<Exemption__c> { draftExemption, receivedExemption1, receivedExemption2, updatedExemption };

        //Act
        Test.startTest();
        Map<String, Integer> result = PRSE_LocalAuthorityDashboardController.getExemptionsByStatus(localAuthorityCodes, propertyType);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(8, result.keySet().size(), 'Incorrect number of Exemption statuses returned');
        Assert.areEqual(0, result.get('Approved'), 'Incorrect number of Approved Exemptions returned');
        Assert.areEqual(1, result.get('Draft'), 'Incorrect number of Draft Exemptions returned');
        Assert.areEqual(0, result.get('Ended'), 'Incorrect number of Ended Exemptions returned');
        Assert.areEqual(0, result.get('Expired'), 'Incorrect number of Expired Exemptions returned');
        Assert.areEqual(0, result.get('Needs update'), 'Incorrect number of Needs update Exemptions returned');
        Assert.areEqual(0, result.get('Penalty sent'), 'Incorrect number of Penalty sent Exemptions returned');
        Assert.areEqual(2, result.get('Received'), 'Incorrect number of Received Exemptions returned');
        Assert.areEqual(1, result.get('Updated'), 'Incorrect number of Updated Exemptions returned');
    }

    @isTest
    static void getExemptionsByStatus_withErrorInProcess_logsErrorAndReturnsZerosAsMapValues() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';
        Map<String, Object> bindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes,
            'propertyType' => propertyType
        };

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT count(Id) numberOfRecords, Status__c ' +
                'FROM Exemption__c ' +
                'WHERE Local_Custodian_Code__c IN :localAuthorityCodes AND PropertyType__c = :propertyType ' +
                'GROUP BY Status__c', 
                bindMap
            )
        ).thenThrow(new Exceptions.CustomException('An error has occured'));

        //Act
        Test.startTest();
        Map<String, Integer> result = PRSE_LocalAuthorityDashboardController.getExemptionsByStatus(localAuthorityCodes, propertyType);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LocalAuthorityDashboardController', 'getExemptionsByStatus', 'An error has occured');
        for(String exemptionStatus :result.keySet()) {
            Assert.areEqual(0, result.get(exemptionStatus), 'Incorrect number of Exemptions returned for status ' + exemptionStatus);
        }
    }

    @isTest
    static void getExemptionsByType_withLocalAuthorityCodesAndPropertyTypeNotMatchingDatabaseRecords_returnsZerosAsMapValues() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';

        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Exemption_Type__c exemptionType1 = new Exemption_Type__c(
            Name = 'Type 1',
            Code__c = 'T001'
        );
        Exemption_Type__c exemptionType2 = new Exemption_Type__c(
            Name = 'Type 2',
            Code__c = 'T002'
        );
        insert new List<Exemption_Type__c> { exemptionType1, exemptionType2 };
        
        Exemption__c exemptionWithWrongLocalAuthorityCode = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 1',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '5300'
        );
        Exemption__c exemptionWithWrongPropertyType = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 1',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Commercial',
            Local_Custodian_Code__c = '5330'
        );
        insert new List<Exemption__c> { exemptionWithWrongLocalAuthorityCode, exemptionWithWrongPropertyType };

        Exemption_Type_Link__c childExemption1 = new Exemption_Type_Link__c(
            Exemption__c = exemptionWithWrongLocalAuthorityCode.Id,
            Exemption_Type__c = exemptionType1.Id
        );
        Exemption_Type_Link__c childExemption2 = new Exemption_Type_Link__c(
            Exemption__c = exemptionWithWrongPropertyType.Id,
            Exemption_Type__c = exemptionType2.Id
        );
        insert new List<Exemption_Type_Link__c> { childExemption1, childExemption2 };

        //Act
        Test.startTest();
        List<PRSE_LocalAuthorityDashboardController.RecordTypeInfo> results = 
            PRSE_LocalAuthorityDashboardController.getExemptionsByType(localAuthorityCodes, propertyType);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(2, results.size(), 'Incorrect number of Exemptions by type returned');
        for(PRSE_LocalAuthorityDashboardController.RecordTypeInfo singleRecordInfo :results) {
            Assert.areEqual(0, singleRecordInfo.numberOfRecords, 'Incorrect number of Exemptions returned for type ' + singleRecordInfo.name);
        }
    }

    @isTest
    static void getExemptionsByType_withLocalAuthorityCodesAndPropertyType_returnsMapWithValues() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';

        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Exemption_Type__c exemptionType1 = new Exemption_Type__c(
            Name = 'Type 1',
            Code__c = 'T001',
            IsCommercial__c = false
        );
        Exemption_Type__c exemptionType2 = new Exemption_Type__c(
            Name = 'Type 2',
            Code__c = 'T002',
            IsCommercial__c = false
        );
        insert new List<Exemption_Type__c> { exemptionType1, exemptionType2 };

        Exemption__c draftExemption = new Exemption__c(
            Status__c = 'Draft', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Draft exemption',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '5330'
        );
        Exemption__c receivedExemption1 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Received exemption 1',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '4610'
        );
        Exemption__c receivedExemption2 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Received exemption 2',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '4610'
        );
        Exemption__c updatedExemption = new Exemption__c(
            Status__c = 'Updated', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Updated exemption',
            LandlordBusinessName__c = 'Test Business Name',
            LandlordFirstName__c = 'Test First Name',
            LandlordLastName__c = 'Test Last Name',
            PropertyAddress__c = 'Address 123',
            PropertyCity__c = 'London',
            PropertyCounty__c = 'Greater London',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyType__c = 'Residential',
            Local_Custodian_Code__c = '4610'
        );
        insert new List<Exemption__c> { draftExemption, receivedExemption1, receivedExemption2, updatedExemption };

        Exemption_Type_Link__c exemption1childExemption1 = new Exemption_Type_Link__c(
            Exemption__c = draftExemption.Id,
            Exemption_Type__c = exemptionType1.Id
        );
        Exemption_Type_Link__c exemption1childExemption2 = new Exemption_Type_Link__c(
            Exemption__c = draftExemption.Id,
            Exemption_Type__c = exemptionType2.Id
        );
        Exemption_Type_Link__c exemption2childExemption = new Exemption_Type_Link__c(
            Exemption__c = receivedExemption1.Id,
            Exemption_Type__c = exemptionType1.Id
        );
        Exemption_Type_Link__c exemption3childExemption = new Exemption_Type_Link__c(
            Exemption__c = receivedExemption2.Id,
            Exemption_Type__c = exemptionType1.Id
        );
        Exemption_Type_Link__c exemption4childExemption = new Exemption_Type_Link__c(
            Exemption__c = updatedExemption.Id,
            Exemption_Type__c = exemptionType1.Id
        );
        Exemption_Type_Link__c exemption4childExemption2 = new Exemption_Type_Link__c(
            Exemption__c = updatedExemption.Id,
            Exemption_Type__c = exemptionType2.Id
        );
        insert new List<Exemption_Type_Link__c> { 
            exemption1childExemption1, exemption1childExemption2,  exemption2childExemption, 
            exemption3childExemption, exemption4childExemption, exemption4childExemption2
        };

        //Act
        Test.startTest();
        List<PRSE_LocalAuthorityDashboardController.RecordTypeInfo> results = 
            PRSE_LocalAuthorityDashboardController.getExemptionsByType(localAuthorityCodes, propertyType);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(2, results.size(), 'Incorrect number of Exemptions by type returned');
        PRSE_LocalAuthorityDashboardController.RecordTypeInfo exemptionType1Info = results[0];
        Assert.areEqual(exemptionType1.Name, exemptionType1Info.name, 'Incorrect name for type ' + exemptionType1Info.name);
        Assert.areEqual(exemptionType1.Code__c, exemptionType1Info.code, 'Incorrect code for type ' + exemptionType1Info.name);
        Assert.areEqual(3, exemptionType1Info.numberOfRecords, 'Incorrect number of Exemptions returned for type ' + exemptionType1Info.name);

        PRSE_LocalAuthorityDashboardController.RecordTypeInfo exemptionType2Info = results[1];
        Assert.areEqual(exemptionType2.Name, exemptionType2Info.name, 'Incorrect name for type ' + exemptionType2Info.name);
        Assert.areEqual(exemptionType2.Code__c, exemptionType2Info.code, 'Incorrect code for type ' + exemptionType2Info.name);
        Assert.areEqual(1, exemptionType2Info.numberOfRecords, 'Incorrect number of Exemptions returned for type ' + exemptionType2Info.name);
    }

    @isTest
    static void getExemptionsByType_withErrorInExemptionTypeQuery_logsErrorAndReturnsEmptyList() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';
        Map<String, Object> bindMap = new Map<String, Object> {
            'isCommercial' => false
        };

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Name, Code__c FROM Exemption_Type__c WHERE IsCommercial__c = :isCommercial ORDER BY Code__c', 
                bindMap
            )
        ).thenThrow(new Exceptions.CustomException('An error has occured'));

        //Act
        Test.startTest();
        List<PRSE_LocalAuthorityDashboardController.RecordTypeInfo> results = 
            PRSE_LocalAuthorityDashboardController.getExemptionsByType(localAuthorityCodes, propertyType);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LocalAuthorityDashboardController', 'getExemptionsByType', 'An error has occured');
        Assert.areEqual(0, results.size(), 'Incorrect number of Exemptions by type returned');
    }

    @isTest
    static void getExemptionsByType_withErrorInAggregateQuery_logsErrorAndReturnsZerosAsMapValues() {
        //Arrange
        Exemption_Type__c exemptionType1 = new Exemption_Type__c(
            Name = 'Type 1',
            Code__c = 'T001',
            IsCommercial__c = false
        );
        Exemption_Type__c exemptionType2 = new Exemption_Type__c(
            Name = 'Type 2',
            Code__c = 'T002',
            IsCommercial__c = false
        );
        List<Exemption_Type__c> exemptionsTypes = new List<Exemption_Type__c> { exemptionType1, exemptionType2 };

        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };
        String propertyType = 'Residential';
        Map<String, Object> exemptionTypesListBindMap = new Map<String, Object> {
            'isCommercial' => false
        };
        Map<String, Object> resultsByTypeBindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes,
            'propertyType' => propertyType
        };
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
            'SELECT Name, Code__c FROM Exemption_Type__c WHERE IsCommercial__c = :isCommercial ORDER BY Code__c',
            exemptionTypesListBindMap
        )).thenReturn(exemptionsTypes);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'Select count(Id) numberOfRecords, Exemption_Type__r.Name, Exemption_Type__r.Code__c ' + 
                'FROM Exemption_Type_Link__c ' + 
                'WHERE Exemption__r.Local_Custodian_Code__c IN :localAuthorityCodes ' +
                'AND Exemption__r.PropertyType__c = :propertyType ' +
                'AND Exemption__r.Status__c != \'Draft\'' +
                'GROUP BY Exemption_Type__r.Name, Exemption_Type__r.Code__c ' +
                'ORDER BY Exemption_Type__r.Code__c',
                resultsByTypeBindMap
            )
        ).thenThrow(new Exceptions.CustomException('An error has occured'));

        //Act
        Test.startTest();
        List<PRSE_LocalAuthorityDashboardController.RecordTypeInfo> results = 
            PRSE_LocalAuthorityDashboardController.getExemptionsByType(localAuthorityCodes, propertyType);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LocalAuthorityDashboardController', 'getExemptionsByType', 'An error has occured');
        Assert.areEqual(2, results.size(), 'Incorrect number of Exemptions by type returned');
        PRSE_LocalAuthorityDashboardController.RecordTypeInfo exemptionType1Info = results[0];
        Assert.areEqual(exemptionType1.Name, exemptionType1Info.name, 'Incorrect name for type ' + exemptionType1Info.name);
        Assert.areEqual(exemptionType1.Code__c, exemptionType1Info.code, 'Incorrect code for type ' + exemptionType1Info.name);
        Assert.areEqual(0, exemptionType1Info.numberOfRecords, 'Incorrect number of Exemptions returned for type ' + exemptionType1Info.name);

        PRSE_LocalAuthorityDashboardController.RecordTypeInfo exemptionType2Info = results[1];
        Assert.areEqual(exemptionType2.Name, exemptionType2Info.name, 'Incorrect name for type ' + exemptionType2Info.name);
        Assert.areEqual(exemptionType2.Code__c, exemptionType2Info.code, 'Incorrect code for type ' + exemptionType2Info.name);
        Assert.areEqual(0, exemptionType2Info.numberOfRecords, 'Incorrect number of Exemptions returned for type ' + exemptionType2Info.name);
    }

    @isTest
    static void getPenaltiesByType_withLocalAuthorityCodesAndNoMatchingDatabaseRecords_returnsZerosAsMapValues() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };

        Penalty_Type__c penaltyType1 = new Penalty_Type__c(
            Name = 'Type 1',
            Code__c = 'T001'
        );
        Penalty_Type__c penaltyType2 = new Penalty_Type__c(
            Name = 'Type 2',
            Code__c = 'T002'
        );
        insert new List<Penalty_Type__c> { penaltyType1, penaltyType2 };

        Penalty__c penalty1 = new Penalty__c(
            Issued_Date__c = Date.newInstance(2024, 04, 12),
            Penalty_Amount__c = 2000,
            Penalty_Reference__c = 'Penalty Reference Before',
            Penalty_Type__c = penaltyType1.Id,
            Published__c = false,
            Local_Custodian_Code__c = '4710'
        );
        Penalty__c penalty2 = new Penalty__c(
            Issued_Date__c = Date.newInstance(2024, 04, 12),
            Penalty_Amount__c = 2000,
            Penalty_Reference__c = 'Penalty Reference Before',
            Penalty_Type__c = penaltyType2.Id,
            Published__c = false,
            Local_Custodian_Code__c = '5300'
        );

        //Act
        Test.startTest();
        List<PRSE_LocalAuthorityDashboardController.RecordTypeInfo> results = 
            PRSE_LocalAuthorityDashboardController.getPenaltiesByType(localAuthorityCodes);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(2, results.size(), 'Incorrect number of Exemptions by type returned');
        for(PRSE_LocalAuthorityDashboardController.RecordTypeInfo singleRecordInfo :results) {
            Assert.areEqual(0, singleRecordInfo.numberOfRecords, 'Incorrect number of Penalties returned for type ' + singleRecordInfo.name);
        }
    }

    @isTest
    static void getPenaltiesByType_withLocalAuthorityCodes_returnsMapWithValues() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };

        Penalty_Type__c penaltyType1 = new Penalty_Type__c(
            Name = 'Type 1',
            Code__c = 'T001'
        );
        Penalty_Type__c penaltyType2 = new Penalty_Type__c(
            Name = 'Type 2',
            Code__c = 'T002'
        );
        insert new List<Penalty_Type__c> { penaltyType1, penaltyType2 };

        Penalty__c penalty1 = new Penalty__c(
            Issued_Date__c = Date.newInstance(2024, 04, 12),
            Penalty_Amount__c = 2000,
            Penalty_Reference__c = 'Penalty Reference 1',
            Penalty_Type__c = penaltyType1.Id,
            Published__c = false,
            Local_Custodian_Code__c = localAuthorityCodes[0]
        );
        Penalty__c penalty2 = new Penalty__c(
            Issued_Date__c = Date.newInstance(2024, 04, 12),
            Penalty_Amount__c = 2000,
            Penalty_Reference__c = 'Penalty Reference 2',
            Penalty_Type__c = penaltyType1.Id,
            Published__c = false,
            Local_Custodian_Code__c = localAuthorityCodes[1]
        );
        Penalty__c penalty3 = new Penalty__c(
            Issued_Date__c = Date.newInstance(2024, 04, 12),
            Penalty_Amount__c = 2000,
            Penalty_Reference__c = 'Penalty Reference 3',
            Penalty_Type__c = penaltyType1.Id,
            Published__c = false,
            Local_Custodian_Code__c = localAuthorityCodes[0]
        );
        Penalty__c penalty4 = new Penalty__c(
            Issued_Date__c = Date.newInstance(2024, 04, 12),
            Penalty_Amount__c = 2000,
            Penalty_Reference__c = 'Penalty Reference 4',
            Penalty_Type__c = penaltyType2.Id,
            Published__c = false,
            Local_Custodian_Code__c = localAuthorityCodes[1]
        );
        Penalty__c penalty5 = new Penalty__c(
            Issued_Date__c = Date.newInstance(2024, 04, 12),
            Penalty_Amount__c = 2000,
            Penalty_Reference__c = 'Penalty Reference 5',
            Penalty_Type__c = penaltyType2.Id,
            Published__c = false,
            Local_Custodian_Code__c = localAuthorityCodes[1]
        );
        insert new List<Penalty__c> { penalty1, penalty2, penalty3, penalty4, penalty5 };

        //Act
        Test.startTest();
        List<PRSE_LocalAuthorityDashboardController.RecordTypeInfo> results = 
            PRSE_LocalAuthorityDashboardController.getPenaltiesByType(localAuthorityCodes);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(2, results.size(), 'Incorrect number of Exemptions by type returned');
        PRSE_LocalAuthorityDashboardController.RecordTypeInfo penaltyType1Info = results[0];
        Assert.areEqual(penaltyType1.Name, penaltyType1Info.name, 'Incorrect name for type ' + penaltyType1Info.name);
        Assert.areEqual(penaltyType1.Code__c, penaltyType1Info.code, 'Incorrect code for type ' + penaltyType1Info.name);
        Assert.areEqual(3, penaltyType1Info.numberOfRecords, 'Incorrect number of Exemptions returned for type ' + penaltyType1Info.name);

        PRSE_LocalAuthorityDashboardController.RecordTypeInfo penaltyType2Info = results[1];
        Assert.areEqual(penaltyType2.Name, penaltyType2Info.name, 'Incorrect name for type ' + penaltyType2Info.name);
        Assert.areEqual(penaltyType2.Code__c, penaltyType2Info.code, 'Incorrect code for type ' + penaltyType2Info.name);
        Assert.areEqual(2, penaltyType2Info.numberOfRecords, 'Incorrect number of Exemptions returned for type ' + penaltyType2Info.name);
    }

    @isTest
    static void getPenaltiesByType_withErrorInPenaltyTypeQuery_logsErrorAndReturnsEmptyList() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.query(
                'SELECT Name, Code__c FROM Penalty_Type__c ORDER BY Code__c'
            )
        ).thenThrow(new Exceptions.CustomException('An error has occured'));

        //Act
        Test.startTest();
        List<PRSE_LocalAuthorityDashboardController.RecordTypeInfo> results = 
            PRSE_LocalAuthorityDashboardController.getPenaltiesByType(localAuthorityCodes);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LocalAuthorityDashboardController', 'getPenaltiesByType', 'An error has occured');
        Assert.areEqual(0, results.size(), 'Incorrect number of Exemptions by type returned');
    }

    @isTest
    static void getPenaltiesByType_withErrorInAggregateQuery_logsErrorAndReturnsZerosAsMapValues() {
        //Arrange
        List<String> localAuthorityCodes = new List<String> {
            '4610',
            '5330'
        };

        Penalty_Type__c penaltyType1 = new Penalty_Type__c(
            Name = 'Type 1',
            Code__c = 'T001'
        );
        Penalty_Type__c penaltyType2 = new Penalty_Type__c(
            Name = 'Type 2',
            Code__c = 'T002'
        );
        List<Penalty_Type__c> penaltyTypes = new List<Penalty_Type__c> { penaltyType1, penaltyType2 };

        Map<String, Object> resultsByTypeBindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes
        };
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.query(
           'SELECT Name, Code__c FROM Penalty_Type__c ORDER BY Code__c'
        )).thenReturn(penaltyTypes);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT COUNT(Id) numberOfRecords, Penalty_Type__r.Name ' +
                'FROM Penalty__c ' +
                'WHERE Local_Custodian_Code__c IN :localAuthorityCodes ' +
                'GROUP BY Penalty_Type__r.Name',
                resultsByTypeBindMap
            )
        ).thenThrow(new Exceptions.CustomException('An error has occured'));

        //Act
        Test.startTest();
        List<PRSE_LocalAuthorityDashboardController.RecordTypeInfo> results = 
            PRSE_LocalAuthorityDashboardController.getPenaltiesByType(localAuthorityCodes);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LocalAuthorityDashboardController', 'getPenaltiesByType', 'An error has occured');
        Assert.areEqual(2, results.size(), 'Incorrect number of Exemptions by type returned');
        PRSE_LocalAuthorityDashboardController.RecordTypeInfo penaltyType1Info = results[0];
        Assert.areEqual(penaltyType1.Name, penaltyType1Info.name, 'Incorrect name for type ' + penaltyType1Info.name);
        Assert.areEqual(penaltyType1.Code__c, penaltyType1Info.code, 'Incorrect code for type ' + penaltyType1Info.name);
        Assert.areEqual(0, penaltyType1Info.numberOfRecords, 'Incorrect number of Exemptions returned for type ' + penaltyType1Info.name);

        PRSE_LocalAuthorityDashboardController.RecordTypeInfo penaltyType2Info = results[1];
        Assert.areEqual(penaltyType2.Name, penaltyType2Info.name, 'Incorrect name for type ' + penaltyType2Info.name);
        Assert.areEqual(penaltyType2.Code__c, penaltyType2Info.code, 'Incorrect code for type ' + penaltyType2Info.name);
        Assert.areEqual(0, penaltyType2Info.numberOfRecords, 'Incorrect number of Exemptions returned for type ' + penaltyType2Info.name);
    }

    static Map<Id, Exemption__c> createMockExemptions(Integer numberOfExemptions, Boolean withChildExemptions) {
        Map<Id, Exemption__c> parentExemptionsToReturn = new Map<Id, Exemption__c>();
        List<Exemption_Type_Link__c> childExemptionsToReturn = new List<Exemption_Type_Link__c>();

        for(Integer i = 0; i < numberOfExemptions; i++) {
            Id exemptionId = SObjectUtil.generateIdForType('Exemption__c');
            Map<String, Object> parentExemptionFields = new Map<String, Object> {
                'LandlordFirstName__c' => 'First Name ' + i,
                'LandlordLastName__c' => 'Last Name ' + i,
                'PropertyAddress__c' => 'Address  ' + i,
                'PropertyCity__c' => 'City  ' + i,
                'PropertyCounty__c' => 'County  ' + i,
                'PropertyCountry__c' => 'Country  ' + i,
                'PropertyPostcode__c' => 'Postcode  ' + i,
                'Full_Property_Address__c' => 'Address  ' + i + ', City  ' + i + ', County  ' + i + ', Country  ' + i + ', Postcode  ' + i,
                'Status__c' => 'Received',
                'Registered_Date__c' => Datetime.now().addDays(i)
            };
            Exemption__c singleExemption = (Exemption__c) SObjectUtil.makeSObject(
                Exemption__c.SObjectType,
                parentExemptionFields
            );
            singleExemption.Id = exemptionId;
            
            if(withChildExemptions) {
                Map<Id, Exemption_Type_Link__c> relatedChildExemptions = new Map<Id, Exemption_Type_Link__c>(createChildMockExemptions(singleExemption));
                childExemptionsToReturn.addAll(relatedChildExemptions.values());
            
                Map<String, Object> childFields = new Map<String, Object> {
                    'ExemptionTypeLinks__r' => relatedChildExemptions.values()
                };
                
                singleExemption = (Exemption__c) SObjectUtil.updateSObject(
                    singleExemption, 
                    childFields
                );
            }
            parentExemptionsToReturn.put(singleExemption.Id, singleExemption);
        }

        return parentExemptionsToReturn;
    }

    static List<Exemption_Type_Link__c> createChildMockExemptions(Exemption__c parentExemption) {
        List<Exemption_Type_Link__c> childExemptionsToReturn = new List<Exemption_Type_Link__c>();

        Exemption_Type__c highCostExemptionType = new Exemption_Type__c();
        highCostExemptionType.Id = SObjectUtil.generateIdForType('Exemption_Type__c');
        highCostExemptionType.Name = 'High Cost';

        Exemption_Type__c newLandlordExemptionType = new Exemption_Type__c();
        newLandlordExemptionType.Id = SObjectUtil.generateIdForType('Exemption_Type__c');
        newLandlordExemptionType.Name = 'New landlord';

        Map<String, Object>  highCostChilExemptionFields = new Map<String, Object> {
            'Id' => SObjectUtil.generateIdForType('Exemption_Type_Link__c'),
            'Name' => highCostExemptionType.Name,
            'Exemption_Type__c' => highCostExemptionType.Id,
            'Exemption_Type__r' => highCostExemptionType,
            'Exemption__c' => parentExemption.Id,
            'Exemption__r' => parentExemption
        };
        Exemption_Type_Link__c highCostChildExemption = (Exemption_Type_Link__c) SObjectUtil.makeSObject(
            Exemption_Type_Link__c.SObjectType, 
            highCostChilExemptionFields
        );
        childExemptionsToReturn.add(highCostChildExemption);

        Map<String, Object>  newLandlordChilExemptionFields = new Map<String, Object> {
            'Id' => SObjectUtil.generateIdForType('Exemption_Type_Link__c'),
            'Name' => newLandlordExemptionType.Name,
            'Exemption_Type__c' => newLandlordExemptionType.Id,
            'Exemption_Type__r' => newLandlordExemptionType,
            'Exemption__c' => parentExemption.Id,
            'Exemption__r' => parentExemption
        };
        Exemption_Type_Link__c newLandlordChildExemption = (Exemption_Type_Link__c) SObjectUtil.makeSObject(
            Exemption_Type_Link__c.SObjectType, 
            newLandlordChilExemptionFields
        );
        childExemptionsToReturn.add(newLandlordChildExemption);

        return childExemptionsToReturn;
    }
}