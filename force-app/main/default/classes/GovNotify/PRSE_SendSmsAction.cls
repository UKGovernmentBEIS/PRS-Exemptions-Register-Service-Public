public with sharing class PRSE_SendSmsAction {

    @InvocableMethod(
        label='Send GOV.UK Notify SMS' 
        description='Sends an SMS via GovNotify service.' 
        category='PRS Exemption Register'
    )
    public static List<GovNotifyInteractionService.NotifyResponse> sendSms(List<GovNotifyInteractionService.SmsRequest> requests) {
        if(requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Request not provided');
        }
        List<GovNotifyInteractionService.NotifyResponse> responses = new List<GovNotifyInteractionService.NotifyResponse>();

        for (GovNotifyInteractionService.SmsRequest request : requests) {
            responses.add(GovNotifyInteractionService.sendSms(request));
        }
        return responses;
    }
}