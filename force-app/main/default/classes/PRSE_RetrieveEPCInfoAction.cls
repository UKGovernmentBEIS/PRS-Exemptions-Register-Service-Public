/**
 * @description Retrieves Energy Performance Certificate (EPC) data for properties.
 *              Supports both new and old GOV EPC endpoints and handles exceptions gracefully.
 */
public class PRSE_RetrieveEPCInfoAction {
    /** System log service for capturing errors */
    final static digitalmodus.SystemLogService errorLoggingService = new digitalmodus.SystemLogService('PRSE_RetrieveEPCInfoAction');

    /** Test-visible flag to force use of the new EPC endpoint during tests */
    @TestVisible private static Boolean forceUseNewEndpointForTest = false;

    /** Test-visible flag to bypass the normal test endpoint selection */
    @TestVisible private static Boolean bypassTestBypassForTest = false;

    /** Test-visible flag to bypass the normal test endpoint selection */
    @TestVisible private static Boolean simulateNullResponse = false;

    /**
     * @description Encapsulates the input parameters for EPC data retrieval.
     */
    public class EPCRequest {
        /** Unique Property Reference Number */
        @InvocableVariable(label='UPRN' required=true)
        public String uprn;

        /** Property type: 'residential' or 'commercial' */
        @InvocableVariable(label='Property Type (residential or commercial)' required=true)
        public String propertyType;
    }

    /**
     * @description Represents EPC data returned from the API.
     */
    public class EPCResponse {
        /** Full property address */
        @InvocableVariable(label='Address')
        public String address;
        
        /** Property postcode */
        @InvocableVariable(label='Postcode')
        public String postcode;

        /** Energy efficiency rating */
        @InvocableVariable(label='Energy Rating')
        public String energyRating;

        /** Formatted date of the certificate */
        @InvocableVariable(label='Date of Certificate')
        public String dateOfCertificate;

        /** Raw date of the certificate */
        @InvocableVariable(label='Raw Date of Certificate')
        public Date rawDateOfCertificate;

        /** Flag indicating if the certificate is expired */
        @InvocableVariable(label='Is Expired')
        public Boolean isExpired;

        /** Certificate number */
        @InvocableVariable(label='Certificate Number')
        public String certificateNumber;

        /** Error message from API or callout */
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    /**
     * @description Main method to fetch EPC data for a list of requests.
     *              Chooses the correct endpoint based on configuration and test flags.
     * @param requests List of EPCRequest objects containing UPRN and property type.
     * @return List of EPCResponse objects with EPC data or error placeholders.
     */
    @InvocableMethod(
        label='Fetch EPC Data by UPRN'
        description='Returns EPC information for a given UPRN.'
        category='PRS Exemption Register'
    )
    public static List<EPCResponse> fetchEPCData(List<EPCRequest> requests) {
        if(Test.isRunningTest() && forceUseNewEndpointForTest && !bypassTestBypassForTest) {
            return fetchEPCData_NEW(requests);
        }

        if(Test.isRunningTest() && !forceUseNewEndpointForTest && !bypassTestBypassForTest) {
            return fetchEPCData_OLD(requests);
        }

        Boolean useNewGovEpcEndpoint = new CustomSettingsService().useNewGovEpcEndpoint();

        if(useNewGovEpcEndpoint || (Test.isRunningTest() && bypassTestBypassForTest && forceUseNewEndpointForTest)) {
            return fetchEPCData_NEW(requests);
        }

        if(!useNewGovEpcEndpoint || (Test.isRunningTest() && bypassTestBypassForTest && !forceUseNewEndpointForTest)) {
            return fetchEPCData_OLD(requests);  
        }

        // Everything else
        return fetchEPCData_OLD(requests); 
    }

    /**
     * @description Fetch EPC data from the new GOV EPC endpoint.
     * @param requests List of EPCRequest objects.
     * @return List of EPCResponse objects with API data or error placeholders.
     */
    public static List<EPCResponse> fetchEPCData_NEW(List<EPCRequest> requests) {
        //HTTP Status 429 means too many requests - need to handle this case properly in future
        List<EPCResponse> responses = new List<EPCResponse>();
        //EPCResponse errorResponse = new EPCResponse();
        try {
            for (EPCRequest req : requests) {
                 
                
                String propertyType = resolvePropertyType(req.propertyType);
                if (propertyType == null) {
                    EPCResponse invalidResponse = new EPCResponse();
                    invalidResponse.errorMessage = 'Invalid property type provided.';
                    responses.add(invalidResponse);
                    continue;
                }

                String endpoint = buildEndpoint_NEW(propertyType, req.uprn);
                HttpResponse httpResponse = sendHttpRequest_NEW(endpoint);

                if (httpResponse == null) {
                    EPCResponse emptyResponse = new EPCResponse();
                        emptyResponse.address = 'No data';
                        emptyResponse.postcode = 'No data';
                        emptyResponse.energyRating = 'No data';
                        emptyResponse.isExpired = false;
                        emptyResponse.errorMessage = 'No response received from EPC service.';
                        responses.add(emptyResponse);
                } else {
                    EPCResponse response = parseEPCResponse_NEW(httpResponse.getBody(),
                                                                httpResponse.getStatusCode()
                                                                );
                        if (response != null) {
                            responses.add(response);
                        } else {
                            EPCResponse emptyResponse = new EPCResponse();
                            emptyResponse.address = 'No data';
                            emptyResponse.postcode = 'No data';
                            emptyResponse.energyRating = 'No data';
                            emptyResponse.isExpired = false;
                            responses.add(emptyResponse);
                        }
                }                
            }
        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_RetrieveEPCInfoAction')
                .setTriggeringAutomationName('fetchEPCData')
                .setMessage(e.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();

            EPCResponse exceptionResponse = new EPCResponse();
            exceptionResponse.address = 'Error';
            exceptionResponse.postcode = 'Error';
            exceptionResponse.energyRating = 'Error';
            exceptionResponse.isExpired = false;
            responses.add(exceptionResponse);
        }

        return responses;
    }

    /**
     * @description Fetch EPC data from the old EPC endpoint using Basic Auth.
     * @param requests List of EPCRequest objects.
     * @return List of EPCResponse objects with API data or error placeholders.
     */
    public static List<EPCResponse> fetchEPCData_OLD(List<EPCRequest> requests) {
        List<EPCResponse> responses = new List<EPCResponse>();
        EPCResponse errorResponse = new EPCResponse();
        try {
            String authHeader = getAuthHeader();
            for (EPCRequest req : requests) {
                String propertyType = resolvePropertyType(req.propertyType);
                if (propertyType == null) {
                    continue;
                }
                String endpoint = buildEndpoint(propertyType, req.uprn);
                HttpResponse httpResponse = sendHttpRequest(endpoint, authHeader);

                if (httpResponse != null && httpResponse.getStatusCode() == 200) {
                    EPCResponse response = parseEPCResponse(httpResponse.getBody(), propertyType);
                    if (response != null) {
                        responses.add(response);
                    } else {
                        EPCResponse emptyResponse = new EPCResponse();
                        emptyResponse.address = 'No data';
                        emptyResponse.postcode = 'No data';
                        emptyResponse.energyRating = 'No data';
                        emptyResponse.isExpired = false;
                        responses.add(emptyResponse);
                    }
                } else {
                    errorResponse.address = 'Error';
                    errorResponse.postcode = 'Error';
                    errorResponse.energyRating = 'Error';
                    errorResponse.isExpired = false;
                    responses.add(errorResponse);

                    errorLoggingService.setLogCode('PRSE_RetrieveEPCInfoAction')
                        .setTriggeringAutomationName('fetchEPCData')
                        .setMessage(httpResponse.getStatus())
                        .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                        .publish();
                }
            }
        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_RetrieveEPCInfoAction')
                .setTriggeringAutomationName('fetchEPCData')
                .setMessage(e.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();

            errorResponse.address = 'Error';
            errorResponse.postcode = 'Error';
            errorResponse.energyRating = 'Error';
            errorResponse.isExpired = false;
            responses.add(errorResponse);
        }
        return responses;
    }

    /**
     * @description Maps the input property type to the endpoint type.
     * @param inputType 'residential' or 'commercial'
     * @return 'domestic' or 'non-domestic' or null if input invalid
     */
    @TestVisible
    private static String resolvePropertyType(String inputType) {
        if (inputType == null) {
            return null;
        }
        String lowerType = inputType.toLowerCase();
        if (lowerType == 'residential') {
            return 'domestic';
        }
        if (lowerType == 'commercial') {
            return 'non-domestic';
        }
        return null;
    }

    /**
     * @description Returns authorization header for old EPC endpoint.
     * @return Base64-encoded Basic Auth header
     */
    private static String getAuthHeader() {
        if (Test.isRunningTest()) {
            return 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf('dummyuser:dummypassword'));
        }
        String username = new CustomSettingsService().getEPCAPIUsername();
        String apiKey = new CustomSettingsService().getEPCAPIKey();
        return 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + apiKey));
    }

    /**
     * @description Builds endpoint URL for old EPC API.
     * @param propertyType Endpoint property type
     * @param uprn Unique Property Reference Number
     * @return Full endpoint URL
     */
    private static String buildEndpoint(String propertyType, String uprn) {
        return 'https://epc.opendatacommunities.org/api/v1/' + propertyType + '/search?uprn=' + uprn;
    }

    /**
     * @description Sends HTTP GET request to old EPC endpoint.
     * @param endpoint Endpoint URL
     * @param authHeader Basic Auth header
     * @return HttpResponse object
     */
    private static HttpResponse sendHttpRequest(String endpoint, String authHeader) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Authorization', authHeader);
        request.setHeader('Accept', 'application/json');

        Http http = new Http();
        return http.send(request);
    }

    /**
     * @description Parses EPC response JSON from old endpoint.
     * @param responseBody JSON string
     * @param propertyType 'domestic' or 'non-domestic'
     * @return EPCResponse object or null if no rows
     */
    @TestVisible
    private static EPCResponse parseEPCResponse(String responseBody, String propertyType) {
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        List<Object> rows = (List<Object>) jsonResponse.get('rows');

        if (rows.isEmpty()) {
            return null;
        }

        Map<String, Object> firstRow = (Map<String, Object>) rows[0];
        EPCResponse response = new EPCResponse();
        response.address = (String) firstRow.get('address');
        response.postcode = (String) firstRow.get('postcode');

        response.energyRating = propertyType == 'domestic' ? (String) firstRow.get('current-energy-rating') : (String) firstRow.get('asset-rating-band');
        
        String rawDate = (String) firstRow.get('lodgement-date');        
        formatDateAndExpiry(rawDate, response);

        return response;
    }

    /**
     * @description Formats a raw date string and sets the expiry flag.
     * @param rawDate Raw date in 'YYYY-MM-DD' format
     * @param response EPCResponse object to populate
     */
    @TestVisible
    private static void formatDateAndExpiry(String rawDate, EPCResponse response) {
        Date parsedDate = Date.valueOf(rawDate);
        response.rawDateOfCertificate = parsedDate;

        List<String> monthNames = new List<String>{
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        };

        response.dateOfCertificate = parsedDate.day() + ' ' +
            monthNames[parsedDate.month() - 1] + ' ' +
            parsedDate.year();

        Date today = Date.today();
        Integer yearsDifference = today.year() - parsedDate.year();
        Boolean expired = yearsDifference > 10 ||
            (yearsDifference == 10 && today.month() >= parsedDate.month() && today.day() >= parsedDate.day());

        response.isExpired = expired;
    }

    /**
     * @description Builds endpoint URL for the new EPC API using Named Credential.
     * @param propertyType Property type
     * @param uprn Unique Property Reference Number
     * @return Full endpoint URL
     */
    private static String buildEndpoint_NEW(String propertyType, String uprn) {
        String typePath = propertyType != null ? propertyType.toLowerCase() : 'domestic';
        String encodedUprn = EncodingUtil.urlEncode(uprn, 'UTF-8');
        return 'callout:EPC_GOV_API/api/' + typePath + '/search?uprn=' + encodedUprn;
    }

    /** Test-visible flag to simulate a callout failure */
    @TestVisible
    private static Boolean simulateCalloutFailure = false;

    /**
     * @description Sends HTTP GET request to the new EPC endpoint.
     *              Can simulate callout failure for testing.
     * @param endpoint Endpoint URL
     * @return HttpResponse object
     * @throws CalloutException when simulateCalloutFailure=true
     */
    private static HttpResponse sendHttpRequest_NEW(String endpoint) {
        if (Test.isRunningTest() && simulateCalloutFailure) {
            throw new CalloutException('Simulated callout failure');
        }
        if (Test.isRunningTest() && simulateNullResponse) {
            return null;
        }

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Accept', 'application/json');

        Http http = new Http();
        return http.send(request);
    }

    /**
     * @description Parses EPC response JSON from new endpoint.
     * @param responseBody JSON string
     * @return EPCResponse object or null if no data
     */
    @TestVisible
    private static EPCResponse parseEPCResponse_NEW(String responseBody, Integer httpStatusCode) {

        EPCResponse response = new EPCResponse();

        if (httpStatusCode == 200) {

            if (String.isBlank(responseBody)) {
                return null;
            }

            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            List<Object> dataRows = (List<Object>) jsonResponse.get('data');

            if (dataRows == null || dataRows.isEmpty()) {
                return null;
            }

            Map<String, Object> firstRow = (Map<String, Object>) dataRows[0];

            List<String> addressParts = new List<String>();
            for (Integer i = 1; i <= 4; i++) {
                String line = (String) firstRow.get('addressLine' + i);
                if (!String.isBlank(line)) {
                    addressParts.add(line);
                }
            }
            response.address = String.join(addressParts, ', ');
            response.postcode = (String) firstRow.get('postcode');
            response.energyRating = (String) firstRow.get('currentEnergyEfficiencyBand');
            response.certificateNumber = (String) firstRow.get('certificateNumber');

            String rawDate = (String) firstRow.get('registrationDate');
            formatDateAndExpiry_NEW(rawDate, response);

        } else if (httpStatusCode == 404) {
            // Handle "No certificates found" error
            if (!String.isBlank(responseBody)) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                Map<String, Object> dataMap = (Map<String, Object>) jsonResponse.get('data');
                if (dataMap != null && dataMap.containsKey('error')) {
                    response.errorMessage = (String) dataMap.get('error');
                }
            }
        } else if (httpStatusCode == 429) {
            // Too many requests
            response.errorMessage = 'Error 429: Too many requests. Please try again later.';
        } else {
            response.errorMessage = 'Error: Unknown error '+httpStatusCode;    
        }

        return response;
    }

    /**
     * @description Formats a raw date string from the new EPC endpoint and sets the expiry flag.
     * @param rawDate Raw date in ISO 8601 format
     * @param response EPCResponse object to populate
     */
    @TestVisible
    private static void formatDateAndExpiry_NEW(String rawDate, EPCResponse response) {
        if (String.isBlank(rawDate) || response == null) {
            return;
        }

        try {
            Date parsedDate;

            if (rawDate.contains('T')) {
                Datetime dt = Datetime.valueOfGmt(rawDate.replace('T', ' ').substring(0, 19));
                parsedDate = dt.date();
            } else {
                parsedDate = Date.valueOf(rawDate);
            }
            response.rawDateOfCertificate = parsedDate;

            List<String> monthNames = new List<String>{
                'January','February','March','April','May','June',
                'July','August','September','October','November','December'
            };
            response.dateOfCertificate = parsedDate.day() + ' ' +
                monthNames[parsedDate.month() - 1] + ' ' +
                parsedDate.year();

            Date today = Date.today();
            Integer yearsDiff = today.year() - parsedDate.year();
            Boolean expired = yearsDiff > 10 ||
                (yearsDiff == 10 && (today.month() > parsedDate.month() || (today.month() == parsedDate.month() && today.day() >= parsedDate.day())));
            response.isExpired = expired;

        } catch (Exception e) {
            response.rawDateOfCertificate = null;
            response.dateOfCertificate = null;
            response.isExpired = false;
        }
    }

}