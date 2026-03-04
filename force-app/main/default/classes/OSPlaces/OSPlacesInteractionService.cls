public without sharing class OSPlacesInteractionService {

    public static List<DeliveryPointAddress> getInformationByPostcode(String postCode) {
        return OSPlacesInteractionServiceLayer.getInstance().getInformationByPostcode(postCode);
    }

    public static List<DeliveryPointAddress> getInformationByPostcodeForEnglandOrWalesOnly(String postCode) {
        return OSPlacesInteractionServiceLayer.getInstance().getInformationByPostcodeForEnglandOrWalesOnly(postCode);
    }

    public static List<DeliveryPointAddress> matchAddressForEnglandOrWalesOnly(String address) { 
        return OSPlacesInteractionServiceLayer.getInstance().matchAddressForEnglandOrWalesOnly(address);
    }
    
    public interface API {
        List<DeliveryPointAddress> getInformationByPostcode(String postCode);
        List<DeliveryPointAddress> getInformationByPostcodeForEnglandOrWalesOnly(String postCode);
        List<DeliveryPointAddress> matchAddressForEnglandOrWalesOnly(String address);
    }
}