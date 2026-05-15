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
        
        User newOwner = new User(
            FirstName = 'New',
            LastName = 'Owner',
            Email = 'newowner.' + System.currentTimeMillis() + '@test.com',
            Username = 'newowner.' + System.currentTimeMillis() + '@test.prse.com',
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

        // Create ContentVersion (file) for each exemption
        List<ContentVersion> versions = new List<ContentVersion>();
        for (Exemption__c exemption : exemptions) {
            versions.add(new ContentVersion(
                Title          = 'Test File ' + exemption.Id,
                PathOnClient   = 'testfile.txt',
                VersionData    = Blob.valueOf('Test file content'),
                IsMajorVersion = true
            ));
        }
        insert versions;

        // Link each file to its exemption via ContentDocumentLink
        List<ContentVersion> insertedVersions = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :versions
        ];

        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
        Integer idx = 0;
        for (ContentVersion cv : insertedVersions) {
            cdls.add(new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId    = exemptions[idx].Id,
                ShareType         = 'V',
                Visibility        = 'AllUsers'
            ));
            idx++;
        }
        insert cdls;
    }
    
    @isTest
    static void transferExemptions_withValidInput_transfersAllExemptionsToNewAccount() {
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
        System.assertEquals('Success', outputs[0].status, 'Status should be Success');
        System.assertEquals(3, outputs[0].recordsTransferred, 'Should transfer 3 records');
        System.assert(outputs[0].message.contains('3 exemption records'), 'Message should mention record count');
        
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

        // Verify new user CDLs were created for each file
        List<Exemption__c> newExemptions = [SELECT Id FROM Exemption__c WHERE Account__c = :newAccount.Id];
        Set<Id> exemptionIds = new Map<Id, Exemption__c>(newExemptions).keySet();
        Set<Id> contentDocIds = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :exemptionIds
        ]) {
            contentDocIds.add(cdl.ContentDocumentId);
        }
        List<ContentDocumentLink> newUserCdls = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId IN :contentDocIds
            AND LinkedEntityId = :newOwner.Id
        ];
        System.assertEquals(3, newUserCdls.size(), 'New owner should have CDLs for all 3 files');
        
        ErrorLogChecker.checkNoErrorsForService('PRSE_AccountLinkingService');
    }
    
    @isTest
    static void transferExemptions_withAccountHavingNoExemptions_returnsSuccessWithZeroRecords() {
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
        System.assertEquals('Success', outputs[0].status, 'Status should be Success');
        System.assertEquals(0, outputs[0].recordsTransferred, 'Should transfer 0 records');
        System.assert(outputs[0].message.contains('No exemption records'), 'Message should mention no records found');
        
        // Verify no errors were logged
        ErrorLogChecker.checkNoErrorsForService('PRSE_AccountLinkingService');
    }
    
    @isTest
    static void transferExemptions_withMultipleInputs_processesEachInputInOrder() {
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
    static void transferExemptions_withValidInput_movesChildExemptionTypeLinksWithParent() {
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
        
        ErrorLogChecker.checkNoErrorsForService('PRSE_AccountLinkingService');
    }

    @isTest
    static void transferExemptions_withValidInput_createsCDLsForNewOwner() {
        Account legacyAccount = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'Legacy' LIMIT 1];
        Account newAccount    = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'New' LIMIT 1];
        User newOwner         = [SELECT Id FROM User WHERE Alias = 'newown' AND LastName = 'Owner' LIMIT 1];

        PRSE_AccountLinkingService.TransferInput input = new PRSE_AccountLinkingService.TransferInput();
        input.legacyAccountId = legacyAccount.Id;
        input.newAccountId    = newAccount.Id;
        input.newOwnerId      = newOwner.Id;

        Test.startTest();
        PRSE_AccountLinkingService.transferExemptions(new List<PRSE_AccountLinkingService.TransferInput>{input});
        Test.stopTest();

        // Get all content docs linked to transferred exemptions
        List<Exemption__c> newExemptions = [SELECT Id FROM Exemption__c WHERE Account__c = :newAccount.Id];
        Set<Id> exemptionIds = new Map<Id, Exemption__c>(newExemptions).keySet();

        Set<Id> contentDocIds = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :exemptionIds
        ]) {
            contentDocIds.add(cdl.ContentDocumentId);
        }

        // Verify new owner has a CDL for each file with correct settings
        List<ContentDocumentLink> newOwnerCdls = [
            SELECT Id, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :contentDocIds
            AND LinkedEntityId = :newOwner.Id
        ];
        System.assertEquals(3, newOwnerCdls.size(), 'New owner should have a CDL for each file');
        for (ContentDocumentLink cdl : newOwnerCdls) {
            System.assertEquals('V', cdl.ShareType, 'ShareType should be Viewer');
            System.assertEquals('AllUsers', cdl.Visibility, 'Visibility should be AllUsers');
        }

        ErrorLogChecker.checkNoErrorsForService('PRSE_AccountLinkingService');
    }

    @isTest
    static void transferExemptions_calledTwiceForSameAccount_doesNotDuplicateCDLsOnSecondCall() {
        Account legacyAccount = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'Legacy' LIMIT 1];
        Account newAccount    = [SELECT Id FROM Account WHERE LastName = 'User' AND FirstName = 'New' LIMIT 1];
        User newOwner         = [SELECT Id FROM User WHERE Alias = 'newown' AND LastName = 'Owner' LIMIT 1];

        PRSE_AccountLinkingService.TransferInput input = new PRSE_AccountLinkingService.TransferInput();
        input.legacyAccountId = legacyAccount.Id;
        input.newAccountId    = newAccount.Id;
        input.newOwnerId      = newOwner.Id;

        // Run transfer twice
        Test.startTest();
        PRSE_AccountLinkingService.transferExemptions(new List<PRSE_AccountLinkingService.TransferInput>{input});
        PRSE_AccountLinkingService.transferExemptions(new List<PRSE_AccountLinkingService.TransferInput>{input});
        Test.stopTest();

        // Second transfer finds no exemptions so no duplicate CDLs should be created
        List<Exemption__c> newExemptions = [SELECT Id FROM Exemption__c WHERE Account__c = :newAccount.Id];
        Set<Id> exemptionIds = new Map<Id, Exemption__c>(newExemptions).keySet();

        Set<Id> contentDocIds = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :exemptionIds
        ]) {
            contentDocIds.add(cdl.ContentDocumentId);
        }

        List<ContentDocumentLink> newOwnerCdls = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId IN :contentDocIds
            AND LinkedEntityId = :newOwner.Id
        ];
        System.assertEquals(3, newOwnerCdls.size(), 'Should not have duplicate CDLs for new owner');

        ErrorLogChecker.checkNoErrorsForService('PRSE_AccountLinkingService');
    }
    
    @isTest
    static void transferExemptions_withInactiveNewOwner_returnsErrorStatus() {
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
        // Inactive user will fail exemption ownership update
        System.assert(outputs[0].status == 'Partial Success' || outputs[0].status == 'Error', 'Status should indicate failure');
        System.assert(outputs[0].message.contains('failed') || outputs[0].message.contains('Partial') || outputs[0].message.contains('Transfer'), 'Message should indicate failure');
        
        // Verify error was logged
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_AccountLinkingService', 'transferExemptions');
    }
    
    @isTest
    static void transferExemptions_withNullLegacyAccountId_returnsValidationError() {
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
        System.assertEquals('Error', outputs[0].status, 'Status should be Error');
        System.assert(outputs[0].message.contains('Validation failed'), 'Message should indicate validation failure');
        System.assert(outputs[0].message.contains('Legacy Account ID'), 'Message should mention legacy account');
        
        // Verify error was logged
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_AccountLinkingService', 'transferExemptions');
    }
    
    @isTest
    static void transferExemptions_withNullNewAccountId_returnsValidationError() {
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
        System.assertEquals('Error', outputs[0].status, 'Status should be Error');
        System.assert(outputs[0].message.contains('Validation failed'), 'Message should indicate validation failure');
        System.assert(outputs[0].message.contains('New Account ID'), 'Message should mention new account');
        
        // Verify error was logged
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_AccountLinkingService', 'transferExemptions');
    }
    
    @isTest
    static void transferExemptions_withNullNewOwnerId_returnsValidationError() {
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
        System.assertEquals('Error', outputs[0].status, 'Status should be Error');
        System.assert(outputs[0].message.contains('Validation failed'), 'Message should indicate validation failure');
        System.assert(outputs[0].message.contains('New Owner ID'), 'Message should mention new owner');
        
        // Verify error was logged
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_AccountLinkingService', 'transferExemptions');
    }
    
    @isTest
    static void transferExemptions_withNonExistentAccountIds_returnsSuccessWithZeroRecords() {
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
        System.assertEquals('Success', outputs[0].status, 'Status should be Success');
        System.assertEquals(0, outputs[0].recordsTransferred, 'Should transfer 0 records');
        
        // Verify no errors were logged (no exemptions found is not an error)
        ErrorLogChecker.checkNoErrorsForService('PRSE_AccountLinkingService');
    }
}