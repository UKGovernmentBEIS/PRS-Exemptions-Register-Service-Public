@IsTest
private class PRSE_PersonAccountSearchControllerTest {

    @testSetup
    static void setupPersonAccounts() {

        Id personRtId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsPersonType = TRUE
            LIMIT 1
        ].Id;

        List<Account> accounts = new List<Account>{
            new Account(
                RecordTypeId = personRtId,
                FirstName = 'MatchFirst',
                LastName = 'Test',
                PersonEmail = 'first@test.com',
                Phone = '07111111111',
                BusinessName__c = 'BusinessA'
            ),
            new Account(
                RecordTypeId = personRtId,
                FirstName = 'John',
                LastName = 'MatchLast',
                PersonEmail = 'last@test.com',
                Phone = '07222222222',
                BusinessName__c = 'BusinessB'
            ),
            new Account(
                RecordTypeId = personRtId,
                FirstName = 'Jane',
                LastName = 'Email',
                PersonEmail = 'match@email.com',
                Phone = '07333333333',
                BusinessName__c = 'BusinessC'
            ),
            new Account(
                RecordTypeId = personRtId,
                FirstName = 'Tom',
                LastName = 'Phone',
                PersonEmail = 'phone@test.com',
                Phone = '07444444444',
                BusinessName__c = 'BusinessD'
            ),
            new Account(
                RecordTypeId = personRtId,
                FirstName = 'Anna',
                LastName = 'Business',
                PersonEmail = 'business@test.com',
                Phone = '07555555555',
                BusinessName__c = 'MatchBusiness'
            )
        };

        insert accounts;
    }

    @IsTest
    static void searchPersonAccounts_blankSearchKey_returnsEmptyList() {

        Test.startTest();
        List<Account> results = PRSE_PersonAccountSearchController.searchPersonAccounts('');
        Test.stopTest();

        System.assertEquals(0, results.size());
    }

    @IsTest
    static void searchPersonAccounts_shortSearchKey_returnsEmptyList() {

        Test.startTest();
        List<Account> results = PRSE_PersonAccountSearchController.searchPersonAccounts('abc');
        Test.stopTest();

        System.assertEquals(0, results.size());
    }

    @IsTest
    static void searchPersonAccounts_searchByFirstName_returnsMatchingAccount() {

        Test.startTest();
        List<Account> results = PRSE_PersonAccountSearchController.searchPersonAccounts('MatchFirst');
        Test.stopTest();

        System.assert(results.size() > 0);
        System.assertEquals('MatchFirst', results[0].FirstName);
    }

    @IsTest
    static void searchPersonAccounts_searchByLastName_returnsMatchingAccount() {

        Test.startTest();
        List<Account> results = PRSE_PersonAccountSearchController.searchPersonAccounts('MatchLast');
        Test.stopTest();

        System.assert(results.size() > 0);
        System.assertEquals('MatchLast', results[0].LastName);
    }

    @IsTest
    static void searchPersonAccounts_searchByEmail_returnsMatchingAccount() {

        Test.startTest();
        List<Account> results = PRSE_PersonAccountSearchController.searchPersonAccounts('match@email');
        Test.stopTest();

        System.assert(results.size() > 0);
        System.assertEquals('match@email.com', results[0].PersonEmail);
    }

    @IsTest
    static void searchPersonAccounts_searchByPhone_returnsMatchingAccount() {

        Test.startTest();
        List<Account> results = PRSE_PersonAccountSearchController.searchPersonAccounts('074444');
        Test.stopTest();

        System.assert(results.size() > 0);
        System.assertEquals('07444444444', results[0].Phone);
    }

    @IsTest
    static void searchPersonAccounts_searchByBusinessName_returnsMatchingAccount() {

        Test.startTest();
        List<Account> results = PRSE_PersonAccountSearchController.searchPersonAccounts('MatchBusiness');
        Test.stopTest();

        System.assert(results.size() > 0);
        System.assertEquals('MatchBusiness', results[0].BusinessName__c);
    }
}