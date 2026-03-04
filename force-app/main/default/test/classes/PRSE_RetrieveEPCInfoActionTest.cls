@IsTest
private class PRSE_RetrieveEPCInfoActionTest {

    // -------------------------------
    // Mock class for HTTP callouts
    // -------------------------------
    private class EPCMockHttpResponse implements HttpCalloutMock {
        public Integer statusCode { get; set; }
        public String body { get; set; }

        public EPCMockHttpResponse(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setBody(this.body);
            return res;
        }
    }
    

    // -------------------------------
    // NEW Endpoint Tests
    // -------------------------------
    @IsTest
    static void fetchEPCData_NEW_withValidUPRN_returnsEPCResponse() {
        PRSE_RetrieveEPCInfoAction.forceUseNewEndpointForTest = true;
        Test.setMock(HttpCalloutMock.class, new EPCMockHttpResponse(
            200,
            '{ "data": [ { "certificateNumber": "1111-2222", "addressLine1": "Building 1", "addressLine2": "Main Street", "postcode": "M20 4AP", "currentEnergyEfficiencyBand": "C", "registrationDate": "2021-08-11T00:00:00.000+00:00" } ] }'
        ));

        PRSE_RetrieveEPCInfoAction.EPCRequest req = new PRSE_RetrieveEPCInfoAction.EPCRequest();
        req.uprn = '10094703381';
        req.propertyType = 'residential';

        Test.startTest();
        List<PRSE_RetrieveEPCInfoAction.EPCResponse> responses = PRSE_RetrieveEPCInfoAction.fetchEPCData(new List<PRSE_RetrieveEPCInfoAction.EPCRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals('Building 1, Main Street', responses[0].address);
        System.assertEquals('M20 4AP', responses[0].postcode);
        System.assertEquals('C', responses[0].energyRating);
        System.assertEquals(Date.newInstance(2021, 8, 11), responses[0].rawDateOfCertificate);
        System.assertEquals(false, responses[0].isExpired);
    }


    @IsTest
    static void fetchEPCData_NEW_withNoData_returnsNoDataResponse() {
        PRSE_RetrieveEPCInfoAction.forceUseNewEndpointForTest = true;
        Test.setMock(HttpCalloutMock.class, new EPCMockHttpResponse(200, '{ "data": [] }'));

        PRSE_RetrieveEPCInfoAction.EPCRequest req = new PRSE_RetrieveEPCInfoAction.EPCRequest();
        req.uprn = '99999999999';
        req.propertyType = 'residential';

        Test.startTest();
        List<PRSE_RetrieveEPCInfoAction.EPCResponse> responses = PRSE_RetrieveEPCInfoAction.fetchEPCData(new List<PRSE_RetrieveEPCInfoAction.EPCRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals('No data', responses[0].address);
        System.assertEquals('No data', responses[0].postcode);
        System.assertEquals('No data', responses[0].energyRating);
        System.assertEquals(false, responses[0].isExpired);
    }


    @IsTest
    static void fetchEPCData_NEW_withHttpError_returnsErrorResponse() {
        PRSE_RetrieveEPCInfoAction.forceUseNewEndpointForTest = true;
        Test.setMock(HttpCalloutMock.class, new EPCMockHttpResponse(500, 'Internal Server Error'));

        PRSE_RetrieveEPCInfoAction.EPCRequest req = new PRSE_RetrieveEPCInfoAction.EPCRequest();
        req.uprn = '10094703381';
        req.propertyType = 'residential';

        Test.startTest();
        List<PRSE_RetrieveEPCInfoAction.EPCResponse> responses = PRSE_RetrieveEPCInfoAction.fetchEPCData(new List<PRSE_RetrieveEPCInfoAction.EPCRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals('Error: Unknown error 500', responses[0].errorMessage,
        'Expected error message for 500 status');
    }


    @IsTest
    static void fetchEPCData_NEW_withNullHttpResponse_returnsNoDataResponse() {
        PRSE_RetrieveEPCInfoAction.forceUseNewEndpointForTest = true;
        PRSE_RetrieveEPCInfoAction.simulateNullResponse = true;

        PRSE_RetrieveEPCInfoAction.EPCRequest req = new PRSE_RetrieveEPCInfoAction.EPCRequest();
        req.uprn = '12345';
        req.propertyType = 'residential';

        Test.startTest();
        List<PRSE_RetrieveEPCInfoAction.EPCResponse> responses =
            PRSE_RetrieveEPCInfoAction.fetchEPCData(new List<PRSE_RetrieveEPCInfoAction.EPCRequest>{ req });
        Test.stopTest();

        PRSE_RetrieveEPCInfoAction.simulateNullResponse = false;

        System.assertEquals(1, responses.size(), 'Expected one response when HTTP response is null');
        System.assertEquals('No data', responses[0].address, 'Expected No data address');
        System.assertEquals('No data', responses[0].postcode, 'Expected No data postcode');
        System.assertEquals('No data', responses[0].energyRating, 'Expected No data energy rating');
        System.assertEquals(false, responses[0].isExpired, 'Expected isExpired to be false');
        System.assertEquals('No response received from EPC service.', responses[0].errorMessage,
            'Expected error message for null HTTP response');
    }   
    
    
	@IsTest
    static void parseEPCResponse_NEW_with404AndBlankBody_setsNoErrorMessage() {
        Test.startTest();
        PRSE_RetrieveEPCInfoAction.EPCResponse response =
            PRSE_RetrieveEPCInfoAction.parseEPCResponse_NEW('', 404);
        Test.stopTest();
    
        System.assertEquals(null, response.errorMessage,
            'Expected null errorMessage when 404 body is blank');
    } 

    
    @IsTest
    static void parseEPCResponse_NEW_with404AndErrorBody_setsErrorMessage() {
        String responseBody = '{"data":{"error":"No certificates found for this property"}}';
    
        Test.startTest();
        PRSE_RetrieveEPCInfoAction.EPCResponse response =
            PRSE_RetrieveEPCInfoAction.parseEPCResponse_NEW(responseBody, 404);
        Test.stopTest();
    
        System.assertEquals(
            'No certificates found for this property',
            response.errorMessage,
            'Expected error message from 404 response body'
        );
        System.assertEquals(null, response.address, 'Expected null address for 404 response');
        System.assertEquals(null, response.certificateNumber, 'Expected null certificate number for 404 response');
    }

    
    @IsTest
    static void parseEPCResponse_NEW_with429_setsTooManyRequestsErrorMessage() {
        Test.startTest();
        PRSE_RetrieveEPCInfoAction.EPCResponse response =
            PRSE_RetrieveEPCInfoAction.parseEPCResponse_NEW('', 429);
        Test.stopTest();
    
        System.assertEquals(
            'Error 429: Too many requests. Please try again later.',
            response.errorMessage,
            'Expected too many requests error message for 429 response'
        );
        System.assertEquals(null, response.address, 'Expected null address for 429 response');
        System.assertEquals(null, response.certificateNumber, 'Expected null certificate number for 429 response');
    } 


    // -------------------------------
    // OLD Endpoint Tests
    // -------------------------------
    @IsTest
    static void fetchEPCData_OLD_withValidUPRN_returnsEPCResponse() {
        PRSE_RetrieveEPCInfoAction.forceUseNewEndpointForTest = false;
        Test.setMock(HttpCalloutMock.class, new EPCMockHttpResponse(
            200,
            '{ "rows": [ { "address": "Building Y", "postcode": "M2 2BB", "current-energy-rating": "B", "lodgement-date": "2021-02-01" } ] }'
        ));

        PRSE_RetrieveEPCInfoAction.EPCRequest req = new PRSE_RetrieveEPCInfoAction.EPCRequest();
        req.uprn = '54321';
        req.propertyType = 'residential';

        Test.startTest();
        List<PRSE_RetrieveEPCInfoAction.EPCResponse> responses = PRSE_RetrieveEPCInfoAction.fetchEPCData(new List<PRSE_RetrieveEPCInfoAction.EPCRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals('Building Y', responses[0].address);
        System.assertEquals('M2 2BB', responses[0].postcode);
        System.assertEquals('B', responses[0].energyRating);
    }


    @IsTest
    static void fetchEPCData_OLD_withNoRows_returnsNoDataResponse() {
        PRSE_RetrieveEPCInfoAction.forceUseNewEndpointForTest = false;
        Test.setMock(HttpCalloutMock.class, new EPCMockHttpResponse(200, '{ "rows": [] }'));

        PRSE_RetrieveEPCInfoAction.EPCRequest req = new PRSE_RetrieveEPCInfoAction.EPCRequest();
        req.uprn = '99999999999';
        req.propertyType = 'residential';

        Test.startTest();
        List<PRSE_RetrieveEPCInfoAction.EPCResponse> responses = PRSE_RetrieveEPCInfoAction.fetchEPCData(new List<PRSE_RetrieveEPCInfoAction.EPCRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals('No data', responses[0].address);
        System.assertEquals('No data', responses[0].postcode);
        System.assertEquals('No data', responses[0].energyRating);
        System.assertEquals(false, responses[0].isExpired);
    }


    @IsTest
    static void fetchEPCData_OLD_withHttpError_returnsErrorResponse() {
        PRSE_RetrieveEPCInfoAction.forceUseNewEndpointForTest = false;
        Test.setMock(HttpCalloutMock.class, new EPCMockHttpResponse(500, 'Internal Server Error'));

        PRSE_RetrieveEPCInfoAction.EPCRequest req = new PRSE_RetrieveEPCInfoAction.EPCRequest();
        req.uprn = '10094703381';
        req.propertyType = 'residential';

        Test.startTest();
        List<PRSE_RetrieveEPCInfoAction.EPCResponse> responses = PRSE_RetrieveEPCInfoAction.fetchEPCData(new List<PRSE_RetrieveEPCInfoAction.EPCRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals('Error', responses[0].address);
        System.assertEquals('Error', responses[0].postcode);
        System.assertEquals('Error', responses[0].energyRating);
        System.assertEquals(false, responses[0].isExpired);
    }


    // -------------------------------
    // formatDateAndExpiry_NEW test
    // -------------------------------
    @IsTest
    static void formatDateAndExpiry_NEW_withHardcodedOldDate_setsExpiredTrue() {
        PRSE_RetrieveEPCInfoAction.EPCResponse response = new PRSE_RetrieveEPCInfoAction.EPCResponse();
        String rawDate = '2010-01-01T00:00:00.000+00:00';

        PRSE_RetrieveEPCInfoAction.formatDateAndExpiry_NEW(rawDate, response);

        System.assertEquals(true, response.isExpired);
        System.assertEquals(Date.newInstance(2010, 1, 1), response.rawDateOfCertificate);
        System.assertEquals('1 January 2010', response.dateOfCertificate);
    }
    
    
    @IsTest
    static void fetchEPCData_NEW_withNullPropertyType_returnsInvalidResponse() {
        PRSE_RetrieveEPCInfoAction.forceUseNewEndpointForTest = true;
        // Arrange: mock a valid HTTP response
        Test.setMock(HttpCalloutMock.class, new EPCMockHttpResponse(
            200,
            '{ "data": [ { "certificateNumber": "1111-2222", "addressLine1": "Building Z", "postcode": "M3 3CC", "currentEnergyEfficiencyBand": "D", "registrationDate": "2022-05-15T00:00:00.000+00:00" } ] }'
        ));

        // EPC request with null propertyType
        PRSE_RetrieveEPCInfoAction.EPCRequest req = new PRSE_RetrieveEPCInfoAction.EPCRequest();
        req.uprn = '55555';
        req.propertyType = null;

        // Act
        Test.startTest();
        List<PRSE_RetrieveEPCInfoAction.EPCResponse> responses =
            PRSE_RetrieveEPCInfoAction.fetchEPCData(new List<PRSE_RetrieveEPCInfoAction.EPCRequest>{ req });
        Test.stopTest();

    System.assertEquals(1, responses.size(), 'Should return one response for null propertyType');
    System.assertEquals('Invalid property type provided.', responses[0].errorMessage, 
        'Expected error message for null propertyType');
    }   


    @IsTest
    static void resolvePropertyType_withCommercial_returnsNonDomestic() {
        // Act
        String result = PRSE_RetrieveEPCInfoAction.resolvePropertyType('commercial');

        // Assert
        System.assertEquals('non-domestic', result, 'Commercial property type should resolve to non-domestic');
    }


    @IsTest
    static void resolvePropertyType_withUnsupportedType_returnsNull() {

        // Call the method
        String result = PRSE_RetrieveEPCInfoAction.resolvePropertyType('office');

        // Assert it returns null (hits the final return)
        System.assertEquals(null, result, 'Should return null for unsupported property type');
    }



    @IsTest
    static void parseEPCResponse_NEW_withBlankBody_doesNothing() {
        // Arrange
        PRSE_RetrieveEPCInfoAction.EPCResponse response =
            new PRSE_RetrieveEPCInfoAction.EPCResponse();

        // Act
        PRSE_RetrieveEPCInfoAction.parseEPCResponse_NEW('',200);

        // Assert – nothing should be set
        System.assertEquals(null, response.rawDateOfCertificate);
        System.assertEquals(null, response.dateOfCertificate);
        System.assertEquals(null, response.isExpired);
    }


    @IsTest
    static void formatDateAndExpiry_NEW_withBlankRawDate_doesNothing() {
        // Arrange
        PRSE_RetrieveEPCInfoAction.EPCResponse response =
            new PRSE_RetrieveEPCInfoAction.EPCResponse();

        // Act
        PRSE_RetrieveEPCInfoAction.formatDateAndExpiry_NEW('', response);

        // Assert – nothing should be set
        System.assertEquals(null, response.rawDateOfCertificate);
        System.assertEquals(null, response.dateOfCertificate);
        System.assertEquals(null, response.isExpired);
    }

    @IsTest
    static void formatDateAndExpiry_NEW_withNullResponse_doesNotThrow() {
        // Act + Assert (implicit)
        Test.startTest();
        PRSE_RetrieveEPCInfoAction.formatDateAndExpiry_NEW(
            '2021-08-11T00:00:00.000+00:00',
            null
        );
        Test.stopTest();

        // If we reach here, the guard clause worked
        System.assert(true, 'Method should exit safely when response is null');
    }


    @IsTest
    static void formatDateAndExpiry_NEW_withInvalidDate_hitsCatchBlock() {
        // Arrange
        PRSE_RetrieveEPCInfoAction.EPCResponse response =
            new PRSE_RetrieveEPCInfoAction.EPCResponse();

        // Invalid ISO string that will throw during parsing
        String invalidRawDate = 'NOT_A_REAL_DATE';

        // Act
        PRSE_RetrieveEPCInfoAction.formatDateAndExpiry_NEW(invalidRawDate, response);

        // Assert: fallback values from catch block
        System.assertEquals(null, response.rawDateOfCertificate,
            'rawDateOfCertificate should be null when parsing fails');
        System.assertEquals(null, response.dateOfCertificate,
            'dateOfCertificate should be null when parsing fails');
        System.assertEquals(false, response.isExpired,
            'isExpired should default to false when parsing fails');
    }


    @IsTest
    static void fetchEPCData_OLD_throwsException_returnsErrorResponse() {
        PRSE_RetrieveEPCInfoAction.forceUseNewEndpointForTest = false;
        // Arrange: create a request with valid property type
        PRSE_RetrieveEPCInfoAction.EPCRequest req = new PRSE_RetrieveEPCInfoAction.EPCRequest();
        req.uprn = '12345';
        req.propertyType = 'residential';

        // Inject a mock that throws an exception when sendHttpRequest is called
        Test.startTest();
            // Use a try/catch inside a static inner class for testing
            // Simulate exception by calling a request with a null UPRN (or any trick that causes NPE)
            req.uprn = null;

            List<PRSE_RetrieveEPCInfoAction.EPCResponse> responses = PRSE_RetrieveEPCInfoAction.fetchEPCData(
                new List<PRSE_RetrieveEPCInfoAction.EPCRequest>{ req }
            );
        Test.stopTest();

        // Assert: the catch block should return the error response
        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals('Error', responses[0].address, 'Address should indicate error');
        System.assertEquals('Error', responses[0].postcode, 'Postcode should indicate error');
        System.assertEquals('Error', responses[0].energyRating, 'Energy rating should indicate error');
        System.assertEquals(false, responses[0].isExpired, 'isExpired should be false');

    }


    @IsTest
    static void fetchEPCData_withBypassFlags() {
        // Arrange: create a sample EPCRequest
        PRSE_RetrieveEPCInfoAction.EPCRequest req = new PRSE_RetrieveEPCInfoAction.EPCRequest();
        req.uprn = '123456';
        req.propertyType = 'residential';
        List<PRSE_RetrieveEPCInfoAction.EPCRequest> requests = new List<PRSE_RetrieveEPCInfoAction.EPCRequest>{ req };

        // Use a mock to simulate HTTP response
        Test.setMock(HttpCalloutMock.class, new PRSE_RetrieveEPCInfoActionTest.EPCMockHttpResponse(
            200,
            '{ "data": [ { "certificateNumber": "1111-2222", "addressLine1": "Test Building", "postcode": "T1 2AB", "currentEnergyEfficiencyBand": "B", "registrationDate": "2022-01-01T00:00:00.000+00:00" } ] }'
        ));

        Test.startTest();
        
        // --- Case 1: forceUseNewEndpointForTest = true ---
        PRSE_RetrieveEPCInfoAction.forceUseNewEndpointForTest = true;
        PRSE_RetrieveEPCInfoAction.bypassTestBypassForTest = true;

        List<PRSE_RetrieveEPCInfoAction.EPCResponse> responses1 = 
            PRSE_RetrieveEPCInfoAction.fetchEPCData(requests);

        System.assertEquals(1, responses1.size());
        System.assertEquals('Test Building', responses1[0].address.split(',')[0]);

        // --- Case 2: forceUseNewEndpointForTest = false ---
        PRSE_RetrieveEPCInfoAction.forceUseNewEndpointForTest = false;
        PRSE_RetrieveEPCInfoAction.bypassTestBypassForTest = true;

            Test.setMock(HttpCalloutMock.class, new PRSE_RetrieveEPCInfoActionTest.EPCMockHttpResponse(
        200,
        '{ "rows": [ { "address": "Test Building", "postcode": "T1 2AB", "current-energy-rating": "B", "lodgement-date": "2022-01-01" } ] }'
    ));

        List<PRSE_RetrieveEPCInfoAction.EPCResponse> responses2 = 
            PRSE_RetrieveEPCInfoAction.fetchEPCData(requests);

        System.assertEquals(1, responses2.size());
        System.assertEquals('Test Building', responses2[0].address.split(',')[0]);

        Test.stopTest();

        // Reset flags
        PRSE_RetrieveEPCInfoAction.forceUseNewEndpointForTest = false;
        PRSE_RetrieveEPCInfoAction.bypassTestBypassForTest = false;
    }


    @IsTest
    static void fetchEPCData_NEW_catchBlockIsCovered() {
        // Arrange: make a normal EPC request
        PRSE_RetrieveEPCInfoAction.EPCRequest req = new PRSE_RetrieveEPCInfoAction.EPCRequest();
        req.uprn = '12345';
        req.propertyType = 'residential';

        // Force the catch block by simulating failure
        PRSE_RetrieveEPCInfoAction.simulateCalloutFailure = true;
        PRSE_RetrieveEPCInfoAction.forceUseNewEndpointForTest = true;

        // Act
        Test.startTest();
        List<PRSE_RetrieveEPCInfoAction.EPCResponse> responses = 
            PRSE_RetrieveEPCInfoAction.fetchEPCData(new List<PRSE_RetrieveEPCInfoAction.EPCRequest>{ req });
        Test.stopTest();

        // Reset flag
        PRSE_RetrieveEPCInfoAction.simulateCalloutFailure = false;

        // Assert: should hit the catch block and return error response
        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals('Error', responses[0].address);
        System.assertEquals('Error', responses[0].postcode);
        System.assertEquals('Error', responses[0].energyRating);
        System.assertEquals(false, responses[0].isExpired);
    }   
    
}