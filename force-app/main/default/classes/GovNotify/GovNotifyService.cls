public class GovNotifyService {
    private static final String NOTIFY_URL = 'https://api.notifications.service.gov.uk/v2/notifications/email';
    private static final String SECRET = '90e1d637-e991-4f4b-9855-31af8f555348';
    private static final String ISS = '5c96e9eb-58ff-4d19-8767-b22ed2995659';

    public static String sendEmail(String emailAddress) {
        Map<String, String> personalisation = new Map<String, String>();
        personalisation.put('first name', 'test');
        personalisation.put('url', '(www.google.com)');

        Map<String, Object> payload = new Map<String, Object> {
            'email_address' => emailAddress,
            'template_id' => 'ee93d222-f901-4e38-aca9-55362ae088ed',
            'personalisation' => personalisation
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint(NOTIFY_URL);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + buildJWT());
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 201) {
            Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) resBody.get('id');
        } else {
            throw new CalloutException('Failed to send email: ' + res.getStatusCode() + ' ' + res.getBody());
        }
    }

    private static String buildJWT() {
        JSONGenerator header = JSON.createGenerator(false);
        header.writeStartObject();
        header.writeStringField('alg', 'HS256');
        header.writeEndObject();
        String encodedHeader = base64URLencode(Blob.valueOf(header.getAsString()));
        
        Long iat = DateTime.now().getTime() / 1000;
        JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeStringField('iss', iss);
        body.writeNumberField('iat', iat);
        body.writeEndObject();
        
        String jwt = encodedHeader + '.' + base64URLencode(Blob.valueOf(body.getAsString()));
        Blob signature = Crypto.generateMac('hmacSHA256', Blob.valueof(jwt), Blob.valueOf(SECRET));
        jwt += '.' + base64URLencode(signature);
        return jwt;

    }

    public static String base64URLencode(Blob input) { 
        String output = encodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        while ( output.endsWith('=')) {
            output = output.subString(0, output.length() - 1);
        }
        return output;
    }
}