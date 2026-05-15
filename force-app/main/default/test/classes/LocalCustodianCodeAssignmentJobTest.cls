@isTest
private class LocalCustodianCodeAssignmentJobTest {

    @isTest
    static void execute_withNoValidRecordsToProcess_noUpdatesMade() {
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
            Ref_Legacy__c = 'TEST 1'
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
            PropertyType__c = 'Residential'
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
            Local_Custodian_Code__c = '4610',
            Ref_Legacy__c = 'TEST 3'
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
            Ref_Legacy__c = 'TEST 4'
        );
        insert new List<Exemption__c> { draftExemption, receivedExemption1, receivedExemption2, updatedExemption };

        //Act
        Test.startTest();
        System.enqueueJob(new LocalCustodianCodeAssignmentJob(), 0);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.isNull(draftExemption.Local_Custodian_Code__c, 'Expected draft exemption local custodian code to be empty');
        Assert.isNull(receivedExemption1.Local_Custodian_Code__c, 'Expected received exemption local custodian code to be empty');
        Assert.isNull(updatedExemption.Local_Custodian_Code__c, 'Expected updated exemption local custodian code to be empty');
    }

    @isTest
    static void execute_withRecordsToProcess_updatesRecordWithLocalCustodianCode() {
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
            Ref_Legacy__c = 'TEST 1'
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
            Ref_Legacy__c = 'TEST 2'
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
            Local_Custodian_Code__c = '4610',
            Ref_Legacy__c = 'TEST 3'
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
            Ref_Legacy__c = 'TEST 4'
        );
        insert new List<Exemption__c> { draftExemption, receivedExemption1, receivedExemption2, updatedExemption };

        DeliveryPointAddress dpaToReturn = new DeliveryPointAddress();
        dpaToReturn.LOCAL_CUSTODIAN_CODE = 5990;
        String dpaQueryAddress = 
            receivedExemption1.PropertyAddress__c + ', ' + 
            receivedExemption1.PropertyCity__c + ', ' + 
            receivedExemption1.PropertyCounty__c + ', ' + 
            receivedExemption1.PropertyPostcode__c;
        MockProvider mockProvider = new MockProvider();
        System.debug('dpaQueryAddress: ' + dpaQueryAddress);
        OSPlacesInteractionService.API mockLayer = (OSPlacesInteractionService.API) mockProvider.createMock(OSPlacesInteractionServiceLayer.class);
        OSPlacesInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.matchAddressForEnglandOrWalesOnly(dpaQueryAddress)).thenReturn(new List<DeliveryPointAddress>{ dpaToReturn });

        //Act
        Test.startTest();
        System.enqueueJob(new LocalCustodianCodeAssignmentJob(), 0);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.isNull(draftExemption.Local_Custodian_Code__c, 'Expected draft exemption local custodian code to be empty');
        Assert.areEqual('4610', receivedExemption2.Local_Custodian_Code__c, 'Expected received exemption 2 local custodian code to be 4610');
        Assert.isNull(updatedExemption.Local_Custodian_Code__c, 'Expected updated exemption local custodian code to be empty');

        Exemption__c expectedUpdatedExemption = [SELECT Id, Local_Custodian_Code__c FROM Exemption__c WHERE Ref_Legacy__c = 'TEST 2' LIMIT 1];
        Assert.areEqual('5990', expectedUpdatedExemption.Local_Custodian_Code__c, 'Expected received exemption 1 local custodian code to be 5990');
    }

    @isTest
    static void execute_withExemptionInCallout_logsError() {
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
            Ref_Legacy__c = 'TEST 1'
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
            Ref_Legacy__c = 'TEST 2'
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
            Local_Custodian_Code__c = '4610',
            Ref_Legacy__c = 'TEST 3'
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
            Ref_Legacy__c = 'TEST 4'
        );
        insert new List<Exemption__c> { draftExemption, receivedExemption1, receivedExemption2, updatedExemption };

        String dpaQueryAddress = 
            receivedExemption1.PropertyAddress__c + ', ' + 
            receivedExemption1.PropertyCity__c + ', ' + 
            receivedExemption1.PropertyCounty__c + ', ' + 
            receivedExemption1.PropertyPostcode__c;
        MockProvider mockProvider = new MockProvider();
        OSPlacesInteractionService.API mockLayer = (OSPlacesInteractionService.API) mockProvider.createMock(OSPlacesInteractionServiceLayer.class);
        OSPlacesInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.matchAddressForEnglandOrWalesOnly(dpaQueryAddress)).thenThrow(new Exceptions.CustomException('An error has occured'));

        //Act
        Test.startTest();
        System.enqueueJob(new LocalCustodianCodeAssignmentJob(), 0);
        Test.stopTest();

        //Assert
        Exemption__c expectedUpdatedExemptionToError = [SELECT Id FROM Exemption__c WHERE Ref_Legacy__c = 'TEST 2' LIMIT 1];
        String expectedErrorMessage = 'execute for record ' + expectedUpdatedExemptionToError.Id + ' with error: An error has occured';
        List<digitalmodus__System_Log__c> errorLogs = [
            SELECT Id, digitalmodus__Log_Message__c, digitalmodus__Log_Code__c,  digitalmodus__Related_Service__c 
            FROM digitalmodus__System_Log__c
        ];
        system.debug(expectedErrorMessage);
        system.debug(errorLogs);
        ErrorLogChecker.checkErrorForServiceAndMethod('LocalCustodianCodeAssignmentJob', 'execute', expectedErrorMessage);
    }
}