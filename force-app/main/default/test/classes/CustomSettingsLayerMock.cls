@isTest
public with sharing class CustomSettingsLayerMock implements CustomSettingsService.API {

    private String OSPlacesAPIKey = '123456';
    private String govNotifyAPIKey = '123456';
    private String userTokenEncryptionKey = '123456';
    private String oneLoginPublicKey = '123456';
    private String EPCAPIUsername = 'test@test.com';
    private String EPCAPIKey = '123456';
    private Integer publicExemptionsPageSize = 20;
    private Integer publicPenaltiesPageSize = 20;
    private Boolean useNewGovEpcEndpoint = false;

    public void setOSPlacesAPIKey(String OSPlacesAPIKey) {
       this.OSPlacesAPIKey = OSPlacesAPIKey;
    }
    public String getOSPlacesAPIKey() {
        return OSPlacesAPIKey;
    }
    
    public void setGovNotifyAPIKey(String govNotifyAPIKey) {
        this.govNotifyAPIKey = govNotifyAPIKey;
    }
    public String getGovNotifyAPIKey() {
        return govNotifyAPIKey;
    }

    public void setUserTokenEncryptionKey(String userTokenEncryptionKey) {
        this.userTokenEncryptionKey = userTokenEncryptionKey;
    }
    public String getUserTokenEncryptionKey() {
        return userTokenEncryptionKey;
    }

    public void setOneLoginPublicKey(String oneLoginPublicKey) {
        this.oneLoginPublicKey = oneLoginPublicKey;
    }
    public String getOneLoginPublicKey() {
        return oneLoginPublicKey;
    }

    public void setEPCAPIUsername(String EPCAPIUsername) {
        this.EPCAPIUsername = EPCAPIUsername;
    }
    public String getEPCAPIUsername() {
        return EPCAPIUsername;
    }

    public void setEPCAPIKey(String EPCAPIKey) {
        this.EPCAPIKey = EPCAPIKey;
    }
    public String getEPCAPIKey() {
        return EPCAPIKey;
    }

    public void setPublicExemptionsPageSize(Integer pageSize) {
        this.publicExemptionsPageSize = pageSize;
    }   
    public Integer getPublicExemptionsPageSize() {
        return publicExemptionsPageSize;
    }

    public void setPublicPenaltiesPageSize(Integer pageSize) {
        this.publicPenaltiesPageSize = pageSize;
    }
    public Integer getPublicPenaltiesPageSize() {
        return publicPenaltiesPageSize;
    }

    public void setUseNewGovEpcEndpoint(Boolean useNewGovEpcEndpoint) {
        this.useNewGovEpcEndpoint = useNewGovEpcEndpoint;
    }
    public Boolean useNewGovEpcEndpoint() {
        return useNewGovEpcEndpoint;
    }
}
