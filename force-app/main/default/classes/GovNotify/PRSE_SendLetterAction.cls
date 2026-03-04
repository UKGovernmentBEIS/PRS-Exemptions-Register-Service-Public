public with sharing class PRSE_SendLetterAction {

    @InvocableMethod(
        label='Send GOV.UK Notify Letter' 
        description='Sends a letter via GovNotify service.' 
        category='PRS Exemption Register'
    )
    public static List<GovNotifyInteractionService.NotifyResponse> sendLetter(List<GovNotifyInteractionService.LetterRequest> requests) {
        if(requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Request not provided');
        }
        return new List<GovNotifyInteractionService.NotifyResponse> { 
            GovNotifyInteractionService.sendLetter(requests[0]) 
        };
    }
}