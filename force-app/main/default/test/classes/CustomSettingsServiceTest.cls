@isTest(IsParallel=true)
private class CustomSettingsServiceTest {
    
    private static final String mockApiKey = '123456';

    @isTest
    static void getOSPlacesAPIKey_callsLayer_andReturnsKey() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        String key = new CustomSettingsService().getOSPlacesAPIKey();

        //Assert
        Assert.isTrue(CustomSettingsServiceLayer.instance instanceof CustomSettingsLayerMock, 'Incorrect layer instance type returned');
        Assert.areEqual(mockApiKey, key, 'Incorrect key returned');
    }

    @isTest
    static void getGovNotifyAPIKey_callsLayer_andReturnsKey() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        String key = new CustomSettingsService().getGovNotifyAPIKey();

        //Assert
        Assert.isTrue(CustomSettingsServiceLayer.instance instanceof CustomSettingsLayerMock, 'Incorrect layer instance type returned');
        Assert.areEqual(mockApiKey, key, 'Incorrect key returned');
    }

    @isTest
    static void getUserTokenEncryptionKey_callsLayer_andReturnsKey() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        String key = new CustomSettingsService().getUserTokenEncryptionKey();

        //Assert
        Assert.isTrue(CustomSettingsServiceLayer.instance instanceof CustomSettingsLayerMock, 'Incorrect layer instance type returned');
        Assert.areEqual(mockApiKey, key, 'Incorrect key returned');
    }

    @isTest
    static void getOneLoginPublicKey_callsLayer_andReturnsKey() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        String key = new CustomSettingsService().getOneLoginPublicKey();

        //Assert
        Assert.isTrue(CustomSettingsServiceLayer.instance instanceof CustomSettingsLayerMock, 'Incorrect layer instance type returned');
        Assert.areEqual(mockApiKey, key, 'Incorrect key returned');
    }

    @isTest
    static void getEPCAPIUsername_callsLayer_andReturnsUsername() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        String username = new CustomSettingsService().getEPCAPIUsername();

        //Assert
        Assert.isTrue(CustomSettingsServiceLayer.instance instanceof CustomSettingsLayerMock, 'Incorrect layer instance type returned');
        Assert.areEqual('test@test.com', username, 'Incorrect Username returned');
    }

    @isTest
    static void getEPCAPIKey_callsLayer_andReturnsKey() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        String key = new CustomSettingsService().getEPCAPIKey();

        //Assert
        Assert.isTrue(CustomSettingsServiceLayer.instance instanceof CustomSettingsLayerMock, 'Incorrect layer instance type returned');
        Assert.areEqual(mockApiKey, key, 'Incorrect key returned');
    }

    @isTest
    static void getPublicExemptionsPageSize_callsLayer_andReturnsPageSize() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        Integer pageSize = new CustomSettingsService().getPublicExemptionsPageSize();

        //Assert
        Assert.isTrue(CustomSettingsServiceLayer.instance instanceof CustomSettingsLayerMock, 'Incorrect layer instance type returned');
        Assert.areEqual(20, pageSize, 'Incorrect page size returned');
    }

    @isTest
    static void getPublicPenaltiesPageSize_callsLayer_andReturnsPageSize() {
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        Integer pageSize = new CustomSettingsService().getPublicPenaltiesPageSize();

        //Assert
        Assert.isTrue(CustomSettingsServiceLayer.instance instanceof CustomSettingsLayerMock, 'Incorrect layer instance type returned');
        Assert.areEqual(20, pageSize, 'Incorrect page size returned');
    }

    @isTest
    static void useNewGovEpcEndpoint_callsLayer_andReturnsBoolean() {       
        //Arrange
        CustomSettingsServiceLayer.instance = new CustomSettingsLayerMock();

        //Act
        Boolean useNewEndpoint = new CustomSettingsService().useNewGovEpcEndpoint();

        //Assert
        Assert.isTrue(CustomSettingsServiceLayer.instance instanceof CustomSettingsLayerMock, 'Incorrect layer instance type returned');
        Assert.isFalse(useNewEndpoint, 'Incorrect boolean value returned');
    }
}
