public with sharing class PRSE_AddressRetrievalAction {

    public class Response {
        @InvocableVariable
        public Integer numberOfAddresses;
        
        @InvocableVariable
        public String addresses;

        @InvocableVariable
        public List<DeliveryPointAddress> deliveryPointAddresses;

        public Response(Integer numberOfAddresses, String addresses, List<DeliveryPointAddress> deliveryPointAddresses) {
            this.numberOfAddresses = numberOfAddresses;
            this.addresses = addresses;
            this.deliveryPointAddresses = deliveryPointAddresses;
        }
    }

    @InvocableMethod(
        label='Get addresses by postcode' 
        description='Returns addresses for the passed in postcode.' 
        category='PRS Exemption Register'
    )
    public static List<Response> getAddressesByPostcode(List<String> postCodes) {
        List<String> addressList = new List<String>();
        String concatenatedAddressList = '';
        List<DeliveryPointAddress> directPostalAddresses = OSPlacesInteractionService.getInformationByPostcode(postCodes[0]);
        for(DeliveryPointAddress address : directPostalAddresses) {
            concatenatedAddressList += address.ADDRESS + '|';
        }

        return new List<Response>{ 
            new Response(
                directPostalAddresses.size(), 
                concatenatedAddressList.removeEnd('|'),
                directPostalAddresses
            ) 
        };
    }
}