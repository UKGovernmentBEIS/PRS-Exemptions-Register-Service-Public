/**
 * @description       Test class for PRSE_LAViewExemptionController.
 *                    Covers all controller methods, including null-Id branches.
 *                    Creates required test data for Exemption__c, child links, Person Account, and ContentDocument links.
 * @group             PRS Exemptions
 * @since             v1.0
 */
@IsTest
private class PRSE_LAViewExemptionControllerTest {

    /**
     * @description       Sets up test data for all test methods in this class.
     *                    Creates Person Account, User, Exemption__c record,
     *                    Child Exemption Type Link, and ContentDocument/ContentDocumentLink.
     */
    @TestSetup
    static void setupData() {
        // Query Person Account RecordType
        RecordType personRt = [SELECT Id, Name 
                            FROM RecordType 
                            WHERE SObjectType = 'Account' 
                                AND IsPersonType = true
                            LIMIT 1];

        Account personAcc = new Account(
            FirstName = 'John',
            LastName = 'Landlord',
            RecordTypeId = personRt.Id,
            Landlord_Type__c = 'Individual',
            BusinessName__c = 'Landlord Ltd'
        );
        insert personAcc;

        Account personAccAgent = new Account(
            FirstName = 'John',
            LastName = 'Landlord',
            RecordTypeId = personRt.Id,
            Landlord_Type__c = 'Agent',
            BusinessName__c = 'Agency Ltd',
            PersonMailingStreet = 'Street',
            PersonMailingCity = 'City',
            PersonMailingState = 'State',
            PersonMailingPostalCode = 'PostCode'
        );
        insert personAccAgent;

        Account linkedAccount = [SELECT Id, PersonContactId,Landlord_Type__c, BusinessName__c FROM Account WHERE Id = :personAcc.Id LIMIT 1];

        Profile portalProfile = [SELECT Id FROM Profile WHERE Name='DEZNZ_PRS_Landlord Customer Community Plus Login User' LIMIT 1];

        // Create User linked to Person Account
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = portalProfile.Id,
            TimeZoneSidKey = 'Europe/London',
            UserName = 'testuser' + System.currentTimeMillis() + '@example.com',
            ContactId = linkedAccount.PersonContactId
        );
        insert u;

        // create test user to run the tests as LA user and with and without access
        Profile laPortalProfile = [
            SELECT Id 
            FROM Profile 
            WHERE Name = 'DEZNZ_PRS_Local Authority Customer Community Plus Login User'
            LIMIT 1
        ];

        Account laPersonAcc = new Account(
            FirstName = 'LA',
            LastName = 'User',
            RecordTypeId = personRt.Id,
            BusinessName__c = 'Test LA Ltd'
        );
        insert laPersonAcc; 
        
        laPersonAcc = [SELECT Id, PersonContactId, OwnerId, FirstName, LastName FROM Account WHERE Id = :laPersonAcc.Id];

        RecordType laRt = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND Name = 'Local Authority'
            LIMIT 1
        ];

        Account laBusinessAcc = new Account(
            Name = 'Test LA Business',
            RecordTypeId = laRt.Id,
            Local_Custodian_Code__c = '1945'
        );
        insert laBusinessAcc;

        insert new AccountContactRelation(
            AccountId = laBusinessAcc.Id,
            ContactId = laPersonAcc.PersonContactId,
            Roles = 'Local Authority User',
            IsActive = true
        );     

        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User sysAdmin = new User(
            Alias = 'sauser',
            Email = 'sauser' + System.currentTimeMillis() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'Europe/London',
            UserName = 'sauser' + System.currentTimeMillis() + '@example.com',
            IsActive = true
        );
        insert sysAdmin;

        System.runAs(sysAdmin) {
            User laUser = new User(
                Alias = 'lauser',
                Email = 'lauser' + System.currentTimeMillis() + '@example.com',
                EmailEncodingKey = 'UTF-8',
                FirstName = laPersonAcc.FirstName,
                LastName = laPersonAcc.LastName,
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = laPortalProfile.Id,
                TimeZoneSidKey = 'Europe/London',
                UserName = 'lauser' + System.currentTimeMillis() + '@example.com',
                ContactId = laPersonAcc.PersonContactId,
                IsActive = true
            );
            insert laUser;
        }

        // Create Exemption
        Exemption__c ex = new Exemption__c(
            Account__c = personAcc.Id,
            Local_Custodian_Code__c = '1945',
            LandlordFirstName__c = 'John1',
            LandlordLastName__c = 'Doe',
            LandlordBusinessName__c = 'JD Rentals',
            LandlordAddress__c = '1 Main Street',
            LandlordPhone__c = '01234567891',
            LandlordEmail__c = 'jd@example.com',
            EPC_Certificate__c = '0000-0000-0000-0000-0000',
            OwnerId = u.Id
        );
        insert ex;

        // Create Exemption Type record
        Exemption_Type__c exType = new Exemption_Type__c(
            Name = 'Test Type',
            Code__c = '01'
        );
        insert exType;

        // Create Child Exemption Type Link
        Exemption_Type_Link__c link = new Exemption_Type_Link__c(
            Exemption__c = ex.Id,
            Exemption_Type__c = exType.Id
        );
        insert link;

        Exemption__c ex2 = new Exemption__c(
            Account__c = personAcc.Id,
            Local_Custodian_Code__c = '1945',
            LandlordFirstName__c = 'John2',
            LandlordLastName__c = 'Doe',
            LandlordBusinessName__c = 'JD2 Rentals',
            LandlordAddress__c = '2 Main Street',
            LandlordPhone__c = '01234567892',
            LandlordEmail__c = 'jd2@example.com',
            OwnerId = u.Id
        );
        insert ex2;   

        // Create a second Exemption Type record
        Exemption_Type__c exType2 = new Exemption_Type__c(
            Name='Type Without Docs',
            Code__c='02'
        );
        insert exType2;

        // Create a second Exemption Type Link, with no documents attached
        Exemption_Type_Link__c linkNoDocs = new Exemption_Type_Link__c(
            Exemption__c = ex2.Id,
            Exemption_Type__c = exType2.Id
        );
        insert linkNoDocs;

        Exemption__c ex3 = new Exemption__c(
            Account__c = personAcc.Id,
            Local_Custodian_Code__c = '1945',
            LandlordFirstName__c = 'John3',
            LandlordLastName__c = 'Doe',
            LandlordBusinessName__c = 'JD3 Rentals',
            LandlordAddress__c = '3 Main Street',
            LandlordPhone__c = '01234567893',
            LandlordEmail__c = 'jd3@example.com',
            OwnerId = u.Id,
            Status__c = 'Received'
        );
        insert ex3;  
        
        Exemption__c ex4 = new Exemption__c(
            Account__c = personAccAgent.Id,
            Local_Custodian_Code__c = '360',
            LandlordFirstName__c = 'John360',
            LandlordLastName__c = 'Doe',
            LandlordBusinessName__c = 'JD4 Rentals',
            LandlordAddress__c = '4 Main Street',
            LandlordPhone__c = '01234567894',
            LandlordEmail__c = 'jd4@example.com',
            OwnerId = u.Id,
            Status__c = 'Received'
        );
        insert ex4;
        
        Exemption__c ex5 = new Exemption__c(
            Account__c = personAccAgent.Id,
            Local_Custodian_Code__c = '1945',
            LandlordFirstName__c = 'John1945Agent',
            LandlordLastName__c = 'Doe',
            LandlordBusinessName__c = 'JD5 Rentals',
            LandlordAddress__c = '5 Main Street',
            LandlordPhone__c = '01234567895',
            LandlordEmail__c = 'jd5@example.com',
            OwnerId = u.Id,
            Status__c = 'Received'
        );
        insert ex5;  

        Exemption__c ex6 = new Exemption__c(
            Account__c = personAcc.Id,
            Local_Custodian_Code__c = '1945',
            LandlordFirstName__c = 'John6NoAgent',
            LandlordLastName__c = 'Doe',
            LandlordBusinessName__c = 'JD6 Rentals',
            LandlordAddress__c = '6 Main Street',
            LandlordPhone__c = '01234567896',
            LandlordEmail__c = 'jd6@example.com',
            OwnerId = u.Id,
            Status__c = 'Received'
        );
        insert ex6;

        // Add a ContentDocument for testing
        ContentVersion cv = new ContentVersion(
            Title = 'Evidence Doc',
            PathOnClient = 'Evidence.pdf',
            VersionData = Blob.valueOf('Test content'),
            IsMajorVersion = true
        );
        insert cv;

        // Step 2: Query ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = link.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;       
        
        // Add a ContentDocument for testing
        ContentVersion cv2 = new ContentVersion(
            Title = 'EPC Certificate',
            PathOnClient = 'EPCCert.pdf',
            VersionData = Blob.valueOf('Test content'),
            IsMajorVersion = true
        );
        insert cv2;

        // Step 2: Query ContentDocumentId
        cv2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id];

        ContentDocumentLink cdl2 = new ContentDocumentLink(
            LinkedEntityId = ex2.Id,
            ContentDocumentId = cv2.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl2;     
        
    }


    @IsTest
    private static User getLaUser() {
        return [
            SELECT Id, FirstName, LastName
            FROM User
            WHERE Profile.Name = 'DEZNZ_PRS_Local Authority Customer Community Plus Login User'
            AND FirstName = 'LA'
            AND LastName = 'User'
            AND IsActive = true
            LIMIT 1
        ];
    }


    /**
     * @description       Tests getExemption() method with a valid Id.
     */
    @IsTest
    static void getExemption_withValidIdForLocalAuth_returnsExemption() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c WHERE Local_Custodian_Code__c = '1945' LIMIT 1];
        
        System.runAs(laUser) {
            Exemption__c result = PRSE_LAViewExemptionController.getExemption(ex.Id);            
            System.assertNotEquals(null, result, 'Expected a non-null Exemption__c record');            
            System.assertEquals(ex.Id, result.Id, 'Returned Id should match the test Exemption');
        }
    }


    /**
     * @description       Tests getExemption() method with a valid Id but not a local authority
     */
    @IsTest
    static void getExemption_withValidIdButNotForLocalAuth_returnsExemption() {
        User laUser = getLaUser();        
        Exemption__c ex = [SELECT Id FROM Exemption__c WHERE Local_Custodian_Code__c = '360' LIMIT 1];
        Boolean exceptionThrown = false;
        
        System.runAs(laUser) {
            try{
                Exemption__c result = PRSE_LAViewExemptionController.getExemption(ex.Id);

            } catch (AuraHandledException e) {
            	exceptionThrown = true;
        	}
        	System.assert(exceptionThrown, 'Expected AuraHandledException for null postcode');
         }
    }


    /**
     * @description       Tests getExemptionLandlordDetails() method with a valid exemption Id.
     */
    @IsTest
    static void getExemptionLandlordDetails_withValidId_returnsLandlordDetails() {
        User laUser = getLaUser();        
        Exemption__c ex = [SELECT Id FROM Exemption__c WHERE LandlordFirstName__c = 'John1' LIMIT 1];
		
        System.runAs(laUser) {
            PRSE_LAViewExemptionController.ExemptionWrapper wrapper = PRSE_LAViewExemptionController.getExemptionLandlordDetails(ex.Id);
            System.assertNotEquals(null, wrapper, 'Expected a non-null ExemptionWrapper');
            System.assertEquals('John1', wrapper.LandlordFirstName, 'Landlord first name should match');
        }
    }


    /**
     * @description       Tests getExemptionLandlordDetails() method with a valid Id but not a local authority
     */
    @IsTest
    static void getExemptionLandlordDetails_withValidIdButNotForLocalAuth_returnsExemption() {
        User laUser = getLaUser();        
        Exemption__c ex = [SELECT Id FROM Exemption__c WHERE Local_Custodian_Code__c = '360' LIMIT 1];
        Boolean exceptionThrown = false;
        
        System.runAs(laUser) {
            try{
                PRSE_LAViewExemptionController.ExemptionWrapper wrapper = PRSE_LAViewExemptionController.getExemptionLandlordDetails(ex.Id);
            } catch (AuraHandledException e) {
            	exceptionThrown = true;
        	}
        	System.assert(exceptionThrown, 'Expected AuraHandledException for invalid LA');
         }
    }


    /**
     * @description       Tests getExemptionAgentDetails() with valid agent now returns AgentWrapper.
     */
    @IsTest
    static void getExemptionAgentDetails_withAgent_returnsAgentWrapper() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c WHERE LandlordFirstName__c = 'John1945Agent' LIMIT 1];

        System.runAs(laUser) {
            PRSE_LAViewExemptionController.AgentWrapper agent =
                PRSE_LAViewExemptionController.getExemptionAgentDetails(ex.Id);

            System.assertNotEquals(null, agent, 'Expected a non-null AgentWrapper');
            System.assertEquals('Agent', agent.LandlordType, 'Expected LandlordType to be Agent');
            Assert.areEqual('Street', agent.Address.contains('Street') ? 'Street' : null);
        }
    }


    /**
     * @description       Tests getExemptionAgentDetails() with agent but wrong LA expects exception.
     */
    @IsTest
    static void getExemptionAgentDetails_withAgentWrongLA_returnsException() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c WHERE Local_Custodian_Code__c = '360' LIMIT 1];
        Boolean exceptionThrown = false;

        System.runAs(laUser) {
            try {
                PRSE_LAViewExemptionController.AgentWrapper agent =
                    PRSE_LAViewExemptionController.getExemptionAgentDetails(ex.Id);
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
            System.assert(exceptionThrown, 'Expected AuraHandledException for invalid LA');
        }
    }


    /**
     * @description       Tests getExemptionAgentDetails() when landlord is not an agent expects null return.
     */
    @IsTest
    static void getExemptionAgentDetails_withoutAgent_returnsNull() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c WHERE LandlordFirstName__c = 'John6NoAgent' LIMIT 1];

        System.runAs(laUser) {
            PRSE_LAViewExemptionController.AgentWrapper agent =
                PRSE_LAViewExemptionController.getExemptionAgentDetails(ex.Id);

            System.assertEquals(null, agent, 'Expected null when landlord type is not Agent');
        }
    }


    /**
     * @description       Tests getExemptionDetails() method and ensures child exemptions are returned.
     */
    @IsTest
    static void getExemptionDetails_withValidId_returnsChildExemptions() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c WHERE LandlordFirstName__c = 'John1' LIMIT 1];

        System.runAs(laUser) {
            PRSE_LAViewExemptionController.ExemptionDetailsWrapper wrap =
            PRSE_LAViewExemptionController.getExemptionDetails(ex.Id);

            System.assertNotEquals(null, wrap, 'Expected non-null ExemptionDetailsWrapper');
            System.assert(wrap.childExemptions.size() > 0, 'Expected at least one child exemption');
        }
    }


    /**
     * @description       Tests getExemptionDetails() method for invalid LA
     */
    @IsTest
    static void getExemptionDetails_withValidIdWrongLA_returnsChildExemptions() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c WHERE Local_Custodian_Code__c = '360' LIMIT 1];
        Boolean exceptionThrown = false;

        System.runAs(laUser) {
            try {
                PRSE_LAViewExemptionController.ExemptionDetailsWrapper wrap =
                PRSE_LAViewExemptionController.getExemptionDetails(ex.Id);
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
            System.assert(exceptionThrown, 'Expected AuraHandledException for invalid LA');
        }
    }

    /**
     * @description       Tests getExemptionEvidenceDocumentsGrouped() method.
     */
    @IsTest
    static void getExemptionEvidenceDocumentsGrouped_withDocuments_returnsGroupedDocuments() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c where LandlordFirstName__c = 'John1' LIMIT 1];

        System.runAs(laUser) {        
            List<Map<String, Object>> groupedDocs = PRSE_LAViewExemptionController.getExemptionEvidenceDocumentsGrouped(ex.Id);

            Boolean foundWithDocs = false;
            for (Map<String, Object> theGroup : groupedDocs) {
                List<Map<String, String>> docs = (List<Map<String, String>>)theGroup.get('Documents');
                for (Map<String, String> doc : docs) {
                    if (doc.get('DocumentTitle').startsWith('Evidence Doc')) {
                        foundWithDocs = true;
                    }
                }
            }
            System.assert(foundWithDocs, 'Expected document with actual ContentDocument');
        }
    }


    /**
     * @description       Tests getExemptionEvidenceDocumentsGrouped() method when no documents are attached.
     */
    @IsTest
    static void getExemptionEvidenceDocumentsGrouped_withoutDocuments_returnsNoDocumentPlaceholder() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c where LandlordFirstName__c = 'John2' LIMIT 1];

        System.runAs(laUser) {
            List<Map<String, Object>> groupedDocs = PRSE_LAViewExemptionController.getExemptionEvidenceDocumentsGrouped(ex.Id);

            Boolean foundNoDocs = false;
            for (Map<String, Object> theGroup : groupedDocs) {
                List<Map<String, String>> docs = (List<Map<String, String>>)theGroup.get('Documents');
                for (Map<String, String> doc : docs) {
                    if (doc.get('DocumentTitle') == 'No document attached') {
                        foundNoDocs = true;
                    }
                }
            }
            System.assert(foundNoDocs, 'Expected at least one document group with "No document attached"');
        }
    }
    /**
     * @description       Tests getExemptionEvidenceDocumentsGrouped() method for invalid LA
     */
    @IsTest
    static void getExemptionEvidenceDocumentsGrouped_withDocumentsWrongLA_returnsGroupedDocuments() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c WHERE Local_Custodian_Code__c = '360' LIMIT 1];
        Boolean exceptionThrown = false;

        System.runAs(laUser) {
            try {
                List<Map<String, Object>> groupedDocs = PRSE_LAViewExemptionController.getExemptionEvidenceDocumentsGrouped(ex.Id);
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }

            System.assert(exceptionThrown, 'Expected AuraHandledException for invalid LA');
        }
    }    


    /**
     * @description Tests getExemptionNotes returns the correct notes
     */
    @IsTest
    static void getExemptionNotes_withValidExemption_returnsNullNotes() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c where LandlordFirstName__c = 'John2' LIMIT 1];
        System.runAs(laUser) {        
            String notes = PRSE_LAViewExemptionController.getExemptionNotes(ex.Id);
            System.assertEquals('', notes, 'Expected initial notes to be empty string');
        }
    }


    /**
     * @description Tests getExemptionNotes returns exception for null Id.
     */
    @IsTest
    static void getExemptionNotes_withNullExemption_throwsAuraHandledException() {
        Boolean exceptionThrown = false;
        try {
            PRSE_LAViewExemptionController.getExemptionNotes(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected AuraHandledException for null exemptionId');
    }


    /**
     * @description Tests getExemptionNotes returns wrong LA exception
     */
    @IsTest
    static void getExemptionNotes_withValidExemptionWrongLA_returnsNullNotes() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c WHERE Local_Custodian_Code__c = '360' LIMIT 1];
        Boolean exceptionThrown = false;

        System.runAs(laUser) {   
            try {
                String notes = PRSE_LAViewExemptionController.getExemptionNotes(ex.Id);
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }   
            System.assert(exceptionThrown, 'Expected AuraHandledException for invalid LA');
        }
    }


    /**
     * @description Tests saveExemptionNotes updates notes correctly for a valid exemption Id.
     */
    @IsTest
    static void saveExemptionNotes_withValidId_updatesNotes() {
        User laUser = getLaUser();

        Exemption__c ex = [
            SELECT Id, Local_Authority_Notes__c
            FROM Exemption__c
            WHERE LandlordFirstName__c = 'John2'
            LIMIT 1
        ];

        String newNotes = 'These are test notes';

        System.runAs(laUser) {
            Test.startTest();
            PRSE_LAViewExemptionController.saveExemptionNotes(ex.Id, newNotes);
            Test.stopTest();
        }

        Exemption__c updatedEx = [
            SELECT Local_Authority_Notes__c
            FROM Exemption__c
            WHERE Id = :ex.Id
        ];

        System.assertEquals(
            newNotes,
            updatedEx.Local_Authority_Notes__c,
            'Notes should be updated'
        );
    }


    /**
     * @description Tests saveExemptionNotes throws an AuraHandledException when exemption Id is null.
     */
    @IsTest
    static void saveExemptionNotes_withNullId_throwsException() {
        User laUser = getLaUser();
        Boolean exceptionThrown = false;

        System.runAs(laUser) {
            try {
                PRSE_LAViewExemptionController.saveExemptionNotes(null, 'Some notes');
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
        }

        System.assert(exceptionThrown, 'Expected AuraHandledException for null exemptionId');
    }


    /**
     * @description Tests saveExemptionNotes updates notes correctly for a valid exemption Id.
     */
    @IsTest
    static void saveExemptionNotes_withValidIdWrongLA_updatesNotes() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c WHERE Local_Custodian_Code__c = '360' LIMIT 1];
        Boolean exceptionThrown = false;

        String newNotes = 'These are test notes';

        System.runAs(laUser) {
            try {
                PRSE_LAViewExemptionController.saveExemptionNotes(ex.Id, newNotes);
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
            System.assert(exceptionThrown, 'Expected AuraHandledException for invalid LA');       
        }
    }


    /**
     * @description Test updateExemptionStatus successfully updates status
     */
    @IsTest
    static void testUpdateExemptionStatus_success() {
        Exemption__c ex = [SELECT Id, Status__c FROM Exemption__c where LandlordFirstName__c = 'John3' LIMIT 1];

        Test.startTest();
        PRSE_LAViewExemptionController.updateExemptionStatus(ex.Id, 'Approved');
        Test.stopTest();

        Exemption__c updatedEx = [SELECT Status__c FROM Exemption__c WHERE Id = :ex.Id];
        System.assertEquals('Approved', updatedEx.Status__c, 'Status should be updated to Approved');
    }


    /**
     * @description Test updateExemptionStatus throws exception if Id or status is null
     */
    @IsTest
    static void testUpdateExemptionStatus_nullThrowsException() {
        Boolean exceptionThrown = false;

        try {
            PRSE_LAViewExemptionController.updateExemptionStatus(null, 'Approved');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected AuraHandledException for null Id');

        exceptionThrown = false;

        // Test null status
        Exemption__c ex = [SELECT Id, Status__c FROM Exemption__c where LandlordFirstName__c = 'John3' LIMIT 1];
        try {
            PRSE_LAViewExemptionController.updateExemptionStatus(ex.Id, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected AuraHandledException for null status');
    }

    /**
     * @description Test getExemptionStatusOptions returns picklist values
     */
    @IsTest
    static void testGetExemptionStatusOptions_returnsValues() {
        Test.startTest();
        List<String> statuses = PRSE_LAViewExemptionController.getExemptionStatusOptions();
        Test.stopTest();

        System.assertNotEquals(0, statuses.size(), 'Expected at least one picklist value');
        System.assert(statuses.contains('Received') || statuses.contains('Approved'), 
            'Expected known status values in picklist');
    }
    
    
    /**
     * @description Test getExemptionEpcOrFile_withEpc_returnsEpc returns certificate
     */    
    @IsTest
	static void getExemptionEpcOrFile_withEpc_returnsEpc() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c where LandlordFirstName__c = 'John1' LIMIT 1];
		Test.setMock(HttpCalloutMock.class, new EpcOldApiNoResultsMock());
        System.runAs(laUser) {
            Test.startTest();
            PRSE_LAViewExemptionController.EpcLinkWrapper result =
                PRSE_LAViewExemptionController.getExemptionEpcOrFile(ex.Id,'123456789012','residential');
            Test.stopTest();
    
            System.assertEquals('certificate', result.sourceType);
            System.assert(result.url.contains('find-energy-certificate.service.gov.uk'));
            System.assertEquals(null, result.fileName);
        }
    }

    /**
     * @description Test getExemptionEpcOrFile_withEpcUpload_returnsEpc returns file upload link
     */      
     @IsTest
	static void getExemptionEpcOrFile_withEpcUpload_returnsEpc() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c where LandlordFirstName__c = 'John2' LIMIT 1];
		Test.setMock(HttpCalloutMock.class, new EpcOldApiNoResultsMock());
        System.runAs(laUser) {
            Test.startTest();
            PRSE_LAViewExemptionController.EpcLinkWrapper result =
                PRSE_LAViewExemptionController.getExemptionEpcOrFile(ex.Id,'123456789012','residential');
            Test.stopTest();
    
        System.assert(
            result.sourceType == 'file',
            'Expected sourceType to be file, got: ' + result.sourceType
        );
        System.assert(result.url.contains('/sfc/servlet.shepherd/document/download/'));
        System.assertEquals('EPC Certificate.pdf', result.fileName);
        }
    }   
    
    /**
     * @description Test getExemptionEpcOrFile_withNullId_returnsNone returns none    
     */
   /* @IsTest
    static void getExemptionEpcOrFile_withNullId_returnsNone() {    
            User laUser = getLaUser();
            Exemption__c ex = [SELECT Id FROM Exemption__c where LandlordFirstName__c = 'John3' LIMIT 1];   
        
        Test.startTest();
        PRSE_LAViewExemptionController.EpcLinkWrapper result =
            PRSE_LAViewExemptionController.getExemptionEpcOrFile(null,null,null);
        Test.stopTest();

        System.assertEquals('none', result.sourceType);
        System.assertEquals(null, result.url);  
    }  */
    
    /**
     * @description Test getExemptionEpcOrFile_exceptionHandling_throwsAuraHandledException returns exception    
     */
      @IsTest
    static void getExemptionEpcOrFile_exceptionHandling_throwsAuraHandledException() {
        Boolean exceptionThrown = false;

        // Use a fake Id (15-char string) that doesn't exist
        Id fakeId = '001000000000000'; // Account Id format, but no record exists

        Test.startTest();
        try {
            PRSE_LAViewExemptionController.getExemptionEpcOrFile(fakeId,null,null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown for invalid exemption Id');
    }  
    
    /**
     * @description Test getExemptionEpcOrFile returns none when no EPC or file exists
     */
    @IsTest
    static void getExemptionEpcOrFile_withNoEpcOrFile_returnsNone() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c WHERE LandlordFirstName__c = 'John3' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new EpcOldApiNoResultsMock());
        System.runAs(laUser) {
            Test.startTest();
            PRSE_LAViewExemptionController.EpcLinkWrapper result =
                PRSE_LAViewExemptionController.getExemptionEpcOrFile(ex.Id,'123456789012','residential');
            Test.stopTest();
    
            System.assert(
            	result.sourceType == 'none',
                'Expected sourceType to be none, got: ' + result.sourceType
        	);
            System.assertEquals(null, result.url, 'Expected url to be null');
            System.assertEquals(null, result.fileName, 'Expected fileName to be null');
        }
    }


    /**
     * @description Tests controller methods with null exemption Ids to cover exception branches.
     */
    @IsTest
    static void controllerMethods_withNullExemptionId_throwAuraHandledExceptions() {

        Boolean exceptionThrown;

        // getExemption null Id
        exceptionThrown = false;
        try {
            PRSE_LAViewExemptionController.getExemption(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown for getExemption with null Id');

        // getExemptionLandlordDetails null Id
        exceptionThrown = false;
        try {
            PRSE_LAViewExemptionController.getExemptionLandlordDetails(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown for getExemptionLandlordDetails with null Id');

        // getExemptionAgentDetails null Id
        exceptionThrown = false;
        try {
            PRSE_LAViewExemptionController.getExemptionAgentDetails(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown for getExemptionAgentDetails with null Id');

        // getExemptionDetails null Id
        exceptionThrown = false;
        try {
            PRSE_LAViewExemptionController.getExemptionDetails(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown for getExemptionDetails with null Id');

        // getExemptionEvidenceDocumentsGrouped null Id
        exceptionThrown = false;
        try {
            PRSE_LAViewExemptionController.getExemptionEvidenceDocumentsGrouped(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown for getExemptionEvidenceDocumentsGrouped with null Id');
    }

    /**
     * @description Tests that when the EPC API returns an error response,
     *              the controller sets errorResponse = true, url = null, and sourceType = 'none'.
     *              Uses John3 (no EPC_Certificate__c, no ContentDocumentLink) to ensure
     *              no fallback data interferes with the assertion.
     */
    @IsTest
    static void getExemptionEpcOrFile_withApiError_setsErrorResponseAndReturnsNone() {
        User laUser = getLaUser();
        Exemption__c ex = [SELECT Id FROM Exemption__c WHERE LandlordFirstName__c = 'John3' LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new EpcOldApiErrorMock());

        System.runAs(laUser) {
            Test.startTest();
            PRSE_LAViewExemptionController.EpcLinkWrapper result =
                PRSE_LAViewExemptionController.getExemptionEpcOrFile(ex.Id, '123456789012', 'residential');
            Test.stopTest();

            System.assertEquals(
                'none',
                result.sourceType,
                'Expected sourceType none when API returns an error response'
            );
            System.assertEquals(
                null,
                result.url,
                'Expected url to be null when API returns an error response'
            );
        }
    }
    /**
     * @description Tests getExemptionEpcOrFile returns 'api' sourceType when the new EPC API
     *              returns a valid, non-expired certificate number.
     *              Uses forceUseNewEndpointForTest to route through fetchEPCData_NEW,
     *              and mocks the HTTP callout with a valid non-expired registrationDate.
     */
    @IsTest
    static void getExemptionEpcOrFile_withNewApiCertificate_returnsApiSourceType() {
        User laUser = getLaUser();

        // John3 has no EPC_Certificate__c and no ContentDocumentLink attached,
        // so only the API response can reach the 'api' branch.
        Exemption__c ex = [
            SELECT Id
            FROM Exemption__c
            WHERE LandlordFirstName__c = 'John3'
            LIMIT 1
        ];

        // Force the new endpoint and mock its HTTP callout
        PRSE_RetrieveEPCInfoAction.forceUseNewEndpointForTest = true;
        Test.setMock(HttpCalloutMock.class, new EpcNewApiValidCertificateMock());

        System.runAs(laUser) {
            Test.startTest();
            PRSE_LAViewExemptionController.EpcLinkWrapper result =
                PRSE_LAViewExemptionController.getExemptionEpcOrFile(
                    ex.Id,
                    '123456789012',
                    'residential'
                );
            Test.stopTest();

            System.assertEquals(
                'api',
                result.sourceType,
                'Expected sourceType to be api when new EPC API returns a valid non-expired certificate'
            );
            System.assertNotEquals(
                null,
                result.url,
                'Expected a non-null URL when API certificate is returned'
            );
            System.assert(
                result.url.contains('find-energy-certificate.service.gov.uk/energy-certificate/'),
                'Expected URL to point to the find-energy-certificate service'
            );
            System.assert(
                result.url.contains('1111-2222-3333-4444-5555'),
                'Expected URL to contain the certificate number returned by the API'
            );
            System.assertEquals(
                null,
                result.fileName,
                'Expected fileName to be null for api sourceType'
            );
            System.assertEquals(
                null,
                result.contentDocumentId,
                'Expected contentDocumentId to be null for api sourceType'
            );
        }

        // Reset flag so other tests are unaffected
        PRSE_RetrieveEPCInfoAction.forceUseNewEndpointForTest = false;
    }

    /**
     * @description Mock returning a valid, non-expired EPC certificate
     *              matching the new endpoint JSON structure parsed by parseEPCResponse_NEW.
     *              'data' must be a direct array, and registrationDate must be within 10 years.
     */
    private class EpcNewApiValidCertificateMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // registrationDate 1 year ago — well within the 10-year expiry window
            String registrationDate = Date.today().addYears(-1).year() + '-' +
                String.valueOf(Date.today().addYears(-1).month()).leftPad(2, '0') + '-' +
                String.valueOf(Date.today().addYears(-1).day()).leftPad(2, '0');

            String body = '{"data":[{'
                + '"certificateNumber":"1111-2222-3333-4444-5555",'
                + '"addressLine1":"Flat 2",'
                + '"addressLine2":"Some Street",'
                + '"addressLine3":null,'
                + '"addressLine4":null,'
                + '"postcode":"M20 4AP",'
                + '"postTown":"MANCHESTER",'
                + '"council":"Manchester",'
                + '"constituency":"Manchester Rusholme",'
                + '"currentEnergyEfficiencyBand":"D",'
                + '"registrationDate":"' + registrationDate + '",'
                + '"uprn":10094703381'
                + '}],'
                + '"pagination":{'
                + '"totalRecords":1,'
                + '"currentPage":1,'
                + '"totalPages":1,'
                + '"nextPage":null,'
                + '"prevPage":null,'
                + '"pageSize":5000'
                + '}}';

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody(body);
            return res;
        }
    }
    /**
     * @description Mock returning a 200 with empty rows so the OLD EPC endpoint
     *              produces a response with null certificateNumber, allowing the
     *              controller to fall through to EPC_Certificate__c / file / none branches.
     */
    private class EpcOldApiNoResultsMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"rows":[],"totalResults":0}');
            return res;
        }
    }
    
    /**
     * @description Mock returning a non-200 status to trigger the 'Error' address
     *              branch in fetchEPCData_OLD, causing the controller to set errorResponse = true
     *              and sourceType = 'none'.
     */
    private class EpcOldApiErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

}