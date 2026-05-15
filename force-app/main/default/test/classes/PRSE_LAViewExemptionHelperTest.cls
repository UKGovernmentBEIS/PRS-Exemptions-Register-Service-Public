/**
 * @class PRSE_LAViewExemptionHelper_Test
 * @description
 * This test class verifies the behavior of the PRSE_LAViewExemptionHelper utility class.
 * It sets up test data including Person Accounts, Users, Local Authority Accounts,
 * AccountContactRelation links, Exemption__c records, and Exemption_Type_Link__c child records.
 *
 * @note All test methods run in an isolated context with @IsTest and @TestSetup annotations.
 */
@IsTest
private class PRSE_LAViewExemptionHelperTest {

    /**
     * @description
     * Sets up all necessary test data for the class.
     * Creates:
     *   - Person Accounts for a Local Authority user and a Landlord user.
     *   - Community / Portal Users linked to the Person Accounts.
     *   - Local Authority Account and AccountContactRelation linking the user to it.
     *   - Agent Account.
     *   - Exemption__c records and Exemption_Type__c / Exemption_Type_Link__c child records.
     *
     * @note
     * Data created here is available to all test methods and runs in a single transaction.
     */
    @TestSetup
    static void setupData() {
        // Query Person Account RecordType
        RecordType personRt = [SELECT Id, Name 
                               FROM RecordType 
                               WHERE SObjectType = 'Account' 
                                 AND IsPersonType = true
                               LIMIT 1];

        // Create Person Account for Local Authority User
        Account laPersonAcc = new Account(
            FirstName = 'John',
            LastName = 'LABod',
            RecordTypeId = personRt.Id
        );
        insert laPersonAcc;

        Account lalinkedAccount = [SELECT Id, PersonContactId, Landlord_Type__c, BusinessName__c 
                                   FROM Account 
                                   WHERE Id = :laPersonAcc.Id 
                                   LIMIT 1];

        // Query Profile for Local Authority Community User
        Profile laPortalProfile = [SELECT Id 
                                   FROM Profile 
                                   WHERE Name='DEZNZ_PRS_Local Authority Customer Community Plus Login User' 
                                   LIMIT 1];

        // Create Local Authority User
        User laUser = new User(
            Username = 'localAuthorityUser@test.com',
            LastName = 'User',
            Email = 'test@test.com',
            Alias = 'tusr',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = laPortalProfile.Id,
            ContactId = lalinkedAccount.PersonContactId
        );
        insert laUser;

        // Query Local Authority RecordType
        RecordType laRT = [SELECT Id
                           FROM RecordType
                           WHERE SObjectType = 'Account'
                             AND Name = 'Local Authority'
                           LIMIT 1];

        // Create Local Authority Account
        Account la = new Account(
            Name = 'Test Local Authority',
            RecordTypeId = laRT.Id,
            Local_Custodian_Code__c = '1950'
        );
        insert la;

        // Link Local Authority User to Account
        AccountContactRelation acr = new AccountContactRelation(
            AccountId = la.Id,
            ContactId = lalinkedAccount.PersonContactId
        );
        insert acr;      

        // Create Person Account for Landlord User
        Account landlordPersonAcc = new Account(
            FirstName = 'John',
            LastName = 'Landlord',
            RecordTypeId = personRt.Id, 
            Landlord_Type__c = 'Individual',
            BusinessName__c = 'Landlord Ltd'
        );
        insert landlordPersonAcc;

        Account linkedAccount = [SELECT Id, PersonContactId, Landlord_Type__c, BusinessName__c 
                                 FROM Account 
                                 WHERE Id = :landlordPersonAcc.Id 
                                 LIMIT 1];

        // Query Profile for Landlord Community User
        Profile portalProfile = [SELECT Id 
                                 FROM Profile 
                                 WHERE Name='DEZNZ_PRS_Landlord Customer Community Plus Login User' 
                                 LIMIT 1];

        // Create Landlord User linked to Person Account
        User landlordUser = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = portalProfile.Id,
            TimeZoneSidKey = 'Europe/London',
            UserName = 'landlordUser@example.com',
            ContactId = linkedAccount.PersonContactId
        );
        insert landlordUser;

        // Create Exemption record linked to Landlord User
        Exemption__c ex = new Exemption__c(
            Account__c = landlordPersonAcc.Id,
            LandlordFirstName__c = 'John1',
            LandlordLastName__c = 'Doe',
            LandlordBusinessName__c = 'JD Rentals',
            LandlordAddress__c = '123 Main Street',
            LandlordPhone__c = '0123456789',
            LandlordEmail__c = 'jd@example.com',
            OwnerId = landlordUser.Id,
            Local_Custodian_Code__c = '1950'
        );
        insert ex;

        // Create Exemption Type record
        Exemption_Type__c exType = new Exemption_Type__c(
            Name = 'Test Type',
            Code__c = '01'
        );
        insert exType;

        // Link Exemption to Exemption Type
        Exemption_Type_Link__c link = new Exemption_Type_Link__c(
            Exemption__c = ex.Id,
            Exemption_Type__c = exType.Id
        );
        insert link;

        // Create another Exemption record for negative test
        Exemption__c ex350 = new Exemption__c(
            Account__c = landlordPersonAcc.Id,
            LandlordFirstName__c = 'John1',
            LandlordLastName__c = 'Doe',
            LandlordBusinessName__c = 'JD Rentals',
            LandlordAddress__c = '123 Main Street',
            LandlordPhone__c = '0123456789',
            LandlordEmail__c = 'jd@example.com',
            OwnerId = landlordUser.Id,
            Local_Custodian_Code__c = '350'
        );
        insert ex350;

        // Link second Exemption to Exemption Type
        Exemption_Type_Link__c link2 = new Exemption_Type_Link__c(
            Exemption__c = ex350.Id,
            Exemption_Type__c = exType.Id
        );
        insert link2;

        Penalty_Type__c parentPenaltyType = new Penalty_Type__c();
        parentPenaltyType.Name = 'Test Penalty Type';
        parentPenaltyType.Code__c = 'P009';
        insert parentPenaltyType;

        // Create Penalty record linked to Landlord User
        Penalty__c linkedPenalty = new Penalty__c(
            Penalty_Reference__c = 'Penalty 1',
            Penalty_Type__c = parentPenaltyType.Id,
            Issued_Date__c = Date.today(),
            Local_Custodian_Code__c = '1950'
        );

        // Create another Penalty record for negative test
        Penalty__c unlinkedPenalty = new Penalty__c(
            Penalty_Reference__c = 'Penalty 2',
            Penalty_Type__c = parentPenaltyType.Id,
            Issued_Date__c = Date.today(),
            Local_Custodian_Code__c = '350'
        );
        insert new List<Penalty__c>{ linkedPenalty, unlinkedPenalty };
    }

    /**
     * @testMethod
     * @description
     * Verifies that checkExemption returns true when the exemption's
     * Local_Custodian_Code__c matches a Local Authority linked to the user.
     */
    @IsTest
    static void testCheckExemption_ReturnsTrue() {
        User laUser = [SELECT Id FROM User WHERE Username = 'localAuthorityUser@test.com' LIMIT 1];

        System.runAs(laUser) {
            Exemption__c ex = [SELECT Id FROM Exemption__c WHERE Local_Custodian_Code__c = '1950' LIMIT 1];

            Boolean result = PRSE_LAViewExemptionHelper.checkExemption(ex.Id);
            System.assertEquals(true, result, 'Exemption should belong to the user’s Local Authorities');
        }
    }

    /**
     * @testMethod
     * @description
     * Verifies that checkExemption returns false when the exemption's
     * Local_Custodian_Code__c does not match any Local Authority linked to the user.
     */
    @IsTest
    static void testCheckExemption_ReturnsFalse() {
        User laUser = [SELECT Id FROM User WHERE Username = 'localAuthorityUser@test.com' LIMIT 1];

        System.runAs(laUser) {
            Exemption__c ex = [SELECT Id FROM Exemption__c WHERE Local_Custodian_Code__c = '350' LIMIT 1];

            Boolean result = PRSE_LAViewExemptionHelper.checkExemption(ex.Id);
            System.assertEquals(false, result, 'Should return false when no matching Local Authority exists');
        }
    }

    @IsTest
    static void checkPenalty_withSameLocalAuthorityAsUser_returnsTrue() {
        User laUser = [SELECT Id FROM User WHERE Username = 'localAuthorityUser@test.com' LIMIT 1];

        System.runAs(laUser) {
            Penalty__c penalty = [SELECT Id FROM Penalty__c WHERE Local_Custodian_Code__c = '1950' LIMIT 1];

            Boolean result = PRSE_LAViewExemptionHelper.checkPenalty(penalty.Id);
            System.assertEquals(true, result, 'Penalty should belong to the user’s Local Authorities');
        }
    }

    @IsTest
    static void checkPenalty_withoutSameLocalAuthorityAsUser_returnsFalse() {
        User laUser = [SELECT Id FROM User WHERE Username = 'localAuthorityUser@test.com' LIMIT 1];

        System.runAs(laUser) {
            Penalty__c penalty = [SELECT Id FROM Penalty__c WHERE Local_Custodian_Code__c = '350' LIMIT 1];

            Boolean result = PRSE_LAViewExemptionHelper.checkPenalty(penalty.Id);
            System.assertEquals(false, result, 'Should return false when no matching Local Authority exists');
        }
    }
}
