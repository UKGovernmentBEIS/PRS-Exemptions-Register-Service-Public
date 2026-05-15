@isTest(IsParallel=true)
private class PRSE_PropertyAddressMatchActionTest {
    @isTest
    static void PRSE_PropertyAddressMatchAction_Response_newObject_setsExpectedVariables() {
        //Arrange
        DeliveryPointAddress tempDPA = new DeliveryPointAddress();
        tempDPA.UPRN = 12333;
        tempDPA.POSTCODE = 'AA3 1AB';
        tempDPA.ADDRESS = 'Flat 1, Road XYZ, London, AA3 1AB';

        //Act
        PRSE_PropertyAddressMatchAction.Response response = new PRSE_PropertyAddressMatchAction.Response(
            1,
            String.valueOf(tempDPA.UPRN),
            tempDPA
        );

        //Assert
        Assert.areEqual(1, response.numberOfAddresses, 'Incorrect numberOfAddresses');
        Assert.areEqual(String.valueOf(tempDPA.UPRN), response.addressUPRN, 'Incorrect addressUPRN');
        Assert.areEqual(tempDPA, response.deliveryPointAddress, 'Incorrect numberOfAddresses');
    }

    @isTest
    static void matchAddress_withServiceReturningNoAddresses_returnsEmptyResponse() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        OSPlacesInteractionService.API mockLayer = (OSPlacesInteractionService.API) mockProvider.createMock(OSPlacesInteractionServiceLayer.class);
        OSPlacesInteractionServiceLayer.instance = mockLayer;
        String mockAddress = 'Flat 1, Road Xyz, London, AA3 1AB';
        mockProvider.when(mockLayer.matchAddressForEnglandOrWalesOnly(mockAddress)).thenReturn(new List<DeliveryPointAddress>());

        //Act
        List<PRSE_PropertyAddressMatchAction.Response> responses = PRSE_PropertyAddressMatchAction.matchAddress(new List<String>{ mockAddress });

        //Assert
        Assert.areEqual(1, responses.size(), 'Incorrect number of results returned');

        PRSE_PropertyAddressMatchAction.Response response = responses[0];
        Assert.areEqual(0, response.numberOfAddresses, 'Incorrect number of addresses returned');
        Assert.areEqual('', response.addressUPRN, 'Incorrect address UPRN returned');
        Assert.areEqual(null, response.deliveryPointAddress, 'Incorrect DPA returned');
    }

    @isTest
    static void matchAddress_withServiceReturningSingleAddress_returnHighestMatchedAddress() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        OSPlacesInteractionService.API mockLayer = (OSPlacesInteractionService.API) mockProvider.createMock(OSPlacesInteractionServiceLayer.class);
        OSPlacesInteractionServiceLayer.instance = mockLayer;
        String mockAddress = 'Flat 1, Road Xyz, London, AA3 1AB';
        List<DeliveryPointAddress> mockDeliveryPointAddresses = createMockDeliveryPointAddresses('AA3 1AB', 1);
        mockProvider.when(mockLayer.matchAddressForEnglandOrWalesOnly(mockAddress)).thenReturn(mockDeliveryPointAddresses);

        //Act
        List<PRSE_PropertyAddressMatchAction.Response> responses = PRSE_PropertyAddressMatchAction.matchAddress(new List<String>{ mockAddress });

        //Assert
        Assert.areEqual(1, responses.size(), 'Incorrect number of results returned');

        PRSE_PropertyAddressMatchAction.Response response = responses[0];
        Assert.areEqual(1, response.numberOfAddresses, 'Incorrect number of addresses returned');
        Assert.areEqual('1', response.addressUPRN, 'Incorrect address UPRN returned');
        Assert.areEqual(1, response.deliveryPointAddress.UPRN, 'Incorrect DPA UPRN returned');
        Assert.areEqual('AA3 1AB', response.deliveryPointAddress.POSTCODE, 'Incorrect DPA POSTCODE returned');
        Assert.areEqual('Flat 1, Road Xyz, London, AA3 1AB', response.deliveryPointAddress.ADDRESS, 'Incorrect DPA ADDRESS returned');
    }

    @isTest
    static void matchAddress_withServiceReturningMultipleAddress_returnHighestMatchedAddress() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        OSPlacesInteractionService.API mockLayer = (OSPlacesInteractionService.API) mockProvider.createMock(OSPlacesInteractionServiceLayer.class);
        OSPlacesInteractionServiceLayer.instance = mockLayer;
        String mockAddress = 'Flat 1, Road Xyz, London, AA3 1AB';
        List<DeliveryPointAddress> mockDeliveryPointAddresses = createMockDeliveryPointAddresses('AA3 1AB', 4);
        mockProvider.when(mockLayer.matchAddressForEnglandOrWalesOnly(mockAddress)).thenReturn(mockDeliveryPointAddresses);

        //Act
        List<PRSE_PropertyAddressMatchAction.Response> responses = PRSE_PropertyAddressMatchAction.matchAddress(new List<String>{ mockAddress });

        //Assert
        Assert.areEqual(1, responses.size(), 'Incorrect number of results returned');

        PRSE_PropertyAddressMatchAction.Response response = responses[0];
        Assert.areEqual(1, response.numberOfAddresses, 'Incorrect number of addresses returned');
        Assert.areEqual('1', response.addressUPRN, 'Incorrect address UPRN returned');
        Assert.areEqual(1, response.deliveryPointAddress.UPRN, 'Incorrect DPA UPRN returned');
        Assert.areEqual('AA3 1AB', response.deliveryPointAddress.POSTCODE, 'Incorrect DPA POSTCODE returned');
        Assert.areEqual('Flat 1, Road Xyz, London, AA3 1AB', response.deliveryPointAddress.ADDRESS, 'Incorrect DPA ADDRESS returned');
    }

    private static List<String> extractAddressesFromSingleString(String formattedAddresses) {
        List<String> addresses = new List<String>();
        for(String address : formattedAddresses.split('\\|')) {
            addresses.add(address);
        }
        return addresses;
    }

    public static List<DeliveryPointAddress> createMockDeliveryPointAddresses(String postCode, Integer numberOfAddresses) {
        List<DeliveryPointAddress> directPostAddresses = new List<DeliveryPointAddress>();
        for(Integer i = 1; i <= numberOfAddresses; i++) {
            DeliveryPointAddress tempDPA = new DeliveryPointAddress();
            tempDPA.UPRN = i;
            tempDPA.POSTCODE = 'AA3 1AB';
            tempDPA.ADDRESS = 'Flat ' + i +', Road XYZ, London, AA3 1AB';
            directPostAddresses.add(tempDPA);
        }
        return directPostAddresses;
    }
}