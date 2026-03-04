@isTest(IsParallel=true)
private class OSPlacesInteractionServiceTest {

    @isTest
    static void getInformationByPostcode_callsLayer_andReturnAddressMap() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        OSPlacesInteractionService.API mockLayer = (OSPlacesInteractionService.API) mockProvider.createMock(OSPlacesInteractionServiceLayer.class);
        OSPlacesInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.getInformationByPostcode('AA3 1AB')).thenReturn(createMockDeliveryPointAddresses('AA3 1AB'));

        //Act
        List<DeliveryPointAddress> directPostAddresses = OSPlacesInteractionService.getInformationByPostcode('AA3 1AB');

        //Assert
        Assert.areEqual(2, directPostAddresses.size(), 'Incorrect number of direct postal addresses returned');
        
        DeliveryPointAddress dpa1 = directPostAddresses[0];
        Assert.areEqual(1, dpa1.UPRN, 'Incorrect UPRN returned');
        Assert.areEqual('AA3 1AB', dpa1.POSTCODE, 'Incorrect POSTCODE returned');

        DeliveryPointAddress dpa2 = directPostAddresses[1];
        Assert.areEqual(2, dpa2.UPRN, 'Incorrect UPRN returned');
        Assert.areEqual('AA3 1AB', dpa2.POSTCODE, 'Incorrect POSTCODE returned');
    }

    @isTest
    static void getInformationByPostcodeForEnglandOrWalesOnly_callsLayer_andReturnAddressMap() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        OSPlacesInteractionService.API mockLayer = (OSPlacesInteractionService.API) mockProvider.createMock(OSPlacesInteractionServiceLayer.class);
        OSPlacesInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.getInformationByPostcodeForEnglandOrWalesOnly('AA3 1AB')).thenReturn(createMockDeliveryPointAddresses('AA3 1AB'));

        //Act
        List<DeliveryPointAddress> directPostAddresses = OSPlacesInteractionService.getInformationByPostcodeForEnglandOrWalesOnly('AA3 1AB');

        //Assert
        Assert.areEqual(2, directPostAddresses.size(), 'Incorrect number of direct postal addresses returned');

        DeliveryPointAddress dpa1 = directPostAddresses[0];
        Assert.areEqual(1, dpa1.UPRN, 'Incorrect UPRN returned');
        Assert.areEqual('AA3 1AB', dpa1.POSTCODE, 'Incorrect POSTCODE returned');

        DeliveryPointAddress dpa2 = directPostAddresses[1];
        Assert.areEqual(2, dpa2.UPRN, 'Incorrect UPRN returned');
        Assert.areEqual('AA3 1AB', dpa2.POSTCODE, 'Incorrect POSTCODE returned');
    }

    @isTest
    static void matchAddressForEnglandOrWalesOnly_callsLayer_andReturnAddressMap() {
        //Arrange
        String mockAddress = 'Flat 1, Road Xyz, London, AA3 1AB';
        MockProvider mockProvider = new MockProvider();
        OSPlacesInteractionService.API mockLayer = (OSPlacesInteractionService.API) mockProvider.createMock(OSPlacesInteractionServiceLayer.class);
        OSPlacesInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.matchAddressForEnglandOrWalesOnly(mockAddress)).thenReturn(createMockDeliveryPointAddresses('AA3 1AB'));

        //Act
        List<DeliveryPointAddress> directPostAddresses = OSPlacesInteractionService.matchAddressForEnglandOrWalesOnly(mockAddress);

        //Assert
        Assert.areEqual(2, directPostAddresses.size(), 'Incorrect number of direct postal addresses returned');

        DeliveryPointAddress dpa1 = directPostAddresses[0];
        Assert.areEqual(1, dpa1.UPRN, 'Incorrect UPRN returned');
        Assert.areEqual('AA3 1AB', dpa1.POSTCODE, 'Incorrect POSTCODE returned');

        DeliveryPointAddress dpa2 = directPostAddresses[1];
        Assert.areEqual(2, dpa2.UPRN, 'Incorrect UPRN returned');
        Assert.areEqual('AA3 1AB', dpa2.POSTCODE, 'Incorrect POSTCODE returned');
    }

    public static List<DeliveryPointAddress> createMockDeliveryPointAddresses(String postCode) {
        List<DeliveryPointAddress> directPostAddresses = new List<DeliveryPointAddress>();
        DeliveryPointAddress dpa1 = new DeliveryPointAddress();
        dpa1.UPRN = 1;
        dpa1.POSTCODE = 'AA3 1AB';
        directPostAddresses.add(dpa1);

        DeliveryPointAddress dpa2 = new DeliveryPointAddress();
        dpa2.UPRN = 2;
        dpa2.POSTCODE = 'AA3 1AB';
        directPostAddresses.add(dpa2);
        return directPostAddresses;
    }
}