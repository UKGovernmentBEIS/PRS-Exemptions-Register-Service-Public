@isTest(IsParallel=true)
private class PRSE_AddressRetrievalActionTest {

    @isTest
    static void getInformationByPostcode_callsService_returnSingleAddressFormattedInSingleString() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        OSPlacesInteractionService.API mockLayer = (OSPlacesInteractionService.API) mockProvider.createMock(OSPlacesInteractionServiceLayer.class);
        OSPlacesInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.getInformationByPostcode('AA3 1AB')).thenReturn(createMockDeliveryPointAddresses('AA3 1AB', 1));

        //Act
        List<PRSE_AddressRetrievalAction.Response> responses = PRSE_AddressRetrievalAction.getAddressesByPostcode(new List<String>{ 'AA3 1AB' });

        //Assert
        Assert.areEqual(1, responses.size(), 'Incorrect number of results returned');

        PRSE_AddressRetrievalAction.Response response = responses[0];
        Assert.areEqual(1, response.numberOfAddresses, 'Incorrect number of addresses returned');

        List<String> extractedAddresses = extractAddressesFromSingleString(response.addresses);
        Assert.areEqual(1, extractedAddresses.size(), 'Incorrect number of addresses returned');
        Assert.areEqual('Flat 1, Road Xyz, London, AA3 1AB', extractedAddresses[0], 'Incorrect address returned');
    }

    @isTest
    static void getInformationByPostcode_callsService_returnMultipleAddressesFormattedInSingleString() {
        //Arrange
        MockProvider mockProvider = new MockProvider();
        OSPlacesInteractionService.API mockLayer = (OSPlacesInteractionService.API) mockProvider.createMock(OSPlacesInteractionServiceLayer.class);
        OSPlacesInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.getInformationByPostcode('AA3 1AB')).thenReturn(createMockDeliveryPointAddresses('AA3 1AB', 2));

        //Act
        List<PRSE_AddressRetrievalAction.Response> responses = PRSE_AddressRetrievalAction.getAddressesByPostcode(new List<String>{ 'AA3 1AB' });

        //Assert
        Assert.areEqual(1, responses.size(), 'Incorrect number of results returned');

        PRSE_AddressRetrievalAction.Response response = responses[0];
        Assert.areEqual(2, response.numberOfAddresses, 'Incorrect number of addresses returned');
        
        List<String> extractedAddresses = extractAddressesFromSingleString(response.addresses);
        Assert.areEqual(2, extractedAddresses.size(), 'Incorrect number of addresses returned');
        Assert.areEqual('Flat 1, Road Xyz, London, AA3 1AB', extractedAddresses[0], 'Incorrect address returned');
        Assert.areEqual('Flat 2, Road Xyz, London, AA3 1AB', extractedAddresses[1], 'Incorrect address returned');
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