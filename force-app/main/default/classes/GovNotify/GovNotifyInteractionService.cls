public with sharing class GovNotifyInteractionService {

	//Email    
    public class NotifyRequest {
        @InvocableVariable(label='Template Id' required=true)
        public String templateId;

        @InvocableVariable(label='Recipient Email' required=true)
        public String email;

        @InvocableVariable(label='Personalisation JSON' required=true)
        public String personalisationJson;
    }

	//SMS    
    public class SmsRequest {
        @InvocableVariable(label='Template Id' required=true)
        public String templateId;

        @InvocableVariable(label='Recipient Phone Number' required=true)
        public String phoneNumber;

        @InvocableVariable(label='Personalisation JSON' required=true)
        public String personalisationJson;
    }

	//Letter    
    public class LetterRequest {
        @InvocableVariable(label='Template Id' required=true)
        public String templateId;

        @InvocableVariable(label='Personalisation JSON' required=true)
        public String personalisationJson;
    }
    
    public class NotifyResponse {
        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Message')
        public String message;
    }
    
    public static GovNotifyInteractionService.NotifyResponse sendEmail(GovNotifyInteractionService.NotifyRequest request) { 
        return GovNotifyInteractionServiceLayer.getInstance().sendEmail(request);
    }

    public static GovNotifyInteractionService.NotifyResponse sendSms(GovNotifyInteractionService.SmsRequest request) { 
        return GovNotifyInteractionServiceLayer.getInstance().sendSms(request);
    }

    public static GovNotifyInteractionService.NotifyResponse sendLetter(GovNotifyInteractionService.LetterRequest request) { 
        return GovNotifyInteractionServiceLayer.getInstance().sendLetter(request);
    }
    
    public interface API {
        GovNotifyInteractionService.NotifyResponse sendEmail(GovNotifyInteractionService.NotifyRequest request);
        GovNotifyInteractionService.NotifyResponse sendSms(GovNotifyInteractionService.SmsRequest request);
        GovNotifyInteractionService.NotifyResponse sendLetter(GovNotifyInteractionService.LetterRequest request);
    }
}