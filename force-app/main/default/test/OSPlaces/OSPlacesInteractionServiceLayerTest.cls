@isTest
private class OSPlacesInteractionServiceLayerTest {

    private static final String mockApiKey = '123456';
    private static String expectedPostcodeEndpoint = 'https://api.os.uk/search/places/v1/postcode?postcode={0}&key={1}&lr=EN{2}';
    private static String expectedFindEndpoint = 'https://api.os.uk/search/places/v1/find?query={0}&key={1}&maxresults=5&minmatch=0.8&lr=EN&fq=COUNTRY_CODE:E COUNTRY_CODE:W';

    @isTest
    static void getInformationByPostcode_withNullPostCode_returnsEmptyList() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        Test.startTest();
        List<DeliveryPointAddress> returnedAddresses = OSPlacesInteractionServiceLayer.getInstance().getInformationByPostcode(null);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, returnedAddresses.size(), 'Should return empty list of addresses');
    }

    @isTest
    static void getInformationByPostcode_withEmptyPostCode_returnsEmptyList() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        Test.startTest();
        List<DeliveryPointAddress> returnedAddresses = OSPlacesInteractionServiceLayer.getInstance().getInformationByPostcode('');
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, returnedAddresses.size(), 'Should return empty list of addresses');
    }

    @isTest
    static void getInformationByPostcode_withWhiteSpacePostCode_returnsEmptyList() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        Test.startTest();
        List<DeliveryPointAddress> returnedAddresses = OSPlacesInteractionServiceLayer.getInstance().getInformationByPostcode('   ');
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, returnedAddresses.size(), 'Should return empty list of addresses');
    }

    @isTest
    static void getInformationByPostcode_withPostCodeAndNoResultsReturned_returnsEmptyList() {
        //Arrange
        String postCode = 'AA3 1AB';
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();
        Test.setMock(HttpCalloutMock.class, new HttpResponseMock(postCode, 200, 'OK', getMockResponseBodyWithNoResults(postCode, '')));

        //Act
        Test.startTest();
        List<DeliveryPointAddress> returnedAddresses = OSPlacesInteractionServiceLayer.getInstance().getInformationByPostcode(postCode);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, returnedAddresses.size(), 'Should return empty list of addresses');
    }

    @isTest
    static void getInformationByPostcode_withPostCodeAndValidResultsReturned_returnsDeliveryPointAddressList() {
        //Arrange
        String postCode = 'AA3 1AB';
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();
        Test.setMock(HttpCalloutMock.class, new HttpResponseMock(postCode, 200, 'OK', getMockResponseBodyWithResults(postCode, '')));

        //Act
        Test.startTest();
        List<DeliveryPointAddress> returnedAddresses = OSPlacesInteractionServiceLayer.getInstance().getInformationByPostcode(postCode);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(2, returnedAddresses.size(), 'Incorrect number of Delivery Point Addresses returned');
        DeliveryPointAddress deliveryPointAddress = returnedAddresses[0];
        Assert.areEqual('Flat 1, Road Xyz, London, AA3 1AB', deliveryPointAddress.ADDRESS, 'Incorrect ADDRESS returned');
        Assert.areEqual('Road Xyz', deliveryPointAddress.THOROUGHFARE_NAME, 'Incorrect THOROUGHFARE_NAME returned');
        Assert.areEqual('London', deliveryPointAddress.POST_TOWN, 'Incorrect POST_TOWN returned');
        Assert.areEqual('AA3 1AB', deliveryPointAddress.POSTCODE, 'Incorrect POSTCODE returned');

        DeliveryPointAddress deliveryPointAddress2 = returnedAddresses[1];
        Assert.areEqual('Flat 2, Road Xyz, London, AA3 1AB', deliveryPointAddress2.ADDRESS, 'Incorrect ADDRESS returned');
        Assert.areEqual('Road Xyz', deliveryPointAddress2.THOROUGHFARE_NAME, 'Incorrect THOROUGHFARE_NAME returned');
        Assert.areEqual('London', deliveryPointAddress2.POST_TOWN, 'Incorrect POST_TOWN returned');
        Assert.areEqual('AA3 1AB', deliveryPointAddress2.POSTCODE, 'Incorrect POSTCODE returned');
    }

    @isTest
    static void getInformationByPostcode_withPostCodeButStatusCode300_throwsException() {
        //Arrange
        String postCode = 'AA3 1AB';
        String errorMessage = 'Unauthorised access, please contact your administrator.';
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();
        Test.setMock(HttpCalloutMock.class, new HttpResponseMock(postCode, 300, errorMessage, getMockResponseBodyWithResults(postCode, '')));

        //Act
        Test.startTest();
        List<DeliveryPointAddress> deliveryPointAddresses = OSPlacesInteractionServiceLayer.getInstance().getInformationByPostcode(postCode);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('OSPlacesInteractionServiceLayer', 'getInformationByPostcode', errorMessage);
        Assert.isTrue(deliveryPointAddresses.isEmpty(), 'Expected to return empty list of Delivery Point Addresses.');
    }

    @isTest
    static void getInformationByPostcodeForEnglandOrWalesOnly_withNullPostCode_returnsEmptyList() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        Test.startTest();
        List<DeliveryPointAddress> returnedAddresses = OSPlacesInteractionServiceLayer.getInstance().getInformationByPostcodeForEnglandOrWalesOnly(null);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, returnedAddresses.size(), 'Should return empty list of addresses');
    }

    @isTest
    static void getInformationByPostcodeForEnglandOrWalesOnly_withEmptyPostCode_returnsEmptyList() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        Test.startTest();
        List<DeliveryPointAddress> returnedAddresses = OSPlacesInteractionServiceLayer.getInstance().getInformationByPostcodeForEnglandOrWalesOnly('');
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, returnedAddresses.size(), 'Should return empty list of addresses');
    }

    @isTest
    static void getInformationByPostcodeForEnglandOrWalesOnly_withWhiteSpacePostCode_returnsEmptyList() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        Test.startTest();
        List<DeliveryPointAddress> returnedAddresses = OSPlacesInteractionServiceLayer.getInstance().getInformationByPostcodeForEnglandOrWalesOnly('   ');
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, returnedAddresses.size(), 'Should return empty list of addresses');
    }

    @isTest
    static void getInformationByPostcodeForEnglandOrWalesOnly_withPostCodeAndNoResultsReturned_returnsEmptyList() {
        //Arrange
        String postCode = 'AA3 1AB';
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();
        Test.setMock(
            HttpCalloutMock.class, 
            new HttpResponseMock(postCode, 200, 'OK', getMockResponseBodyWithNoResults(postCode, '&fq=COUNTRY_CODE:E COUNTRY_CODE:W'))
            .withFilters('&fq=COUNTRY_CODE:E COUNTRY_CODE:W')
        );

        //Act
        Test.startTest();
        List<DeliveryPointAddress> returnedAddresses = OSPlacesInteractionServiceLayer.getInstance().getInformationByPostcodeForEnglandOrWalesOnly(postCode);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, returnedAddresses.size(), 'Should return empty list of addresses');
    }

    @isTest
    static void getInformationByPostcodeForEnglandOrWalesOnly_withPostCodeAndValidResultsReturned_returnsDeliveryPointAddressList() {
        //Arrange
        String postCode = 'AA3 1AB';
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();
        Test.setMock(
            HttpCalloutMock.class, 
            new HttpResponseMock(postCode, 200, 'OK', getMockResponseBodyWithResults(postCode, '&fq=COUNTRY_CODE:E COUNTRY_CODE:W'))
            .withFilters('&fq=COUNTRY_CODE:E COUNTRY_CODE:W')
        );

        //Act
        Test.startTest();
        List<DeliveryPointAddress> returnedAddresses = OSPlacesInteractionServiceLayer.getInstance().getInformationByPostcodeForEnglandOrWalesOnly(postCode);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(2, returnedAddresses.size(), 'Incorrect number of Delivery Point Addresses returned');
        DeliveryPointAddress deliveryPointAddress = returnedAddresses[0];
        Assert.areEqual('Flat 1, Road Xyz, London, AA3 1AB', deliveryPointAddress.ADDRESS, 'Incorrect ADDRESS returned');
        Assert.areEqual('Road Xyz', deliveryPointAddress.THOROUGHFARE_NAME, 'Incorrect THOROUGHFARE_NAME returned');
        Assert.areEqual('London', deliveryPointAddress.POST_TOWN, 'Incorrect POST_TOWN returned');
        Assert.areEqual('AA3 1AB', deliveryPointAddress.POSTCODE, 'Incorrect POSTCODE returned');

        DeliveryPointAddress deliveryPointAddress2 = returnedAddresses[1];
        Assert.areEqual('Flat 2, Road Xyz, London, AA3 1AB', deliveryPointAddress2.ADDRESS, 'Incorrect ADDRESS returned');
        Assert.areEqual('Road Xyz', deliveryPointAddress2.THOROUGHFARE_NAME, 'Incorrect THOROUGHFARE_NAME returned');
        Assert.areEqual('London', deliveryPointAddress2.POST_TOWN, 'Incorrect POST_TOWN returned');
        Assert.areEqual('AA3 1AB', deliveryPointAddress2.POSTCODE, 'Incorrect POSTCODE returned');
    }

    @isTest
    static void getInformationByPostcodeForEnglandOrWalesOnly_withPostCodeButStatusCode300_throwsException() {
        //Arrange
        String postCode = 'AA3 1AB';
        String errorMessage = 'Unauthorised access, please contact your administrator.';
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();
        Test.setMock(
            HttpCalloutMock.class, 
            new HttpResponseMock(postCode, 300, errorMessage, getMockResponseBodyWithResults(postCode, '&fq=COUNTRY_CODE:E COUNTRY_CODE:W'))
            .withFilters('&fq=COUNTRY_CODE:E COUNTRY_CODE:W')
        );

        //Act
        Test.startTest();
        List<DeliveryPointAddress> deliveryPointAddresses = OSPlacesInteractionServiceLayer.getInstance().getInformationByPostcodeForEnglandOrWalesOnly(postCode);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('OSPlacesInteractionServiceLayer', 'getInformationByPostcodeForEnglandOrWalesOnly', errorMessage);
        Assert.isTrue(deliveryPointAddresses.isEmpty(), 'Expected to return empty list of Delivery Point Addresses.');
    }

     @isTest
    static void matchAddressForEnglandOrWalesOnly_withNullPostCode_returnsEmptyList() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        Test.startTest();
        List<DeliveryPointAddress> returnedAddresses = OSPlacesInteractionServiceLayer.getInstance().matchAddressForEnglandOrWalesOnly(null);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, returnedAddresses.size(), 'Should return empty list of addresses');
    }

    @isTest
    static void matchAddressForEnglandOrWalesOnly_withEmptyPostCode_returnsEmptyList() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        Test.startTest();
        List<DeliveryPointAddress> returnedAddresses = OSPlacesInteractionServiceLayer.getInstance().matchAddressForEnglandOrWalesOnly('');
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, returnedAddresses.size(), 'Should return empty list of addresses');
    }

    @isTest
    static void matchAddressForEnglandOrWalesOnly_withWhiteSpacePostCode_returnsEmptyList() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        Test.startTest();
        List<DeliveryPointAddress> returnedAddresses = OSPlacesInteractionServiceLayer.getInstance().matchAddressForEnglandOrWalesOnly('   ');
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, returnedAddresses.size(), 'Should return empty list of addresses');
    }

    @isTest
    static void matchAddressForEnglandOrWalesOnly_withPostCodeAndNoResultsReturned_returnsEmptyList() {
        //Arrange
        String mockAddress = 'Flat 1, Road Xyz, London, AA3 1AB';
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();
        Test.setMock(
            HttpCalloutMock.class, 
            new HttpResponseMock('AA3 1AB', 200, 'OK', getMockFindResponseBodyWithNoResults(mockAddress, '&fq=COUNTRY_CODE:E COUNTRY_CODE:W'))
            .withFilters('&fq=COUNTRY_CODE:E COUNTRY_CODE:W')
            .withAddress(mockAddress)
            .usingFindQuery(true)
        );

        //Act
        Test.startTest();
        List<DeliveryPointAddress> returnedAddresses = OSPlacesInteractionServiceLayer.getInstance().matchAddressForEnglandOrWalesOnly(mockAddress);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(0, returnedAddresses.size(), 'Should return empty list of addresses');
    }

    @isTest
    static void matchAddressForEnglandOrWalesOnly_withPostCodeAndValidResultsReturned_returnsDeliveryPointAddressList() {
        //Arrange
        String mockAddress = 'Flat 2, Road Xyz, London, AA3 1AB';
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();
        Test.setMock(
            HttpCalloutMock.class, 
            new HttpResponseMock('AA3 1AB', 200, 'OK', getMockFindResponseBodyWithResults('AA3 1AB', '&fq=COUNTRY_CODE:E COUNTRY_CODE:W'))
            .withFilters('&fq=COUNTRY_CODE:E COUNTRY_CODE:W')
            .withAddress(mockAddress)
            .usingFindQuery(true)
        );

        //Act
        Test.startTest();
        List<DeliveryPointAddress> returnedAddresses = OSPlacesInteractionServiceLayer.getInstance().matchAddressForEnglandOrWalesOnly(mockAddress);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkNoErrors();
        Assert.areEqual(2, returnedAddresses.size(), 'Incorrect number of Delivery Point Addresses returned');
        DeliveryPointAddress deliveryPointAddress = returnedAddresses[0];
        Assert.areEqual('Flat 2, Road Xyz, London, AA3 1AB', deliveryPointAddress.ADDRESS, 'Incorrect ADDRESS returned');
        Assert.areEqual('Road Xyz', deliveryPointAddress.THOROUGHFARE_NAME, 'Incorrect THOROUGHFARE_NAME returned');
        Assert.areEqual('London', deliveryPointAddress.POST_TOWN, 'Incorrect POST_TOWN returned');
        Assert.areEqual('AA3 1AB', deliveryPointAddress.POSTCODE, 'Incorrect POSTCODE returned');

        DeliveryPointAddress deliveryPointAddress2 = returnedAddresses[1];
        Assert.areEqual('Flat 1, Road Xyz, London, AA3 1AB', deliveryPointAddress2.ADDRESS, 'Incorrect ADDRESS returned');
        Assert.areEqual('Road Xyz', deliveryPointAddress2.THOROUGHFARE_NAME, 'Incorrect THOROUGHFARE_NAME returned');
        Assert.areEqual('London', deliveryPointAddress2.POST_TOWN, 'Incorrect POST_TOWN returned');
        Assert.areEqual('AA3 1AB', deliveryPointAddress2.POSTCODE, 'Incorrect POSTCODE returned');
    }

    @isTest
    static void matchAddressForEnglandOrWalesOnly_withPostCodeButStatusCode300_throwsException() {
        //Arrange
        String mockAddress = 'Flat 1, Road Xyz, London, AA3 1AB';
        String errorMessage = 'Unauthorised access, please contact your administrator.';
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();
        Test.setMock(
            HttpCalloutMock.class, 
            new HttpResponseMock('AA3 1AB', 300, errorMessage, getMockResponseBodyWithResults(mockAddress, '&fq=COUNTRY_CODE:E COUNTRY_CODE:W'))
            .withFilters('&fq=COUNTRY_CODE:E COUNTRY_CODE:W')
            .withAddress(mockAddress)
            .usingFindQuery(true)
        );

        //Act
        Test.startTest();
        List<DeliveryPointAddress> deliveryPointAddresses = OSPlacesInteractionServiceLayer.getInstance().matchAddressForEnglandOrWalesOnly(mockAddress);
        Test.stopTest();

        //Assert
        ErrorLogChecker.checkErrorForServiceAndMethod('OSPlacesInteractionServiceLayer', 'matchAddressForEnglandOrWalesOnly', errorMessage);
        Assert.isTrue(deliveryPointAddresses.isEmpty(), 'Expected to return empty list of Delivery Point Addresses.');
    }

    private class HttpResponseMock implements HttpCalloutMock {

        private String postCode;
        private Integer statusCode;
        private String status;
        private String responseBody;
        private String filters = '';
        private String address = '';
        private Boolean usingFind = false;
        
        public HttpResponseMock(String postCode, Integer statusCode, String status, String responseBody) {
            this.postCode = postCode;
            this.statusCode = statusCode;
            this.status = status;
            this.responseBody = responseBody;
        }

        public HttpResponseMock withFilters(String filters){
            this.filters = filters;
            return this;
        }

        public HttpResponseMock withAddress(String address){
            this.address = address;
            return this;
        }

        public HttpResponseMock usingFindQuery(Boolean usingFind){
            this.usingFind = usingFind;
            return this;
        }

        public HttpResponse respond(HTTPRequest request) {
            String expectedEndpoint;
            if(usingFind) {
                expectedEndpoint = String.format(
                    expectedFindEndpoint, 
                    new List<String> { 
                        EncodingUtil.urlEncode(address, 'UTF-8'), 
                        mockApiKey
                    }
                );
            } else {
                expectedEndpoint = String.format(
                    expectedPostcodeEndpoint, 
                    new List<String> { 
                        EncodingUtil.urlEncode(postCode, 'UTF-8'), 
                        mockApiKey,
                        filters
                    }
                );
            }
           
            Assert.areEqual(expectedEndpoint, request.getEndpoint(), 'Incorrect endpoint set');
            Assert.areEqual('GET', request.getMethod(), 'Incorrect method set');

            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(responseBody);
            response.setStatus(status);
            return response;
        }
    }
    
    private static String getMockResponseBodyWithNoResults(String postCode, String filters) {
        String encodedPostcode = postCode.replace(' ', '%20');
        String jsonString = 
        '{' +
            '"header": {' +
            '"uri": "https://api.os.uk/search/places/v1/postcode?postcode={0}{1}&lr=EN",' +
            '"query": "postcode={2}",' +
            '"offset": 0,' +
            '"totalresults": 0,' +
            '"format": "JSON",' +
            '"dataset": "DPA",' +
            '"lr": "EN,CY",' +
            '"maxresults": 100,' +
            '"epoch": "119",' +
            '"lastupdate": "2025-07-23",' +
            '"output_srs": "EPSG:27700"' +
            '}' +
        '}';
        return jsonString.replace('{0}', encodedPostcode).replace('{1}', filters).replace('{1}', postCode);
    }

    private static String getMockFindResponseBodyWithNoResults(String address, String filters) {
        String encodedAddress = address.replace(' ', '%20');
        String jsonString = 
        '{' +
            '"header": {' +
            '"uri": "https://api.os.uk/search/places/v1/find?query={0}&key={1}&maxresults=5&minmatch=0.8&lr=EN",' +
            '"query": "postcode={2}",' +
            '"offset": 0,' +
            '"totalresults": 0,' +
            '"format": "JSON",' +
            '"dataset": "DPA",' +
            '"lr": "EN,CY",' +
            '"maxresults": 100,' +
            '"epoch": "119",' +
            '"lastupdate": "2025-07-23",' +
            '"output_srs": "EPSG:27700"' +
            '}' +
        '}';
        return jsonString.replace('{0}', encodedAddress).replace('{1}', filters).replace('{1}', address);
    }

    private static String getMockResponseBodyWithResults(String postCode, String filters) {
        String encodedPostcode = postCode.replace(' ', '%20');
        String jsonString = 
        '{' +
            '"header": {' +
            '"uri": "https://api.os.uk/search/places/v1/postcode?postcode={0}{1}&lr=EN",' +
            '"query": "postcode={2}",' +
            '"offset": 0,' +
            '"totalresults": 2,' +
            '"format": "JSON",' +
            '"dataset": "DPA",' +
            '"lr": "EN,CY",' +
            '"maxresults": 100,' +
            '"epoch": "119",' +
            '"lastupdate": "2025-07-23",' +
            '"output_srs": "EPSG:27700"' +
            '},' +
            '"results": [' +
                '{' +
                    '"DPA": {' +
                        '"UPRN": "2222222222",' +
                        '"UDPRN": "123123123",' +
                        '"ADDRESS": "FLAT 2, ROAD XYZ, LONDON, {2}",' +
                        '"THOROUGHFARE_NAME": "ROAD XYZ",' +
                        '"POST_TOWN": "LONDON",' +
                        '"POSTCODE": "{2}",' +
                        '"RPC": "2",' +
                        '"STATUS": "APPROVED",' +
                        '"LOGICAL_STATUS_CODE": "1",' +
                        '"COUNTRY_CODE": "E",' +
                        '"COUNTRY_CODE_DESCRIPTION": "This record is within England",' +
                        '"POSTAL_ADDRESS_CODE": "D",' +
                        '"POSTAL_ADDRESS_CODE_DESCRIPTION": "A record which is linked to PAF",' +
                        '"BLPU_STATE_CODE_DESCRIPTION": "In use",' +
                        '"LAST_UPDATE_DATE": "13/11/2024",' +
                        '"ENTRY_DATE": "16/09/2009",' +
                        '"BLPU_STATE_DATE": "16/09/2009",' +
                        '"LANGUAGE": "EN",' +
                        '"MATCH": 0.8,' +
                        '"MATCH_DESCRIPTION": "EXACT",' +
                        '"DELIVERY_POINT_SUFFIX": "1A"' +
                    '}' +
                '},' +
                '{' +
                    '"DPA": {' +
                        '"UPRN": "1111111111",' +
                        '"UDPRN": "123123123",' +
                        '"ADDRESS": "FLAT 1, ROAD XYZ, LONDON, {2}",' +
                        '"THOROUGHFARE_NAME": "ROAD XYZ",' +
                        '"POST_TOWN": "LONDON",' +
                        '"POSTCODE": "{2}",' +
                        '"RPC": "2",' +
                        '"STATUS": "APPROVED",' +
                        '"LOGICAL_STATUS_CODE": "1",' +
                        '"COUNTRY_CODE": "E",' +
                        '"COUNTRY_CODE_DESCRIPTION": "This record is within England",' +
                        '"POSTAL_ADDRESS_CODE": "D",' +
                        '"POSTAL_ADDRESS_CODE_DESCRIPTION": "A record which is linked to PAF",' +
                        '"BLPU_STATE_CODE_DESCRIPTION": "In use",' +
                        '"LAST_UPDATE_DATE": "13/11/2024",' +
                        '"ENTRY_DATE": "16/09/2009",' +
                        '"BLPU_STATE_DATE": "16/09/2009",' +
                        '"LANGUAGE": "EN",' +
                        '"MATCH": 0.9,' +
                        '"MATCH_DESCRIPTION": "EXACT",' +
                        '"DELIVERY_POINT_SUFFIX": "1A"' +
                    '}' +
                '}' +
            ']' +
        '}';
        return jsonString.replace('{0}', encodedPostcode).replace('{1}', filters).replace('{2}', postCode);
    }

    private static String getMockFindResponseBodyWithResults(String address, String filters) {
        String encodedAddress = address.replace(' ', '%20');
        String jsonString = 
        '{' +
            '"header": {' +
            '"uri": "https://api.os.uk/search/places/v1/find?query={0}&key={1}&maxresults=5&minmatch=0.8&lr=EN",' +
            '"query": "postcode={2}",' +
            '"offset": 0,' +
            '"totalresults": 2,' +
            '"format": "JSON",' +
            '"dataset": "DPA",' +
            '"lr": "EN,CY",' +
            '"maxresults": 100,' +
            '"epoch": "119",' +
            '"lastupdate": "2025-07-23",' +
            '"output_srs": "EPSG:27700"' +
            '},' +
            '"results": [' +
                '{' +
                    '"DPA": {' +
                        '"UPRN": "1111111111",' +
                        '"UDPRN": "123123123",' +
                        '"ADDRESS": "FLAT 1, ROAD XYZ, LONDON, {2}",' +
                        '"THOROUGHFARE_NAME": "ROAD XYZ",' +
                        '"POST_TOWN": "LONDON",' +
                        '"POSTCODE": "{2}",' +
                        '"RPC": "2",' +
                        '"STATUS": "APPROVED",' +
                        '"LOGICAL_STATUS_CODE": "1",' +
                        '"COUNTRY_CODE": "E",' +
                        '"COUNTRY_CODE_DESCRIPTION": "This record is within England",' +
                        '"POSTAL_ADDRESS_CODE": "D",' +
                        '"POSTAL_ADDRESS_CODE_DESCRIPTION": "A record which is linked to PAF",' +
                        '"BLPU_STATE_CODE_DESCRIPTION": "In use",' +
                        '"LAST_UPDATE_DATE": "13/11/2024",' +
                        '"ENTRY_DATE": "16/09/2009",' +
                        '"BLPU_STATE_DATE": "16/09/2009",' +
                        '"LANGUAGE": "EN",' +
                        '"MATCH": 0.8,' +
                        '"MATCH_DESCRIPTION": "EXACT",' +
                        '"DELIVERY_POINT_SUFFIX": "1A"' +
                    '}' +
                '},' +
                '{' +
                    '"DPA": {' +
                        '"UPRN": "2222222222",' +
                        '"UDPRN": "123123123",' +
                        '"ADDRESS": "FLAT 2, ROAD XYZ, LONDON, {2}",' +
                        '"THOROUGHFARE_NAME": "ROAD XYZ",' +
                        '"POST_TOWN": "LONDON",' +
                        '"POSTCODE": "{2}",' +
                        '"RPC": "2",' +
                        '"STATUS": "APPROVED",' +
                        '"LOGICAL_STATUS_CODE": "1",' +
                        '"COUNTRY_CODE": "E",' +
                        '"COUNTRY_CODE_DESCRIPTION": "This record is within England",' +
                        '"POSTAL_ADDRESS_CODE": "D",' +
                        '"POSTAL_ADDRESS_CODE_DESCRIPTION": "A record which is linked to PAF",' +
                        '"BLPU_STATE_CODE_DESCRIPTION": "In use",' +
                        '"LAST_UPDATE_DATE": "13/11/2024",' +
                        '"ENTRY_DATE": "16/09/2009",' +
                        '"BLPU_STATE_DATE": "16/09/2009",' +
                        '"LANGUAGE": "EN",' +
                        '"MATCH": 1.0,' +
                        '"MATCH_DESCRIPTION": "EXACT",' +
                        '"DELIVERY_POINT_SUFFIX": "1A"' +
                    '}' +
                '}' +
            ']' +
        '}';
        return jsonString.replace('{0}', encodedAddress).replace('{1}', filters).replace('{2}', address);
    }
}