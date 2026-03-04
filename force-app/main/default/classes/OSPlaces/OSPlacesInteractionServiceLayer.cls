public with sharing class OSPlacesInteractionServiceLayer implements OSPlacesInteractionService.API{
    final static digitalmodus.SystemLogService errorLoggingService = new digitalmodus.SystemLogService('OSPlacesInteractionServiceLayer');

    @TestVisible
    private static OSPlacesInteractionService.API instance;

    private final String API_KEY;

    private final String POSTCODE_ENDPOINT = 'https://api.os.uk/search/places/v1/postcode?postcode={0}&key={1}&lr=EN';
    private final String FIND_ENDPOINT = 'https://api.os.uk/search/places/v1/find?query={0}&key={1}&maxresults=5&minmatch=0.8&lr=EN';

    public static OSPlacesInteractionService.API getInstance() {
        if(instance == null) {
            instance = new OSPlacesInteractionServiceLayer();
        } 
        return instance;
    }

    public OSPlacesInteractionServiceLayer(String doNotUse) {
        throw new Exceptions.MockConstructorOnlyException('Constructor only used for mocking, due to Stub API limitations.');
    }

    private OSPlacesInteractionServiceLayer() {
        API_KEY = new CustomSettingsService().getOSPlacesAPIKey();
    }

    public List<DeliveryPointAddress> getInformationByPostcode(String postCode) {
        List<DeliveryPointAddress> deliveryPointAddressesToReturn = new List<DeliveryPointAddress>();
        if(String.isBlank(postCode)) {
            return deliveryPointAddressesToReturn;
        }
        try {
            deliveryPointAddressesToReturn = processData(sendRequest(getPostCodeEndPoint(postCode)));
        } catch (Exception ex) {
            errorLoggingService.setLogCode('OSPlacesInteractionServiceLayer')
                .setTriggeringAutomationName('getInformationByPostcode')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return deliveryPointAddressesToReturn;
    }

    public List<DeliveryPointAddress> getInformationByPostcodeForEnglandOrWalesOnly(String postCode) {
        List<DeliveryPointAddress> deliveryPointAddressesToReturn = new List<DeliveryPointAddress>();
        if(String.isBlank(postCode)) {
            return deliveryPointAddressesToReturn;
        }
        try {
           deliveryPointAddressesToReturn = processData(sendRequest(getPostCodeEndPointWithFilters(postCode, '&fq=COUNTRY_CODE:E COUNTRY_CODE:W')));
        } catch (Exception ex) {
            errorLoggingService.setLogCode('OSPlacesInteractionServiceLayer')
                .setTriggeringAutomationName('getInformationByPostcodeForEnglandOrWalesOnly')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return deliveryPointAddressesToReturn;
    }

    public List<DeliveryPointAddress> matchAddressForEnglandOrWalesOnly(String address) {
        List<DeliveryPointAddress> deliveryPointAddressesToReturn = new List<DeliveryPointAddress>();
        if(String.isBlank(address)) {
            return new List<DeliveryPointAddress>();
        }
        try {
            String filters = '&fq=COUNTRY_CODE:E COUNTRY_CODE:W';
            String formattedQuery = String.format(FIND_ENDPOINT + filters, new List<String> { EncodingUtil.urlEncode(address, 'UTF-8'), API_KEY });
            deliveryPointAddressesToReturn = processMatchData(sendRequest(formattedQuery));
        } catch (Exception ex) {
            errorLoggingService.setLogCode('OSPlacesInteractionServiceLayer')
                .setTriggeringAutomationName('matchAddressForEnglandOrWalesOnly')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return deliveryPointAddressesToReturn;
    }

    private String getPostCodeEndPoint(String postCode) {
        return String.format(POSTCODE_ENDPOINT, new List<String> { EncodingUtil.urlEncode(postCode, 'UTF-8'), API_KEY });
    }

    private String getPostCodeEndPointWithFilters(String postCode, String filters) {
        return String.format(POSTCODE_ENDPOINT + filters, new List<String> { EncodingUtil.urlEncode(postCode, 'UTF-8'), API_KEY });
    }

    private String sendRequest(String endPoint) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endPoint);
        request.setMethod('GET');

        HttpResponse response = http.send(request);
        String responseBody;
        if (response.getStatusCode() == 200) {
            responseBody = response.getBody();
        } else {
            throw new Exceptions.OSPlacesException(response.getStatus());
        }
        return responseBody;
    }

    private List<DeliveryPointAddress> processData(String jsonInput) {
        return AddressDataProcessor.processAddressData(jsonInput);
    }

    private List<DeliveryPointAddress> processMatchData(String jsonInput) {
        return AddressDataProcessor.processMatchData(jsonInput);
    }
}