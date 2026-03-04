@isTest(IsParallel=true)
private class PRSE_TokenGeneratorActionTest {

    @isTest
    static void generateToken_withEmptyRequests_returnsEmptyResponses() {
        //Arrange, Act
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setUserTokenEncryptionKey(createMockUserTokenEncryptionKey());
        CustomSettingsServiceLayer.instance = customSettingsMock;
        List<PRSE_TokenGeneratorAction.TokenResponse> TokenRequests = PRSE_TokenGeneratorAction.generateToken(
            new List<PRSE_TokenGeneratorAction.TokenRequest>()
        );

        //Assert
        Assert.isTrue(TokenRequests.isEmpty(), 'Expected no tokenRequests');
    }

    @isTest
    static void generateToken_withInvalidEncryptionKey_throwsException() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setUserTokenEncryptionKey('asdasd123123123');
        CustomSettingsServiceLayer.instance = customSettingsMock;

        PRSE_TokenGeneratorAction.TokenRequest tokenRequest = new PRSE_TokenGeneratorAction.TokenRequest();
        tokenRequest.userId = '12345';
        tokenRequest.targetId = '67890';

        //Act
        try {
            PRSE_TokenGeneratorAction.generateToken(
                new List<PRSE_TokenGeneratorAction.TokenRequest>{ tokenRequest }
            );
            Assert.fail('Expected exception.');
        } catch (Exception ex) {
            //Assert
             Assert.areEqual('Script-thrown exception', ex.getMessage(), 'Incorrect error message');
        }
    }

    @isTest
    static void generateToken_withSingleRequest_returnsValidResponse() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setUserTokenEncryptionKey(createMockUserTokenEncryptionKey());
        CustomSettingsServiceLayer.instance = customSettingsMock;

        PRSE_TokenGeneratorAction.TokenRequest tokenRequest = new PRSE_TokenGeneratorAction.TokenRequest();
        tokenRequest.userId = '12345';
        tokenRequest.targetId = '67890';

        //Act
        List<PRSE_TokenGeneratorAction.TokenResponse> tokenResponses = PRSE_TokenGeneratorAction.generateToken(
            new List<PRSE_TokenGeneratorAction.TokenRequest>{ tokenRequest }
        );

        //Assert
        Assert.areEqual(1, tokenResponses.size(), 'Incorrect number of token outputs returned.');

        PRSE_TokenGeneratorAction.TokenResponse singleTokenResponse = tokenResponses[0];
        Assert.isNotNull(singleTokenResponse.token, 'Expected token to be populated');
        Assert.isNotNull(singleTokenResponse.timestamp, 'Expected timestamp to be populated');

        PRSE_TokenDecryptionAction.TokenOutput decryptedOutput = generateExpectedDecryptedInfo(singleTokenResponse.token);
        Assert.areEqual('12345', decryptedOutput.userId, 'Incorrect userId decrypted.');
        Assert.areEqual('67890', decryptedOutput.targetId, 'Incorrect targetId decrypted.');
    }

    @isTest
    static void generateToken_withMultipleRequests_returnsMultipleValidResponses() {
        //Arrange
        CustomSettingsLayerMock customSettingsMock = new CustomSettingsLayerMock();
        customSettingsMock.setUserTokenEncryptionKey(createMockUserTokenEncryptionKey());
        CustomSettingsServiceLayer.instance = customSettingsMock;

        PRSE_TokenGeneratorAction.TokenRequest tokenRequest = new PRSE_TokenGeneratorAction.TokenRequest();
        tokenRequest.userId = '12345';
        tokenRequest.targetId = '67890';
        PRSE_TokenGeneratorAction.TokenRequest tokenRequest2 = new PRSE_TokenGeneratorAction.TokenRequest();
        tokenRequest2.userId = '33333';
        tokenRequest2.targetId = '44444';

        //Act
        List<PRSE_TokenGeneratorAction.TokenResponse> tokenResponses = PRSE_TokenGeneratorAction.generateToken(
            new List<PRSE_TokenGeneratorAction.TokenRequest>{ tokenRequest, tokenRequest2 }
        );

        //Assert
        Assert.areEqual(2, tokenResponses.size(), 'Incorrect number of token outputs returned.');

        PRSE_TokenGeneratorAction.TokenResponse tokenResponse = tokenResponses[0];
        Assert.isNotNull(tokenResponse.token, 'Expected token to be populated');
        Assert.isNotNull(tokenResponse.timestamp, 'Expected timestamp to be populated');

        PRSE_TokenDecryptionAction.TokenOutput decryptedOutput = generateExpectedDecryptedInfo(tokenResponse.token);
        Assert.areEqual('12345', decryptedOutput.userId, 'Incorrect userId decrypted.');
        Assert.areEqual('67890', decryptedOutput.targetId, 'Incorrect targetId decrypted.');

        PRSE_TokenGeneratorAction.TokenResponse tokenResponse2 = tokenResponses[1];
        Assert.isNotNull(tokenResponse2.token, 'Expected token to be populated');
        Assert.isNotNull(tokenResponse2.timestamp, 'Expected timestamp to be populated');

        PRSE_TokenDecryptionAction.TokenOutput decryptedOutput2 = generateExpectedDecryptedInfo(tokenResponse2.token);
        Assert.areEqual('33333', decryptedOutput2.userId, 'Incorrect userId decrypted.');
        Assert.areEqual('44444', decryptedOutput2.targetId, 'Incorrect targetId decrypted.');
    }

    private static PRSE_TokenDecryptionAction.TokenOutput generateExpectedDecryptedInfo(String token) { 
        PRSE_TokenDecryptionAction.TokenInput tokenInput = new PRSE_TokenDecryptionAction.TokenInput();
        tokenInput.token = token;
        PRSE_TokenDecryptionAction.TokenOutput tokenOutput = PRSE_TokenDecryptionAction.decrypt(
            new List<PRSE_TokenDecryptionAction.TokenInput>{ tokenInput }
        )[0];
        return tokenOutput;
    }

    private static String createMockUserTokenEncryptionKey() {
        Blob key = Crypto.generateAesKey(256);
        return EncodingUtil.base64Encode(key);
    }
}