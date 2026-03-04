public with sharing class GovNotifyInteractionServiceLayer implements GovNotifyInteractionService.API {
    final static digitalmodus.SystemLogService errorLoggingService = new digitalmodus.SystemLogService('GovNotifyInteractionServiceLayer');

    @TestVisible
    private static GovNotifyInteractionService.API instance;

    private static ApiKey keyObject;

    private static final String EMAIL_ENDPOINT = 'https://api.notifications.service.gov.uk/v2/notifications/email';
    private static final String SMS_ENDPOINT = 'https://api.notifications.service.gov.uk/v2/notifications/sms'; 
    private static final String LETTER_ENDPOINT = 'https://api.notifications.service.gov.uk/v2/notifications/letter'; 

    public static GovNotifyInteractionService.API getInstance() {
        if(instance == null) {
            instance = new GovNotifyInteractionServiceLayer();
        } 
        return instance;
    }

    public GovNotifyInteractionServiceLayer(String doNotUse) {
        throw new Exceptions.MockConstructorOnlyException('Constructor only used for mocking, due to Stub API limitations.');
    }

    private GovNotifyInteractionServiceLayer() {
        keyObject = parseApiKey(new CustomSettingsService().getGovNotifyAPIKey());
    }

	//Email
    public GovNotifyInteractionService.NotifyResponse sendEmail(GovNotifyInteractionService.NotifyRequest request) {
        GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
        HttpResponse httpResponse;
        try{
            Map<String, Object> payload = new Map<String, Object> {
                'email_address' => request.email,
                'template_id' => request.templateId
            };
            if (request.personalisationJson != null && request.personalisationJson.trim() != '') {
                payload.put('personalisation', (Map<String, Object>)JSON.deserializeUntyped(request.personalisationJson));
            }

            HttpRequest req = new HttpRequest();
            req.setEndpoint(EMAIL_ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + buildJWT());
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(payload));

            Http http = new Http();
            httpResponse = http.send(req);
            if (httpResponse.getStatusCode() == 201) {
                response.status = 'Success';
                response.message = 'Notification sent successfully.';
            } else {
                response.status = 'Error';
                response.message = 'Failed with status code: ' + httpResponse.getStatusCode() + ' - ' + httpResponse.getBody();

                errorLoggingService.setLogCode('GovNotifyInteractionServiceLayer')
                    .setTriggeringAutomationName('sendEmail')
                    .setMessage(httpResponse.getBody())
                    .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                    .publish();
            }

        } catch (Exception ex) {
            response.status = 'Error';
            response.message = 'Failed with status code: ' + httpResponse.getStatusCode() + ' - ' + httpResponse.getBody();

            errorLoggingService.setLogCode('GovNotifyInteractionServiceLayer')
                .setTriggeringAutomationName('sendEmail')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return response;
    }

	//SMS
    public GovNotifyInteractionService.NotifyResponse sendSms(GovNotifyInteractionService.SmsRequest request) {
        GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
        HttpResponse httpResponse;
        try{
            Map<String, Object> payload = new Map<String, Object> {
                'phone_number' => request.phoneNumber,
                'template_id' => request.templateId
            };
            if (request.personalisationJson != null && request.personalisationJson.trim() != '') {
                payload.put('personalisation', (Map<String, Object>)JSON.deserializeUntyped(request.personalisationJson));
            }

            HttpRequest req = new HttpRequest();
            req.setEndpoint(SMS_ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + buildJWT());
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(payload));

            Http http = new Http();
            httpResponse = http.send(req);
            if (httpResponse.getStatusCode() == 201) {
                response.status = 'Success';
                response.message = 'SMS notification sent successfully.';
            } else {
                response.status = 'Error';
                response.message = 'Failed with status code: ' + httpResponse.getStatusCode() + ' - ' + httpResponse.getBody();

                errorLoggingService.setLogCode('GovNotifyInteractionServiceLayer')
                    .setTriggeringAutomationName('sendSms')
                    .setMessage(httpResponse.getBody())
                    .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                    .publish();
            }

        } catch (Exception ex) {
            response.status = 'Error';
            response.message = 'Failed with status code: ' + httpResponse.getStatusCode() + ' - ' + httpResponse.getBody();

            errorLoggingService.setLogCode('GovNotifyInteractionServiceLayer')
                .setTriggeringAutomationName('sendSms')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return response;
    }

	//Letter
    public GovNotifyInteractionService.NotifyResponse sendLetter(GovNotifyInteractionService.LetterRequest request) {
        GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
        HttpResponse httpResponse;
        try{
            Map<String, Object> payload = new Map<String, Object> {
                'template_id' => request.templateId
            };
            if (request.personalisationJson != null && request.personalisationJson.trim() != '') {
                payload.put('personalisation', (Map<String, Object>)JSON.deserializeUntyped(request.personalisationJson));
            }

            HttpRequest req = new HttpRequest();
            req.setEndpoint(LETTER_ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + buildJWT());
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(payload));

            Http http = new Http();
            httpResponse = http.send(req);
            if (httpResponse.getStatusCode() == 201) {
                response.status = 'Success';
                response.message = 'Letter notification sent successfully.';
            } else {
                response.status = 'Error';
                response.message = 'Failed with status code: ' + httpResponse.getStatusCode() + ' - ' + httpResponse.getBody();

                errorLoggingService.setLogCode('GovNotifyInteractionServiceLayer')
                    .setTriggeringAutomationName('sendLetter')
                    .setMessage(httpResponse.getBody())
                    .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                    .publish();
            }

        } catch (Exception ex) {
            response.status = 'Error';
            response.message = 'Failed with status code: ' + httpResponse.getStatusCode() + ' - ' + httpResponse.getBody();

            errorLoggingService.setLogCode('GovNotifyInteractionServiceLayer')
                .setTriggeringAutomationName('sendLetter')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return response;
    }

    private String buildJWT() {
        String header = '{"typ": "JWT","alg": "HS256"}';
        String encodedHeader = base64URLencode(Blob.valueOf(header));
        
        Long iat = DateTime.now().getTime() / 1000;
        String payload ='{"iss": "' + keyObject.iss + '","iat": ' + iat + '}';
        String jwt = encodedHeader + '.' + base64URLencode(Blob.valueOf(payload));

        Blob signature = Crypto.generateMac('hmacSHA256', Blob.valueof(jwt), Blob.valueOf(keyObject.secret));
        jwt += '.' + base64URLencode(signature);
        return jwt;
    }

    private String base64URLencode(Blob input) { 
        String output = encodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        while ( output.endsWith('=')) {
            output = output.subString(0, output.length() - 1);
        }
        return output;
    }

    private class ApiKey {
        public String keyName;
        public String iss;
        public String secret;
    }

    private ApiKey parseApiKey(String apiKey) {
        if (String.isBlank(apiKey)) {
            throw new IllegalArgumentException('Missing API key.');
        }

        List<String> parts = apiKey.split('-');

        if (parts.size() != 11) {
            throw new IllegalArgumentException('Invalid API key format.');
        }

        String keyName = parts[0];

        // Extract the iss as the next 4 hyphen-separated parts
        String iss = String.join(new List<String>{
            parts[1], parts[2], parts[3], parts[4], parts[5]
        }, '-');

        // Extract the secret as the remaining parts
        String secret = String.join(new List<String>{
            parts[6], parts[7], parts[8], parts[9], parts[10]
        }, '-');

        ApiKey result = new ApiKey();
        result.keyName = keyName;
        result.iss = iss;
        result.secret = secret;

        return result;
    }
}