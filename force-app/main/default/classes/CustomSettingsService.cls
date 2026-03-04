public with sharing class CustomSettingsService {
    
    public String getOSPlacesAPIKey() {
        return CustomSettingsServiceLayer.getInstance().getOSPlacesAPIKey();
    }

    public String getGovNotifyAPIKey() {
        return CustomSettingsServiceLayer.getInstance().getGovNotifyAPIKey();
    }

    public String getUserTokenEncryptionKey() {
        return CustomSettingsServiceLayer.getInstance().getUserTokenEncryptionKey();
    }

    public String getEPCAPIUsername() {
        return CustomSettingsServiceLayer.getInstance().getEPCAPIUsername();
    }
    
    public String getEPCAPIKey() {
        return CustomSettingsServiceLayer.getInstance().getEPCAPIKey();
    }

    public String getOneLoginPublicKey() {
        return CustomSettingsServiceLayer.getInstance().getOneLoginPublicKey();
    }

    public Integer getPublicExemptionsPageSize() {
        return CustomSettingsServiceLayer.getInstance().getPublicExemptionsPageSize();
    }

    public Integer getPublicPenaltiesPageSize() {
        return CustomSettingsServiceLayer.getInstance().getPublicPenaltiesPageSize();
    }

    public Boolean useNewGovEpcEndpoint() {
        return CustomSettingsServiceLayer.getInstance().useNewGovEpcEndpoint();
    }

    public interface API {
        String getOSPlacesAPIKey();
        String getGovNotifyAPIKey();
        String getUserTokenEncryptionKey();
        string getEPCAPIUsername();
        string getEPCAPIKey();
        String getOneLoginPublicKey();
        Integer getPublicExemptionsPageSize();
        Integer getPublicPenaltiesPageSize();
        Boolean useNewGovEpcEndpoint();
    }
}
