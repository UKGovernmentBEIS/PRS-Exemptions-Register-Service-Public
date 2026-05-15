@isTest(IsParallel=true)
private class PRSE_LADashboardPenaltiesControllerTest {
    
    @isTest
    static void hasAccessToParentExemption_withAccessToExemption_returnsTrue() {
        //Arrange
        Id mockExemptionId = SObjectUtil.generateIdForType('Exemption__c');
        MockProvider mockProvider = new MockProvider();
        PRSE_LAViewExemptionHelper mockExemptionHelper = (PRSE_LAViewExemptionHelper) mockProvider.createMock(PRSE_LAViewExemptionHelper.class);
        PRSE_LAViewExemptionHelper.instance = mockExemptionHelper;
        mockProvider.when(mockExemptionHelper.checkExemptionInstance(mockExemptionId)).thenReturn(true);

        //Act
        Test.startTest();
        Boolean hasAccess = PRSE_LADashboardPenaltiesController.hasAccessToParentExemption(mockExemptionId);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(true, hasAccess, 'Expected to have access to Exemption');
    }

    @isTest
    static void hasAccessToParentExemption_withoutAccessToExemption_returnsFalse() {
        //Arrange
        Id mockExemptionId = SObjectUtil.generateIdForType('Exemption__c');
        MockProvider mockProvider = new MockProvider();
        PRSE_LAViewExemptionHelper mockExemptionHelper = (PRSE_LAViewExemptionHelper) mockProvider.createMock(PRSE_LAViewExemptionHelper.class);
        PRSE_LAViewExemptionHelper.instance = mockExemptionHelper;
        mockProvider.when(mockExemptionHelper.checkExemptionInstance(mockExemptionId)).thenReturn(false);

        //Act
        Test.startTest();
        Boolean hasAccess = PRSE_LADashboardPenaltiesController.hasAccessToParentExemption(mockExemptionId);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(false, hasAccess, 'Expected to have access to Exemption');
    }

    @isTest
    static void hasAccessToParentExemption_withErrorInMethodCall_logsErrorAndReturnsFalse() {
        //Arrange
        Id mockExemptionId = SObjectUtil.generateIdForType('Exemption__c');
        MockProvider mockProvider = new MockProvider();
        PRSE_LAViewExemptionHelper mockExemptionHelper = (PRSE_LAViewExemptionHelper) mockProvider.createMock(PRSE_LAViewExemptionHelper.class);
        PRSE_LAViewExemptionHelper.instance = mockExemptionHelper;
        mockProvider.when(mockExemptionHelper.checkExemptionInstance(mockExemptionId)).thenThrow(new Exceptions.CustomException('An error has occured'));

        //Act
        Test.startTest();
        Boolean hasAccess = PRSE_LADashboardPenaltiesController.hasAccessToParentExemption(mockExemptionId);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LADashboardPenaltiesController', 'hasAccessToParentExemption', 'An error has occured');
        Assert.areEqual(false, hasAccess, 'Expected to have access to Exemption');
    }

    @isTest
    static void getAssociatedChildExemptions_withNoParentExemptionId_returnsEmptyList() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;

        Id parentExemptionId = null;
        Map<String, Object> bindMap = new Map<String, Object> { 'parentExemptionId' => parentExemptionId };
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Child_Exemption_Ref__c, End_Date__c, Name ' +
                'FROM Exemption_Type_Link__c ' +
                'WHERE Exemption__c  = :parentExemptionId AND End_Date__c = NULL',
                bindMap
            )
        ).thenReturn(new List<Exemption_Type_Link__c>());
        
        //Act
        Test.startTest();
        List<Exemption_Type_Link__c> childExemptions = PRSE_LADashboardPenaltiesController.getAssociatedChildExemptions(parentExemptionId);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.isTrue(childExemptions.isEmpty(), 'Expected no Child Exemptions to be returned.');
    }

    @isTest
    static void getAssociatedChildExemptions_withParentExemptionId_returnsChildExemptions() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        PRSE_LAViewExemptionHelper mockExemptionHelper = (PRSE_LAViewExemptionHelper) mockProvider.createMock(PRSE_LAViewExemptionHelper.class);
        PRSE_LAViewExemptionHelper.instance = mockExemptionHelper;
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;

        ExemptionData exemptions = createMockExemptions(3, true);
        Id parentExemptionId = exemptions.getParentExemptions()[0].Id;
        mockProvider.when(mockExemptionHelper.checkExemptionInstance(parentExemptionId)).thenReturn(true);
        List<Exemption_Type_Link__c> childExemptionsToReturn = exemptions.getChildExemptionsForParent(parentExemptionId);
        Map<String, Object> bindMap = new Map<String, Object> { 
            'parentExemptionId' => parentExemptionId
        };
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Child_Exemption_Ref__c, End_Date__c, Name ' +
                'FROM Exemption_Type_Link__c ' +
                'WHERE Exemption__c  = :parentExemptionId AND End_Date__c = NULL',
                bindMap
            )
        ).thenReturn(childExemptionsToReturn);
        
        //Act
        List<Exemption_Type_Link__c> childExemptions = PRSE_LADashboardPenaltiesController.getAssociatedChildExemptions(parentExemptionId);

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(2, childExemptions.size(), 'Incorrect number of Child Exemptions returned.');
        Assert.areEqual(childExemptionsToReturn[0], childExemptions[0], 'Incorrect Child Exemption returned.');
        Assert.areEqual(childExemptionsToReturn[1], childExemptions[1], 'Incorrect Child Exemption returned.');
    }

    @isTest
    static void getAssociatedChildExemptions_queryError_catchesErrorAndReturnsEmptyList() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        PRSE_LAViewExemptionHelper mockExemptionHelper = (PRSE_LAViewExemptionHelper) mockProvider.createMock(PRSE_LAViewExemptionHelper.class);
        PRSE_LAViewExemptionHelper.instance = mockExemptionHelper;
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;

        Id parentExemptionId = SObjectUtil.generateIdForType('Exemption__c');
        mockProvider.when(mockExemptionHelper.checkExemptionInstance(parentExemptionId)).thenReturn(true);
        Map<String, Object> bindMap = new Map<String, Object> { 'parentExemptionId' => parentExemptionId };
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Child_Exemption_Ref__c, End_Date__c, Name ' +
                'FROM Exemption_Type_Link__c ' +
                'WHERE Exemption__c  = :parentExemptionId AND End_Date__c = NULL',
                bindMap
            )
        ).thenThrow(new Exceptions.CustomException('An error has occured'));
        
        //Act
        Test.startTest();
        List<Exemption_Type_Link__c> childExemptions = PRSE_LADashboardPenaltiesController.getAssociatedChildExemptions(parentExemptionId);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LADashboardPenaltiesController', 'getAssociatedChildExemptions', 'An error has occured');
        Assert.isTrue(childExemptions.isEmpty(), 'Expected no Child Exemptions to be returned.');
    }

    @isTest
    static void getAssociatedPenalties_withNoParentExemptionId_returnsEmptyResult() {
        //Arrange, Act
        Test.startTest();
        PRSE_LADashboardPenaltiesController.PaginatedResult penaltyResult = PRSE_LADashboardPenaltiesController.getAssociatedPenalties(
            null,
            30,
            1
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.isTrue(penaltyResult.records.isEmpty(), 'Expected no Penalties to be returned.');
        Assert.areEqual(0, penaltyResult.totalRecords, 'Incorrect number of total records returned.');
        Assert.areEqual(30, penaltyResult.pageSize, 'Incorrect page size returned.');
        Assert.areEqual(1, penaltyResult.pageNumber, 'Incorrect page number returned.');
    }

    @isTest
    static void getAssociatedPenalties_withNoPenaltiesAvailable_returnsEmptyResult() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        PRSE_LAViewExemptionHelper mockExemptionHelper = (PRSE_LAViewExemptionHelper) mockProvider.createMock(PRSE_LAViewExemptionHelper.class);
        PRSE_LAViewExemptionHelper.instance = mockExemptionHelper;
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;

        Id parentExemptionId = SObjectUtil.generateIdForType('Exemption__c');
        mockProvider.when(mockExemptionHelper.checkExemptionInstance(parentExemptionId)).thenReturn(true);
        Map<String, Object> countBindMap = new Map<String, Object> { 
            'parentExemptionId' => parentExemptionId
        };
        Map<String, Object> penaltiesBindMap = new Map<String, Object> { 
            'parentExemptionId' => parentExemptionId,
            'pageSize' => 30,
            'offsetValue' => 0
        };
        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
                'SELECT COUNT() FROM Penalty__c WHERE Exemption__c = :parentExemptionId',
                countBindMap
            )
        ).thenReturn(0);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Exemption__c, Penalty_Reference__c, Exemption_Type_Link__c, Exemption_Type_Link__r.Name, ' +
                'Penalty_Type__c, Penalty_Type__r.Name, Issued_Date__c, Unpublish_Date__c, Published__c, Penalty_Amount__c, ' +
                'LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c, ' +
                'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c, PropertyType__c, Full_Property_Address__c ' +
                'FROM Penalty__c ' +
                'WHERE Exemption__c = :parentExemptionId ' +
                'ORDER BY Issued_Date__c DESC ' +
                'LIMIT :pageSize ' +
                'OFFSET :offsetValue',
                penaltiesBindMap
            )
        ).thenReturn(new List<Penalty__c>());

        //Act
        Test.startTest();
        PRSE_LADashboardPenaltiesController.PaginatedResult penaltyResult = PRSE_LADashboardPenaltiesController.getAssociatedPenalties(
            parentExemptionId,
            30,
            1
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.isTrue(penaltyResult.records.isEmpty(), 'Expected no Penalties to be returned.');
        Assert.areEqual(0, penaltyResult.totalRecords, 'Incorrect number of total records returned.');
        Assert.areEqual(30, penaltyResult.pageSize, 'Incorrect page size returned.');
        Assert.areEqual(1, penaltyResult.pageNumber, 'Incorrect page number returned.');
    }

    @isTest
    static void getAssociatedPenalties_withPenaltiesAvailableForParentExemptionId_returnsResultWithPenalties() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        PRSE_LAViewExemptionHelper mockExemptionHelper = (PRSE_LAViewExemptionHelper) mockProvider.createMock(PRSE_LAViewExemptionHelper.class);
        PRSE_LAViewExemptionHelper.instance = mockExemptionHelper;
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        
        ExemptionData exemptions = createMockExemptions(3, true);
        Exemption__c parentExemption = exemptions.getParentExemptions()[1];
        Id parentExemptionId = parentExemption.Id;
        mockProvider.when(mockExemptionHelper.checkExemptionInstance(parentExemptionId)).thenReturn(true);
        Map<String, Object> countBindMap = new Map<String, Object> { 
            'parentExemptionId' => parentExemptionId
        };
        Map<String, Object> penaltiesBindMap = new Map<String, Object> { 
            'parentExemptionId' => parentExemptionId,
            'pageSize' => 30,
            'offsetValue' => 0
        };
        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
                'SELECT COUNT() FROM Penalty__c WHERE Exemption__c = :parentExemptionId',
                countBindMap
            )
        ).thenReturn(3);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Exemption__c, Penalty_Reference__c, Exemption_Type_Link__c, Exemption_Type_Link__r.Name, ' +
                'Penalty_Type__c, Penalty_Type__r.Name, Issued_Date__c, Unpublish_Date__c, Published__c, Penalty_Amount__c, ' +
                'LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c, ' +
                'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c, PropertyType__c, Full_Property_Address__c ' +
                'FROM Penalty__c ' +
                'WHERE Exemption__c = :parentExemptionId ' +
                'ORDER BY Issued_Date__c DESC ' +
                'LIMIT :pageSize ' +
                'OFFSET :offsetValue',
                penaltiesBindMap
            )
        ).thenReturn(createMockPenalties(3, parentExemption));

        //Act
        Test.startTest();
        PRSE_LADashboardPenaltiesController.PaginatedResult penaltyResult = PRSE_LADashboardPenaltiesController.getAssociatedPenalties(
            parentExemptionId,
            30,
            1
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(3, penaltyResult.records.size(), 'Incorrect number of Penalties returned.');
        Date todaysDate = Date.today();
        Date unpublishedDate = Date.today().addMonths(1);
        for(Integer i = 0; i < penaltyResult.records.size(); i++) {
            PRSE_LADashboardPenaltiesController.Penalty singlePenalty = penaltyResult.records[i];
            String issuedDate = todaysDate.day() + '/' + todaysDate.month() + '/' + todaysDate.year();
            String unpublishDate = unpublishedDate.day() + '/' + unpublishedDate.month() + '/' + unpublishedDate.year();
            Assert.areEqual('Penalty ' + i, singlePenalty.reference, 'Incorrect penalty reference returned.');
            Assert.areEqual(parentExemptionId, singlePenalty.exemptionId, 'Incorrect penalty exemptionId returned.');
            Assert.areEqual(parentExemption.ExemptionTypeLinks__r[0].Id, singlePenalty.exemptionTypeId, 'Incorrect penalty exemptionTypeId returned.');
            Assert.areEqual(issuedDate, singlePenalty.dateIssued, 'Incorrect penalty dateIssued returned.');
            Assert.areEqual(unpublishDate, singlePenalty.unpublishDate, 'Incorrect penalty unpublishDate returned.');
            Assert.areEqual(true, singlePenalty.published, 'Incorrect penalty published returned.');
            Assert.areEqual(1000 + i, singlePenalty.penaltyAmount, 'Incorrect penalty penaltyAmount returned.');
        }
        Assert.areEqual(3, penaltyResult.totalRecords, 'Incorrect number of total records returned.');
        Assert.areEqual(30, penaltyResult.pageSize, 'Incorrect page size returned.');
        Assert.areEqual(1, penaltyResult.pageNumber, 'Incorrect page number returned.');
    }

    @isTest
    static void getAssociatedPenalties_withErrorInCountQuery_returnsEmptyResult() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        PRSE_LAViewExemptionHelper mockExemptionHelper = (PRSE_LAViewExemptionHelper) mockProvider.createMock(PRSE_LAViewExemptionHelper.class);
        PRSE_LAViewExemptionHelper.instance = mockExemptionHelper;
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;

        Id parentExemptionId = SObjectUtil.generateIdForType('Exemption__c');
        mockProvider.when(mockExemptionHelper.checkExemptionInstance(parentExemptionId)).thenReturn(true);
        Map<String, Object> countBindMap = new Map<String, Object> { 
            'parentExemptionId' => parentExemptionId
        };
        Map<String, Object> penaltiesBindMap = new Map<String, Object> { 
            'parentExemptionId' => parentExemptionId,
            'pageSize' => 30,
            'offsetValue' => 0
        };
        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
                'SELECT COUNT() FROM Penalty__c WHERE Exemption__c = :parentExemptionId',
                countBindMap
            )
        ).thenThrow(new Exceptions.CustomException('An error has occured in the count query.'));
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Exemption__c, Penalty_Reference__c, Exemption_Type_Link__c, Exemption_Type_Link__r.Name, ' +
                'Penalty_Type__c, Penalty_Type__r.Name, Issued_Date__c, Unpublish_Date__c, Published__c, Penalty_Amount__c, ' +
                'LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c, ' +
                'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c, PropertyType__c, Full_Property_Address__c ' +
                'FROM Penalty__c ' +
                'WHERE Exemption__c = :parentExemptionId ' +
                'ORDER BY Issued_Date__c DESC ' +
                'LIMIT :pageSize ' +
                'OFFSET :offsetValue',
                penaltiesBindMap
            )
        ).thenReturn(new List<Penalty__c>());

        //Act
        Test.startTest();
        PRSE_LADashboardPenaltiesController.PaginatedResult penaltyResult = PRSE_LADashboardPenaltiesController.getAssociatedPenalties(
            parentExemptionId,
            30,
            1
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LADashboardPenaltiesController', 'getAssociatedPenalties', 'An error has occured in the count query.');
        Assert.isTrue(penaltyResult.records.isEmpty(), 'Expected no Penalties to be returned.');
        Assert.areEqual(0, penaltyResult.totalRecords, 'Incorrect number of total records returned.');
        Assert.areEqual(30, penaltyResult.pageSize, 'Incorrect page size returned.');
        Assert.areEqual(1, penaltyResult.pageNumber, 'Incorrect page number returned.');
    }

    @isTest
    static void getAssociatedPenalties_withErrorInPenaltyQuery_returnsEmptyResult() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        PRSE_LAViewExemptionHelper mockExemptionHelper = (PRSE_LAViewExemptionHelper) mockProvider.createMock(PRSE_LAViewExemptionHelper.class);
        PRSE_LAViewExemptionHelper.instance = mockExemptionHelper;
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;

        Id parentExemptionId = SObjectUtil.generateIdForType('Exemption__c');
        mockProvider.when(mockExemptionHelper.checkExemptionInstance(parentExemptionId)).thenReturn(true);
        Map<String, Object> countBindMap = new Map<String, Object> { 
            'parentExemptionId' => parentExemptionId
        };
        Map<String, Object> penaltiesBindMap = new Map<String, Object> { 
            'parentExemptionId' => parentExemptionId,
            'pageSize' => 30,
            'offsetValue' => 0
        };
        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
                'SELECT COUNT() FROM Penalty__c WHERE Exemption__c = :parentExemptionId',
                countBindMap
            )
        ).thenReturn(3);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Exemption__c, Penalty_Reference__c, Exemption_Type_Link__c, Exemption_Type_Link__r.Name, ' +
                'Penalty_Type__c, Penalty_Type__r.Name, Issued_Date__c, Unpublish_Date__c, Published__c, Penalty_Amount__c, ' +
                'LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c, ' +
                'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c, PropertyType__c, Full_Property_Address__c ' +
                'FROM Penalty__c ' +
                'WHERE Exemption__c = :parentExemptionId ' +
                'ORDER BY Issued_Date__c DESC ' +
                'LIMIT :pageSize ' +
                'OFFSET :offsetValue',
                penaltiesBindMap
            )
        ).thenThrow(new Exceptions.CustomException('An error has occured in the penalty query.'));

        //Act
        Test.startTest();
        PRSE_LADashboardPenaltiesController.PaginatedResult penaltyResult = PRSE_LADashboardPenaltiesController.getAssociatedPenalties(
            parentExemptionId,
            30,
            1
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LADashboardPenaltiesController', 'getAssociatedPenalties', 'An error has occured in the penalty query.');
        Assert.isTrue(penaltyResult.records.isEmpty(), 'Expected no Penalties to be returned.');
        Assert.areEqual(3, penaltyResult.totalRecords, 'Incorrect number of total records returned.');
        Assert.areEqual(30, penaltyResult.pageSize, 'Incorrect page size returned.');
        Assert.areEqual(1, penaltyResult.pageNumber, 'Incorrect page number returned.');
    }

    @isTest
    static void getAssociatedPenaltiesForLocalAuthorities_withNoLocalAuthorityCodes_returnsEmptyResult() {
        //Arrange
        String filters = '{}';

        //Act
        Test.startTest();
        PRSE_LADashboardPenaltiesController.PaginatedResult penaltyResult = PRSE_LADashboardPenaltiesController.getAssociatedPenaltiesForLocalAuthorities(
            filters,
            30,
            1
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.isTrue(penaltyResult.records.isEmpty(), 'Expected no Penalties to be returned.');
        Assert.areEqual(0, penaltyResult.totalRecords, 'Incorrect number of total records returned.');
        Assert.areEqual(30, penaltyResult.pageSize, 'Incorrect page size returned.');
        Assert.areEqual(1, penaltyResult.pageNumber, 'Incorrect page number returned.');
    }

    @isTest
    static void getAssociatedPenaltiesForLocalAuthorities_withNoPenaltiesAvailableForFilter_returnsEmptyResult() {
        //Arrange
        String filters = 
        '{' + 
            '"localAuthorityCodes": ["5300", "5330"], ' + 
            '"penaltyTypeCodes": ["P03"], ' + 
            '"searchTerm": "   James   ", ' + 
            '"propertyType": "Domestic"' +
        '}';
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;

        Map<String, Object> countBindMap = new Map<String, Object> { 
            'localAuthorityCodes' => new List<String>{ '5300', '5330' },
            'penaltyTypeCodes' => new List<String>{ 'P03' },
            'propertyType' => 'Domestic',
            'searchTerm' => '%James%', 
            'trimmedSearchTerm' => '%James%'
        };
        Map<String, Object> penaltiesBindMap = new Map<String, Object> { 
            'localAuthorityCodes' => new List<String>{ '5300', '5330' },
            'penaltyTypeCodes' => new List<String>{ 'P03' },
            'propertyType' => 'Domestic',
            'searchTerm' => '%James%', 
            'trimmedSearchTerm' => '%James%',
            'offsetValue' => 0,
            'pageSize' => 30
        };
        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
                'SELECT COUNT() FROM Penalty__c ' +
                'WHERE Local_Custodian_Code__c IN :localAuthorityCodes AND Penalty_Type__r.Code__c IN :penaltyTypeCodes AND PropertyType__c = :propertyType ' +
                'AND (Penalty_Reference__c LIKE :searchTerm OR Penalty_Reference__c LIKE :trimmedSearchTerm ' +
                'OR LandlordFirstName__c LIKE :searchTerm OR LandlordFirstName__c LIKE :trimmedSearchTerm ' +
                'OR LandlordLastName__c LIKE :searchTerm OR LandlordLastName__c LIKE :trimmedSearchTerm ' +
                'OR LandlordBusinessName__c LIKE :searchTerm OR LandlordBusinessName__c LIKE :trimmedSearchTerm ' +
                'OR PropertyAddress__c LIKE :searchTerm OR PropertyAddress__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCity__c LIKE :searchTerm OR PropertyCity__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCounty__c LIKE :searchTerm OR PropertyCounty__c LIKE :trimmedSearchTerm OR ' +
                'PropertyPostcode__c LIKE :searchTerm OR PropertyPostcode__c LIKE :trimmedSearchTerm)',
                countBindMap
            )
        ).thenReturn(0);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Exemption__c, Penalty_Reference__c, Exemption_Type_Link__c, Exemption_Type_Link__r.Name, ' +
                'Penalty_Type__c, Penalty_Type__r.Name, Issued_Date__c, Unpublish_Date__c, Published__c, Penalty_Amount__c, ' +
                'LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c, ' +
                'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c, PropertyType__c, Full_Property_Address__c ' +
                'FROM Penalty__c ' +
                'WHERE Local_Custodian_Code__c IN :localAuthorityCodes AND Penalty_Type__r.Code__c IN :penaltyTypeCodes AND PropertyType__c = :propertyType ' +
                'AND (Penalty_Reference__c LIKE :searchTerm OR Penalty_Reference__c LIKE :trimmedSearchTerm OR ' +
                'LandlordFirstName__c LIKE :searchTerm OR LandlordFirstName__c LIKE :trimmedSearchTerm OR ' +
                'LandlordLastName__c LIKE :searchTerm OR LandlordLastName__c LIKE :trimmedSearchTerm OR ' + 
                'LandlordBusinessName__c LIKE :searchTerm OR LandlordBusinessName__c LIKE :trimmedSearchTerm OR ' +
                'PropertyAddress__c LIKE :searchTerm OR PropertyAddress__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCity__c LIKE :searchTerm OR PropertyCity__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCounty__c LIKE :searchTerm OR PropertyCounty__c LIKE :trimmedSearchTerm OR ' +
                'PropertyPostcode__c LIKE :searchTerm OR PropertyPostcode__c LIKE :trimmedSearchTerm) ' +
                'ORDER BY Issued_Date__c DESC ' +
                'LIMIT :pageSize ' +
                'OFFSET :offsetValue',
                penaltiesBindMap
            )
        ).thenReturn(new List<Penalty__c>());

        //Act
        Test.startTest();
        PRSE_LADashboardPenaltiesController.PaginatedResult penaltyResult = PRSE_LADashboardPenaltiesController.getAssociatedPenaltiesForLocalAuthorities(
            filters,
            30,
            1
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.isTrue(penaltyResult.records.isEmpty(), 'Expected no Penalties to be returned.');
        Assert.areEqual(0, penaltyResult.totalRecords, 'Incorrect number of total records returned.');
        Assert.areEqual(30, penaltyResult.pageSize, 'Incorrect page size returned.');
        Assert.areEqual(1, penaltyResult.pageNumber, 'Incorrect page number returned.');
    }

    @isTest
    static void getAssociatedPenaltiesForLocalAuthorities_withPenaltiesAvailableForFilter_returnsResultWithPenalties() {
        //Arrange
        String filters = 
        '{' + 
            '"localAuthorityCodes": ["5300", "5330"], ' + 
            '"penaltyTypeCodes": ["P03"], ' + 
            '"searchTerm": "   James   ", ' + 
            '"propertyType": "Domestic"' +
        '}';
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;

        Map<String, Object> countBindMap = new Map<String, Object> { 
            'localAuthorityCodes' => new List<String>{ '5300', '5330' },
            'penaltyTypeCodes' => new List<String>{ 'P03' },
            'propertyType' => 'Domestic',
            'searchTerm' => '%James%', 
            'trimmedSearchTerm' => '%James%'
        };
        Map<String, Object> penaltiesBindMap = new Map<String, Object> { 
            'localAuthorityCodes' => new List<String>{ '5300', '5330' },
            'penaltyTypeCodes' => new List<String>{ 'P03' },
            'propertyType' => 'Domestic',
            'searchTerm' => '%James%', 
            'trimmedSearchTerm' => '%James%',
            'offsetValue' => 0,
            'pageSize' => 30
        };
        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
                'SELECT COUNT() FROM Penalty__c ' +
                'WHERE Local_Custodian_Code__c IN :localAuthorityCodes AND Penalty_Type__r.Code__c IN :penaltyTypeCodes AND PropertyType__c = :propertyType ' +
                'AND (Penalty_Reference__c LIKE :searchTerm OR Penalty_Reference__c LIKE :trimmedSearchTerm ' +
                'OR LandlordFirstName__c LIKE :searchTerm OR LandlordFirstName__c LIKE :trimmedSearchTerm ' +
                'OR LandlordLastName__c LIKE :searchTerm OR LandlordLastName__c LIKE :trimmedSearchTerm ' +
                'OR LandlordBusinessName__c LIKE :searchTerm OR LandlordBusinessName__c LIKE :trimmedSearchTerm ' +
                'OR PropertyAddress__c LIKE :searchTerm OR PropertyAddress__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCity__c LIKE :searchTerm OR PropertyCity__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCounty__c LIKE :searchTerm OR PropertyCounty__c LIKE :trimmedSearchTerm OR ' +
                'PropertyPostcode__c LIKE :searchTerm OR PropertyPostcode__c LIKE :trimmedSearchTerm)',
                countBindMap
            )
        ).thenReturn(3);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Exemption__c, Penalty_Reference__c, Exemption_Type_Link__c, Exemption_Type_Link__r.Name, ' +
                'Penalty_Type__c, Penalty_Type__r.Name, Issued_Date__c, Unpublish_Date__c, Published__c, Penalty_Amount__c, ' +
                'LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c, ' +
                'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c, PropertyType__c, Full_Property_Address__c ' +
                'FROM Penalty__c ' +
                'WHERE Local_Custodian_Code__c IN :localAuthorityCodes AND Penalty_Type__r.Code__c IN :penaltyTypeCodes AND PropertyType__c = :propertyType ' +
                'AND (Penalty_Reference__c LIKE :searchTerm OR Penalty_Reference__c LIKE :trimmedSearchTerm OR ' +
                'LandlordFirstName__c LIKE :searchTerm OR LandlordFirstName__c LIKE :trimmedSearchTerm OR ' +
                'LandlordLastName__c LIKE :searchTerm OR LandlordLastName__c LIKE :trimmedSearchTerm OR ' + 
                'LandlordBusinessName__c LIKE :searchTerm OR LandlordBusinessName__c LIKE :trimmedSearchTerm OR ' +
                'PropertyAddress__c LIKE :searchTerm OR PropertyAddress__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCity__c LIKE :searchTerm OR PropertyCity__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCounty__c LIKE :searchTerm OR PropertyCounty__c LIKE :trimmedSearchTerm OR ' +
                'PropertyPostcode__c LIKE :searchTerm OR PropertyPostcode__c LIKE :trimmedSearchTerm) ' +
                'ORDER BY Issued_Date__c DESC ' +
                'LIMIT :pageSize ' +
                'OFFSET :offsetValue',
                penaltiesBindMap
            )
        ).thenReturn(createMockPenalties(3, null));

        //Act
        Test.startTest();
        PRSE_LADashboardPenaltiesController.PaginatedResult penaltyResult = PRSE_LADashboardPenaltiesController.getAssociatedPenaltiesForLocalAuthorities(
            filters,
            30,
            1
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(3, penaltyResult.records.size(), 'Incorrect number of Penalties returned.');
        Date todaysDate = Date.today();
        Date unpublishedDate = Date.today().addMonths(1);
        for(Integer i = 0; i < penaltyResult.records.size(); i++) {
            PRSE_LADashboardPenaltiesController.Penalty singlePenalty = penaltyResult.records[i];
            String issuedDate = todaysDate.day() + '/' + todaysDate.month() + '/' + todaysDate.year();
            String unpublishDate = unpublishedDate.day() + '/' + unpublishedDate.month() + '/' + unpublishedDate.year();
            Assert.areEqual('Penalty ' + i, singlePenalty.reference, 'Incorrect penalty reference returned.');
            Assert.areEqual(issuedDate, singlePenalty.dateIssued, 'Incorrect penalty dateIssued returned.');
            Assert.areEqual(unpublishDate, singlePenalty.unpublishDate, 'Incorrect penalty unpublishDate returned.');
            Assert.areEqual(true, singlePenalty.published, 'Incorrect penalty published returned.');
            Assert.areEqual(1000 + i, singlePenalty.penaltyAmount, 'Incorrect penalty penaltyAmount returned.');
        }
        Assert.areEqual(3, penaltyResult.totalRecords, 'Incorrect number of total records returned.');
        Assert.areEqual(30, penaltyResult.pageSize, 'Incorrect page size returned.');
        Assert.areEqual(1, penaltyResult.pageNumber, 'Incorrect page number returned.');
    }

    @isTest
    static void getAssociatedPenaltiesForLocalAuthorities_withErrorInCountQuery_returnsEmptyResult() {
        //Arrange
        String filters = 
        '{' + 
            '"localAuthorityCodes": ["5300", "5330"], ' + 
            '"penaltyTypeCodes": ["P03"], ' + 
            '"searchTerm": "   James   ", ' + 
            '"propertyType": "Domestic"' +
        '}';
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;

        Map<String, Object> countBindMap = new Map<String, Object> { 
            'localAuthorityCodes' => new List<String>{ '5300', '5330' },
            'penaltyTypeCodes' => new List<String>{ 'P03' },
            'propertyType' => 'Domestic',
            'searchTerm' => '%James%', 
            'trimmedSearchTerm' => '%James%'
        };
        Map<String, Object> penaltiesBindMap = new Map<String, Object> { 
            'localAuthorityCodes' => new List<String>{ '5300', '5330' },
            'penaltyTypeCodes' => new List<String>{ 'P03' },
            'propertyType' => 'Domestic',
            'searchTerm' => '%James%', 
            'trimmedSearchTerm' => '%James%',
            'offsetValue' => 0,
            'pageSize' => 30
        };
        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
                'SELECT COUNT() FROM Penalty__c ' +
                'WHERE Local_Custodian_Code__c IN :localAuthorityCodes AND Penalty_Type__r.Code__c IN :penaltyTypeCodes AND PropertyType__c = :propertyType ' +
                'AND (Penalty_Reference__c LIKE :searchTerm OR Penalty_Reference__c LIKE :trimmedSearchTerm ' +
                'OR LandlordFirstName__c LIKE :searchTerm OR LandlordFirstName__c LIKE :trimmedSearchTerm ' +
                'OR LandlordLastName__c LIKE :searchTerm OR LandlordLastName__c LIKE :trimmedSearchTerm ' +
                'OR LandlordBusinessName__c LIKE :searchTerm OR LandlordBusinessName__c LIKE :trimmedSearchTerm ' +
                'OR PropertyAddress__c LIKE :searchTerm OR PropertyAddress__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCity__c LIKE :searchTerm OR PropertyCity__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCounty__c LIKE :searchTerm OR PropertyCounty__c LIKE :trimmedSearchTerm OR ' +
                'PropertyPostcode__c LIKE :searchTerm OR PropertyPostcode__c LIKE :trimmedSearchTerm)',
                countBindMap
            )
        ).thenThrow(new Exceptions.CustomException('An error has occured in the count query.'));
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Exemption__c, Penalty_Reference__c, Exemption_Type_Link__c, Exemption_Type_Link__r.Name, ' +
                'Penalty_Type__c, Penalty_Type__r.Name, Issued_Date__c, Unpublish_Date__c, Published__c, Penalty_Amount__c, ' +
                'LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c, ' +
                'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c, PropertyType__c, Full_Property_Address__c ' +
                'FROM Penalty__c ' +
                'WHERE Local_Custodian_Code__c IN :localAuthorityCodes AND Penalty_Type__r.Code__c IN :penaltyTypeCodes AND PropertyType__c = :propertyType ' +
                'AND (Penalty_Reference__c LIKE :searchTerm OR Penalty_Reference__c LIKE :trimmedSearchTerm OR ' +
                'LandlordFirstName__c LIKE :searchTerm OR LandlordFirstName__c LIKE :trimmedSearchTerm OR ' +
                'LandlordLastName__c LIKE :searchTerm OR LandlordLastName__c LIKE :trimmedSearchTerm OR ' + 
                'LandlordBusinessName__c LIKE :searchTerm OR LandlordBusinessName__c LIKE :trimmedSearchTerm OR ' +
                'PropertyAddress__c LIKE :searchTerm OR PropertyAddress__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCity__c LIKE :searchTerm OR PropertyCity__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCounty__c LIKE :searchTerm OR PropertyCounty__c LIKE :trimmedSearchTerm OR ' +
                'PropertyPostcode__c LIKE :searchTerm OR PropertyPostcode__c LIKE :trimmedSearchTerm) ' +
                'ORDER BY Issued_Date__c DESC ' +
                'LIMIT :pageSize ' +
                'OFFSET :offsetValue',
                penaltiesBindMap
            )
        ).thenReturn(new List<Penalty__c>());

        //Act
        Test.startTest();
        PRSE_LADashboardPenaltiesController.PaginatedResult penaltyResult = PRSE_LADashboardPenaltiesController.getAssociatedPenaltiesForLocalAuthorities(
            filters,
            30,
            1
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LADashboardPenaltiesController', 'getAssociatedPenaltiesForLocalAuthorities', 'An error has occured in the count query.');
        Assert.isTrue(penaltyResult.records.isEmpty(), 'Expected no Penalties to be returned.');
        Assert.areEqual(0, penaltyResult.totalRecords, 'Incorrect number of total records returned.');
        Assert.areEqual(30, penaltyResult.pageSize, 'Incorrect page size returned.');
        Assert.areEqual(1, penaltyResult.pageNumber, 'Incorrect page number returned.');
    }

    @isTest
    static void getAssociatedPenaltiesForLocalAuthorities_withErrorInPenaltyQuery_returnsEmptyResult() {
        //Arrange
        String filters = 
        '{' + 
            '"localAuthorityCodes": ["5300", "5330"], ' + 
            '"penaltyTypeCodes": ["P03"], ' + 
            '"searchTerm": "   James   ", ' + 
            '"propertyType": "Domestic"' +
        '}';
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;

        Map<String, Object> countBindMap = new Map<String, Object> { 
            'localAuthorityCodes' => new List<String>{ '5300', '5330' },
            'penaltyTypeCodes' => new List<String>{ 'P03' },
            'propertyType' => 'Domestic',
            'searchTerm' => '%James%', 
            'trimmedSearchTerm' => '%James%'
        };
        Map<String, Object> penaltiesBindMap = new Map<String, Object> { 
            'localAuthorityCodes' => new List<String>{ '5300', '5330' },
            'penaltyTypeCodes' => new List<String>{ 'P03' },
            'propertyType' => 'Domestic',
            'searchTerm' => '%James%', 
            'trimmedSearchTerm' => '%James%',
            'offsetValue' => 0,
            'pageSize' => 30
        };
        mockProvider.when(
            mockDatabaseWrapper.countQueryWithBinds(
                'SELECT COUNT() FROM Penalty__c ' +
                'WHERE Local_Custodian_Code__c IN :localAuthorityCodes AND Penalty_Type__r.Code__c IN :penaltyTypeCodes AND PropertyType__c = :propertyType ' +
                'AND (Penalty_Reference__c LIKE :searchTerm OR Penalty_Reference__c LIKE :trimmedSearchTerm OR ' +
                'LandlordFirstName__c LIKE :searchTerm OR LandlordFirstName__c LIKE :trimmedSearchTerm OR ' +
                'LandlordLastName__c LIKE :searchTerm OR LandlordLastName__c LIKE :trimmedSearchTerm OR ' +
                'LandlordBusinessName__c LIKE :searchTerm OR LandlordBusinessName__c LIKE :trimmedSearchTerm OR ' +
                'PropertyAddress__c LIKE :searchTerm OR PropertyAddress__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCity__c LIKE :searchTerm OR PropertyCity__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCounty__c LIKE :searchTerm OR PropertyCounty__c LIKE :trimmedSearchTerm OR ' +
                'PropertyPostcode__c LIKE :searchTerm OR PropertyPostcode__c LIKE :trimmedSearchTerm)',
                countBindMap
            )
        ).thenReturn(3);
        mockProvider.when(
            mockDatabaseWrapper.queryWithBinds(
                'SELECT Id, Exemption__c, Penalty_Reference__c, Exemption_Type_Link__c, Exemption_Type_Link__r.Name, ' +
                'Penalty_Type__c, Penalty_Type__r.Name, Issued_Date__c, Unpublish_Date__c, Published__c, Penalty_Amount__c, ' +
                'LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c, ' +
                'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c, PropertyType__c, Full_Property_Address__c ' +
                'FROM Penalty__c ' +
                'WHERE Local_Custodian_Code__c IN :localAuthorityCodes AND Penalty_Type__r.Code__c IN :penaltyTypeCodes AND PropertyType__c = :propertyType ' +
                'AND (Penalty_Reference__c LIKE :searchTerm OR Penalty_Reference__c LIKE :trimmedSearchTerm OR ' +
                'LandlordFirstName__c LIKE :searchTerm OR LandlordFirstName__c LIKE :trimmedSearchTerm OR ' +
                'LandlordLastName__c LIKE :searchTerm OR LandlordLastName__c LIKE :trimmedSearchTerm OR ' + 
                'LandlordBusinessName__c LIKE :searchTerm OR LandlordBusinessName__c LIKE :trimmedSearchTerm OR ' +
                'PropertyAddress__c LIKE :searchTerm OR PropertyAddress__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCity__c LIKE :searchTerm OR PropertyCity__c LIKE :trimmedSearchTerm OR ' +
                'PropertyCounty__c LIKE :searchTerm OR PropertyCounty__c LIKE :trimmedSearchTerm OR ' +
                'PropertyPostcode__c LIKE :searchTerm OR PropertyPostcode__c LIKE :trimmedSearchTerm) ' +
                'ORDER BY Issued_Date__c DESC ' +
                'LIMIT :pageSize ' +
                'OFFSET :offsetValue',
                penaltiesBindMap
            )
        ).thenThrow(new Exceptions.CustomException('An error has occured in the penalty query.'));

        //Act
        Test.startTest();
        PRSE_LADashboardPenaltiesController.PaginatedResult penaltyResult = PRSE_LADashboardPenaltiesController.getAssociatedPenaltiesForLocalAuthorities(
            filters,
            30,
            1
        );
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LADashboardPenaltiesController', 'getAssociatedPenaltiesForLocalAuthorities', 'An error has occured in the penalty query.');
        Assert.isTrue(penaltyResult.records.isEmpty(), 'Expected no Penalties to be returned.');
        Assert.areEqual(3, penaltyResult.totalRecords, 'Incorrect number of total records returned.');
        Assert.areEqual(30, penaltyResult.pageSize, 'Incorrect page size returned.');
        Assert.areEqual(1, penaltyResult.pageNumber, 'Incorrect page number returned.');
    }

    @isTest
    static void upsertPenalty_withoutPenaltyJSONString_doesNotUpsertAnything() {
        //Arrange
        Integer penaltiesBeforeUpsert = [SELECT COUNT() FROM Penalty__c];
        
        //Act
        Test.startTest();
        Id upsertedPenaltyId = PRSE_LADashboardPenaltiesController.upsertPenalty(null);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Integer penaltiesAfterUpsert = [SELECT COUNT() FROM Penalty__c];
        Assert.areEqual(penaltiesBeforeUpsert, penaltiesAfterUpsert, 'Incorrect number of penalties present.');
        Assert.areEqual(null, upsertedPenaltyId, 'Incorrect upsertedPenaltyId.');
    }

    @isTest
    static void upsertPenalty_withJSONStringAsNewPenalty_insertsNewPenalty() {
        //Arrange
        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Exemption__c testExemption = new Exemption__c(
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
            Local_Custodian_Code__c = '5330',
            PropertyUPRN__c = '10033612794'
        );
        insert testExemption;

        Penalty_Type__c parentPenaltyType = new Penalty_Type__c();
        parentPenaltyType.Name = 'Test Penalty Type';
        parentPenaltyType.Code__c = 'P009';
        insert parentPenaltyType;

        PRSE_LADashboardPenaltiesController.Penalty penaltyToInsert = new PRSE_LADashboardPenaltiesController.Penalty();
        penaltyToInsert.exemptionId = testExemption.Id;
        penaltyToInsert.dateIssued = '12/04/2024';
        penaltyToInsert.penaltyAmount = 3000;
        penaltyToInsert.reference = 'Test Reference 1';
        penaltyToInsert.penaltyTypeId = parentPenaltyType.Id;
        penaltyToInsert.published = true;
        penaltyToInsert.unpublishDate = '31/12/2026';

        String penaltyJSONString = JSON.serialize(penaltyToInsert);

        //Act
        Test.startTest();
        Id upsertedPenaltyId = PRSE_LADashboardPenaltiesController.upsertPenalty(penaltyJSONString);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        List<Penalty__c> penalties = [
            SELECT Id, Exemption__c, Issued_Date__c, Penalty_Amount__c, 
            Penalty_Reference__c, Penalty_Type__c, Published__c, Unpublish_Date__c,
            LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c,
            PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c, 
            Local_Custodian_Code__c, PropertyType__c, PropertyUPRN__c
            FROM Penalty__c
        ];
        Assert.areEqual(1, penalties.size(), 'Incorrect number of penalties present.');
        Penalty__c penalty = penalties[0];
        Assert.areEqual(penalty.Id, upsertedPenaltyId, 'Incorrect upsertedPenaltyId.');
        Assert.areEqual(testExemption.Id, penalty.Exemption__c, 'Incorrect Exemption__c on Penalty.');
        Assert.areEqual(Date.newInstance(2024, 04, 12), penalty.Issued_Date__c, 'Incorrect Issued_Date__c on Penalty.');
        Assert.areEqual(penaltyToInsert.penaltyAmount, penalty.Penalty_Amount__c, 'Incorrect Penalty_Amount__c on Penalty.');
        Assert.areEqual(penaltyToInsert.reference, penalty.Penalty_Reference__c, 'Incorrect Penalty_Reference__c on Penalty.');
        Assert.areEqual(penaltyToInsert.penaltyTypeId, penalty.Penalty_Type__c, 'Incorrect Penalty_Type__c on Penalty.');
        Assert.areEqual(penaltyToInsert.published, penalty.Published__c, 'Incorrect Published__c on Penalty.');
        Assert.areEqual(Date.newInstance(2026, 12, 31), penalty.Unpublish_Date__c, 'Incorrect Unpublish_Date__c on Penalty.');

        Assert.areEqual(testExemption.LandlordBusinessName__c, penalty.LandlordBusinessName__c, 'Incorrect LandlordBusinessName__c on Penalty.');
        Assert.areEqual(testExemption.LandlordFirstName__c, penalty.LandlordFirstName__c, 'Incorrect LandlordFirstName__c on Penalty.');
        Assert.areEqual(testExemption.LandlordLastName__c, penalty.LandlordLastName__c, 'Incorrect LandlordLastName__c on Penalty.');
        Assert.areEqual(testExemption.PropertyAddress__c, penalty.PropertyAddress__c, 'Incorrect PropertyAddress__c on Penalty.');
        Assert.areEqual(testExemption.PropertyCity__c, penalty.PropertyCity__c, 'Incorrect PropertyCity__c on Penalty.');
        Assert.areEqual(testExemption.PropertyCounty__c, penalty.PropertyCounty__c, 'Incorrect PropertyCounty__c on Penalty.');
        Assert.areEqual(testExemption.PropertyPostcode__c, penalty.PropertyPostcode__c, 'Incorrect PropertyPostcode__c on Penalty.');
        Assert.areEqual(testExemption.PropertyType__c, penalty.PropertyType__c, 'Incorrect PropertyType__c on Penalty.');
        Assert.areEqual(testExemption.Local_Custodian_Code__c, penalty.Local_Custodian_Code__c, 'Incorrect Local_Custodian_Code__c on Penalty.');
        Assert.areEqual(testExemption.PropertyUPRN__c, penalty.PropertyUPRN__c, 'Incorrect PropertyUPRN__c on Penalty.');
    }

    @isTest
    static void upsertPenalty_withJSONStringAsExistringPenalty_updatesExistingPenalty() {
        //Arrange
        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Exemption__c testExemption = new Exemption__c(
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
            Local_Custodian_Code__c = '5330',
            PropertyUPRN__c = '10033612794'
        );
        insert testExemption;

        Penalty_Type__c parentPenaltyType = new Penalty_Type__c();
        parentPenaltyType.Name = 'Test Penalty Type';
        parentPenaltyType.Code__c = 'P009';
        insert parentPenaltyType;

        Penalty__c existingPenalty = new Penalty__c();
        existingPenalty.Exemption__c = testExemption.Id;
        existingPenalty.Issued_Date__c = Date.newInstance(2024, 04, 12);
        existingPenalty.Penalty_Amount__c = 2000;
        existingPenalty.Penalty_Reference__c = 'Penalty Reference Before';
        existingPenalty.Penalty_Type__c = parentPenaltyType.Id;
        existingPenalty.Published__c = false;
        insert existingPenalty;

        PRSE_LADashboardPenaltiesController.Penalty penaltyToUpdate = new PRSE_LADashboardPenaltiesController.Penalty();
        penaltyToUpdate.exemptionId = testExemption.Id;
        penaltyToUpdate.dateIssued = '12/04/2024';
        penaltyToUpdate.penaltyAmount = 3000;
        penaltyToUpdate.reference = 'Penalty Reference After';
        penaltyToUpdate.penaltyTypeId = parentPenaltyType.Id;
        penaltyToUpdate.published = true;
        penaltyToUpdate.unpublishDate = '31/12/2026';
        penaltyToUpdate.penaltyId = existingPenalty.Id;

        String penaltyJSONString = JSON.serialize(penaltyToUpdate);

        //Act
        Test.startTest();
        Id upsertedPenaltyId = PRSE_LADashboardPenaltiesController.upsertPenalty(penaltyJSONString);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        List<Penalty__c> penalties = [
            SELECT Id, Exemption__c, Issued_Date__c, Penalty_Amount__c, 
            Penalty_Reference__c, Penalty_Type__c, Published__c, Unpublish_Date__c,
            LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c,
            PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c,
            Local_Custodian_Code__c, PropertyType__c, PropertyUPRN__c
            FROM Penalty__c
        ];
        Assert.areEqual(existingPenalty.Id, upsertedPenaltyId, 'Incorrect upsertedPenaltyId.');
        Assert.areEqual(1, penalties.size(), 'Incorrect number of penalties present.');
        Penalty__c penalty = penalties[0];
        Assert.areEqual(testExemption.Id, penalty.Exemption__c, 'Incorrect Exemption__c on Penalty.');
        Assert.areEqual(Date.newInstance(2024, 04, 12), penalty.Issued_Date__c, 'Incorrect Issued_Date__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.penaltyAmount, penalty.Penalty_Amount__c, 'Incorrect Penalty_Amount__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.reference, penalty.Penalty_Reference__c, 'Incorrect Penalty_Reference__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.penaltyTypeId, penalty.Penalty_Type__c, 'Incorrect Penalty_Type__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.published, penalty.Published__c, 'Incorrect Published__c on Penalty.');
        Assert.areEqual(Date.newInstance(2026, 12, 31), penalty.Unpublish_Date__c, 'Incorrect Unpublish_Date__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.penaltyId, penalty.Id, 'Incorrect Id on Penalty.');

        Assert.areEqual(testExemption.LandlordBusinessName__c, penalty.LandlordBusinessName__c, 'Incorrect LandlordBusinessName__c on Penalty.');
        Assert.areEqual(testExemption.LandlordFirstName__c, penalty.LandlordFirstName__c, 'Incorrect LandlordFirstName__c on Penalty.');
        Assert.areEqual(testExemption.LandlordLastName__c, penalty.LandlordLastName__c, 'Incorrect LandlordLastName__c on Penalty.');
        Assert.areEqual(testExemption.PropertyAddress__c, penalty.PropertyAddress__c, 'Incorrect PropertyAddress__c on Penalty.');
        Assert.areEqual(testExemption.PropertyCity__c, penalty.PropertyCity__c, 'Incorrect PropertyCity__c on Penalty.');
        Assert.areEqual(testExemption.PropertyCounty__c, penalty.PropertyCounty__c, 'Incorrect PropertyCounty__c on Penalty.');
        Assert.areEqual(testExemption.PropertyPostcode__c, penalty.PropertyPostcode__c, 'Incorrect PropertyPostcode__c on Penalty.');
        Assert.areEqual(testExemption.PropertyType__c, penalty.PropertyType__c, 'Incorrect PropertyType__c on Penalty.');
        Assert.areEqual(testExemption.Local_Custodian_Code__c, penalty.Local_Custodian_Code__c, 'Incorrect Local_Custodian_Code__c on Penalty.');
        Assert.areEqual(testExemption.PropertyUPRN__c, penalty.PropertyUPRN__c, 'Incorrect PropertyUPRN__c on Penalty.');
    }

    @isTest
    static void upsertPenalty_withJSONStringAsExistringPenaltyAndNotPublishedDate_updatesExistingPenalty() {
        //Arrange
        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Exemption__c testExemption = new Exemption__c(
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
            Local_Custodian_Code__c = '5330',
            PropertyUPRN__c = '10033612794'
        );
        insert testExemption;

        Penalty_Type__c parentPenaltyType = new Penalty_Type__c();
        parentPenaltyType.Name = 'Test Penalty Type';
        parentPenaltyType.Code__c = 'P009';
        insert parentPenaltyType;

        Penalty__c existingPenalty = new Penalty__c();
        existingPenalty.Exemption__c = testExemption.Id;
        existingPenalty.Issued_Date__c = Date.newInstance(2024, 04, 12);
        existingPenalty.Penalty_Amount__c = 2000;
        existingPenalty.Penalty_Reference__c = 'Penalty Reference Before';
        existingPenalty.Penalty_Type__c = parentPenaltyType.Id;
        existingPenalty.Published__c = true;
        existingPenalty.Unpublish_Date__c = Date.today().addYears(1);
        insert existingPenalty;

        PRSE_LADashboardPenaltiesController.Penalty penaltyToUpdate = new PRSE_LADashboardPenaltiesController.Penalty();
        penaltyToUpdate.exemptionId = testExemption.Id;
        penaltyToUpdate.dateIssued = '12/04/2024';
        penaltyToUpdate.penaltyAmount = 3000;
        penaltyToUpdate.reference = 'Penalty Reference After';
        penaltyToUpdate.penaltyTypeId = parentPenaltyType.Id;
        penaltyToUpdate.published = false;
        penaltyToUpdate.unpublishDate = 'Not published';
        penaltyToUpdate.penaltyId = existingPenalty.Id;

        String penaltyJSONString = JSON.serialize(penaltyToUpdate);

        //Act
        Test.startTest();
        Id upsertedPenaltyId = PRSE_LADashboardPenaltiesController.upsertPenalty(penaltyJSONString);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        List<Penalty__c> penalties = [
            SELECT Id, Exemption__c, Issued_Date__c, Penalty_Amount__c, 
            Penalty_Reference__c, Penalty_Type__c, Published__c, Unpublish_Date__c,
            LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c,
            PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c,
            Local_Custodian_Code__c, PropertyType__c, PropertyUPRN__c
            FROM Penalty__c
        ];
        Assert.areEqual(existingPenalty.Id, upsertedPenaltyId, 'Incorrect upsertedPenaltyId.');
        Assert.areEqual(1, penalties.size(), 'Incorrect number of penalties present.');
        Penalty__c penalty = penalties[0];
        Assert.areEqual(testExemption.Id, penalty.Exemption__c, 'Incorrect Exemption__c on Penalty.');
        Assert.areEqual(Date.newInstance(2024, 04, 12), penalty.Issued_Date__c, 'Incorrect Issued_Date__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.penaltyAmount, penalty.Penalty_Amount__c, 'Incorrect Penalty_Amount__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.reference, penalty.Penalty_Reference__c, 'Incorrect Penalty_Reference__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.penaltyTypeId, penalty.Penalty_Type__c, 'Incorrect Penalty_Type__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.published, penalty.Published__c, 'Incorrect Published__c on Penalty.');
        Assert.areEqual(null, penalty.Unpublish_Date__c, 'Incorrect Unpublish_Date__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.penaltyId, penalty.Id, 'Incorrect Id on Penalty.');

        Assert.areEqual(testExemption.LandlordBusinessName__c, penalty.LandlordBusinessName__c, 'Incorrect LandlordBusinessName__c on Penalty.');
        Assert.areEqual(testExemption.LandlordFirstName__c, penalty.LandlordFirstName__c, 'Incorrect LandlordFirstName__c on Penalty.');
        Assert.areEqual(testExemption.LandlordLastName__c, penalty.LandlordLastName__c, 'Incorrect LandlordLastName__c on Penalty.');
        Assert.areEqual(testExemption.PropertyAddress__c, penalty.PropertyAddress__c, 'Incorrect PropertyAddress__c on Penalty.');
        Assert.areEqual(testExemption.PropertyCity__c, penalty.PropertyCity__c, 'Incorrect PropertyCity__c on Penalty.');
        Assert.areEqual(testExemption.PropertyCounty__c, penalty.PropertyCounty__c, 'Incorrect PropertyCounty__c on Penalty.');
        Assert.areEqual(testExemption.PropertyPostcode__c, penalty.PropertyPostcode__c, 'Incorrect PropertyPostcode__c on Penalty.');
        Assert.areEqual(testExemption.PropertyType__c, penalty.PropertyType__c, 'Incorrect PropertyType__c on Penalty.');
        Assert.areEqual(testExemption.Local_Custodian_Code__c, penalty.Local_Custodian_Code__c, 'Incorrect Local_Custodian_Code__c on Penalty.');
        Assert.areEqual(testExemption.PropertyUPRN__c, penalty.PropertyUPRN__c, 'Incorrect PropertyUPRN__c on Penalty.');
    }

    @isTest
    static void upsertPenalty_withErrorInProcess_logsErrorAndDoesNotUpsertAnything() {
        //Arrange
        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Exemption__c testExemption = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 1'
        );
        insert testExemption;

        Penalty_Type__c parentPenaltyType = new Penalty_Type__c();
        parentPenaltyType.Name = 'Test Penalty Type';
        parentPenaltyType.Code__c = 'P009';
        insert parentPenaltyType;

        PRSE_LADashboardPenaltiesController.Penalty penaltyToInsert = new PRSE_LADashboardPenaltiesController.Penalty();
        penaltyToInsert.exemptionId = testExemption.Id;
        penaltyToInsert.dateIssued = '12/04/2024';
        penaltyToInsert.penaltyAmount = 3000;
        penaltyToInsert.reference = 'Test Reference 1';
        penaltyToInsert.penaltyTypeId = parentPenaltyType.Id;
        penaltyToInsert.published = false;

        Penalty__c expectedPenalty = new Penalty__c();
        expectedPenalty.Exemption__c = testExemption.Id;
        expectedPenalty.Exemption_Type_Link__c = null;
        expectedPenalty.Issued_Date__c = Date.newInstance(2024, 04, 12);
        expectedPenalty.Penalty_Amount__c = 3000;
        expectedPenalty.Penalty_Reference__c = 'Test Reference 1';
        expectedPenalty.Penalty_Type__c = parentPenaltyType.Id;
        expectedPenalty.Published__c = false;
        expectedPenalty.Unpublish_Date__c = null;
        expectedPenalty.Id = null;

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(mockDatabaseWrapper.queryWithBinds(
            'SELECT Id, LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c, ' +
            'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c, ' +
            'PropertyType__c, Local_Custodian_Code__c, PropertyUPRN__c ' +
            'FROM Exemption__c ' +
            'WHERE Id = :exemptionId ' +
            'LIMIT 1',
            new Map<String, Object> {
                'exemptionId' => testExemption.Id
            }
        )).thenThrow(new Exceptions.CustomException('An error has occured'));

        String penaltyJSONString = JSON.serialize(penaltyToInsert);

        //Act
        Test.startTest();
        Id upsertedPenaltyId = PRSE_LADashboardPenaltiesController.upsertPenalty(penaltyJSONString);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LADashboardPenaltiesController', 'upsertPenalty', 'An error has occured');
        List<Penalty__c> penalties = [
            SELECT Id, Exemption__c, Issued_Date__c, Penalty_Amount__c, 
            Penalty_Reference__c, Penalty_Type__c, Published__c, Unpublish_Date__c
            FROM Penalty__c
        ];
        Assert.areEqual(0, penalties.size(), 'Incorrect number of penalties present.');
        Assert.areEqual(null, upsertedPenaltyId, 'Incorrect upsertedPenaltyId.');
    }

    @isTest
    static void upsertPenaltyWithoutExemption_withoutPenaltyJSONString_doesNotUpsertAnything() {
        //Arrange
        Integer penaltiesBeforeUpsert = [SELECT COUNT() FROM Penalty__c];
        
        //Act
        Test.startTest();
        Id upsertedPenaltyId = PRSE_LADashboardPenaltiesController.upsertPenaltyWithoutExemption(null);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Integer penaltiesAfterUpsert = [SELECT COUNT() FROM Penalty__c];
        Assert.areEqual(penaltiesBeforeUpsert, penaltiesAfterUpsert, 'Incorrect number of penalties present.');
        Assert.areEqual(null, upsertedPenaltyId, 'Incorrect upsertedPenaltyId.');
    }

    @isTest
    static void upsertPenaltyWithoutExemption_withJSONStringAsNewPenaltyWithOSPlacesError_insertsNewPenalty() {
        //Arrange
        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Penalty_Type__c parentPenaltyType = new Penalty_Type__c();
        parentPenaltyType.Name = 'Test Penalty Type';
        parentPenaltyType.Code__c = 'P009';
        insert parentPenaltyType;

        PRSE_LADashboardPenaltiesController.Penalty penaltyToInsert = new PRSE_LADashboardPenaltiesController.Penalty();
        penaltyToInsert.propertyAddress = '3 Whitehall Place';
        penaltyToInsert.propertyCity = 'LONDON';
        penaltyToInsert.propertyPostcode = 'SW1A 2AW';
        penaltyToInsert.propertyCounty = 'Greater London';
        penaltyToInsert.propertyType = 'Commercial';
        penaltyToInsert.dateIssued = '12/04/2024';
        penaltyToInsert.penaltyAmount = 3000;
        penaltyToInsert.reference = 'Test Reference 1';
        penaltyToInsert.penaltyTypeId = parentPenaltyType.Id;
        penaltyToInsert.published = true;
        penaltyToInsert.unpublishDate = '31/12/2026';
        penaltyToInsert.landlordBusinessName = 'DEPARTMENT FOR ENERGY SECURITY & NET ZERO';
        penaltyToInsert.landlordFirstName = 'Jim';
        penaltyToInsert.landlordLastName = 'Jimothy';

        String penaltyJSONString = JSON.serialize(penaltyToInsert);

        String dpaQueryAddress = penaltyToInsert.propertyAddress + ', ' + penaltyToInsert.propertyCity + ', ' + penaltyToInsert.propertyPostcode;
        MockProvider mockProvider = new MockProvider();
        OSPlacesInteractionService.API mockLayer = (OSPlacesInteractionService.API) mockProvider.createMock(OSPlacesInteractionServiceLayer.class);
        OSPlacesInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.matchAddressForEnglandOrWalesOnly(dpaQueryAddress)).thenReturn(new List<DeliveryPointAddress>());

        //Act
        Test.startTest();
        Id upsertedPenaltyId = PRSE_LADashboardPenaltiesController.upsertPenaltyWithoutExemption(penaltyJSONString);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        List<Penalty__c> penalties = [
            SELECT Id, Exemption__c, Issued_Date__c, Penalty_Amount__c, 
            Penalty_Reference__c, Penalty_Type__c, Published__c, Unpublish_Date__c,
            LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c,
            PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c, 
            Local_Custodian_Code__c, PropertyType__c, PropertyUPRN__c
            FROM Penalty__c
        ];
        Assert.areEqual(1, penalties.size(), 'Incorrect number of penalties present.');
        Penalty__c penalty = penalties[0];
        Assert.areEqual(penalty.Id, upsertedPenaltyId, 'Incorrect upsertedPenaltyId.');
        Assert.areEqual(penaltyToInsert.propertyAddress, penalty.PropertyAddress__c, 'Incorrect PropertyAddress__c on Penalty.');
        Assert.areEqual(penaltyToInsert.propertyCity, penalty.PropertyCity__c, 'Incorrect PropertyCity__c on Penalty.');
        Assert.areEqual(penaltyToInsert.propertyPostcode, penalty.PropertyPostcode__c, 'Incorrect PropertyPostcode__c on Penalty.');
        Assert.areEqual(penaltyToInsert.propertyCounty, penalty.PropertyCounty__c, 'Incorrect PropertyCounty__c on Penalty.');
        Assert.areEqual(penaltyToInsert.propertyType, penalty.PropertyType__c, 'Incorrect PropertyType__c on Penalty.');
        Assert.areEqual(Date.newInstance(2024, 04, 12), penalty.Issued_Date__c, 'Incorrect Issued_Date__c on Penalty.');
        Assert.areEqual(penaltyToInsert.penaltyAmount, penalty.Penalty_Amount__c, 'Incorrect Penalty_Amount__c on Penalty.');
        Assert.areEqual(penaltyToInsert.reference, penalty.Penalty_Reference__c, 'Incorrect Penalty_Reference__c on Penalty.');
        Assert.areEqual(penaltyToInsert.penaltyTypeId, penalty.Penalty_Type__c, 'Incorrect Penalty_Type__c on Penalty.');
        Assert.areEqual(penaltyToInsert.published, penalty.Published__c, 'Incorrect Published__c on Penalty.');
        Assert.areEqual(Date.newInstance(2026, 12, 31), penalty.Unpublish_Date__c, 'Incorrect Unpublish_Date__c on Penalty.');
        Assert.areEqual(penaltyToInsert.landlordBusinessName, penalty.LandlordBusinessName__c, 'Incorrect LandlordBusinessName__c on Penalty.');
        Assert.areEqual(penaltyToInsert.landlordFirstName, penalty.LandlordFirstName__c, 'Incorrect LandlordFirstName__c on Penalty.');
        Assert.areEqual(penaltyToInsert.landlordLastName, penalty.LandlordLastName__c, 'Incorrect LandlordLastName__c on Penalty.');
        Assert.areEqual(null, penalty.Local_Custodian_Code__c, 'Incorrect Local_Custodian_Code__c on Penalty.');
        Assert.areEqual(null, penalty.PropertyUPRN__c, 'Incorrect PropertyUPRN__c on Penalty.');
    }

    @isTest
    static void upsertPenaltyWithoutExemption_withJSONStringAsNewPenaltyWithAddressFromOSPlaces_insertsNewPenalty() {
        //Arrange
        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Penalty_Type__c parentPenaltyType = new Penalty_Type__c();
        parentPenaltyType.Name = 'Test Penalty Type';
        parentPenaltyType.Code__c = 'P009';
        insert parentPenaltyType;
        
        PRSE_LADashboardPenaltiesController.Penalty penaltyToInsert = new PRSE_LADashboardPenaltiesController.Penalty();
        penaltyToInsert.propertyAddress = '3 Whitehall Place Before';
        penaltyToInsert.propertyCity = 'LONDON before';
        penaltyToInsert.propertyPostcode = 'SW1A 2AW';
        penaltyToInsert.propertyCounty = 'Greater London Before';
        penaltyToInsert.propertyType = 'Commercial';
        penaltyToInsert.dateIssued = '12/04/2024';
        penaltyToInsert.penaltyAmount = 3000;
        penaltyToInsert.reference = 'Test Reference 1';
        penaltyToInsert.penaltyTypeId = parentPenaltyType.Id;
        penaltyToInsert.published = true;
        penaltyToInsert.unpublishDate = '31/12/2026';
        penaltyToInsert.landlordBusinessName = 'DEPARTMENT FOR ENERGY SECURITY & NET ZERO';
        penaltyToInsert.landlordFirstName = 'Jim';
        penaltyToInsert.landlordLastName = 'Jimothy';

        String penaltyJSONString = JSON.serialize(penaltyToInsert);

        DeliveryPointAddress dpaToReturn = new DeliveryPointAddress();
        dpaToReturn.ADDRESS = 'DEPARTMENT FOR ENERGY SECURITY & NET ZERO, 3, WHITEHALL PLACE, LONDON, SW1A 2AW';
        dpaToReturn.ORGANISATION_NAME = 'DEPARTMENT FOR ENERGY SECURITY & NET ZERO';
        dpaToReturn.BUILDING_NUMBER = Long.valueOf('3');
        dpaToReturn.THOROUGHFARE_NAME = 'WHITEHALL PLACE';
        dpaToReturn.POST_TOWN = 'London';
        dpaToReturn.POSTCODE = 'SW1A 2AW2';
        dpaToReturn.UPRN = Long.valueOf('10038612291');
        dpaToReturn.LOCAL_CUSTODIAN_CODE = 5990;

        String dpaQueryAddress = penaltyToInsert.propertyAddress + ', ' + penaltyToInsert.propertyCity + ', ' + penaltyToInsert.propertyPostcode;
        MockProvider mockProvider = new MockProvider();
        OSPlacesInteractionService.API mockLayer = (OSPlacesInteractionService.API) mockProvider.createMock(OSPlacesInteractionServiceLayer.class);
        OSPlacesInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.matchAddressForEnglandOrWalesOnly(dpaQueryAddress)).thenReturn(new List<DeliveryPointAddress>{ dpaToReturn });

        //Act
        Test.startTest();
        Id upsertedPenaltyId = PRSE_LADashboardPenaltiesController.upsertPenaltyWithoutExemption(penaltyJSONString);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        List<Penalty__c> penalties = [
            SELECT Id, Exemption__c, Issued_Date__c, Penalty_Amount__c, 
            Penalty_Reference__c, Penalty_Type__c, Published__c, Unpublish_Date__c,
            LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c,
            PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c, 
            Local_Custodian_Code__c, PropertyType__c, PropertyUPRN__c
            FROM Penalty__c
        ];
        Assert.areEqual(1, penalties.size(), 'Incorrect number of penalties present.');
        Penalty__c penalty = penalties[0];
        Assert.areEqual(penalty.Id, upsertedPenaltyId, 'Incorrect upsertedPenaltyId.');
        String expectedPenaltyAddress = dpaToReturn.ORGANISATION_NAME + ', ' + dpaToReturn.BUILDING_NUMBER + ', ' + dpaToReturn.THOROUGHFARE_NAME;
        Assert.areEqual(penaltyToInsert.propertyAddress, penalty.PropertyAddress__c, 'Incorrect PropertyAddress__c on Penalty.');
        Assert.areEqual(penaltyToInsert.propertyCity, penalty.PropertyCity__c, 'Incorrect PropertyCity__c on Penalty.');
        Assert.areEqual(penaltyToInsert.propertyPostcode, penalty.PropertyPostcode__c, 'Incorrect PropertyPostcode__c on Penalty.');
        Assert.areEqual(penaltyToInsert.propertyCounty, penalty.PropertyCounty__c, 'Incorrect PropertyCounty__c on Penalty.');
        Assert.areEqual(penaltyToInsert.propertyType, penalty.PropertyType__c, 'Incorrect PropertyType__c on Penalty.');
        Assert.areEqual(Date.newInstance(2024, 04, 12), penalty.Issued_Date__c, 'Incorrect Issued_Date__c on Penalty.');
        Assert.areEqual(penaltyToInsert.penaltyAmount, penalty.Penalty_Amount__c, 'Incorrect Penalty_Amount__c on Penalty.');
        Assert.areEqual(penaltyToInsert.reference, penalty.Penalty_Reference__c, 'Incorrect Penalty_Reference__c on Penalty.');
        Assert.areEqual(penaltyToInsert.penaltyTypeId, penalty.Penalty_Type__c, 'Incorrect Penalty_Type__c on Penalty.');
        Assert.areEqual(penaltyToInsert.published, penalty.Published__c, 'Incorrect Published__c on Penalty.');
        Assert.areEqual(Date.newInstance(2026, 12, 31), penalty.Unpublish_Date__c, 'Incorrect Unpublish_Date__c on Penalty.');
        Assert.areEqual(penaltyToInsert.landlordBusinessName, penalty.LandlordBusinessName__c, 'Incorrect LandlordBusinessName__c on Penalty.');
        Assert.areEqual(penaltyToInsert.landlordFirstName, penalty.LandlordFirstName__c, 'Incorrect LandlordFirstName__c on Penalty.');
        Assert.areEqual(penaltyToInsert.landlordLastName, penalty.LandlordLastName__c, 'Incorrect LandlordLastName__c on Penalty.');
        Assert.areEqual(String.valueOf(dpaToReturn.LOCAL_CUSTODIAN_CODE), penalty.Local_Custodian_Code__c, 'Incorrect Local_Custodian_Code__c on Penalty.');
        Assert.areEqual(String.valueOf(dpaToReturn.UPRN), penalty.PropertyUPRN__c, 'Incorrect PropertyUPRN__c on Penalty.');
    }

    @isTest
    static void upsertPenaltyWithoutExemption_withJSONStringAsExistringPenalty_updatesExistingPenalty() {
        //Arrange
        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Penalty_Type__c parentPenaltyType = new Penalty_Type__c();
        parentPenaltyType.Name = 'Test Penalty Type';
        parentPenaltyType.Code__c = 'P009';
        insert parentPenaltyType;

        Penalty__c existingPenalty = new Penalty__c();
        existingPenalty.Issued_Date__c = Date.newInstance(2024, 04, 12);
        existingPenalty.Penalty_Amount__c = 2000;
        existingPenalty.Penalty_Reference__c = 'Penalty Reference Before';
        existingPenalty.Penalty_Type__c = parentPenaltyType.Id;
        existingPenalty.LandlordBusinessName__c = 'DEPARTMENT FOR ENERGY SECURITY & NET ZERO';
        existingPenalty.LandlordFirstName__c = 'Jim';
        existingPenalty.LandlordLastName__c = 'Jimothy';
        existingPenalty.PropertyAddress__c = 'Department For Energy Security & Net Zero, 3, Whitehall Place';
        existingPenalty.PropertyCity__c = 'London';
        existingPenalty.PropertyCounty__c = 'Greater London Before';
        existingPenalty.PropertyPostcode__c = 'SW1A 2AW2';
        existingPenalty.Local_Custodian_Code__c = '5990';
        existingPenalty.PropertyType__c = 'Commercial';
        existingPenalty.PropertyUPRN__c = '10038612291';
        insert existingPenalty;

        PRSE_LADashboardPenaltiesController.Penalty penaltyToUpdate = new PRSE_LADashboardPenaltiesController.Penalty();
        penaltyToUpdate.propertyAddress = '3 Whitehall Place After';
        penaltyToUpdate.propertyCity = 'LONDON After';
        penaltyToUpdate.propertyPostcode = 'SW1A 2AW';
        penaltyToUpdate.propertyCounty = 'Greater London After';
        penaltyToUpdate.propertyType = 'Commercial';
        penaltyToUpdate.dateIssued = '12/04/2024';
        penaltyToUpdate.penaltyAmount = 3000;
        penaltyToUpdate.reference = 'Penalty Reference After';
        penaltyToUpdate.penaltyTypeId = parentPenaltyType.Id;
        penaltyToUpdate.published = true;
        penaltyToUpdate.unpublishDate = '31/12/2026';
        penaltyToUpdate.landlordBusinessName = 'DEPARTMENT FOR ENERGY SECURITY & NET ZERO';
        penaltyToUpdate.landlordFirstName = 'James';
        penaltyToUpdate.landlordLastName = 'Jimmy';
        penaltyToUpdate.penaltyId = existingPenalty.Id;

        String penaltyJSONString = JSON.serialize(penaltyToUpdate);

        String dpaQueryAddress = penaltyToUpdate.propertyAddress + ', ' + penaltyToUpdate.propertyCity + ', ' + penaltyToUpdate.propertyPostcode;
        MockProvider mockProvider = new MockProvider();
        OSPlacesInteractionService.API mockLayer = (OSPlacesInteractionService.API) mockProvider.createMock(OSPlacesInteractionServiceLayer.class);
        OSPlacesInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.matchAddressForEnglandOrWalesOnly(dpaQueryAddress)).thenReturn(new List<DeliveryPointAddress>());

        //Act
        Test.startTest();
        Id upsertedPenaltyId = PRSE_LADashboardPenaltiesController.upsertPenaltyWithoutExemption(penaltyJSONString);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        List<Penalty__c> penalties = [
            SELECT Id, Exemption__c, Issued_Date__c, Penalty_Amount__c, 
            Penalty_Reference__c, Penalty_Type__c, Published__c, Unpublish_Date__c,
            LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c,
            PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c,
            Local_Custodian_Code__c, PropertyType__c, PropertyUPRN__c
            FROM Penalty__c
        ];
        Assert.areEqual(existingPenalty.Id, upsertedPenaltyId, 'Incorrect upsertedPenaltyId.');
        Assert.areEqual(1, penalties.size(), 'Incorrect number of penalties present.');
        Penalty__c penalty = penalties[0];
        Assert.areEqual(penalty.Id, upsertedPenaltyId, 'Incorrect upsertedPenaltyId.');
        Assert.areEqual(penaltyToUpdate.propertyAddress, penalty.PropertyAddress__c, 'Incorrect PropertyAddress__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.propertyCity, penalty.PropertyCity__c, 'Incorrect PropertyCity__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.propertyPostcode, penalty.PropertyPostcode__c, 'Incorrect PropertyPostcode__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.propertyCounty, penalty.PropertyCounty__c, 'Incorrect PropertyCounty__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.propertyType, penalty.PropertyType__c, 'Incorrect PropertyType__c on Penalty.');
        Assert.areEqual(Date.newInstance(2024, 04, 12), penalty.Issued_Date__c, 'Incorrect Issued_Date__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.penaltyAmount, penalty.Penalty_Amount__c, 'Incorrect Penalty_Amount__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.reference, penalty.Penalty_Reference__c, 'Incorrect Penalty_Reference__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.penaltyTypeId, penalty.Penalty_Type__c, 'Incorrect Penalty_Type__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.published, penalty.Published__c, 'Incorrect Published__c on Penalty.');
        Assert.areEqual(Date.newInstance(2026, 12, 31), penalty.Unpublish_Date__c, 'Incorrect Unpublish_Date__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.landlordBusinessName, penalty.LandlordBusinessName__c, 'Incorrect LandlordBusinessName__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.landlordFirstName, penalty.LandlordFirstName__c, 'Incorrect LandlordFirstName__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.landlordLastName, penalty.LandlordLastName__c, 'Incorrect LandlordLastName__c on Penalty.');
        Assert.areEqual(existingPenalty.Local_Custodian_Code__c, penalty.Local_Custodian_Code__c, 'Incorrect Local_Custodian_Code__c on Penalty.');
        Assert.areEqual(existingPenalty.PropertyUPRN__c, penalty.PropertyUPRN__c, 'Incorrect PropertyUPRN__c on Penalty.');
    }

    @isTest
    static void upsertPenaltyWithoutExemption_withJSONStringAsExistringPenaltyAndNotPublishedDate_updatesExistingPenalty() {
        //Arrange
        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Penalty_Type__c parentPenaltyType = new Penalty_Type__c();
        parentPenaltyType.Name = 'Test Penalty Type';
        parentPenaltyType.Code__c = 'P009';
        insert parentPenaltyType;

        Penalty__c existingPenalty = new Penalty__c();
        existingPenalty.Issued_Date__c = Date.newInstance(2024, 04, 12);
        existingPenalty.Penalty_Amount__c = 2000;
        existingPenalty.Penalty_Reference__c = 'Penalty Reference Before';
        existingPenalty.Penalty_Type__c = parentPenaltyType.Id;
        existingPenalty.LandlordBusinessName__c = 'DEPARTMENT FOR ENERGY SECURITY & NET ZERO';
        existingPenalty.LandlordFirstName__c = 'Jim';
        existingPenalty.LandlordLastName__c = 'Jimothy';
        existingPenalty.PropertyAddress__c = 'Department For Energy Security & Net Zero, 3, Whitehall Place';
        existingPenalty.PropertyCity__c = 'London';
        existingPenalty.PropertyCounty__c = 'Greater London Before';
        existingPenalty.PropertyPostcode__c = 'SW1A 2AW2';
        existingPenalty.Local_Custodian_Code__c = '5990';
        existingPenalty.PropertyType__c = 'Commercial';
        existingPenalty.PropertyUPRN__c = '10038612291';
        existingPenalty.Published__c = true;
        existingPenalty.Unpublish_Date__c = Date.today().addYears(1);
        insert existingPenalty;

        PRSE_LADashboardPenaltiesController.Penalty penaltyToUpdate = new PRSE_LADashboardPenaltiesController.Penalty();
        penaltyToUpdate.propertyAddress = '3 Whitehall Place After';
        penaltyToUpdate.propertyCity = 'LONDON After';
        penaltyToUpdate.propertyPostcode = 'SW1A 2AW';
        penaltyToUpdate.propertyCounty = 'Greater London After';
        penaltyToUpdate.propertyType = 'Commercial';
        penaltyToUpdate.dateIssued = '12/04/2024';
        penaltyToUpdate.penaltyAmount = 3000;
        penaltyToUpdate.reference = 'Penalty Reference After';
        penaltyToUpdate.penaltyTypeId = parentPenaltyType.Id;
        penaltyToUpdate.published = false;
        penaltyToUpdate.unpublishDate = 'Not published';
        penaltyToUpdate.landlordBusinessName = 'DEPARTMENT FOR ENERGY SECURITY & NET ZERO';
        penaltyToUpdate.landlordFirstName = 'James';
        penaltyToUpdate.landlordLastName = 'Jimmy';
        penaltyToUpdate.penaltyId = existingPenalty.Id;

        String penaltyJSONString = JSON.serialize(penaltyToUpdate);

        String dpaQueryAddress = penaltyToUpdate.propertyAddress + ', ' + penaltyToUpdate.propertyCity + ', ' + penaltyToUpdate.propertyPostcode;
        MockProvider mockProvider = new MockProvider();
        OSPlacesInteractionService.API mockLayer = (OSPlacesInteractionService.API) mockProvider.createMock(OSPlacesInteractionServiceLayer.class);
        OSPlacesInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.matchAddressForEnglandOrWalesOnly(dpaQueryAddress)).thenReturn(new List<DeliveryPointAddress>());

        //Act
        Test.startTest();
        Id upsertedPenaltyId = PRSE_LADashboardPenaltiesController.upsertPenaltyWithoutExemption(penaltyJSONString);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        List<Penalty__c> penalties = [
            SELECT Id, Exemption__c, Issued_Date__c, Penalty_Amount__c, 
            Penalty_Reference__c, Penalty_Type__c, Published__c, Unpublish_Date__c,
            LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c,
            PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c,
            Local_Custodian_Code__c, PropertyType__c, PropertyUPRN__c
            FROM Penalty__c
        ];
        Assert.areEqual(existingPenalty.Id, upsertedPenaltyId, 'Incorrect upsertedPenaltyId.');
        Assert.areEqual(1, penalties.size(), 'Incorrect number of penalties present.');
        Penalty__c penalty = penalties[0];
        Assert.areEqual(penalty.Id, upsertedPenaltyId, 'Incorrect upsertedPenaltyId.');
        Assert.areEqual(penaltyToUpdate.propertyAddress, penalty.PropertyAddress__c, 'Incorrect PropertyAddress__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.propertyCity, penalty.PropertyCity__c, 'Incorrect PropertyCity__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.propertyPostcode, penalty.PropertyPostcode__c, 'Incorrect PropertyPostcode__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.propertyCounty, penalty.PropertyCounty__c, 'Incorrect PropertyCounty__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.propertyType, penalty.PropertyType__c, 'Incorrect PropertyType__c on Penalty.');
        Assert.areEqual(Date.newInstance(2024, 04, 12), penalty.Issued_Date__c, 'Incorrect Issued_Date__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.penaltyAmount, penalty.Penalty_Amount__c, 'Incorrect Penalty_Amount__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.reference, penalty.Penalty_Reference__c, 'Incorrect Penalty_Reference__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.penaltyTypeId, penalty.Penalty_Type__c, 'Incorrect Penalty_Type__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.published, penalty.Published__c, 'Incorrect Published__c on Penalty.');
        Assert.areEqual(null, penalty.Unpublish_Date__c, 'Incorrect Unpublish_Date__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.landlordBusinessName, penalty.LandlordBusinessName__c, 'Incorrect LandlordBusinessName__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.landlordFirstName, penalty.LandlordFirstName__c, 'Incorrect LandlordFirstName__c on Penalty.');
        Assert.areEqual(penaltyToUpdate.landlordLastName, penalty.LandlordLastName__c, 'Incorrect LandlordLastName__c on Penalty.');
        Assert.areEqual(existingPenalty.Local_Custodian_Code__c, penalty.Local_Custodian_Code__c, 'Incorrect Local_Custodian_Code__c on Penalty.');
        Assert.areEqual(existingPenalty.PropertyUPRN__c, penalty.PropertyUPRN__c, 'Incorrect PropertyUPRN__c on Penalty.');
    }

    @isTest
    static void upsertPenaltyWithoutExemption_withErrorInProcess_logsErrorAndDoesNotUpsertAnything() {
        //Arrange
        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Penalty_Type__c parentPenaltyType = new Penalty_Type__c();
        parentPenaltyType.Name = 'Test Penalty Type';
        parentPenaltyType.Code__c = 'P009';
        insert parentPenaltyType;

        PRSE_LADashboardPenaltiesController.Penalty penaltyToInsert = new PRSE_LADashboardPenaltiesController.Penalty();
        penaltyToInsert.propertyAddress = '3 Whitehall Place';
        penaltyToInsert.propertyCity = 'LONDON';
        penaltyToInsert.propertyPostcode = 'SW1A 2AW';
        penaltyToInsert.propertyCounty = 'Greater London';
        penaltyToInsert.propertyType = 'Commercial';
        penaltyToInsert.dateIssued = '12/04/2024';
        penaltyToInsert.penaltyAmount = 3000;
        penaltyToInsert.reference = 'Test Reference 1';
        penaltyToInsert.penaltyTypeId = parentPenaltyType.Id;
        penaltyToInsert.published = true;
        penaltyToInsert.unpublishDate = '31/12/2026';
        penaltyToInsert.landlordBusinessName = 'DEPARTMENT FOR ENERGY SECURITY & NET ZERO';
        penaltyToInsert.landlordFirstName = 'Jim';
        penaltyToInsert.landlordLastName = 'Jimothy';

        Penalty__c expectedPenaltyToBeInserted = new Penalty__c(
            PropertyAddress__c = '3 Whitehall Place',
            PropertyCity__c = 'LONDON',
            PropertyPostcode__c = 'SW1A 2AW',
            PropertyCounty__c = 'Greater London',
            PropertyType__c = 'Commercial',
            Issued_Date__c = Date.newInstance(2024, 4, 12),
            Penalty_Amount__c = 3000,
            Penalty_Reference__c = 'Test Reference 1',
            Penalty_Type__c = 'a0tPv00000Xo1kHIAR',
            Published__c = true,
            Unpublish_Date__c = Date.newInstance(2026, 12, 31),
            LandlordBusinessName__c = 'DEPARTMENT FOR ENERGY SECURITY & NET ZERO',
            LandlordFirstName__c = 'Jim',
            LandlordLastName__c = 'Jimothy'
        );

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(mockDatabaseWrapper.upsertRecord(expectedPenaltyToBeInserted)).thenThrow(new Exceptions.CustomException('An error has occured'));

        String penaltyJSONString = JSON.serialize(penaltyToInsert);

        String dpaQueryAddress = penaltyToInsert.propertyAddress + ', ' + penaltyToInsert.propertyCity + ', ' + penaltyToInsert.propertyPostcode;
        OSPlacesInteractionService.API mockLayer = (OSPlacesInteractionService.API) mockProvider.createMock(OSPlacesInteractionServiceLayer.class);
        OSPlacesInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.matchAddressForEnglandOrWalesOnly(dpaQueryAddress)).thenReturn(new List<DeliveryPointAddress>());

        //Act
        Test.startTest();
        Id upsertedPenaltyId = PRSE_LADashboardPenaltiesController.upsertPenaltyWithoutExemption(penaltyJSONString);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LADashboardPenaltiesController', 'upsertPenaltyWithoutExemption');
        List<Penalty__c> penalties = [
            SELECT Id, Exemption__c, Issued_Date__c, Penalty_Amount__c, 
            Penalty_Reference__c, Penalty_Type__c, Published__c, Unpublish_Date__c
            FROM Penalty__c
        ];
        Assert.areEqual(0, penalties.size(), 'Incorrect number of penalties present.');
        Assert.areEqual(null, upsertedPenaltyId, 'Incorrect upsertedPenaltyId.');
    }

    @isTest
    static void deletePenalty_withoutPenaltyId_doesNotDeleteAnything() {
        //Arrange
        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Exemption__c testExemption1 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 1'
        );
        insert testExemption1;
        Exemption__c testExemption2 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 2'
        );
        insert testExemption2;

        Penalty_Type__c parentPenaltyType = new Penalty_Type__c();
        parentPenaltyType.Name = 'Test Penalty Type';
        parentPenaltyType.Code__c = 'P009';
        insert parentPenaltyType;

        List<Penalty__c> penalties = new List<Penalty__c>();
        Penalty__c testPenalty1 = new Penalty__c();
        testPenalty1.Penalty_Reference__c = 'Penalty 1';
        testPenalty1.Exemption__c = testExemption1.Id;
        testPenalty1.Penalty_Type__c = parentPenaltyType.Id;
        testPenalty1.Issued_Date__c = Date.today();
        penalties.add(testPenalty1);
        Penalty__c testPenalty2 = new Penalty__c();
        testPenalty2.Penalty_Reference__c = 'Penalty 2';
        testPenalty2.Exemption__c = testExemption2.Id;
        testPenalty2.Penalty_Type__c = parentPenaltyType.Id;
        testPenalty2.Issued_Date__c = Date.today();
        penalties.add(testPenalty2);
        insert penalties;

        //Act
        Test.startTest();
        PRSE_LADashboardPenaltiesController.deletePenalty('');
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        List<Penalty__c> penaltiesAfterDelete = [SELECT Id FROM Penalty__c];
        Assert.areEqual(2, penaltiesAfterDelete.size(), 'Expected 1 Penalty to be returned.');
        Assert.areEqual(testPenalty1.Id, penaltiesAfterDelete[0].Id, 'Incorrect Penalty returned.');
        Assert.areEqual(testPenalty2.Id, penaltiesAfterDelete[1].Id, 'Incorrect Penalty returned.');
    }

    @isTest
    static void deletePenalty_withPenaltyIdAndPenaltyMatchingLocalAuthority_deletesPenalty() {
        //Arrange
        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Exemption__c testExemption1 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 1'
        );
        insert testExemption1;
        Exemption__c testExemption2 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 2'
        );
        insert testExemption2;

        Penalty_Type__c parentPenaltyType = new Penalty_Type__c();
        parentPenaltyType.Name = 'Test Penalty Type';
        parentPenaltyType.Code__c = 'P009';
        insert parentPenaltyType;

        List<Penalty__c> penalties = new List<Penalty__c>();
        Penalty__c testPenalty1 = new Penalty__c();
        testPenalty1.Penalty_Reference__c = 'Penalty 1';
        testPenalty1.Exemption__c = testExemption1.Id;
        testPenalty1.Penalty_Type__c = parentPenaltyType.Id;
        testPenalty1.Issued_Date__c = Date.today();
        penalties.add(testPenalty1);
        Penalty__c testPenalty2 = new Penalty__c();
        testPenalty2.Penalty_Reference__c = 'Penalty 2';
        testPenalty2.Exemption__c = testExemption2.Id;
        testPenalty2.Penalty_Type__c = parentPenaltyType.Id;
        testPenalty2.Issued_Date__c = Date.today();
        penalties.add(testPenalty2);
        insert penalties;

        MockProvider mockProvider = new MockProvider();
        PRSE_LAViewExemptionHelper mockExemptionHelper = (PRSE_LAViewExemptionHelper) mockProvider.createMock(PRSE_LAViewExemptionHelper.class);
        PRSE_LAViewExemptionHelper.instance = mockExemptionHelper;
        mockProvider.when(mockExemptionHelper.checkPenaltyInstance(testPenalty1.Id)).thenReturn(true);

        //Act
        Test.startTest();
        PRSE_LADashboardPenaltiesController.deletePenalty(testPenalty1.Id);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        List<Penalty__c> penaltiesAfterDelete = [SELECT Id FROM Penalty__c];
        Assert.areEqual(1, penaltiesAfterDelete.size(), 'Expected 1 Penalty to be returned.');
        Assert.areEqual(testPenalty2.Id, penaltiesAfterDelete[0].Id, 'Incorrect Penalty returned.');
    }

    @isTest
    static void deletePenalty_withPenaltyIdAndPenaltyNotMatchingLocalAuthority_doesNotDeletePenalty() {
        //Arrange
        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Exemption__c testExemption1 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 1'
        );
        insert testExemption1;
        Exemption__c testExemption2 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 2'
        );
        insert testExemption2;

        Penalty_Type__c parentPenaltyType = new Penalty_Type__c();
        parentPenaltyType.Name = 'Test Penalty Type';
        parentPenaltyType.Code__c = 'P009';
        insert parentPenaltyType;

        List<Penalty__c> penalties = new List<Penalty__c>();
        Penalty__c testPenalty1 = new Penalty__c();
        testPenalty1.Penalty_Reference__c = 'Penalty 1';
        testPenalty1.Exemption__c = testExemption1.Id;
        testPenalty1.Penalty_Type__c = parentPenaltyType.Id;
        testPenalty1.Issued_Date__c = Date.today();
        penalties.add(testPenalty1);
        Penalty__c testPenalty2 = new Penalty__c();
        testPenalty2.Penalty_Reference__c = 'Penalty 2';
        testPenalty2.Exemption__c = testExemption2.Id;
        testPenalty2.Penalty_Type__c = parentPenaltyType.Id;
        testPenalty2.Issued_Date__c = Date.today();
        penalties.add(testPenalty2);
        insert penalties;

        MockProvider mockProvider = new MockProvider();
        PRSE_LAViewExemptionHelper mockExemptionHelper = (PRSE_LAViewExemptionHelper) mockProvider.createMock(PRSE_LAViewExemptionHelper.class);
        PRSE_LAViewExemptionHelper.instance = mockExemptionHelper;
        mockProvider.when(mockExemptionHelper.checkPenaltyInstance(testPenalty1.Id)).thenReturn(false);

        //Act
        Test.startTest();
        PRSE_LADashboardPenaltiesController.deletePenalty(testPenalty1.Id);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        List<Penalty__c> penaltiesAfterDelete = [SELECT Id FROM Penalty__c];
        Assert.areEqual(2, penaltiesAfterDelete.size(), 'Expected 2 Penalties to be returned.');
    }

    @isTest
    static void deletePenalty_deleteError_catchesErrorAndDoesNotDelete() {
        //Arrange
        Account testAccount = new Account(Name = 'Test');
        insert testAccount;

        Exemption__c testExemption1 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 1'
        );
        insert testExemption1;
        Exemption__c testExemption2 = new Exemption__c(
            Status__c = 'Received', 
            Account__c = testAccount.Id,
            Published__c = true,
            AdditionalInformation__c = 'Test Exemption 2'
        );
        insert testExemption2;

        Penalty_Type__c parentPenaltyType = new Penalty_Type__c();
        parentPenaltyType.Name = 'Test Penalty Type';
        parentPenaltyType.Code__c = 'P009';
        insert parentPenaltyType;

        List<Penalty__c> penalties = new List<Penalty__c>();
        Penalty__c testPenalty1 = new Penalty__c();
        testPenalty1.Penalty_Reference__c = 'Penalty 1';
        testPenalty1.Exemption__c = testExemption1.Id;
        testPenalty1.Penalty_Type__c = parentPenaltyType.Id;
        testPenalty1.Issued_Date__c = Date.today();
        penalties.add(testPenalty1);
        Penalty__c testPenalty2 = new Penalty__c();
        testPenalty2.Penalty_Reference__c = 'Penalty 2';
        testPenalty2.Exemption__c = testExemption2.Id;
        testPenalty2.Penalty_Type__c = parentPenaltyType.Id;
        testPenalty2.Issued_Date__c = Date.today();
        penalties.add(testPenalty2);
        insert penalties;

        MockProvider mockProvider = new MockProvider();
        PRSE_LAViewExemptionHelper mockExemptionHelper = (PRSE_LAViewExemptionHelper) mockProvider.createMock(PRSE_LAViewExemptionHelper.class);
        PRSE_LAViewExemptionHelper.instance = mockExemptionHelper;
        mockProvider.when(mockExemptionHelper.checkPenaltyInstance(testPenalty1.Id)).thenReturn(true);
        
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.deleteRecordWithId(testPenalty1.Id)
        ).thenThrow(new Exceptions.CustomException('An error has occured'));
        
        //Act
        Test.startTest();
        PRSE_LADashboardPenaltiesController.deletePenalty(testPenalty1.Id);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LADashboardPenaltiesController', 'deletePenalty', 'An error has occured');
        List<Penalty__c> penaltiesAfterDelete = [SELECT Id FROM Penalty__c];
        Assert.areEqual(2, penaltiesAfterDelete.size(), 'Expected 1 Penalty to be returned.');
        Assert.areEqual(testPenalty1.Id, penaltiesAfterDelete[0].Id, 'Incorrect Penalty returned.');
        Assert.areEqual(testPenalty2.Id, penaltiesAfterDelete[1].Id, 'Incorrect Penalty returned.');
    }

    @isTest
    static void getPenaltyTypes_withNoTypesInDatabase_returnsEmptyList() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.query('SELECT Id, Name, Code__c FROM Penalty_Type__c ORDER BY Code__C ASC')
        ).thenReturn(new List<Penalty_Type__c>());
        
        //Act
        Test.startTest();
        List<Penalty_Type__c> penaltyTypes = PRSE_LADashboardPenaltiesController.getPenaltyTypes();
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.isTrue(penaltyTypes.isEmpty(), 'Expected no Penalty Types to be returned.');
    }

    @isTest
    static void getPenaltyTypes_withTypesInDatabase_returnsPenaltyTypes() {
        //Arrange
        List<Penalty_Type__c> penaltyTypesToReturn = new List<Penalty_Type__c>();
        Penalty_Type__c type1 = new Penalty_Type__c();
        type1.Code__c = 'P01';
        type1.Id = SObjectUtil.generateIdForType('Penalty_Type__c');
        type1.Name = 'Type 1';
        penaltyTypesToReturn.add(type1);
        Penalty_Type__c type2 = new Penalty_Type__c();
        type2.Code__c = 'P02';
        type2.Id = SObjectUtil.generateIdForType('Penalty_Type__c');
        type2.Name = 'Type 2';
        penaltyTypesToReturn.add(type2);

        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.query('SELECT Id, Name, Code__c FROM Penalty_Type__c ORDER BY Code__C ASC')
        ).thenReturn(penaltyTypesToReturn);
        
        //Act
        Test.startTest();
        List<Penalty_Type__c> penaltyTypes = PRSE_LADashboardPenaltiesController.getPenaltyTypes();
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(2, penaltyTypes.size(), 'Incorrect number of Penalty Types returned.');
        Assert.areEqual(penaltyTypesToReturn[0], penaltyTypes[0], 'Incorrect Penalty Type returned.');
        Assert.areEqual(penaltyTypesToReturn[1], penaltyTypes[1], 'Incorrect Penalty Type returned.');
    }

    @isTest
    static void getPenaltyTypes_queryError_catchesErrorAndReturnsEmptyList() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        DatabaseWrapper mockDatabaseWrapper = (DatabaseWrapper) mockProvider.createMock(DatabaseWrapper.class);
        DatabaseWrapper.instance = mockDatabaseWrapper;
        mockProvider.when(
            mockDatabaseWrapper.query('SELECT Id, Name, Code__c FROM Penalty_Type__c ORDER BY Code__C ASC')
        ).thenThrow(new Exceptions.CustomException('An error has occured'));
        
        //Act
        Test.startTest();
        List<Penalty_Type__c> penaltyTypes = PRSE_LADashboardPenaltiesController.getPenaltyTypes();
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_LADashboardPenaltiesController', 'getPenaltyTypes', 'An error has occured');
        Assert.isTrue(penaltyTypes.isEmpty(), 'Expected no Penalty Types to be returned.');
    }

    static List<Penalty__c> createMockPenalties(Integer numberOfPenalties, Exemption__c parentExemption) {
        List<Penalty__c> toReturn = new List<Penalty__c>();
        for(Integer i = 0; i < numberOfPenalties; i++) {
            Penalty__c newPenalty = new Penalty__c();
            newPenalty.Penalty_Reference__c = 'Penalty ' + i;
            if(parentExemption != null) {
                newPenalty.Exemption__c = parentExemption.Id;
                newPenalty.Exemption_Type_Link__c = parentExemption.ExemptionTypeLinks__r[0].Id;
            }
            newPenalty.Penalty_Type__c = SObjectUtil.generateIdForType('Penalty_Type__c');
            newPenalty.Issued_Date__c = Date.today();
            newPenalty.Unpublish_Date__c = Date.today().addMonths(1);
            newPenalty.Published__c = true;
            newPenalty.Penalty_Amount__c = 1000 + i;
            toReturn.add(newPenalty);
        }
        return toReturn;
    }

    static ExemptionData createMockExemptions(Integer numberOfExemptions, Boolean withChildExemptions) {
        ExemptionData toReturn = new ExemptionData();
        
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
                List<Exemption_Type_Link__c> relatedChildExemptions = createChildMockExemptions(singleExemption);
                toReturn.childExemptionsByParentId.put(exemptionId, relatedChildExemptions);
            
                Map<String, Object> childFields = new Map<String, Object> {
                    'ExemptionTypeLinks__r' => relatedChildExemptions
                };
                
                singleExemption = (Exemption__c) SObjectUtil.updateSObject(
                    singleExemption, 
                    childFields
                );
            }
            toReturn.parentExemptions.put(exemptionId, singleExemption);
        }

        return toReturn;
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

    private class ExemptionData {
        public Map<Id, Exemption__c> parentExemptions;
        public Map<Id, List<Exemption_Type_Link__c>> childExemptionsByParentId;
        
        public ExemptionData() {
            this.parentExemptions = new Map<Id, Exemption__c>();
            this.childExemptionsByParentId = new Map<Id, List<Exemption_Type_Link__c>>();
        }

        public List<Exemption__c> getParentExemptions() {
            return this.parentExemptions.values();
        }
        
        public List<Exemption_Type_Link__c> getChildExemptionsForParent(Id parentId) {
            if (childExemptionsByParentId.containsKey(parentId)) {
                return childExemptionsByParentId.get(parentId);
            }
            return new List<Exemption_Type_Link__c>();
        }
    }

}