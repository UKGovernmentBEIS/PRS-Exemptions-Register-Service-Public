public class PRSE_TokenDecryptionAction {
    
    public class TokenInput {
        @InvocableVariable(required=true)
        public String token;
    }

    public class TokenOutput {
        @InvocableVariable 
        public String userId;
        
        @InvocableVariable 
        public String timestamp;
        
        @InvocableVariable 
        public String targetId;
    }

    @InvocableMethod(
        label='Decrypts User Login Token'
        category='PRS Exemption Register'
    )
    public static List<TokenOutput> decrypt(List<TokenInput> inputs) {
        List<TokenOutput> results = new List<TokenOutput>();

        for (TokenInput input : inputs) {
            try {
                // Get encryption key 
                String encryptionKey = new CustomSettingsService().getUserTokenEncryptionKey();
                Blob keyBlob = EncodingUtil.base64Decode(encryptionKey);

                // Decode and decrypt the token
                Blob encryptedBlob = EncodingUtil.base64Decode(input.token);
                Blob decryptedBlob = Crypto.decryptWithManagedIV('AES256', keyBlob, encryptedBlob);

                // Convert decrypted blob to string
                String decrypted = decryptedBlob.toString();

                // Parse the string into key-value pairs
                Map<String, String> values = new Map<String, String>();
                for (String pair : decrypted.split('&')) {
                    List<String> kv = pair.split('=');
                    if (kv.size() == 2) {
                        values.put(kv[0], kv[1]);
                    }
                }

                // Build output
                TokenOutput output = new TokenOutput();
                output.userId = values.get('userId');
                output.timestamp = values.get('timestamp');
                output.targetId = values.get('targetId');
                results.add(output);

            } catch (Exception e) {
                throw new AuraHandledException('Token decryption failed: ' + e.getMessage());
            }
        }

        return results;
    }
}