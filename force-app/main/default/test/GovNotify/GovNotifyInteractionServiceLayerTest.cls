@isTest(IsParallel=true)
private class GovNotifyInteractionServiceLayerTest {

    private static String expectedEmailEndpoint = 'https://api.notifications.service.gov.uk/v2/notifications/email';
    private static String expectedSmsEndpoint = 'https://api.notifications.service.gov.uk/v2/notifications/sms';
    private static String expectedLetterEndpoint = 'https://api.notifications.service.gov.uk/v2/notifications/letter';
    //This is a dummy API key and is not valid for any real interactions with the Notify service. It is only used for testing purposes to ensure that the code can handle a valid API key format.
    private static String validAPIKey = 'my_test_key-26785a09-ab16-4eb0-8407-a37497a57506-3d844edf-8d35-48ac-975b-e847b4f122b0';

    @isTest
    static void getInstance_withMissingAPIKey_throwsException() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setGovNotifyAPIKey(null);
        CustomSettingsServiceLayer.instance = customSettingsMock;

        try {
            //Act
            GovNotifyInteractionServiceLayer.getInstance();
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            //Assert
            Assert.isTrue(ex instanceof System.IllegalArgumentException, 'Incorrect exception type thrown.');
            Assert.areEqual('Missing API key.', ex.getMessage(), 'Incorrect exception message thrown');
        }
    }

    @isTest
    static void getInstance_withInvalidAPIKey_throwsException() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        try {
            //Act
            GovNotifyInteractionServiceLayer.getInstance();
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            //Assert
            Assert.isTrue(ex instanceof System.IllegalArgumentException, 'Incorrect exception type thrown.');
            Assert.areEqual('Invalid API key format.', ex.getMessage(), 'Incorrect exception message thrown');
        }
    }

    @isTest
    static void getInstance_withShorterInvalidAPIKey_throwsException() {
        //Arrange
        String shorterApiKey = 'my_test_key-26785a09-ab16';
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setGovNotifyAPIKey(shorterApiKey);
        CustomSettingsServiceLayer.instance = customSettingsMock;

        try {
            //Act
            GovNotifyInteractionServiceLayer.getInstance();
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            //Assert
            Assert.isTrue(ex instanceof System.IllegalArgumentException, 'Incorrect exception type thrown.');
            Assert.areEqual('Invalid API key format.', ex.getMessage(), 'Incorrect exception message thrown');
        }
    }

    @isTest
    static void getInstance_withLongerInvalidAPIKey_throwsException() {
        //Arrange
        String longerApiKey = 'my_test_key-26785a09-ab16-4eb0-8407-a37497a57506-3d844edf-8d35-48ac-975b-e847b4f122b0-8d35-48ac-975b-e847b4f122b0';
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setGovNotifyAPIKey(longerApiKey);
        CustomSettingsServiceLayer.instance = customSettingsMock;

        try {
            //Act
            GovNotifyInteractionServiceLayer.getInstance();
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            //Assert
            Assert.isTrue(ex instanceof System.IllegalArgumentException, 'Incorrect exception type thrown.');
            Assert.areEqual('Invalid API key format.', ex.getMessage(), 'Incorrect exception message thrown');
        }
    }
    
    //Email
    @isTest
    static void sendEmail_requestWithoutPersonalisation_returnsResponse() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setGovNotifyAPIKey(validAPIKey);
        CustomSettingsServiceLayer.instance = customSettingsMock;

        GovNotifyInteractionService.NotifyRequest singleRequest = new GovNotifyInteractionService.NotifyRequest();
        singleRequest.templateId = '4442133123';
        singleRequest.email = 'test@test.com';
        Test.setMock(HttpCalloutMock.class, new EmailHttpResponseMock(singleRequest, 201, '{failed}'));

        //Act
        GovNotifyInteractionService.NotifyResponse response = GovNotifyInteractionServiceLayer.getInstance().sendEmail(singleRequest);

        //Assert
        Assert.isNotNull(response, 'Expected Response to be returned.');
        Assert.areEqual('Success', response.status, 'Incorrect status returned');
        Assert.areEqual('Notification sent successfully.', response.message, 'Incorrect message returned');
    }

    @isTest
    static void sendEmail_requestWithPersonalisation_returnsResponse() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setGovNotifyAPIKey(validAPIKey);
        CustomSettingsServiceLayer.instance = customSettingsMock;

        Map<String, String> personalisation = new Map<String, String>();
        personalisation.put('first name', 'test');
        personalisation.put('url', 'www.google.com');
        GovNotifyInteractionService.NotifyRequest singleRequest = new GovNotifyInteractionService.NotifyRequest();
        singleRequest.templateId = '4442133123';
        singleRequest.email = 'test@test.com';
        singleRequest.personalisationJson = JSON.serialize(personalisation);
        Test.setMock(HttpCalloutMock.class, new EmailHttpResponseMock(singleRequest, 201, '{failed}'));

        //Act
        GovNotifyInteractionService.NotifyResponse response = GovNotifyInteractionServiceLayer.getInstance().sendEmail(singleRequest);

        //Assert
        Assert.isNotNull(response, 'Expected Response to be returned.');
        Assert.areEqual('Success', response.status, 'Incorrect status returned');
        Assert.areEqual('Notification sent successfully.', response.message, 'Incorrect message returned');
    }

    @isTest
    static void sendEmail_withValidRequestButStatus300Return_returnsResponseWithError() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setGovNotifyAPIKey(validAPIKey);
        CustomSettingsServiceLayer.instance = customSettingsMock;

        GovNotifyInteractionService.NotifyRequest singleRequest = new GovNotifyInteractionService.NotifyRequest();
        singleRequest.templateId = '4442133123';
        singleRequest.email = 'test@test.com';
        Integer statusCode = 300;
        String errorBody = '{failed}';
        Test.setMock(HttpCalloutMock.class, new EmailHttpResponseMock(singleRequest, statusCode, errorBody));

        //Act
        GovNotifyInteractionService.NotifyResponse response = GovNotifyInteractionServiceLayer.getInstance().sendEmail(singleRequest);

        //Assert
        Assert.isNotNull(response, 'Expected Response to be returned.');
        Assert.areEqual('Error', response.status, 'Incorrect status returned');
        String expectedErrorMessage = 'Failed with status code: ' + statusCode + ' - ' + errorBody;
        Assert.areEqual(expectedErrorMessage, response.message, 'Incorrect message returned');
    }
    
    //SMS
    @isTest
    static void sendSms_requestWithoutPersonalisation_returnsResponse() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setGovNotifyAPIKey(validAPIKey);
        CustomSettingsServiceLayer.instance = customSettingsMock;

        GovNotifyInteractionService.SmsRequest singleRequest = new GovNotifyInteractionService.SmsRequest();
        singleRequest.templateId = '4442133123';
        singleRequest.phoneNumber = '+447700900123';
        Test.setMock(HttpCalloutMock.class, new SmsHttpResponseMock(singleRequest, 201, '{success}'));

        //Act
        GovNotifyInteractionService.NotifyResponse response = GovNotifyInteractionServiceLayer.getInstance().sendSms(singleRequest);

        //Assert
        Assert.isNotNull(response, 'Expected Response to be returned.');
        Assert.areEqual('Success', response.status, 'Incorrect status returned');
        Assert.areEqual('SMS notification sent successfully.', response.message, 'Incorrect message returned');
    }

    @isTest
    static void sendSms_requestWithPersonalisation_returnsResponse() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setGovNotifyAPIKey(validAPIKey);
        CustomSettingsServiceLayer.instance = customSettingsMock;

        Map<String, String> personalisation = new Map<String, String>();
        personalisation.put('name', 'test');
        personalisation.put('code', '123456');
        GovNotifyInteractionService.SmsRequest singleRequest = new GovNotifyInteractionService.SmsRequest();
        singleRequest.templateId = '4442133123';
        singleRequest.phoneNumber = '+447700900123';
        singleRequest.personalisationJson = JSON.serialize(personalisation);
        Test.setMock(HttpCalloutMock.class, new SmsHttpResponseMock(singleRequest, 201, '{success}'));

        //Act
        GovNotifyInteractionService.NotifyResponse response = GovNotifyInteractionServiceLayer.getInstance().sendSms(singleRequest);

        //Assert
        Assert.isNotNull(response, 'Expected Response to be returned.');
        Assert.areEqual('Success', response.status, 'Incorrect status returned');
        Assert.areEqual('SMS notification sent successfully.', response.message, 'Incorrect message returned');
    }

    @isTest
    static void sendSms_withValidRequestButStatus400Return_returnsResponseWithError() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setGovNotifyAPIKey(validAPIKey);
        CustomSettingsServiceLayer.instance = customSettingsMock;

        GovNotifyInteractionService.SmsRequest singleRequest = new GovNotifyInteractionService.SmsRequest();
        singleRequest.templateId = '4442133123';
        singleRequest.phoneNumber = '+447700900123';
        Integer statusCode = 400;
        String errorBody = '{invalid_phone}';
        Test.setMock(HttpCalloutMock.class, new SmsHttpResponseMock(singleRequest, statusCode, errorBody));

        //Act
        GovNotifyInteractionService.NotifyResponse response = GovNotifyInteractionServiceLayer.getInstance().sendSms(singleRequest);

        //Assert
        Assert.isNotNull(response, 'Expected Response to be returned.');
        Assert.areEqual('Error', response.status, 'Incorrect status returned');
        String expectedErrorMessage = 'Failed with status code: ' + statusCode + ' - ' + errorBody;
        Assert.areEqual(expectedErrorMessage, response.message, 'Incorrect message returned');
    }
    
    //Letter
    @isTest
    static void sendLetter_requestWithPersonalisation_returnsResponse() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setGovNotifyAPIKey(validAPIKey);
        CustomSettingsServiceLayer.instance = customSettingsMock;

        Map<String, String> personalisation = new Map<String, String>();
        personalisation.put('address_line_1', '123 Test Street');
        personalisation.put('address_line_2', 'Test Town');
        personalisation.put('postcode', 'TE1 1ST');
        GovNotifyInteractionService.LetterRequest singleRequest = new GovNotifyInteractionService.LetterRequest();
        singleRequest.templateId = '4442133123';
        singleRequest.personalisationJson = JSON.serialize(personalisation);
        Test.setMock(HttpCalloutMock.class, new LetterHttpResponseMock(singleRequest, 201, '{success}'));

        //Act
        GovNotifyInteractionService.NotifyResponse response = GovNotifyInteractionServiceLayer.getInstance().sendLetter(singleRequest);

        //Assert
        Assert.isNotNull(response, 'Expected Response to be returned.');
        Assert.areEqual('Success', response.status, 'Incorrect status returned');
        Assert.areEqual('Letter notification sent successfully.', response.message, 'Incorrect message returned');
    }

    @isTest
    static void sendLetter_withValidRequestButStatus500Return_returnsResponseWithError() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setGovNotifyAPIKey(validAPIKey);
        CustomSettingsServiceLayer.instance = customSettingsMock;

        Map<String, String> personalisation = new Map<String, String>();
        personalisation.put('address_line_1', '123 Test Street');
        GovNotifyInteractionService.LetterRequest singleRequest = new GovNotifyInteractionService.LetterRequest();
        singleRequest.templateId = '4442133123';
        singleRequest.personalisationJson = JSON.serialize(personalisation);
        Integer statusCode = 500;
        String errorBody = '{server_error}';
        Test.setMock(HttpCalloutMock.class, new LetterHttpResponseMock(singleRequest, statusCode, errorBody));

        //Act
        GovNotifyInteractionService.NotifyResponse response = GovNotifyInteractionServiceLayer.getInstance().sendLetter(singleRequest);

        //Assert
        Assert.isNotNull(response, 'Expected Response to be returned.');
        Assert.areEqual('Error', response.status, 'Incorrect status returned');
        String expectedErrorMessage = 'Failed with status code: ' + statusCode + ' - ' + errorBody;
        Assert.areEqual(expectedErrorMessage, response.message, 'Incorrect message returned');
    }

    private class EmailHttpResponseMock implements HttpCalloutMock {

        GovNotifyInteractionService.NotifyRequest notifyRequest;
        private Integer statusCode;
        private String responseBody;
        
        public EmailHttpResponseMock(GovNotifyInteractionService.NotifyRequest notifyRequest, Integer statusCode, String responseBody) {
            this.notifyRequest = notifyRequest;
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HTTPRequest request) {
            Map<String, Object> payload = new Map<String, Object> {
                'email_address' => notifyRequest.email,
                'template_id' => notifyRequest.templateId
            };
            if (notifyRequest.personalisationJson != null && notifyRequest.personalisationJson.trim() != '') {
                payload.put('personalisation', (Map<String, Object>)JSON.deserializeUntyped(notifyRequest.personalisationJson));
            }
            String expectedBody = JSON.serialize(payload);
            Assert.areEqual(expectedEmailEndpoint, request.getEndpoint(), 'Incorrect endpoint set');
            Assert.areEqual('POST', request.getMethod(), 'Incorrect method set');
            Assert.areEqual('application/json', request.getHeader('Content-Type'), 'Incorrect Content-Type header');
            Assert.areEqual(expectedBody, request.getBody(), 'Incorrect body passed to Notify');

            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(responseBody);
            return response;
        }
    }

    private class SmsHttpResponseMock implements HttpCalloutMock {

        GovNotifyInteractionService.SmsRequest smsRequest;
        private Integer statusCode;
        private String responseBody;
        
        public SmsHttpResponseMock(GovNotifyInteractionService.SmsRequest smsRequest, Integer statusCode, String responseBody) {
            this.smsRequest = smsRequest;
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HTTPRequest request) {
            Map<String, Object> payload = new Map<String, Object> {
                'phone_number' => smsRequest.phoneNumber,
                'template_id' => smsRequest.templateId
            };
            if (smsRequest.personalisationJson != null && smsRequest.personalisationJson.trim() != '') {
                payload.put('personalisation', (Map<String, Object>)JSON.deserializeUntyped(smsRequest.personalisationJson));
            }
            String expectedBody = JSON.serialize(payload);
            Assert.areEqual(expectedSmsEndpoint, request.getEndpoint(), 'Incorrect endpoint set');
            Assert.areEqual('POST', request.getMethod(), 'Incorrect method set');
            Assert.areEqual('application/json', request.getHeader('Content-Type'), 'Incorrect Content-Type header');
            Assert.areEqual(expectedBody, request.getBody(), 'Incorrect body passed to Notify');

            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(responseBody);
            return response;
        }
    }

    private class LetterHttpResponseMock implements HttpCalloutMock {

        GovNotifyInteractionService.LetterRequest letterRequest;
        private Integer statusCode;
        private String responseBody;
        
        public LetterHttpResponseMock(GovNotifyInteractionService.LetterRequest letterRequest, Integer statusCode, String responseBody) {
            this.letterRequest = letterRequest;
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HTTPRequest request) {
            Map<String, Object> payload = new Map<String, Object> {
                'template_id' => letterRequest.templateId
            };
            if (letterRequest.personalisationJson != null && letterRequest.personalisationJson.trim() != '') {
                payload.put('personalisation', (Map<String, Object>)JSON.deserializeUntyped(letterRequest.personalisationJson));
            }
            String expectedBody = JSON.serialize(payload);
            Assert.areEqual(expectedLetterEndpoint, request.getEndpoint(), 'Incorrect endpoint set');
            Assert.areEqual('POST', request.getMethod(), 'Incorrect method set');
            Assert.areEqual('application/json', request.getHeader('Content-Type'), 'Incorrect Content-Type header');
            Assert.areEqual(expectedBody, request.getBody(), 'Incorrect body passed to Notify');

            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(responseBody);
            return response;
        }
    }
}