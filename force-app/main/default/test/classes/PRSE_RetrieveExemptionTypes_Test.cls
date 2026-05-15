@IsTest
private class PRSE_RetrieveExemptionTypes_Test {        

    @TestSetup
    static void makeData() {
        List<String> codes = new List<String>{
            'D01','D02','D03','D04','D05','D06',
            'ND01','ND02','ND03','ND04','ND05','ND06'
        };

        List<Exemption_Type__c> records = new List<Exemption_Type__c>();
        for (String code : codes) {
            records.add(new Exemption_Type__c(
                Name                     = code + '_Name',
                Code__c                  = code,
                RequiredEvidence__c      = code + '_Evidence',
                AdditionalInformation__c = code + '_Additional'
            ));
        }
        insert records;
    }


    @IsTest
    static void testGetExemptionTypeData_AllRecords() {
        Test.startTest();
        List<PRSE_RetrieveExemptionTypes.ExemptionTypeData> resultList =
            PRSE_RetrieveExemptionTypes.getExemptionTypeData();
        Test.stopTest();

        System.assertEquals(1, resultList.size(), 'Should return exactly one result wrapper');

        PRSE_RetrieveExemptionTypes.ExemptionTypeData result = resultList[0];

        System.assertEquals('D01_Name',  result.D01_Name,  'D01 name mismatch');
        System.assertEquals('D02_Name',  result.D02_Name,  'D02 name mismatch');
        System.assertEquals('D03_Name',  result.D03_Name,  'D03 name mismatch');
        System.assertEquals('D04_Name',  result.D04_Name,  'D04 name mismatch');
        System.assertEquals('D05_Name',  result.D05_Name,  'D05 name mismatch');
        System.assertEquals('D06_Name',  result.D06_Name,  'D06 name mismatch');
        System.assertEquals('ND01_Name', result.ND01_Name, 'ND01 name mismatch');
        System.assertEquals('ND02_Name', result.ND02_Name, 'ND02 name mismatch');
        System.assertEquals('ND03_Name', result.ND03_Name, 'ND03 name mismatch');
        System.assertEquals('ND04_Name', result.ND04_Name, 'ND04 name mismatch');
        System.assertEquals('ND05_Name', result.ND05_Name, 'ND05 name mismatch');
        System.assertEquals('ND06_Name', result.ND06_Name, 'ND06 name mismatch');

        System.assertEquals('D01_Evidence',  result.D01_RequiredEvidence,  'D01 evidence mismatch');
        System.assertEquals('D02_Evidence',  result.D02_RequiredEvidence,  'D02 evidence mismatch');
        System.assertEquals('D03_Evidence',  result.D03_RequiredEvidence,  'D03 evidence mismatch');
        System.assertEquals('D04_Evidence',  result.D04_RequiredEvidence,  'D04 evidence mismatch');
        System.assertEquals('D05_Evidence',  result.D05_RequiredEvidence,  'D05 evidence mismatch');
        System.assertEquals('D06_Evidence',  result.D06_RequiredEvidence,  'D06 evidence mismatch');
        System.assertEquals('ND01_Evidence', result.ND01_RequiredEvidence, 'ND01 evidence mismatch');
        System.assertEquals('ND02_Evidence', result.ND02_RequiredEvidence, 'ND02 evidence mismatch');
        System.assertEquals('ND03_Evidence', result.ND03_RequiredEvidence, 'ND03 evidence mismatch');
        System.assertEquals('ND04_Evidence', result.ND04_RequiredEvidence, 'ND04 evidence mismatch');
        System.assertEquals('ND05_Evidence', result.ND05_RequiredEvidence, 'ND05 evidence mismatch');
        System.assertEquals('ND06_Evidence', result.ND06_RequiredEvidence, 'ND06 evidence mismatch');

        System.assertEquals('D01_Additional',  result.D01_AdditionalInformation,  'D01 additional mismatch');
        System.assertEquals('D02_Additional',  result.D02_AdditionalInformation,  'D02 additional mismatch');
        System.assertEquals('D03_Additional',  result.D03_AdditionalInformation,  'D03 additional mismatch');
        System.assertEquals('D04_Additional',  result.D04_AdditionalInformation,  'D04 additional mismatch');
        System.assertEquals('D05_Additional',  result.D05_AdditionalInformation,  'D05 additional mismatch');
        System.assertEquals('D06_Additional',  result.D06_AdditionalInformation,  'D06 additional mismatch');
        System.assertEquals('ND01_Additional', result.ND01_AdditionalInformation, 'ND01 additional mismatch');
        System.assertEquals('ND02_Additional', result.ND02_AdditionalInformation, 'ND02 additional mismatch');
        System.assertEquals('ND03_Additional', result.ND03_AdditionalInformation, 'ND03 additional mismatch');
        System.assertEquals('ND04_Additional', result.ND04_AdditionalInformation, 'ND04 additional mismatch');
        System.assertEquals('ND05_Additional', result.ND05_AdditionalInformation, 'ND05 additional mismatch');
        System.assertEquals('ND06_Additional', result.ND06_AdditionalInformation, 'ND06 additional mismatch');
    }


    @IsTest
    static void testGetExemptionTypeData_NoRecords() {
        delete [SELECT Id FROM Exemption_Type__c];

        Test.startTest();
        List<PRSE_RetrieveExemptionTypes.ExemptionTypeData> resultList =
            PRSE_RetrieveExemptionTypes.getExemptionTypeData();
        Test.stopTest();

        System.assertEquals(1, resultList.size(), 'Should always return one result wrapper');

        PRSE_RetrieveExemptionTypes.ExemptionTypeData result = resultList[0];

        System.assertEquals(null, result.D01_Name,               'D01 name should be null');
        System.assertEquals(null, result.ND06_Name,              'ND06 name should be null');
        System.assertEquals(null, result.D01_RequiredEvidence,   'D01 evidence should be null');
        System.assertEquals(null, result.ND06_RequiredEvidence,  'ND06 evidence should be null');
        System.assertEquals(null, result.D01_AdditionalInformation,  'D01 additional should be null');
        System.assertEquals(null, result.ND06_AdditionalInformation, 'ND06 additional should be null');
    }


    @IsTest
    static void testGetExemptionTypeData_PartialRecords() {
        delete [SELECT Id FROM Exemption_Type__c WHERE Code__c LIKE 'ND%'];

        Test.startTest();
        List<PRSE_RetrieveExemptionTypes.ExemptionTypeData> resultList =
            PRSE_RetrieveExemptionTypes.getExemptionTypeData();
        Test.stopTest();

        PRSE_RetrieveExemptionTypes.ExemptionTypeData result = resultList[0];

        System.assertEquals('D01_Name',    result.D01_Name,           'D01 name should be populated');
        System.assertEquals('D01_Evidence', result.D01_RequiredEvidence, 'D01 evidence should be populated');
        System.assertEquals(null, result.ND01_Name,                   'ND01 name should be null');
        System.assertEquals(null, result.ND01_RequiredEvidence,       'ND01 evidence should be null');
        System.assertEquals(null, result.ND06_AdditionalInformation,  'ND06 additional should be null');
    }


    @IsTest
    static void testGetExemptionTypeData_ReturnsCorrectType() {
        Test.startTest();
        List<PRSE_RetrieveExemptionTypes.ExemptionTypeData> resultList =
            PRSE_RetrieveExemptionTypes.getExemptionTypeData();
        Test.stopTest();

        System.assertNotEquals(null, resultList, 'Result list should not be null');
        System.assertEquals(1, resultList.size(), 'Result list should contain one element');
        System.assertNotEquals(null, resultList[0], 'Result wrapper should not be null');
    }
}
