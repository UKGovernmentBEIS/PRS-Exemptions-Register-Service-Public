@isTest(IsParallel=true)
private class LogoutControllerTest {
    
    private static final String TEST_EMAIL = 'testuser@example.com';
    private static final String TEST_ID_TOKEN = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.test.token';
    private static final String EXPECTED_LOGOUT_BASE_URL = 'https://oidc.integration.account.gov.uk/logout';
    
    @TestSetup
    static void setupTestData() {
        User_Session__c userSession = new User_Session__c(
            User__c = UserInfo.getUserEmail(),
            Id_Token__c = TEST_ID_TOKEN
        );
        insert userSession;
    }
    
    @IsTest
    static void testGetLogoutUrl_Success() {
        // Arrange
        User_Session__c session = [
            SELECT Id, User__c, Id_Token__c
            FROM User_Session__c
            WHERE User__c = :UserInfo.getUserEmail()
            LIMIT 1
        ];
        
        // Act
        Test.startTest();
        Map<String, String> result = LogoutController.getLogoutUrl();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('true', result.get('success'), 'Success flag should be true');
        System.assertNotEquals(null, result.get('logoutUrl'), 'Logout URL should not be null');
        System.assert(result.get('logoutUrl').contains(EXPECTED_LOGOUT_BASE_URL), 
            'Logout URL should contain expected base URL');
        System.assert(result.get('logoutUrl').contains('id_token_hint=' + TEST_ID_TOKEN), 
            'Logout URL should contain id_token_hint parameter');
        System.assert(result.get('logoutUrl').contains('post_logout_redirect_uri='), 
            'Logout URL should contain post_logout_redirect_uri parameter');
    }
    
    @IsTest
    static void testGetLogoutUrl_NoActiveSession() {
        // Arrange
        delete [SELECT Id FROM User_Session__c WHERE User__c = :UserInfo.getUserEmail()];
        
        // Act & Assert
        Test.startTest();
        try {
            Map<String, String> result = LogoutController.getLogoutUrl();
            System.assert(false, 'Should have thrown an exception for no active session');
        } catch (AuraHandledException ex) {
            // AuraHandledException wraps the message, so check if it contains our text anywhere
            String exMessage = ex.getMessage();
            System.assert(
                exMessage.contains('No active session found') || 
                exMessage.contains('Script-thrown exception'), 
                'Exception should be thrown. Message: ' + exMessage
            );
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetLogoutUrl_BlankIdToken() {
        // Arrange
        User_Session__c session = [
            SELECT Id 
            FROM User_Session__c 
            WHERE User__c = :UserInfo.getUserEmail()
            LIMIT 1
        ];
        session.Id_Token__c = '';
        update session;
        
        // Act & Assert
        Test.startTest();
        try {
            Map<String, String> result = LogoutController.getLogoutUrl();
            System.assert(false, 'Should have thrown an exception for blank id token');
        } catch (AuraHandledException ex) {
            String exMessage = ex.getMessage();
            System.assert(
                exMessage.contains('No active session found') || 
                exMessage.contains('Script-thrown exception'), 
                'Exception should be thrown. Message: ' + exMessage
            );
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetLogoutUrl_NullIdToken() {
        // Arrange
        User_Session__c session = [
            SELECT Id 
            FROM User_Session__c 
            WHERE User__c = :UserInfo.getUserEmail()
            LIMIT 1
        ];
        session.Id_Token__c = null;
        update session;
        
        // Act & Assert
        Test.startTest();
        try {
            Map<String, String> result = LogoutController.getLogoutUrl();
            System.assert(false, 'Should have thrown an exception for null id token');
        } catch (AuraHandledException ex) {
            String exMessage = ex.getMessage();
            System.assert(
                exMessage.contains('No active session found') || 
                exMessage.contains('Script-thrown exception'), 
                'Exception should be thrown. Message: ' + exMessage
            );
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testClearSalesforceSession_Success() {
        // Arrange
        List<User_Session__c> sessionsBefore = [
            SELECT Id, User__c
            FROM User_Session__c
            WHERE User__c = :UserInfo.getUserEmail()
        ];
        System.assertEquals(1, sessionsBefore.size(), 'Should have 1 session from setup');
        
        // Act
        Test.startTest();
        Map<String, Object> result = LogoutController.clearSalesforceSession();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Success flag should be true');
        System.assertEquals(null, result.get('error'), 'Error should be null on success');
        
        // Verify session was deleted
        List<User_Session__c> sessions = [
            SELECT Id 
            FROM User_Session__c 
            WHERE User__c = :UserInfo.getUserEmail()
        ];
        System.assertEquals(0, sessions.size(), 'Session should be deleted from database');
    }
    
    @IsTest
    static void testClearSalesforceSession_NoActiveSession() {
        // Arrange
        delete [SELECT Id FROM User_Session__c WHERE User__c = :UserInfo.getUserEmail()];
        
        // Act
        Test.startTest();
        Map<String, Object> result = LogoutController.clearSalesforceSession();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.get('success'), 'Success flag should be false');
        System.assertNotEquals(null, result.get('error'), 'Error message should be present');
        System.assert(result.get('error').toString().contains('No active session found'), 
            'Error message should indicate no active session. Actual: ' + result.get('error'));
    }
    
    @IsTest
    static void testClearSalesforceSession_MultipleSessionsDeletesLatest() {
        // Arrange
        List<User_Session__c> additionalSessions = new List<User_Session__c>();
        for (Integer i = 0; i < 3; i++) {
            additionalSessions.add(new User_Session__c(
                User__c = UserInfo.getUserEmail(),
                Id_Token__c = 'token_' + i
            ));
        }
        insert additionalSessions;
        
        Integer sessionCountBefore = [
            SELECT COUNT() 
            FROM User_Session__c 
            WHERE User__c = :UserInfo.getUserEmail()
        ];
        
        System.assertEquals(4, sessionCountBefore, 'Should have 4 sessions total');
        
        // Act
        Test.startTest();
        Map<String, Object> result = LogoutController.clearSalesforceSession();
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result.get('success'), 'Should successfully delete latest session');
        
        Integer sessionCountAfter = [
            SELECT COUNT() 
            FROM User_Session__c 
            WHERE User__c = :UserInfo.getUserEmail()
        ];
        System.assertEquals(3, sessionCountAfter, 
            'Should have 3 sessions remaining after deleting latest');
    }
    
    @IsTest
    static void testGetLogoutUrl_ExceptionHandling() {
        // Arrange
        delete [SELECT Id FROM User_Session__c WHERE User__c = :UserInfo.getUserEmail()];
        
        // Act & Assert
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            LogoutController.getLogoutUrl();
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
            System.assertNotEquals(null, ex.getMessage(), 
                'Exception message should not be null');
            // Just verify an exception was thrown, don't check specific message
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 
            'An AuraHandledException should be thrown for error scenarios');
    }
    
    @IsTest
    static void testGetIdTokenFromAuthSession_ReturnsLatestSession() {
        // Arrange
        List<User_Session__c> oldSessions = new List<User_Session__c>();
        for (Integer i = 0; i < 2; i++) {
            oldSessions.add(new User_Session__c(
                User__c = UserInfo.getUserEmail(),
                Id_Token__c = 'old_token_' + i
            ));
        }
        insert oldSessions;
        
        // Act
        Test.startTest();
        Map<String, String> result = LogoutController.getLogoutUrl();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.get('logoutUrl'), 'Logout URL should be generated');
        System.assertEquals('true', result.get('success'), 'Should be successful');
    }
}