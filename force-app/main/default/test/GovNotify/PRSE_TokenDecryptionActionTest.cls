@isTest(IsParallel=true)
private class PRSE_TokenDecryptionActionTest {

    @isTest
    static void decrypt_withEmptyInputs_returnsEmptyResults() {
        //Arrange, Act
        List<PRSE_TokenDecryptionAction.TokenOutput> tokenOutputs = PRSE_TokenDecryptionAction.decrypt(
            new List<PRSE_TokenDecryptionAction.TokenInput>()
        );

        //Assert
        Assert.isTrue(tokenOutputs.isEmpty(), 'Expected no tokenOutputs');
    }

    @isTest
    static void decrypt_withSingleInputAndNullToken_throwsExeption() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setUserTokenEncryptionKey(createMockUserTokenEncryptionKey());
        CustomSettingsServiceLayer.instance = customSettingsMock;
        PRSE_TokenDecryptionAction.TokenInput tokenInput = new PRSE_TokenDecryptionAction.TokenInput();

        //Act
        try{
            PRSE_TokenDecryptionAction.decrypt(
                new List<PRSE_TokenDecryptionAction.TokenInput>{ tokenInput }
            );
            Assert.fail('Expected exception');
        } catch(Exception ex){
            //Assert
            Assert.isTrue(ex instanceof System.AuraHandledException, 'Expected to throw an AuraHandledException');
            Assert.areEqual('Script-thrown exception', ex.getMessage(), 'Incorrect error message thrown');
        }
    }

    @isTest
    static void decrypt_withSingleInputAndEmptyToken_returnsEmptyResults() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setUserTokenEncryptionKey(createMockUserTokenEncryptionKey());
        CustomSettingsServiceLayer.instance = customSettingsMock;
        PRSE_TokenDecryptionAction.TokenInput tokenInput = new PRSE_TokenDecryptionAction.TokenInput();
        tokenInput.token = '';

        //Act
        try{
            PRSE_TokenDecryptionAction.decrypt(
                new List<PRSE_TokenDecryptionAction.TokenInput>{ tokenInput }
            );
            Assert.fail('Expected exception');
        } catch(Exception ex){
            //Assert
            Assert.isTrue(ex instanceof System.AuraHandledException, 'Expected to throw an AuraHandledException');
            Assert.areEqual('Script-thrown exception', ex.getMessage(), 'Incorrect error message thrown');
        }
    }

    @isTest
    static void decrypt_withSingleInputAndInvalidToken_throwsException() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setUserTokenEncryptionKey(createMockUserTokenEncryptionKey());
        CustomSettingsServiceLayer.instance = customSettingsMock;
        PRSE_TokenDecryptionAction.TokenInput tokenInput = new PRSE_TokenDecryptionAction.TokenInput();
        tokenInput.token = '123123123';

        //Act
        try{
            PRSE_TokenDecryptionAction.decrypt(
                new List<PRSE_TokenDecryptionAction.TokenInput>{ tokenInput }
            );
            Assert.fail('Expected exception');
        } catch(Exception ex){
            //Assert
            Assert.isTrue(ex instanceof System.AuraHandledException, 'Expected to throw an AuraHandledException');
            Assert.areEqual('Script-thrown exception', ex.getMessage(), 'Incorrect error message thrown');
        }
    }

    @isTest
    static void decrypt_withSingleInputAndValidToken_returnsValidOutput() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setUserTokenEncryptionKey(createMockUserTokenEncryptionKey());
        CustomSettingsServiceLayer.instance = customSettingsMock;
        PRSE_TokenDecryptionAction.TokenInput tokenInput = new PRSE_TokenDecryptionAction.TokenInput();
        tokenInput.token = generateMockUserToken('12345', '67890');

        //Act
         List<PRSE_TokenDecryptionAction.TokenOutput> tokenOutputs = PRSE_TokenDecryptionAction.decrypt(
            new List<PRSE_TokenDecryptionAction.TokenInput>{ tokenInput }
        );

        //Assert
        Assert.areEqual(1, tokenOutputs.size(), 'Incorrect number of token outputs returned.');
        PRSE_TokenDecryptionAction.TokenOutput singleTokenOutput = tokenOutputs[0];
        Assert.areEqual('12345', singleTokenOutput.userId, 'Incorrect userId on TokenOutput.');
        Assert.areEqual('67890', singleTokenOutput.targetId, 'Incorrect targetId on TokenOutput.');
        Assert.isNotNull(singleTokenOutput.timeStamp, 'Expected timeStamp to be populated');
    }

    @isTest
    static void decrypt_withMultipleInputsWithValidTokens_returnsMultipleValidOutputs() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setUserTokenEncryptionKey(createMockUserTokenEncryptionKey());
        CustomSettingsServiceLayer.instance = customSettingsMock;
        PRSE_TokenDecryptionAction.TokenInput tokenInput = new PRSE_TokenDecryptionAction.TokenInput();
        tokenInput.token = generateMockUserToken('12345', '67890');
        PRSE_TokenDecryptionAction.TokenInput tokenInput2 = new PRSE_TokenDecryptionAction.TokenInput();
        tokenInput2.token = generateMockUserToken('44444', '33333');

        //Act
         List<PRSE_TokenDecryptionAction.TokenOutput> tokenOutputs = PRSE_TokenDecryptionAction.decrypt(
            new List<PRSE_TokenDecryptionAction.TokenInput>{ tokenInput, tokenInput2 }
        );

        //Assert
        Assert.areEqual(2, tokenOutputs.size(), 'Incorrect number of token outputs returned.');

        PRSE_TokenDecryptionAction.TokenOutput firstTokenOutput = tokenOutputs[0];
        Assert.areEqual('12345', firstTokenOutput.userId, 'Incorrect userId on TokenOutput.');
        Assert.areEqual('67890', firstTokenOutput.targetId, 'Incorrect targetId on TokenOutput.');
        Assert.isNotNull(firstTokenOutput.timeStamp, 'Expected timeStamp to be populated');

        PRSE_TokenDecryptionAction.TokenOutput secondTokenOutput = tokenOutputs[1];
        Assert.areEqual('44444', secondTokenOutput.userId, 'Incorrect userId on TokenOutput.');
        Assert.areEqual('33333', secondTokenOutput.targetId, 'Incorrect targetId on TokenOutput.');
        Assert.isNotNull(secondTokenOutput.timeStamp, 'Expected timeStamp to be populated');
    }
    private static String generateMockUserToken(String userId, String targetId) { 
        PRSE_TokenGeneratorAction.TokenRequest singleRequest = new PRSE_TokenGeneratorAction.TokenRequest();
        singleRequest.userId = userId;
        singleRequest.targetId = targetId;
        PRSE_TokenGeneratorAction.TokenResponse generatedToken = PRSE_TokenGeneratorAction.generateToken(
            new List<PRSE_TokenGeneratorAction.TokenRequest>{ singleRequest }
        )[0];
        return generatedToken.token;
    }

    private static String createMockUserTokenEncryptionKey() {
        Blob key = Crypto.generateAesKey(256);
        return EncodingUtil.base64Encode(key);
    }
}