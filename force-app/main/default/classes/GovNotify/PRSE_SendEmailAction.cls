public with sharing class PRSE_SendEmailAction {

    @InvocableMethod(
        label='Send GOV.UK Notify Email' 
        description='Sends an email via GovNotify service.' 
        category='PRS Exemption Register'
    )
    public static List<GovNotifyInteractionService.NotifyResponse> sendEmail(List<GovNotifyInteractionService.NotifyRequest> requests) {
        if(requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Request not provided');
        }
        List<GovNotifyInteractionService.NotifyResponse> responses = new List<GovNotifyInteractionService.NotifyResponse>();

        for (GovNotifyInteractionService.NotifyRequest request : requests) {
            responses.add(GovNotifyInteractionService.sendEmail(request));
        }
        return responses;
    }
}
