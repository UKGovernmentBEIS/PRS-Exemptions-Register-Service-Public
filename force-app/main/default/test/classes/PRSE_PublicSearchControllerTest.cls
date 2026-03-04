/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@IsTest
private class PRSE_PublicSearchControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create Account / Landlord records
        Account landlord1 = new Account(Name = 'Landlord One');
        insert landlord1;

        Account landlord2 = new Account(Name = 'Landlord Two');
        insert landlord2;

        Account landlord3 = new Account(Name = 'Landlord Three');
        insert landlord3;

        // Create Exemption Types
        Exemption_Type__c exType1 = new Exemption_Type__c(Name='Type A', IsCommercial__c=false);
        Exemption_Type__c exType2 = new Exemption_Type__c(Name='Type B', IsCommercial__c=true);
        Exemption_Type__c exType3 = new Exemption_Type__c(Name='Type C', IsCommercial__c=false);
        insert new List<Exemption_Type__c>{exType1, exType2,exType3};

        // Create Exemptions (remove Name, formula fields)
        Exemption__c ex1 = new Exemption__c(
            Account__c=landlord1.Id,
            Status__c='Approved',
            PropertyPostcode__c='AB1 2CD',
            LandlordBusinessName__c='Landlord One',
            Registered_Date__c=Date.today(),
            PropertyAddress__c='123 Main St'
        );
        Exemption__c ex2 = new Exemption__c(
            Account__c=landlord2.Id,
            Status__c='Approved',
            PropertyPostcode__c='AB1 2CD',
            LandlordBusinessName__c='Landlord Two',
            Registered_Date__c=Date.today(),
            PropertyAddress__c='124 Main St'
        );
        Exemption__c ex3 = new Exemption__c(
            Account__c=landlord3.Id,
            Status__c='Approved',
            PropertyPostcode__c='AB1 2CD',
            LandlordBusinessName__c='Landlord Three',
            Registered_Date__c=Date.today(),
            PropertyAddress__c='125 Main St'
        );
        insert new List<Exemption__c>{ex1, ex2, ex3};

        // Create Exemption_Type_Links (only set writeable fields)
        Exemption_Type_Link__c link1 = new Exemption_Type_Link__c(
            Exemption__c = ex1.Id,
            Exemption_Type__c = exType1.Id
        );
        Exemption_Type_Link__c link2 = new Exemption_Type_Link__c(
            Exemption__c = ex2.Id,
            Exemption_Type__c = exType2.Id
        );
        Exemption_Type_Link__c link3 = new Exemption_Type_Link__c(
            Exemption__c = ex3.Id,
            Exemption_Type__c = exType3.Id
        );
        insert new List<Exemption_Type_Link__c>{link1, link2, link3};

        // Create Penalty Types
        Penalty_Type__c pt1 = new Penalty_Type__c(Code__c='P001', Name='Penalty Type 1');
        Penalty_Type__c pt2 = new Penalty_Type__c(Code__c='P002', Name='Penalty Type 2');
        Penalty_Type__c pt3 = new Penalty_Type__c(Code__c='P003', Name='Penalty Type 3');
        insert new List<Penalty_Type__c>{pt1, pt2, pt3};

        // Create Penalties
        Penalty__c p1 = new Penalty__c(
            Exemption__c = ex1.Id,
            Penalty_Type__c = pt1.Id,
            Published__c = true,           
            PropertyAddress__c = '123 Main St'
        );
        Penalty__c p2 = new Penalty__c(
            Exemption__c = ex2.Id,
            Penalty_Type__c = pt2.Id,
            Published__c = true,
            PropertyAddress__c = '124 Main St'
        );
        Penalty__c p3 = new Penalty__c(
            Exemption__c = ex3.Id,
            Penalty_Type__c = pt3.Id,
            Published__c = false,
            PropertyAddress__c = '125 Main St'
        );        
        insert new List<Penalty__c>{p1, p2, p3};
    }


    @IsTest
    static void searchPropertyExemptionsPaginated_withPageSizeAndNumber_returnsPaginatedResults() {
        PRSE_PublicSearchController.PaginatedExemptionResult result =
            PRSE_PublicSearchController.searchPropertyExemptionsPaginated('AB12CD', 1, 1);
        System.assertEquals(1, result.records.size());
        System.assertEquals(3, result.totalRecords);
        System.assertEquals(1, result.pageNumber);
        System.assertEquals(1, result.pageSize);
    }


    @IsTest
    static void searchPropertyExemptionsOtherWaysPaginated_withPropertyAddress_returnsFilteredResults() {
        PRSE_PublicSearchController.PaginatedExemptionResult result =
            PRSE_PublicSearchController.searchPropertyExemptionsOtherWaysPaginated(
                '123 Main St', null, null, null, null, 10, 1);
        System.assertEquals(1, result.records.size());
    }
        

    @IsTest
    static void searchPropertyExemptionsOtherWaysPaginated_withNoSearchCriteria_throwsAuraHandledException() {
        Boolean exceptionThrown = false;
        try {
            PRSE_PublicSearchController.searchPropertyExemptionsOtherWaysPaginated(null, null, null, null, null, 10, 1);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected AuraHandledException when no search criteria provided');
    }


    @IsTest
    static void searchPropertyPenaltiesPaginated_withPageSizeAndNumber_returnsPaginatedResults() {
        PRSE_PublicSearchController.PaginatedPenaltyResult result =
            PRSE_PublicSearchController.searchPropertyPenaltiesPaginated('AB12CD', 1, 2);
        System.assertEquals(1, result.records.size());
        System.assertEquals(2, result.totalRecords);
        System.assertEquals(2, result.pageNumber);
        System.assertEquals(1, result.pageSize);
    }


    @IsTest
    static void searchPropertyPenaltiesOtherWaysPaginated_withPropertyAddress_returnsPaginatedResults() {
        PRSE_PublicSearchController.PaginatedPenaltyResult result =
            PRSE_PublicSearchController.searchPropertyPenaltiesOtherWaysPaginated('123 Main St', null, null, null, null, 1, 1);
        System.assertEquals(1, result.records.size());
        System.assertEquals(1, result.totalRecords);
        System.assertEquals(1, result.pageNumber);
        System.assertEquals(1, result.pageSize);
    }

    @IsTest
    static void searchPropertyPenaltiesOtherWaysPaginated_withNoSearchCriteria_throwsAuraHandledException() {
        Boolean exceptionThrown = false;
        try {
            PRSE_PublicSearchController.searchPropertyPenaltiesOtherWaysPaginated(null, null, null, null, null, 10, 1);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected AuraHandledException when no search criteria provided');
    }    


    @IsTest
    static void getExemptionTypes_returnsAllExemptionTypes() {
        List<Exemption_Type__c> types = PRSE_PublicSearchController.getExemptionTypes();
        System.assertEquals(3, types.size());
    }

    @IsTest
        static void getPenaltyTypes_returnsAllPenaltyTypes() {
            List<Penalty_Type__c> types = PRSE_PublicSearchController.getPenaltyTypes();
            System.assertEquals(3, types.size());
        }


    @IsTest
    static void searchPropertyExemptionsPaginated_withBlankPostcode_throwsAuraHandledException() {
        Boolean exceptionThrown = false;
        try {
            PRSE_PublicSearchController.searchPropertyExemptionsPaginated('', 10, 1);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected AuraHandledException for blank postcode');
    }


    @IsTest
    static void searchPropertyPenaltiesPaginated_withNullPostcode_throwsAuraHandledException() {
        Boolean exceptionThrown = false;
        try {
            PRSE_PublicSearchController.searchPropertyPenaltiesPaginated(null, 10, 1);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected AuraHandledException for null postcode');
    }


    @IsTest
    static void searchPropertyPenaltiesOtherWaysPaginated_withNoMatchingRecords_returnsEmptyResult() {
        // Call with filter values that are not present in the org
        PRSE_PublicSearchController.PaginatedPenaltyResult result;
        try {
            result = PRSE_PublicSearchController.searchPropertyPenaltiesOtherWaysPaginated(
                'NonExistentAddress', // propertyAddress
                'NonExistentTown',    // townOrCity
                'NonExistentLandlord',// landlordsName
                'NonExistentType',    // propertyType
                'NonExistentExemption',// exemptionType
                10,                   // pageSize
                1                     // pageNumber
            );
        } catch (AuraHandledException e) {
            System.assert(false, 'Did not expect AuraHandledException to be thrown');
        }

        // Assert that the returned object is not null
        System.assertNotEquals(null, result, 'Expected a PaginatedPenaltyResult object');

        // Assert that totalRecords = 0 and records list is empty
        System.assertEquals(0, result.totalRecords, 'Expected totalRecords to be 0 when no matching records exist');
        System.assertEquals(0, result.records.size(), 'Expected records list to be empty when no matching records exist');

        // Assert pagination properties are set correctly
        System.assertEquals(10, result.pageSize, 'Expected pageSize to match input');
        System.assertEquals(1, result.pageNumber, 'Expected pageNumber to match input');
    }


    @IsTest
    static void searchPropertyExemptionsOtherWaysPaginated_withNoMatchingRecords_returnsEmptyResult() {
        PRSE_PublicSearchController.PaginatedExemptionResult result;
        try {
            result = PRSE_PublicSearchController.searchPropertyExemptionsOtherWaysPaginated(
                'NonExistentAddress', // propertyAddress
                'NonExistentTown',    // townOrCity
                'NonExistentLandlord',// landlordsName
                'NonExistentType',    // propertyType
                'NonExistentExemption',// exemptionType
                10,                   // pageSize
                1                     // pageNumber
            );
        } catch (AuraHandledException e) {
            System.assert(false, 'Did not expect AuraHandledException to be thrown');
        }

        // Assert that the returned object is not null
        System.assertNotEquals(null, result, 'Expected a PaginatedExemptionResult object');

        // Assert that totalRecords = 0 and records list is empty
        System.assertEquals(0, result.totalRecords, 'Expected totalRecords to be 0 when no matching records exist');
        System.assertEquals(0, result.records.size(), 'Expected records list to be empty when no matching records exist');

        // Assert pagination properties are set correctly
        System.assertEquals(10, result.pageSize, 'Expected pageSize to match input');
        System.assertEquals(1, result.pageNumber, 'Expected pageNumber to match input');
    }

    @isTest
    static void sanitizeForLike_withNullInput_returnsNull() {
        String result = PRSE_PublicSearchController.sanitizeForLike(null);
        System.assertEquals(null, result, 'Null input should return null');
    }
    
    @isTest
    static void sanitizeForLike_withEmptyString_returnsEmptyString() {
        String result = PRSE_PublicSearchController.sanitizeForLike('');
        System.assertEquals('', result, 'Empty string should return empty string');
    }
    
    @isTest
    static void sanitizeForLike_withBlankString_returnsBlankString() {
        String result = PRSE_PublicSearchController.sanitizeForLike('   ');
        System.assertEquals('   ', result, 'Blank string should return as-is');
    }
    
    @isTest
    static void sanitizeForLike_withNormalString_returnsUnchangedString() {
        String result = PRSE_PublicSearchController.sanitizeForLike('Test String');
        System.assertEquals('Test String', result, 'Normal string should remain unchanged');
    }
    
    @isTest
    static void sanitizeForLike_withSingleQuote_returnsEscapedQuote() {
        String result = PRSE_PublicSearchController.sanitizeForLike('O\'Brien');
        System.assertEquals('O\\\\\'Brien', result, 'Single quotes should be escaped');
    }

    @isTest
    static void sanitizeForLike_withBackslash_returnsDoubledBackslash() {
        String result = PRSE_PublicSearchController.sanitizeForLike('C:\\Users');
        System.assertEquals('C:\\\\\\\\Users', result, 'Backslashes should be doubled');
    }
    
    @isTest
    static void sanitizeForLike_withPercent_returnsEscapedPercent() {
        String result = PRSE_PublicSearchController.sanitizeForLike('100% Complete');
        System.assertEquals('100\\% Complete', result, 'Percent signs should be escaped');
    }
    
    @isTest
    static void sanitizeForLike_withUnderscore_returnsEscapedUnderscore() {
        String result = PRSE_PublicSearchController.sanitizeForLike('first_name');
        System.assertEquals('first\\_name', result, 'Underscores should be escaped');
    }
    
    @isTest
    static void sanitizeForLike_withAllSpecialCharacters_returnsAllEscaped() {
        String result = PRSE_PublicSearchController.sanitizeForLike('O\'Brien: 100%_complete\\test');
        System.assertEquals('O\\\\\'Brien: 100\\%\\_complete\\\\\\\\test', result, 
            'All special characters should be properly escaped');
    }
    
    @isTest
    static void sanitizeForLike_withMultiplePercents_returnsAllPercentsEscaped() {
        String result = PRSE_PublicSearchController.sanitizeForLike('%%test%%');
        System.assertEquals('\\%\\%test\\%\\%', result, 'Multiple percents should all be escaped');
    }
    
    @isTest
    static void sanitizeForLike_withMultipleUnderscores_returnsAllUnderscoresEscaped() {
        String result = PRSE_PublicSearchController.sanitizeForLike('__test__');
        System.assertEquals('\\_\\_test\\_\\_', result, 'Multiple underscores should all be escaped');
    }


    @IsTest
    static void searchExemptions_withNumericAddresses_returnsSortedByAscendingNumber() {
    
        // Create landlord account
        Account landlord = new Account(Name = 'Landlord One');
        insert landlord;
    
        Exemption__c ex1 = new Exemption__c(
    
            Status__c = 'Received',
            Account__c = landlord.Id,
            PropertyAddress__c = '1 kruger avenue',
            PropertyCity__c = 'Kingston',
            PropertyPostcode__c = 'KN1 1AA',
            PropertyType__c = 'Residential'
        );
    
        Exemption__c ex2 = new Exemption__c(
            Status__c = 'Received',
            Account__c = landlord.Id,
            PropertyAddress__c = '3 high street',
            PropertyCity__c = 'Hull',
            PropertyPostcode__c = 'HU3 3CC',
            PropertyType__c = 'Residential'
        );
    
        Exemption__c ex3 = new Exemption__c(
            Status__c = 'Received',
            Account__c = landlord.Id,
            PropertyAddress__c = '5 alpha street',
            PropertyCity__c = 'Aberdeen',
            PropertyPostcode__c = 'AB5 5EE',
            PropertyType__c = 'Residential'
        );
    
        Exemption__c ex4 = new Exemption__c(
            Status__c = 'Received',
            Account__c = landlord.Id,
            PropertyAddress__c = 'a house name',
            PropertyCity__c = 'Aberdeen',
            PropertyPostcode__c = 'AB1 1AA',
            PropertyType__c = 'Residential'
        );
    
        Exemption__c ex5 = new Exemption__c(
            Status__c = 'Received',
            Account__c = landlord.Id,
            PropertyAddress__c = 'Zoological Society',
            PropertyCity__c = 'Aberdeen',
            PropertyPostcode__c = 'AB4 4DD',
            PropertyType__c = 'Residential'
        );
    
        // Insert intentionally unordered
        insert new List<Exemption__c>{ ex5, ex3, ex1, ex4, ex2 };

        Test.startTest();
    
        PRSE_PublicSearchController.PaginatedExemptionResult result =
            PRSE_PublicSearchController.searchPropertyExemptionsOtherWaysPaginated(
                null,
                null,
                null,
                'Residential',
                null,
                10,
                1
            );

        Test.stopTest();
    
        System.assertEquals(5, result.records.size());
        System.assertEquals(5, result.totalRecords);
    
        // Numeric addresses first
        System.assertEquals(
            '1 kruger avenue, Kingston, KN1 1AA',
            result.records[0].Full_Property_Address__c
        );
        System.assertEquals(
            '3 high street, Hull, HU3 3CC',
            result.records[1].Full_Property_Address__c
        );
        System.assertEquals(
            '5 alpha street, Aberdeen, AB5 5EE',
            result.records[2].Full_Property_Address__c
        );
    
        // Then alphabetical (no leading number)
        System.assertEquals(
            'a house name, Aberdeen, AB1 1AA',
            result.records[3].Full_Property_Address__c
        );
        System.assertEquals(
            'Zoological Society, Aberdeen, AB4 4DD',
            result.records[4].Full_Property_Address__c
        );
    }
    
    @IsTest
    static void PropertyWrapper_withUnknownSObject_setsAddressToEmpty() {
        
        // Create a generic SObject (not Exemption__c or Penalty__c)
        Account acct = new Account(Name = 'Random Account');
        insert acct;
    
        // Construct PropertyWrapper with this SObject
        PRSE_PublicSearchController.PropertyWrapper wrapper =
            new PRSE_PublicSearchController.PropertyWrapper(acct);
    
        // Assert that address is set to empty string
        System.assertEquals('', wrapper.address, 'Address should be empty for unknown SObject types');
    
        // Also assert that the record field is assigned
        System.assertEquals(acct.Id, ((Account)wrapper.record).Id, 'Record field should hold original SObject');
    }
    
}