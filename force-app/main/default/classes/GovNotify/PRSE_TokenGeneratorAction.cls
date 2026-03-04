public class PRSE_TokenGeneratorAction {

    public class TokenRequest {
        @InvocableVariable(required=true)
        public String userId;
        
        @InvocableVariable(required=true)
        public String targetId;
    }

    public class TokenResponse {
        @InvocableVariable
        public String token;
        
        @InvocableVariable
        public String timestamp;
    }

    @InvocableMethod(
        label='Generates User Login Token'
        description='Generates a secure token for a user with timestamp'
        category='PRS Exemption Register'
    )
    public static List<TokenResponse> generateToken(List<TokenRequest> requests) {
        List<TokenResponse> responses = new List<TokenResponse>();
        String encryptionKey = new CustomSettingsService().getUserTokenEncryptionKey();
        for (TokenRequest req : requests) {
            try {
                Long timestamp = DateTime.now().getTime();
                String message = 'userId=' + req.userId + '&timestamp=' + timestamp + '&targetId=' + req.targetId;
                Blob keyBlob = EncodingUtil.base64Decode(encryptionKey);
                Blob messageBlob = Blob.valueOf(message);
                Blob mac = Crypto.encryptWithManagedIV('AES256', keyBlob, messageBlob);
                String token = EncodingUtil.base64Encode(mac);
                TokenResponse res = new TokenResponse();
                res.token = token;
                res.timestamp = String.valueOf(timestamp);
                responses.add(res);
            } catch (Exception e) {
                throw new AuraHandledException('Token decryption failed: ' + e.getMessage());
            }
        }
        return responses;
    }
}