/**
 * Test class for OneLoginProvider
 * Created by hpatel on 17/09/2025.
 */
@IsTest
private class OneLoginProviderTest {

    // Test data constants
    private static final String CLIENT_ID = 'test-client-id';
    private static final String REDIRECT_URL = 'https://test.salesforce.com/auth/callback';
    private static final String SCOPE = 'openid email phone';
    private static final String DISCOVERY_URL = 'https://test.onelogin.com/.well-known/openid_configuration';
    private static final String VTR = 'Cl.Cm';
    //The key provided in this test is a dummy key and is not valid for any real authentication. It is only used for testing purposes to ensure that the code can handle the presence of a private key in the configuration.
    private static final String PRIVATE_KEY = '-----BEGIN PRIVATE KEY-----\n' +
            'MIIBOgIBAAJBAKj34GkxFhD90vcNLYLInFEX6Ppy1tPf9Cnzj4p4WGeKLs1Pt8Qu\n' +
            'KUpRKfFLfRYC9AIKjbJTWit+CqvjWYzvQwECAwEAAQJAIJLixBy2qpFoS4DSmoEm\n' +
            'o3qGy0t6z09AIJtH+5OeRV1be+N4cDYJKffGzDa88vQENZiRm0GRq6a+HPGQMd2k\n' +
            'TQIhAKMSvzIBnni7ot/OSie2TmJLY4SwTQAevXysE2RbFDYdAiEBCUEaRQnMnbp7\n' +
            '9mxDXDf6AU0cN/RPBjb9qSHDcWZHGzUCIG2Es59z8ugGrDY+pxLQnwfotadxd+Uy\n' +
            'v/Ow5T0q5gIJAiEAyS4RaI9YG8EWx/2w0T67ZUVAw8eOMB6BIUg0Xcu+3okCIBOs\n' +
            '/5OiPgoTdSy7bcF9IGpSE8ZgGKzgYQVZeN97YE00\n' +
            '-----END PRIVATE KEY-----';
    private static final String STATE = 'test-state-123';
    private static final String NONCE = 'test-nonce-456';
    private static final String AUTH_CODE = 'test-auth-code-789';
    private static final String ACCESS_TOKEN = 'test-access-token';
    private static final String ID_TOKEN = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.test-signature';
    @TestSetup
    static void makeData() {
        // Setup test user if needed
        User testUser = new User(
                Username = 'test@onelogin.test.com',
                Email = 'test@onelogin.test.com',
                FirstName = 'Test',
                LastName = 'User',
                Alias = 'tuser',
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
                FederationIdentifier = 'test-sub-123'
        );
        // Note: Don't insert the user in setup, we'll handle it in individual tests
    }
    @IsTest
    static void testGetCustomMetadataType() {
        // Given
        OneLoginProvider provider = new OneLoginProvider();

        // When
        Test.startTest();
        String metadataType = provider.getCustomMetadataType();
        Test.stopTest();

        // Then
        System.assertEquals('OneLoginClientConfiguration__mdt', metadataType,
                'Should return correct custom metadata type');
    }
    @IsTest
    static void testInitiate_Success() {
        // Given
        OneLoginProvider provider = new OneLoginProvider();
        Map<String, String> authConfig = createAuthProviderConfig();

        // Mock HTTP responses for discovery endpoint
        Test.setMock(HttpCalloutMock.class, new DiscoveryMockHttpResponse());

        // When
        Test.startTest();
        PageReference result = provider.initiate(authConfig, STATE);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, result, 'Should return PageReference');
        String url = result.getUrl();
        System.assert(url.contains('client_id=' + CLIENT_ID), 'URL should contain client ID');
        System.assert(url.contains('response_type=code'), 'URL should contain response type');
        System.assert(url.contains('redirect_uri='), 'URL should contain redirect URI');
        System.assert(url.contains('scope='), 'URL should contain scope');
        System.assert(url.contains('state=' + STATE), 'URL should contain state');
        System.assert(url.contains('nonce='), 'URL should contain nonce');
        System.assert(url.contains('vtr='), 'URL should contain vtr');
    }
    @IsTest
    static void testHandleCallback_Success() {
        // Given
        OneLoginProvider provider = new OneLoginProvider();
        Map<String, String> authConfig = createAuthProviderConfig();
        Auth.AuthProviderCallbackState callbackState = createCallbackState();

        // Mock HTTP responses
        Test.setMock(HttpCalloutMock.class, new CallbackMockHttpResponse());

        // When
        Test.startTest();
        Auth.AuthProviderTokenResponse result = provider.handleCallback(authConfig, callbackState);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, result, 'Should return token response');
        System.assertEquals('OneLogin', result.provider, 'Provider should be OneLogin');
        System.assertEquals(ACCESS_TOKEN, result.oauthToken, 'Should return access token');
        System.assertEquals(ID_TOKEN, result.oauthSecretOrRefreshToken, 'Should return ID token');
        System.assertEquals(STATE, result.state, 'Should return correct state');
    }
    @IsTest
    static void testGetUserInfo_Success() {
        // Given
        OneLoginProvider provider = new OneLoginProvider();
        Map<String, String> authConfig = createAuthProviderConfig();
        Auth.AuthProviderTokenResponse tokenResponse = new Auth.AuthProviderTokenResponse(
                'OneLogin', ACCESS_TOKEN, ID_TOKEN, STATE
        );

        // Mock HTTP responses
        Test.setMock(HttpCalloutMock.class, new UserInfoMockHttpResponse());

        // When
        Test.startTest();
        Auth.UserData userData = provider.getUserInfo(authConfig, tokenResponse);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, userData, 'Should return user data');
        System.assertEquals('test-sub-123', userData.identifier, 'Should return correct user ID');
        System.assertEquals('test@example.com', userData.email, 'Should return correct email');
        System.assertEquals('test@example.com', userData.username, 'Should return correct username');
        System.assertEquals('OneLogin', userData.provider, 'Should return correct provider');
        System.assertEquals('en-GB', userData.locale, 'Should return correct locale');
    }
    @IsTest
    static void testHandleCallback_TokenExchangeFailed() {
        // Given
        OneLoginProvider provider = new OneLoginProvider();
        Map<String, String> authConfig = createAuthProviderConfig();
        Auth.AuthProviderCallbackState callbackState = createCallbackState();

        // Mock HTTP responses with failure
        Test.setMock(HttpCalloutMock.class, new FailedTokenMockHttpResponse());

        // When & Then
        Test.startTest();
        try {
            provider.handleCallback(authConfig, callbackState);
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {

            System.assert(e.getMessage().contains('Token exchange failed'),
                    'Should throw token exchange exception');
        }
        Test.stopTest();
    }
    @IsTest
    static void testGetUserInfo_HttpRequestFailed() {
        // Given
        OneLoginProvider provider = new OneLoginProvider();
        Map<String, String> authConfig = createAuthProviderConfig();
        Auth.AuthProviderTokenResponse tokenResponse = new Auth.AuthProviderTokenResponse(
                'OneLogin', ACCESS_TOKEN, ID_TOKEN, STATE
        );

        // Mock HTTP responses with failure
        Test.setMock(HttpCalloutMock.class, new FailedUserInfoMockHttpResponse());

        // When & Then
        Test.startTest();
        try {
            provider.getUserInfo(authConfig, tokenResponse);
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('HTTP request to userinfo endpoint failed'),
                    'Should throw userinfo request exception');
        }
        Test.stopTest();
    }
    //Methods for the Initiate test
    // Helper methods for creating test data
    private static Map<String, String> createAuthProviderConfig() {
        return new Map<String, String>{
                'ClientID__c' => CLIENT_ID,
                'RedirectUrl__c' => REDIRECT_URL,
                'Scopes__c' => SCOPE,
                'DiscoveryUrl__c' => DISCOVERY_URL,
                'VectorOfTrust__c' => VTR,
                'PrivateKey__c' => PRIVATE_KEY,
                'DIDUrl__c' => 'https://test.gov.uk/.well-known/did.json',
                'IdentityIssuer__c' => 'https://identity.test.account.gov.uk/'
        };
    }

    // Mock HTTP Response classes - Global for guest user access
    private class DiscoveryMockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            Map<String, Object> discoveryData = new Map<String, Object>{
                    'authorization_endpoint' => 'https://test.onelogin.com/auth',
                    'token_endpoint' => 'https://test.onelogin.com/token',
                    'userinfo_endpoint' => 'https://test.onelogin.com/userinfo',
                    'jwks_uri' => 'https://test.onelogin.com/.well-known/jwks.json',
                    'issuer' => 'https://test.onelogin.com'
            };

            res.setBody(JSON.serialize(discoveryData));
            return res;
        }
    }

    //Methods for the handleCallback test
    private static Auth.AuthProviderCallbackState createCallbackState() {
        Map<String, String> queryParams = new Map<String, String>{
                'code' => AUTH_CODE,
                'state' => STATE
        };
        return new Auth.AuthProviderCallbackState(null, null, queryParams);
    }
    private class CallbackMockHttpResponse implements HttpCalloutMock {
        public  HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            if (req.getEndpoint().contains('token')) {
                Map<String, Object> tokenData = new Map<String, Object>{
                        'access_token' => ACCESS_TOKEN,
                        'id_token' => ID_TOKEN,
                        'token_type' => 'Bearer',
                        'expires_in' => 3600
                };
                res.setBody(JSON.serialize(tokenData));
            } else {
                Map<String, Object> discoveryData = new Map<String, Object>{
                        'authorization_endpoint' => 'https://test.onelogin.com/auth',
                        'token_endpoint' => 'https://test.onelogin.com/token',
                        'userinfo_endpoint' => 'https://test.onelogin.com/userinfo',
                        'jwks_uri' => 'https://test.onelogin.com/.well-known/jwks.json',
                        'issuer' => 'https://test.onelogin.com'
                };
                res.setBody(JSON.serialize(discoveryData));
            }

            return res;
        }
    }
    private class UserInfoMockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            if (req.getEndpoint().contains('userinfo')) {
                Map<String, Object> userData = new Map<String, Object>{
                        'sub' => 'test-sub-123',
                        'email' => 'test@example.com',
                        'phone_number' => '+1234567890',
                        'email_verified' => true
                };
                res.setBody(JSON.serialize(userData));
            } else {
                Map<String, Object> discoveryData = new Map<String, Object>{
                        'authorization_endpoint' => 'https://test.onelogin.com/auth',
                        'token_endpoint' => 'https://test.onelogin.com/token',
                        'userinfo_endpoint' => 'https://test.onelogin.com/userinfo',
                        'jwks_uri' => 'https://test.onelogin.com/.well-known/jwks.json',
                        'issuer' => 'https://test.onelogin.com'
                };
                res.setBody(JSON.serialize(discoveryData));
            }

            return res;
        }
    }
    private class FailedTokenMockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(400);

                Map<String, Object> discoveryData = new Map<String, Object>{
                        'authorization_endpoint' => 'https://test.onelogin.com/auth',
                        'token_endpoint' => 'https://test.onelogin.com/token',
                        'userinfo_endpoint' => 'https://test.onelogin.com/userinfo',
                        'jwks_uri' => 'https://test.onelogin.com/.well-known/jwks.json',
                        'issuer' => 'https://test.onelogin.com'
                };
                res.setBody(JSON.serialize(discoveryData));
           return res;
        }
    }
    private class FailedUserInfoMockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();

            if (req.getEndpoint().contains('userinfo')) {
                res.setStatusCode(401);
                res.setBody('{"error":"invalid_token"}');
            } else {
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/json');
                Map<String, Object> discoveryData = new Map<String, Object>{
                        'authorization_endpoint' => 'https://test.onelogin.com/auth',
                        'token_endpoint' => 'https://test.onelogin.com/token',
                        'userinfo_endpoint' => 'https://test.onelogin.com/userinfo',
                        'jwks_uri' => 'https://test.onelogin.com/.well-known/jwks.json',
                        'issuer' => 'https://test.onelogin.com'
                };
                res.setBody(JSON.serialize(discoveryData));
            }

            return res;
        }
    }
}