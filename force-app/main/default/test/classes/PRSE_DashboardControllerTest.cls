@IsTest
private class PRSE_DashboardControllerTest {
    
    private static final String TEST_EMAIL = 'testuser@example.com';
    private static final String TEST_FIRST_NAME = 'Test';
    private static final String TEST_LAST_NAME = 'Landlord';
    
    @IsTest
    static void testGetTotalExemptions_Draft() {
        // Arrange
        createTestData();
        
        // Act
        Test.startTest();
        Integer count = PRSE_DashboardController.getTotalExemptions('draft');
        Test.stopTest();
        
        // Assert
        System.assertEquals(5, count, 'Should return 5 draft exemptions');
    }
    
    @IsTest
    static void testGetTotalExemptions_Registered() {
        // Arrange
        createTestData();
        
        // Act
        Test.startTest();
        Integer count = PRSE_DashboardController.getTotalExemptions('registered');
        Test.stopTest();
        
        // Assert
        System.assertEquals(3, count, 'Should return 3 registered exemptions');
    }
    
    @IsTest
    static void testGetTotalExemptions_Ended() {
        // Arrange
        createTestData();
        
        // Act
        Test.startTest();
        Integer count = PRSE_DashboardController.getTotalExemptions('ended');
        Test.stopTest();
        
        // Assert
        System.assertEquals(3, count, 'Should return 3 ended exemptions');
    }
    
    @IsTest
    static void testGetExemptionRecords_Draft() {
        // Arrange
        createTestData();
        
        // Act
        Test.startTest();
        PRSE_DashboardController.PaginatedResult result = 
            PRSE_DashboardController.getExemptionRecords(3, 1, 'draft');
        Test.stopTest();
        
        // Assert
        System.assertEquals(5, result.totalRecords, 'Total records should be 5');
        System.assertEquals(3, result.records.size(), 'Should return 3 records on first page');
        System.assertEquals(3, result.pageSize, 'Page size should be 3');
        System.assertEquals(1, result.pageNumber, 'Page number should be 1');
    }
    
    @IsTest
    static void testGetExemptionRecords_Registered() {
        // Arrange
        createTestData();
        
        // Act
        Test.startTest();
        PRSE_DashboardController.PaginatedResult result = 
            PRSE_DashboardController.getExemptionRecords(10, 1, 'registered');
        Test.stopTest();
        
        // Assert
        System.assertEquals(3, result.totalRecords, 'Total records should be 3');
        System.assertEquals(3, result.records.size(), 'Should return 3 records');
        
        Exemption__c firstRecord = (Exemption__c)result.records[0];
        System.assertEquals('Needs update', firstRecord.Status__c, 'First record should have Needs update status');
    }
    
    @IsTest
    static void testGetExemptionRecords_Ended() {
        // Arrange
        createTestData();
        
        // Act
        Test.startTest();
        PRSE_DashboardController.PaginatedResult result = 
            PRSE_DashboardController.getExemptionRecords(2, 1, 'ended');
        Test.stopTest();
        
        // Assert
        System.assertEquals(3, result.totalRecords, 'Total records should be 3');
        System.assertEquals(2, result.records.size(), 'Should return 2 records on first page');
    }
    
    @IsTest
    static void testGetExemptionRecords_Pagination() {
        // Arrange
        createTestData();
        
        // Act
        Test.startTest();
        PRSE_DashboardController.PaginatedResult page1 = 
            PRSE_DashboardController.getExemptionRecords(2, 1, 'draft');
        PRSE_DashboardController.PaginatedResult page2 = 
            PRSE_DashboardController.getExemptionRecords(2, 2, 'draft');
        Test.stopTest();
        
        // Assert
        System.assertEquals(2, page1.records.size(), 'Page 1 should have 2 records');
        System.assertEquals(2, page2.records.size(), 'Page 2 should have 2 records');
        System.assertNotEquals(page1.records[0].Id, page2.records[0].Id, 'Pages should have different records');
    }
    
    @IsTest
    static void testGetExemptionRecords_DefaultValues() {
        // Arrange
        createTestData();
        
        // Act
        Test.startTest();
        PRSE_DashboardController.PaginatedResult result = 
            PRSE_DashboardController.getExemptionRecords(null, null, 'draft');
        Test.stopTest();
        
        // Assert
        System.assertEquals(20, result.pageSize, 'Default page size should be 20');
        System.assertEquals(1, result.pageNumber, 'Default page number should be 1');
    }
    
    @IsTest
    static void testGetEndedExemption() {
        // Arrange
        createTestData();
        Exemption_Type_Link__c link = [SELECT Id FROM Exemption_Type_Link__c LIMIT 1];
        
        // Act
        Test.startTest();
        Exemption_Type_Link__c result = PRSE_DashboardController.getEndedExemption(link.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Should return exemption type link');
        System.assertNotEquals(null, result.Child_Exemption_Ref__c, 'Should have child exemption ref');
        System.assertNotEquals(null, result.Exemption_Type__r.Name, 'Should have exemption type name');
        System.assertNotEquals(null, result.Exemption__r.PropertyAddress__c, 'Should have property address');
    }
    
    // Helper method to create test data
    private static void createTestData() {
        // Create Account
        Account testAccount = new Account(
            FirstName = TEST_FIRST_NAME,
            LastName = TEST_LAST_NAME,
            PersonEmail = TEST_EMAIL,
            Landlord_Type__c = 'Individual'
        );
        insert testAccount;
        
        // Create Exemption Type
        Exemption_Type__c exemptionType = new Exemption_Type__c(
            Name = 'Test Exemption Type',
            Code__c = 'T001'
        );
        insert exemptionType;
        
        // Create Draft Exemptions
        List<Exemption__c> draftExemptions = new List<Exemption__c>();
        for(Integer i = 0; i < 5; i++) {
            draftExemptions.add(new Exemption__c(
                Status__c = 'Draft',
                PropertyAddress__c = i + ' Draft Street',
                PropertyPostcode__c = 'DR1 ' + i + 'XX',
                Account__c = testAccount.Id,
                OwnerId = UserInfo.getUserId()
            ));
        }
        insert draftExemptions;
        
        // Create Registered Exemptions
        List<Exemption__c> registeredExemptions = new List<Exemption__c>();
        registeredExemptions.add(new Exemption__c(
            Status__c = 'Received',
            PropertyAddress__c = '1 Registered Street',
            PropertyPostcode__c = 'RG1 1XX',
            Registered_Date__c = Date.today().addDays(-10),
            LandlordFirstName__c = TEST_FIRST_NAME,
            LandlordLastName__c = TEST_LAST_NAME,
            Account__c = testAccount.Id,
            OwnerId = UserInfo.getUserId()
        ));
        registeredExemptions.add(new Exemption__c(
            Status__c = 'Needs update',
            PropertyAddress__c = '2 Registered Street',
            PropertyPostcode__c = 'RG2 2XX',
            Registered_Date__c = Date.today().addDays(-5),
            LandlordFirstName__c = TEST_FIRST_NAME,
            LandlordLastName__c = TEST_LAST_NAME,
            Account__c = testAccount.Id,
            OwnerId = UserInfo.getUserId()
        ));
        registeredExemptions.add(new Exemption__c(
            Status__c = 'Approved',
            PropertyAddress__c = '3 Registered Street',
            PropertyPostcode__c = 'RG3 3XX',
            Registered_Date__c = Date.today().addDays(-15),
            LandlordFirstName__c = TEST_FIRST_NAME,
            LandlordLastName__c = TEST_LAST_NAME,
            Account__c = testAccount.Id,
            OwnerId = UserInfo.getUserId()
        ));
        insert registeredExemptions;
        
        // Create Exemption Type Links (Ended Exemptions)
        List<Exemption_Type_Link__c> exemptionLinks = new List<Exemption_Type_Link__c>();
        for(Integer i = 0; i < 3; i++) {
            exemptionLinks.add(new Exemption_Type_Link__c(
                Exemption__c = registeredExemptions[i].Id,
                Exemption_Type__c = exemptionType.Id,
                End_Date__c = Date.today().addDays(-i)
            ));
        }
        insert exemptionLinks;
    }
}