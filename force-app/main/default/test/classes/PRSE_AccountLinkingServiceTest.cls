@isTest
private class PRSE_AccountLinkingServiceTest {
    
    @testSetup
    static void setupTestData() {
        // Get Person Account RecordType if it exists
        Id personAccountRecordTypeId;
        try {
            personAccountRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;
        } catch (Exception e) {
        }
        
        // Create legacy Person Account
        Account legacyAccount = new Account(
            FirstName = 'Legacy',
            LastName = 'User',
            PersonEmail = 'legacy.user.' + System.currentTimeMillis() + '@test.com'
        );
        if (personAccountRecordTypeId != null) {
            legacyAccount.RecordTypeId = personAccountRecordTypeId;
        }
        insert legacyAccount;
        
        // Create new Person Account
        Account newAccount = new Account(
            FirstName = 'New',
            LastName = 'User',
            PersonEmail = 'new.user.' + System.currentTimeMillis() + '@test.com'
        );
        if (personAccountRecordTypeId != null) {
            newAccount.RecordTypeId = personAccountRecordTypeId;
        }
        insert newAccount;
        
        // Create test users
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        String uniqueUsername = 'newowner.' + System.currentTimeMillis() + '@test.prse.com';
        
        User newOwner = new User(
            FirstName = 'New',
            LastName = 'Owner',
            Email = 'newowner.' + System.currentTimeMillis() + '@test.com',
            Username = uniqueUsername,
            Alias = 'newown',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_GB'
        );
        insert newOwner;
        
        // Create Exemption__c records for legacy account
        List<Exemption__c> exemptions = new List<Exemption__c>();
        for (Integer i = 0; i < 3; i++) {
            exemptions.add(new Exemption__c(
                Account__c = legacyAccount.Id
            ));
        }
        insert exemptions;
        
        // Create child Exemption_Type_Link__c records
        List<Exemption_Type_Link__c> typeLinks = new List<Exemption_Type_Link__c>();
        for (Exemption__c exemption : exemptions) {
            typeLinks.add(new Exemption_Type_Link__c(
                Exemption__c = exemption.Id
            ));
        }
        insert typeLinks;
    }
    
    @isTest
    static void testSuccessfulTransfer() {
        // Get test data
        Account legacyAccount = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'Legacy' LIMIT 1];
        Account newAccount = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'New' LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE Alias = 'newown' AND LastName = 'Owner' LIMIT 1];
        
        // Prepare input
        PRSE_AccountLinkingService.TransferInput input = new PRSE_AccountLinkingService.TransferInput();
        input.legacyAccountId = legacyAccount.Id;
        input.newAccountId = newAccount.Id;
        input.newOwnerId = newOwner.Id;
        
        // Execute transfer
        Test.startTest();
        List<PRSE_AccountLinkingService.TransferOutput> outputs = 
            PRSE_AccountLinkingService.transferExemptions(new List<PRSE_AccountLinkingService.TransferInput>{input});
        Test.stopTest();
        
        // Verify output
        System.assertEquals(1, outputs.size(), 'Should have one output');
        PRSE_AccountLinkingService.TransferOutput output = outputs[0];
        System.assertEquals('Success', output.status, 'Status should be Success');
        System.assertEquals(3, output.recordsTransferred, 'Should transfer 3 records');
        System.assert(output.message.contains('3 exemption records'), 'Message should mention record count');
        
        // Verify transferred exemptions
        List<Exemption__c> transferredExemptions = [
            SELECT Id, OwnerId, Account__c 
            FROM Exemption__c 
            WHERE Account__c = :newAccount.Id
        ];
        System.assertEquals(3, transferredExemptions.size(), 'Should have 3 exemptions in new account');
        
        for (Exemption__c exemption : transferredExemptions) {
            System.assertEquals(newOwner.Id, exemption.OwnerId, 'Owner should be updated');
            System.assertEquals(newAccount.Id, exemption.Account__c, 'Account should be updated');
        }
        
        // Verify no exemptions remain on legacy account
        List<Exemption__c> remainingExemptions = [
            SELECT Id 
            FROM Exemption__c 
            WHERE Account__c = :legacyAccount.Id
        ];
        System.assertEquals(0, remainingExemptions.size(), 'No exemptions should remain on legacy account');
        
        // Verify no errors were logged
        ErrorLogChecker.checkNoErrorsForService('PRSE_AccountLinkingService');
    }
    
    @isTest
    static void testNoExemptionsToTransfer() {
        // Get test data
        Account newAccount = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'New' LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE Alias = 'newown' AND LastName = 'Owner' LIMIT 1];
        
        // Prepare input with account that has no exemptions
        PRSE_AccountLinkingService.TransferInput input = new PRSE_AccountLinkingService.TransferInput();
        input.legacyAccountId = newAccount.Id; // Using new account which has no exemptions
        input.newAccountId = newAccount.Id;
        input.newOwnerId = newOwner.Id;
        
        // Execute transfer
        Test.startTest();
        List<PRSE_AccountLinkingService.TransferOutput> outputs = 
            PRSE_AccountLinkingService.transferExemptions(new List<PRSE_AccountLinkingService.TransferInput>{input});
        Test.stopTest();
        
        // Verify output
        System.assertEquals(1, outputs.size(), 'Should have one output');
        PRSE_AccountLinkingService.TransferOutput output = outputs[0];
        System.assertEquals('Success', output.status, 'Status should be Success');
        System.assertEquals(0, output.recordsTransferred, 'Should transfer 0 records');
        System.assert(output.message.contains('No exemption records'), 'Message should mention no records found');
        
        // Verify no errors were logged
        ErrorLogChecker.checkNoErrorsForService('PRSE_AccountLinkingService');
    }
    
    @isTest
    static void testBulkTransfer() {
        // Get test data
        Account legacyAccount = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'Legacy' LIMIT 1];
        Account newAccount = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'New' LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE Alias = 'newown' AND LastName = 'Owner' LIMIT 1];
        
        // Prepare multiple inputs
        List<PRSE_AccountLinkingService.TransferInput> inputs = new List<PRSE_AccountLinkingService.TransferInput>();
        
        for (Integer i = 0; i < 2; i++) {
            PRSE_AccountLinkingService.TransferInput input = new PRSE_AccountLinkingService.TransferInput();
            input.legacyAccountId = legacyAccount.Id;
            input.newAccountId = newAccount.Id;
            input.newOwnerId = newOwner.Id;
            inputs.add(input);
        }
        
        // Execute transfer
        Test.startTest();
        List<PRSE_AccountLinkingService.TransferOutput> outputs = 
            PRSE_AccountLinkingService.transferExemptions(inputs);
        Test.stopTest();
        
        // Verify outputs
        System.assertEquals(2, outputs.size(), 'Should have two outputs');
        
        // First request transfers all records
        System.assertEquals('Success', outputs[0].status, 'First transfer status should be Success');
        System.assertEquals(3, outputs[0].recordsTransferred, 'First transfer should move 3 records');
        
        // Second request finds no records (already transferred)
        System.assertEquals('Success', outputs[1].status, 'Second transfer status should be Success');
        System.assertEquals(0, outputs[1].recordsTransferred, 'Second transfer should find 0 records');
        
        // Verify no errors were logged
        ErrorLogChecker.checkNoErrorsForService('PRSE_AccountLinkingService');
    }
    
    @isTest
    static void testMasterDetailOwnershipCascade() {
        // Get test data
        Account legacyAccount = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'Legacy' LIMIT 1];
        Account newAccount = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'New' LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE Alias = 'newown' AND LastName = 'Owner' LIMIT 1];
        
        // Count child records before transfer
        Integer initialChildCount = [
            SELECT COUNT()
            FROM Exemption_Type_Link__c
            WHERE Exemption__r.Account__c = :legacyAccount.Id
        ];
        
        System.assertEquals(3, initialChildCount, 'Should have 3 child records');
        
        // Prepare input
        PRSE_AccountLinkingService.TransferInput input = new PRSE_AccountLinkingService.TransferInput();
        input.legacyAccountId = legacyAccount.Id;
        input.newAccountId = newAccount.Id;
        input.newOwnerId = newOwner.Id;
        
        // Execute transfer
        Test.startTest();
        List<PRSE_AccountLinkingService.TransferOutput> outputs = 
            PRSE_AccountLinkingService.transferExemptions(new List<PRSE_AccountLinkingService.TransferInput>{input});
        Test.stopTest();
        
        // Verify transfer was successful
        System.assertEquals('Success', outputs[0].status, 'Transfer status should be Success');
        
        // Verify child records moved with parent exemptions
        Integer finalChildCount = [
            SELECT COUNT()
            FROM Exemption_Type_Link__c
            WHERE Exemption__r.Account__c = :newAccount.Id
        ];
        
        System.assertEquals(3, finalChildCount, 'Child records should move with parent exemptions');
        
        // Verify no errors were logged
        ErrorLogChecker.checkNoErrorsForService('PRSE_AccountLinkingService');
    }
    
    @isTest
    static void testErrorHandling() {
        // Get test data
        Account legacyAccount = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'Legacy' LIMIT 1];
        Account newAccount = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'New' LIMIT 1];
        
        // Create an inactive user to force a DML error
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User inactiveOwner = new User(
            FirstName = 'Inactive',
            LastName = 'Owner',
            Email = 'inactive.' + System.currentTimeMillis() + '@test.com',
            Username = 'inactive.' + System.currentTimeMillis() + '@test.prse.com',
            Alias = 'inact',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = false
        );
        insert inactiveOwner;
        
        // Prepare input with inactive user
        PRSE_AccountLinkingService.TransferInput input = new PRSE_AccountLinkingService.TransferInput();
        input.legacyAccountId = legacyAccount.Id;
        input.newAccountId = newAccount.Id;
        input.newOwnerId = inactiveOwner.Id;
        
        // Execute transfer
        Test.startTest();
        List<PRSE_AccountLinkingService.TransferOutput> outputs = 
            PRSE_AccountLinkingService.transferExemptions(new List<PRSE_AccountLinkingService.TransferInput>{input});
        Test.stopTest();
        
        // Verify error output
        System.assertEquals(1, outputs.size(), 'Should have one output');
        PRSE_AccountLinkingService.TransferOutput output = outputs[0];
        System.assertEquals('Partial Success', output.status, 'Status should be Partial Success or Error');
        System.assert(output.message.contains('failed') || output.message.contains('Partial'), 'Message should indicate failure or partial success');
        
        // Verify error was logged
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_AccountLinkingService', 'transferExemptions');
    }
    
    @isTest
    static void testNullLegacyAccountId() {
        // Get test data
        Account newAccount = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'New' LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE Alias = 'newown' AND LastName = 'Owner' LIMIT 1];
        
        // Prepare input with null legacy account ID
        PRSE_AccountLinkingService.TransferInput input = new PRSE_AccountLinkingService.TransferInput();
        input.legacyAccountId = null;
        input.newAccountId = newAccount.Id;
        input.newOwnerId = newOwner.Id;
        
        // Execute transfer
        Test.startTest();
        List<PRSE_AccountLinkingService.TransferOutput> outputs = 
            PRSE_AccountLinkingService.transferExemptions(new List<PRSE_AccountLinkingService.TransferInput>{input});
        Test.stopTest();
        
        // Verify error output
        System.assertEquals(1, outputs.size(), 'Should have one output');
        PRSE_AccountLinkingService.TransferOutput output = outputs[0];
        System.assertEquals('Error', output.status, 'Status should be Error');
        System.assert(output.message.contains('Validation failed'), 'Message should indicate validation failure');
        System.assert(output.message.contains('Legacy Account ID'), 'Message should mention legacy account');
        
        // Verify error was logged
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_AccountLinkingService', 'transferExemptions');
    }
    
    @isTest
    static void testNullNewAccountId() {
        // Get test data
        Account legacyAccount = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'Legacy' LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE Alias = 'newown' AND LastName = 'Owner' LIMIT 1];
        
        // Prepare input with null new account ID
        PRSE_AccountLinkingService.TransferInput input = new PRSE_AccountLinkingService.TransferInput();
        input.legacyAccountId = legacyAccount.Id;
        input.newAccountId = null;
        input.newOwnerId = newOwner.Id;
        
        // Execute transfer
        Test.startTest();
        List<PRSE_AccountLinkingService.TransferOutput> outputs = 
            PRSE_AccountLinkingService.transferExemptions(new List<PRSE_AccountLinkingService.TransferInput>{input});
        Test.stopTest();
        
        // Verify error output
        System.assertEquals(1, outputs.size(), 'Should have one output');
        PRSE_AccountLinkingService.TransferOutput output = outputs[0];
        System.assertEquals('Error', output.status, 'Status should be Error');
        System.assert(output.message.contains('Validation failed'), 'Message should indicate validation failure');
        System.assert(output.message.contains('New Account ID'), 'Message should mention new account');
        
        // Verify error was logged
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_AccountLinkingService', 'transferExemptions');
    }
    
    @isTest
    static void testNullNewOwnerId() {
        // Get test data
        Account legacyAccount = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'Legacy' LIMIT 1];
        Account newAccount = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'New' LIMIT 1];
        
        // Prepare input with null new owner ID
        PRSE_AccountLinkingService.TransferInput input = new PRSE_AccountLinkingService.TransferInput();
        input.legacyAccountId = legacyAccount.Id;
        input.newAccountId = newAccount.Id;
        input.newOwnerId = null;
        
        // Execute transfer
        Test.startTest();
        List<PRSE_AccountLinkingService.TransferOutput> outputs = 
            PRSE_AccountLinkingService.transferExemptions(new List<PRSE_AccountLinkingService.TransferInput>{input});
        Test.stopTest();
        
        // Verify error output
        System.assertEquals(1, outputs.size(), 'Should have one output');
        PRSE_AccountLinkingService.TransferOutput output = outputs[0];
        System.assertEquals('Error', output.status, 'Status should be Error');
        System.assert(output.message.contains('Validation failed'), 'Message should indicate validation failure');
        System.assert(output.message.contains('New Owner ID'), 'Message should mention new owner');
        
        // Verify error was logged
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_AccountLinkingService', 'transferExemptions');
    }
    
    @isTest
    static void testInvalidAccountId() {
        // Get test data
        User newOwner = [SELECT Id FROM User WHERE Alias = 'newown' AND LastName = 'Owner' LIMIT 1];
        
        // Prepare input with invalid account ID
        PRSE_AccountLinkingService.TransferInput input = new PRSE_AccountLinkingService.TransferInput();
        input.legacyAccountId = '001000000000000'; // Invalid ID
        input.newAccountId = '001000000000001'; // Invalid ID
        input.newOwnerId = newOwner.Id;
        
        // Execute transfer
        Test.startTest();
        List<PRSE_AccountLinkingService.TransferOutput> outputs = 
            PRSE_AccountLinkingService.transferExemptions(new List<PRSE_AccountLinkingService.TransferInput>{input});
        Test.stopTest();
        
        // Verify output (should complete successfully with 0 records)
        System.assertEquals(1, outputs.size(), 'Should have one output');
        PRSE_AccountLinkingService.TransferOutput output = outputs[0];
        System.assertEquals('Success', output.status, 'Status should be Success');
        System.assertEquals(0, output.recordsTransferred, 'Should transfer 0 records');
        
        // Verify no errors were logged (no exemptions found is not an error)
        ErrorLogChecker.checkNoErrorsForService('PRSE_AccountLinkingService');
    }
}