@isTest(IsParallel=true)
private class CustomSettingsServiceLayerTest {

    @isTest
    static void getInstance_withNoPriorInstance_returnsNewInstance() {
        //Arrange, Act
        CustomSettingsService.API instance = CustomSettingsServiceLayer.getInstance();

        //Assert
        Assert.isNotNull(instance, 'Should return instance of CustomSettingsServiceLayer');
    }

    @isTest
    static void getInstance_withPriorInstance_returnsSameInstance() {
        //Arrange
        CustomSettingsService.API initialInstance = CustomSettingsServiceLayer.getInstance();

        //Act
        CustomSettingsService.API secondInstance = CustomSettingsServiceLayer.getInstance();

        //Assert
        Assert.areEqual(initialInstance, secondInstance, 'Should return same instance of CustomSettingsServiceLayer');
    }

    @isTest
    static void getOSPlaceKey_withNoCustomSettingsRecord_throwsException() {
        //Arrange, Act
        try {
            CustomSettingsServiceLayer.getInstance().getOSPlacesAPIKey();
            Assert.fail('Expected exception.');
        } catch(Exception ex) {
            //Assert
            Assert.areEqual('Exceptions.QueryException', ex.getTypeName(), 'Expected to throw a QueryException');
            Assert.areEqual('Missing PRSE_OS_Places_Key custom setting, please ensure this is set up before proceeding.', ex.getMessage(), 'Incorrect error message');
        }
    }

    @isTest
    static void getOSPlaceKey_withIncorrectCustomSettingsRecord_throwsException() {
        //Arrange
        digitalmodus__API_Credentials__c apiCredential = new digitalmodus__API_Credentials__c(
            Name = 'FAKE_OS_Places_Key',
            digitalmodus__Key__c = 'FAKE_OS_Key',
            digitalmodus__Service__c = 'OS_Places',
            digitalmodus__Value__c = '123456789',
            digitalmodus__Endpoint__c = 'https://api.os.uk/search/places/v1/'
        );
        insert apiCredential;

        //Act
        try {
            CustomSettingsServiceLayer.getInstance().getOSPlacesAPIKey();
            Assert.fail('Expected exception.');
        } catch(Exception ex) {
            //Assert
            Assert.areEqual('Exceptions.QueryException', ex.getTypeName(), 'Expected to throw a QueryException');
            Assert.areEqual('Missing PRSE_OS_Places_Key custom setting, please ensure this is set up before proceeding.', ex.getMessage(), 'Incorrect error message');
        }
    }

    @isTest
    static void getOSPlaceKey_withValidCustomSettingsRecord_returnsKey() {
        //Arrange
        digitalmodus__API_Credentials__c apiCredential = new digitalmodus__API_Credentials__c(
            Name = 'PRSE_OS_Places_Key',
            digitalmodus__Key__c = 'PRSE_OS_Key',
            digitalmodus__Service__c = 'OS_Places',
            digitalmodus__Value__c = '123456789',
            digitalmodus__Endpoint__c = 'https://api.os.uk/search/places/v1/'
        );
        insert apiCredential;

        //Act
        String apiKey = CustomSettingsServiceLayer.getInstance().getOSPlacesAPIKey();

        //Assert
        Assert.areEqual(apiCredential.digitalmodus__Value__c, apiKey, 'Incorrect API Key returned');
    }

    @isTest
    static void getGovNotifyAPIKey_withNoCustomSettingsRecord_throwsException() {
        //Arrange, Act
        try {
            CustomSettingsServiceLayer.getInstance().getGovNotifyAPIKey();
            Assert.fail('Expected exception.');
        } catch(Exception ex) {
            //Assert
            Assert.areEqual('Exceptions.QueryException', ex.getTypeName(), 'Expected to throw a QueryException');
            Assert.areEqual('Missing PRSE_Gov_Notify_Key custom setting, please ensure this is set up before proceeding.', ex.getMessage(), 'Incorrect error message');
        }
    }

    @isTest
    static void getGovNotifyAPIKey_withIncorrectCustomSettingsRecord_throwsException() {
        //Arrange
        digitalmodus__API_Credentials__c apiCredential = new digitalmodus__API_Credentials__c(
            Name = 'FAKE_Gov_Notify_Key',
            digitalmodus__Key__c = 'FAKE_Gov_Notify_Key',
            digitalmodus__Service__c = 'GovNotify',
            digitalmodus__Value__c = '123456789',
            digitalmodus__Endpoint__c = 'https://api.notifications.service.gov.uk'
        );
        insert apiCredential;

        //Act
        try {
            CustomSettingsServiceLayer.getInstance().getGovNotifyAPIKey();
            Assert.fail('Expected exception.');
        } catch(Exception ex) {
            //Assert
            Assert.areEqual('Exceptions.QueryException', ex.getTypeName(), 'Expected to throw a QueryException');
            Assert.areEqual('Missing PRSE_Gov_Notify_Key custom setting, please ensure this is set up before proceeding.', ex.getMessage(), 'Incorrect error message');
        }
    }

    @isTest
    static void getGovNotifyAPIKey_withValidCustomSettingsRecord_returnsKey() {
        //Arrange
        digitalmodus__API_Credentials__c apiCredential = new digitalmodus__API_Credentials__c(
            Name = 'PRSE_Gov_Notify_Key',
            digitalmodus__Key__c = 'PRSE_Gov_Notify_Key',
            digitalmodus__Service__c = 'GovNotify',
            digitalmodus__Value__c = '123456789',
            digitalmodus__Endpoint__c = 'https://api.notifications.service.gov.uk'
        );
        insert apiCredential;

        //Act
        String apiKey = CustomSettingsServiceLayer.getInstance().getGovNotifyAPIKey();

        //Assert
        Assert.areEqual(apiCredential.digitalmodus__Value__c, apiKey, 'Incorrect API Key returned');
    }

    @isTest
    static void getUserTokenEncryptionKey_withNoCustomSettingsRecord_throwsException() {
        //Arrange, Act
        try {
            CustomSettingsServiceLayer.getInstance().getUserTokenEncryptionKey();
            Assert.fail('Expected exception.');
        } catch(Exception ex) {
            //Assert
            Assert.areEqual('Exceptions.QueryException', ex.getTypeName(), 'Expected to throw a QueryException');
            Assert.areEqual('Missing PRSE_User_Token custom setting, please ensure this is set up before proceeding.', ex.getMessage(), 'Incorrect error message');
        }
    }

    @isTest
    static void getUserTokenEncryptionKey_withIncorrectCustomSettingsRecord_throwsException() {
        //Arrange
        digitalmodus__API_Credentials__c apiCredential = new digitalmodus__API_Credentials__c(
            Name = 'FAKE_User_Token',
            digitalmodus__Key__c = 'FAKE_User_Token',
            digitalmodus__Service__c = 'PRSE_Login',
            digitalmodus__Value__c = '123456789',
            digitalmodus__Endpoint__c = 'https://www.salesforce.com'
        );
        insert apiCredential;

        //Act
        try {
            CustomSettingsServiceLayer.getInstance().getUserTokenEncryptionKey();
            Assert.fail('Expected exception.');
        } catch(Exception ex) {
            //Assert
            Assert.areEqual('Exceptions.QueryException', ex.getTypeName(), 'Expected to throw aQueryException QueryException');
            Assert.areEqual('Missing PRSE_User_Token custom setting, please ensure this is set up before proceeding.', ex.getMessage(), 'Incorrect error message');
        }
    }

    @isTest
    static void getUserTokenEncryptionKey_withValidCustomSettingsRecord_returnsKey() {
        //Arrange
        digitalmodus__API_Credentials__c apiCredential = new digitalmodus__API_Credentials__c(
            Name = 'PRSE_User_Token',
            digitalmodus__Key__c = 'EncryptionSecret',
            digitalmodus__Service__c = 'PRSE_Login',
            digitalmodus__Value__c = '123456789',
            digitalmodus__Endpoint__c = 'https://www.salesforce.com'
        );
        insert apiCredential;

        //Act
        String apiKey = CustomSettingsServiceLayer.getInstance().getUserTokenEncryptionKey();

        //Assert
        Assert.areEqual(apiCredential.digitalmodus__Value__c, apiKey, 'Incorrect API Key returned');
    }

    @isTest
    static void getOneLoginPublicKey_withNoCustomSettingsRecord_throwsException() {
        //Arrange, Act
        try {
            CustomSettingsServiceLayer.getInstance().getOneLoginPublicKey();
            Assert.fail('Expected exception.');
        } catch(Exception ex) {
            //Assert
            Assert.areEqual('Exceptions.QueryException', ex.getTypeName(), 'Expected to throw a QueryException');
            Assert.areEqual('Missing PRSE_One_Login_Key custom setting, please ensure this is set up before proceeding.', ex.getMessage(), 'Incorrect error message');
        }
    }

    @isTest
    static void getOneLoginPublicKey_withIncorrectCustomSettingsRecord_throwsException() {
        //Arrange
        digitalmodus__API_Credentials__c apiCredential = new digitalmodus__API_Credentials__c(
            Name = 'FAKE_One_Login_Key',
            digitalmodus__Key__c = 'FAKE_One_Login_Key',
            digitalmodus__Service__c = 'OneLogin',
            digitalmodus__Value__c = '123456789',
            digitalmodus__Endpoint__c = 'https://vocab.account.gov.uk/v1/'
        );
        insert apiCredential;

        //Act
        try {
            CustomSettingsServiceLayer.getInstance().getOneLoginPublicKey();
            Assert.fail('Expected exception.');
        } catch(Exception ex) {
            //Assert
            Assert.areEqual('Exceptions.QueryException', ex.getTypeName(), 'Expected to throw an QueryException');
            Assert.areEqual('Missing PRSE_One_Login_Key custom setting, please ensure this is set up before proceeding.', ex.getMessage(), 'Incorrect error message');
        }
    }

    @isTest
    static void getOneLoginPublicKey_withValidCustomSettingsRecord_returnsKey() {
        //Arrange
        digitalmodus__API_Credentials__c apiCredential = new digitalmodus__API_Credentials__c(
            Name = 'PRSE_One_Login_Key',
            digitalmodus__Key__c = 'PRSE_One_Login_Key',
            digitalmodus__Service__c = 'OneLogin',
            digitalmodus__Value__c = '123456789',
            digitalmodus__Endpoint__c = 'https://vocab.account.gov.uk/v1/'
        );
        insert apiCredential;

        //Act
        String apiKey = CustomSettingsServiceLayer.getInstance().getOneLoginPublicKey();

        //Assert
        Assert.areEqual(apiCredential.digitalmodus__Value__c, apiKey, 'Incorrect public Key returned');
    }

    @isTest
    static void getEPCAPIUsername_withNoCustomSettingsRecord_throwsException() {
        //Arrange, Act
        try {
            CustomSettingsServiceLayer.getInstance().getEPCAPIUsername();
            Assert.fail('Expected exception.');
        } catch(Exception ex) {
            //Assert
            Assert.areEqual('Exceptions.QueryException', ex.getTypeName(), 'Expected to throw a QueryException');
            Assert.areEqual('Missing PRSE_EPC_API_Username custom setting, please ensure this is set up before proceeding.', ex.getMessage(), 'Incorrect error message');
        }
    }

    @isTest
    static void getEPCAPIUsername_withIncorrectCustomSettingsRecord_throwsException() {
        //Arrange
        digitalmodus__API_Credentials__c apiCredential = new digitalmodus__API_Credentials__c(
            Name = 'FAKE_EPC_API_Username',
            digitalmodus__Key__c = 'FAKE_EPC_API_Username',
            digitalmodus__Service__c = 'EPC',
            digitalmodus__Value__c = 'test@test.com',
            digitalmodus__Endpoint__c = 'https://epc.opendatacommunities.org/api/v1/'
        );
        insert apiCredential;

        //Act
        try {
            CustomSettingsServiceLayer.getInstance().getEPCAPIUsername();
            Assert.fail('Expected exception.');
        } catch(Exception ex) {
            //Assert
            Assert.areEqual('Exceptions.QueryException', ex.getTypeName(), 'Expected to throw an QueryException');
            Assert.areEqual('Missing PRSE_EPC_API_Username custom setting, please ensure this is set up before proceeding.', ex.getMessage(), 'Incorrect error message');
        }
    }

    @isTest
    static void getEPCAPIUsername_withValidCustomSettingsRecord_returnsUsername() {
        //Arrange
        digitalmodus__API_Credentials__c apiCredential = new digitalmodus__API_Credentials__c(
            Name = 'PRSE_EPC_API_Username',
            digitalmodus__Key__c = 'PRSE_EPC_API_Username',
            digitalmodus__Service__c = 'EPC',
            digitalmodus__Value__c = 'test@test.com',
            digitalmodus__Endpoint__c = 'https://epc.opendatacommunities.org/api/v1/'
        );
        insert apiCredential;

        //Act
        String username = CustomSettingsServiceLayer.getInstance().getEPCAPIUsername();

        //Assert
        Assert.areEqual(apiCredential.digitalmodus__Value__c, username, 'Incorrect username returned');
    }

    @isTest
    static void getEPCAPIKey_withNoCustomSettingsRecord_throwsException() {
        //Arrange, Act
        try {
            CustomSettingsServiceLayer.getInstance().getEPCAPIKey();
            Assert.fail('Expected exception.');
        } catch(Exception ex) {
            //Assert
            Assert.areEqual('Exceptions.QueryException', ex.getTypeName(), 'Expected to throw a QueryException');
            Assert.areEqual('Missing PRSE_EPC_API_Key custom setting, please ensure this is set up before proceeding.', ex.getMessage(), 'Incorrect error message');
        }
    }

    @isTest
    static void getEPCAPIKey_withIncorrectCustomSettingsRecord_throwsException() {
        //Arrange
        digitalmodus__API_Credentials__c apiCredential = new digitalmodus__API_Credentials__c(
            Name = 'FAKE_EPC_API_Key',
            digitalmodus__Key__c = 'FAKE_EPC_API_Key',
            digitalmodus__Service__c = 'EPC',
            digitalmodus__Value__c = 'test@test.com',
            digitalmodus__Endpoint__c = 'https://epc.opendatacommunities.org/api/v1/'
        );
        insert apiCredential;

        //Act
        try {
            CustomSettingsServiceLayer.getInstance().getEPCAPIKey();
            Assert.fail('Expected exception.');
        } catch(Exception ex) {
            //Assert
            Assert.areEqual('Exceptions.QueryException', ex.getTypeName(), 'Expected to throw an QueryException');
            Assert.areEqual('Missing PRSE_EPC_API_Key custom setting, please ensure this is set up before proceeding.', ex.getMessage(), 'Incorrect error message');
        }
    }

    @isTest
    static void getEPCAPIKey_withValidCustomSettingsRecord_returnsUsername() {
        //Arrange
        digitalmodus__API_Credentials__c apiCredential = new digitalmodus__API_Credentials__c(
            Name = 'PRSE_EPC_API_Key',
            digitalmodus__Key__c = 'PRSE_EPC_API_Key',
            digitalmodus__Service__c = 'EPC',
            digitalmodus__Value__c = 'test@test.com',
            digitalmodus__Endpoint__c = 'https://epc.opendatacommunities.org/api/v1/'
        );
        insert apiCredential;

        //Act
        String key = CustomSettingsServiceLayer.getInstance().getEPCAPIKey();

        //Assert
        Assert.areEqual(apiCredential.digitalmodus__Value__c, key, 'Incorrect EPC API key returned');
    }

    @isTest
    static void PublicExemptionsPageSize_withSize_retrievesSize() {

        Integer exPageSize = CustomSettingsServiceLayer.getInstance().getPublicExemptionsPageSize();

        //Assert
        Assert.areEqual(20, exPageSize, 'Incorrect Public Exemptions Page Size returned');        
    }

    @isTest
    static void PublicPenaltiesPageSize_withSize_retrievesSize() {

        Integer penPageSize = CustomSettingsServiceLayer.getInstance().getPublicPenaltiesPageSize();

        //Assert
        Assert.areEqual(20, penPageSize, 'Incorrect Public Penalties Page Size returned');        
    }

    @isTest
    static void useNewGovEpcEndpoint_withValue_retrievesValue() {

        Boolean returnValue = CustomSettingsServiceLayer.getInstance().useNewGovEpcEndpoint();

        //Assert
        Assert.isFalse(returnValue, 'Incorrect Use New Gov EPC Endpoint value returned');        
    }
}