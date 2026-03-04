@isTest
private class CustomSettingsLayerMockTest {

    @isTest
    static void OSPlacesAPIKey_withKey_retrievesKey() {
        //Arrange
        CustomSettingsLayerMock mockInstance = new CustomSettingsLayerMock();
        mockInstance.setOSPlacesAPIKey('232323');
        CustomSettingsServiceLayer.instance = mockInstance;

        //Act
        String returnedKey = CustomSettingsServiceLayer.getInstance().getOSPlacesAPIKey();

        //Assert
        Assert.areEqual('232323', returnedKey, 'Incorrect OS Places Key returned');
    }

    @isTest
    static void GovNotifyAPIKey_withKey_retrievesKey() {
        //Arrange
        CustomSettingsLayerMock mockInstance = new CustomSettingsLayerMock();
        mockInstance.setGovNotifyAPIKey('4444444');
        CustomSettingsServiceLayer.instance = mockInstance;

        //Act
        String returnedKey = CustomSettingsServiceLayer.getInstance().getGovNotifyAPIKey();

        //Assert
        Assert.areEqual('4444444', returnedKey, 'Incorrect Gov Notify Key returned');
    }

    @isTest
    static void UserTokenEncryptionKey_withKey_retrievesKey() {
        //Arrange
        CustomSettingsLayerMock mockInstance = new CustomSettingsLayerMock();
        mockInstance.setUserTokenEncryptionKey('4444444');
        CustomSettingsServiceLayer.instance = mockInstance;

        //Act
        String returnedKey = CustomSettingsServiceLayer.getInstance().getUserTokenEncryptionKey();

        //Assert
        Assert.areEqual('4444444', returnedKey, 'Incorrect User Token Encryption Key returned');
    }

    @isTest
    static void OneLoginPublicKey_withKey_retrievesKey() {
        //Arrange
        CustomSettingsLayerMock mockInstance = new CustomSettingsLayerMock();
        mockInstance.setOneLoginPublicKey('4444444');
        CustomSettingsServiceLayer.instance = mockInstance;

        //Act
        String returnedKey = CustomSettingsServiceLayer.getInstance().getOneLoginPublicKey();

        //Assert
        Assert.areEqual('4444444', returnedKey, 'Incorrect One Login Public Key returned');
    }

    @isTest
    static void EPCAPIUsername_withUser_retrievesKey() {
        //Arrange
        CustomSettingsLayerMock mockInstance = new CustomSettingsLayerMock();
        mockInstance.setEPCAPIUsername('first@last.com');
        CustomSettingsServiceLayer.instance = mockInstance;

        //Act
        String returnedKey = CustomSettingsServiceLayer.getInstance().getEPCAPIUsername();

        //Assert
        Assert.areEqual('first@last.com', returnedKey, 'Incorrect EPC API Username returned');
    }

    @isTest
    static void EPCAPIKey_withKey_retrievesKey() {
        //Arrange
        CustomSettingsLayerMock mockInstance = new CustomSettingsLayerMock();
        mockInstance.setEPCAPIKey('4444444');
        CustomSettingsServiceLayer.instance = mockInstance;

        //Act
        String returnedKey = CustomSettingsServiceLayer.getInstance().getEPCAPIKey();

        //Assert
        Assert.areEqual('4444444', returnedKey, 'Incorrect EPC API Key returned');
    }

    @isTest
    static void PublicExemptionsPageSize_withSize_retrievesSize() {
        //Arrange
        CustomSettingsLayerMock mockInstance = new CustomSettingsLayerMock();
        mockInstance.setPublicExemptionsPageSize(50);
        CustomSettingsServiceLayer.instance = mockInstance;

        //Act
        Integer returnedSize = CustomSettingsServiceLayer.getInstance().getPublicExemptionsPageSize();

        //Assert
        Assert.areEqual(50, returnedSize, 'Incorrect Public Exemptions Page Size returned');
    }
    @isTest
    static void PublicPenaltiesPageSize_withSize_retrievesSize() {
        //Arrange
        CustomSettingsLayerMock mockInstance = new CustomSettingsLayerMock();
        mockInstance.setPublicPenaltiesPageSize(30);
        CustomSettingsServiceLayer.instance = mockInstance;

        //Act
        Integer returnedSize = CustomSettingsServiceLayer.getInstance().getPublicPenaltiesPageSize();

        //Assert
        Assert.areEqual(30, returnedSize, 'Incorrect Public Penalties Page Size returned');
    }
    @isTest
    static void UseNewGovEpcEndpoint_withValue_retrievesValue() {
        //Arrange
        CustomSettingsLayerMock mockInstance = new CustomSettingsLayerMock();
        mockInstance.setUseNewGovEpcEndpoint(true);
        CustomSettingsServiceLayer.instance = mockInstance;

        //Act
        Boolean returnedValue = CustomSettingsServiceLayer.getInstance().useNewGovEpcEndpoint();

        //Assert
        Assert.isTrue(returnedValue, 'Incorrect Use New Gov EPC Endpoint value returned');
    }
}