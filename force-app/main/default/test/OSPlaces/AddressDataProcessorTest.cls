@isTest(IsParallel=true)
private class AddressDataProcessorTest {

    @isTest
    static void processAddressData_withNoResultsInHeader_returnsEmptyList() {
        //Arrange
        String jsonOutput = new JSONObjectBuilder().withHeader(buildMockHeader(0)).build();
        
        //Act
        List<DeliveryPointAddress> deliveryPointAddresses = AddressDataProcessor.processAddressData(jsonOutput);

        //Assert
        Assert.isTrue(deliveryPointAddresses.isEmpty(), 'Should return empty list of addresses');
    }

    @isTest
    static void processAddressData_withSingleResultInHeaderContainingValidUPRNs_returnsListWithOneItem() {
        //Arrange
        AddressDataProcessor.Result result1 = new AddressDataProcessor.Result();
        result1.DPA = buildMockDPA(11);
        String jsonOutput = new JSONObjectBuilder().withHeader(buildMockHeader(1)).withResult(result1).build();
        
        //Act
        List<DeliveryPointAddress> deliveryPointAddresses = AddressDataProcessor.processAddressData(jsonOutput);

        //Assert
        Assert.areEqual(1, deliveryPointAddresses.size(), 'Incorrect number of delivery point addresses returned');
        Assert.areEqual(11, deliveryPointAddresses[0].UPRN, 'DPA 2 UPRN should be populated');
    }

    @isTest
    static void processAddressData_withResultsInHeaderContainingNullUPRNs_sortsByNullsFirst() {
        //Arrange
        AddressDataProcessor.Result result1 = new AddressDataProcessor.Result();
        result1.DPA = buildMockDPA(113);
        AddressDataProcessor.Result result2 = new AddressDataProcessor.Result();
        result2.DPA = buildMockDPA(null);
        AddressDataProcessor.Result result3 = new AddressDataProcessor.Result();
        result3.DPA = buildMockDPA(11);
        List<AddressDataProcessor.Result> results = new List<AddressDataProcessor.Result>{ result1, result2, result3 };
        String jsonOutput = new JSONObjectBuilder().withHeader(buildMockHeader(3)).withResults(results).build();
        
        //Act
        List<DeliveryPointAddress> deliveryPointAddresses = AddressDataProcessor.processAddressData(jsonOutput);

        //Assert
        Assert.areEqual(3, deliveryPointAddresses.size(), 'Incorrect number of delivery point addresses returned');
        Assert.areEqual(null, deliveryPointAddresses[0].UPRN, 'DPA 1 UPRN should be null');
        Assert.areEqual(11, deliveryPointAddresses[1].UPRN, 'DPA 2 UPRN should be populated');
        Assert.areEqual(113, deliveryPointAddresses[2].UPRN, 'DPA 3 UPRN should be populated');
    }

    @isTest
    static void processAddressData_withMultipleResultsInHeaderContainingValidUPRNs_returnsListSortedByUPRNInAscendingOrder() {
        //Arrange
        AddressDataProcessor.Result result1 = new AddressDataProcessor.Result();
        result1.DPA = buildMockDPA(113);
        AddressDataProcessor.Result result2 = new AddressDataProcessor.Result();
        result2.DPA = buildMockDPA(22);
        AddressDataProcessor.Result result3 = new AddressDataProcessor.Result();
        result3.DPA = buildMockDPA(11);
        List<AddressDataProcessor.Result> results = new List<AddressDataProcessor.Result>{ result1, result2, result3 };
        String jsonOutput = new JSONObjectBuilder().withHeader(buildMockHeader(3)).withResults(results).build();
        
        //Act
        List<DeliveryPointAddress> deliveryPointAddresses = AddressDataProcessor.processAddressData(jsonOutput);

        //Assert
        Assert.areEqual(3, deliveryPointAddresses.size(), 'Incorrect number of delivery point addresses returned');
        Assert.areEqual(11, deliveryPointAddresses[0].UPRN, 'DPA 1 UPRN should be populated');
        Assert.areEqual(22, deliveryPointAddresses[1].UPRN, 'DPA 2 UPRN should be populated');
        Assert.areEqual(113, deliveryPointAddresses[2].UPRN, 'DPA 3 UPRN should be populated');
    }

    private static AddressDataProcessor.Header buildMockHeader(Integer totalResults) {
        AddressDataProcessor.Header mockHeader = new AddressDataProcessor.Header();
        mockHeader.uri = 'https://api.os.uk/search/places/v1/postcode?postcode=AA3%201AB';
        mockHeader.query = 'postcode=AA3 1AB';
        mockHeader.offset = 0;
        mockHeader.totalresults = totalResults;
        mockHeader.format = 'JSON';
        mockHeader.dataset = 'DPA';
        mockHeader.lr = 'EN,CY';
        mockHeader.maxresults = 100;
        mockHeader.epoch = '119';
        return mockHeader;
    }

    private static DeliveryPointAddress buildMockDPA(Long uprn) {
        DeliveryPointAddress mockDPA = new DeliveryPointAddress();
        mockDPA.UPRN = uprn;
        mockDPA.UDPRN = uprn;
        mockDPA.ADDRESS = 'FLAT 1, ROAD XYZ, LONDON, AA3 1AB';
        mockDPA.THOROUGHFARE_NAME = 'ROAD XYZ';
        mockDPA.POST_TOWN = 'LONDON';
        mockDPA.POSTCODE = 'AA3 1AB';
        return mockDPA;
    }

    private class JSONObjectBuilder {

        private AddressDataProcessor.Root dataObject;
        public JSONObjectBuilder(){
            dataObject = new AddressDataProcessor.Root();
        }

        public JSONObjectBuilder withHeader(AddressDataProcessor.Header header) {
            dataObject.header = header;
            return this;
        }

        public JSONObjectBuilder withResult(AddressDataProcessor.Result result) {
            dataObject.results = new List<AddressDataProcessor.Result>{ result };
            return this;
        }

        public JSONObjectBuilder withResults(List<AddressDataProcessor.Result> results) {
            dataObject.results = results;
            return this;
        }

        public String build(){
            return JSON.serialize(dataObject);
        }
    }
}