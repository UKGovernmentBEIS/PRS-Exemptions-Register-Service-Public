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
        List<GovNotifyInteractionService.NotifyResponse> responses = new List<GovNotifyInteractionService.NotifyResponse>();

        for (GovNotifyInteractionService.LetterRequest request : requests) {
            responses.add(GovNotifyInteractionService.sendLetter(request));
        }
        return responses;
    }
}