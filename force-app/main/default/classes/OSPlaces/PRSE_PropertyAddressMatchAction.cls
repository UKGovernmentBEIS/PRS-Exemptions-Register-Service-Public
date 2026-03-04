public with sharing class PRSE_PropertyAddressMatchAction {

    public class Response {
        @InvocableVariable
        public Integer numberOfAddresses;

        @InvocableVariable
        public String addressUPRN;

        @InvocableVariable
        public DeliveryPointAddress deliveryPointAddress;

        public Response(Integer numberOfAddresses, String addressUPRN, DeliveryPointAddress deliveryPointAddress) {
            this.numberOfAddresses = numberOfAddresses;
            this.addressUPRN = addressUPRN;
            this.deliveryPointAddress = deliveryPointAddress;
        }
    }

    @InvocableMethod(
        label='Match property address' 
        description='Returns an address matched for the passed in manual address.' 
        category='PRS Exemption Register'
    )
    public static List<Response> matchAddress(List<String> addresses) {
        List<DeliveryPointAddress> directPostalAddresses = OSPlacesInteractionService.matchAddressForEnglandOrWalesOnly(addresses[0]);
        if(directPostalAddresses.size() >= 1) {
            return new List<Response> {
                new Response(
                    1,
                    String.valueOf(directPostalAddresses[0].UPRN),
                    directPostalAddresses[0]
                ) 
            };
        }
        return new List<Response> {
            new Response(
                0,
                '',
                null
            ) 
        };
    }
}