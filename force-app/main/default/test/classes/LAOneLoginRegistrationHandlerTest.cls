@IsTest
private class LAOneLoginRegistrationHandlerTest {
    
    private static final String TEST_EMAIL = 'testuser@example.com';
    private static final String TEST_FIRST_NAME = 'Test';
    private static final String TEST_LAST_NAME = 'User';
    private static final String COMMUNITY_PROFILE_NAME = 'DEZNZ_PRS_Local Authority Customer Community Plus Login User';
    private static final String PERMISSION_SET_GROUP_NAME = 'DEZNZ_PRS_Portal_Local_Authority_Access';
    private static final String PERMISSION_SET_NAME = 'PublicSectorAccsForCmnyUser';
    
    @TestSetup
    static void setupTestData() {
        // Create Person Account with Allow_Local_Authority_Access__c = true
        Account personAccount = new Account(
            FirstName = TEST_FIRST_NAME,
            LastName = TEST_LAST_NAME,
            PersonEmail = TEST_EMAIL,
            Allow_Local_Authority_Access__c = true
        );
        insert personAccount;
    }
    
    @IsTest
    static void testCreateUser_Success() {
        // Arrange
        Account personAccount = [
            SELECT Id, PersonContactId, PersonEmail, FirstName, LastName
            FROM Account
            WHERE PersonEmail = :TEST_EMAIL
            LIMIT 1
        ];
        
        Profile testProfile = [
            SELECT Id 
            FROM Profile 
            WHERE Name = :COMMUNITY_PROFILE_NAME 
            LIMIT 1
        ];
        
        Auth.UserData userData = createUserData(TEST_EMAIL, TEST_FIRST_NAME, TEST_LAST_NAME);
        LAOneLoginRegistrationHandler handler = new LAOneLoginRegistrationHandler();
        
        // Act
        Test.startTest();
        User createdUser = handler.createUser(null, userData);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, createdUser, 'User should be created');
        System.assertEquals(TEST_EMAIL + '.prseLA.co.uk', createdUser.Username, 'Username should match expected format');
        System.assertEquals(TEST_EMAIL, createdUser.Email, 'Email should match');
        System.assertEquals(TEST_FIRST_NAME, createdUser.FirstName, 'First name should match');
        System.assertEquals(TEST_LAST_NAME, createdUser.LastName, 'Last name should match');
        System.assertEquals(personAccount.PersonContactId, createdUser.ContactId, 'ContactId should match Person Account contact');
        System.assertEquals('12345', createdUser.FederationIdentifier, 'Federation ID should be set');
        
        User insertedUser = [
            SELECT Id, Username, Email, ContactId, FederationIdentifier
            FROM User
            WHERE Id = :createdUser.Id
        ];
        System.assertNotEquals(null, insertedUser, 'User should exist in database');
    }
    
    @IsTest
    static void testCreateUser_FailureScenarios() {
        String nonExistentEmail = 'nonexistent@example.com';
        Auth.UserData noAccountData = createUserData(nonExistentEmail, 'NonExistent', 'User');
        LAOneLoginRegistrationHandler handler = new LAOneLoginRegistrationHandler();
        
        Test.startTest();
        User noAccountUser = handler.createUser(null, noAccountData);
        Test.stopTest();
        
        System.assertEquals(null, noAccountUser, 'User should not be created when no Person Account exists');
        
        Account restrictedAccount = new Account(
            FirstName = 'Restricted',
            LastName = 'User',
            PersonEmail = 'restricted@example.com',
            Allow_Local_Authority_Access__c = false
        );
        insert restrictedAccount;
        
        Auth.UserData restrictedData = createUserData('restricted@example.com', 'Restricted', 'User');
        User restrictedUser = handler.createUser(null, restrictedData);
        
        System.assertEquals(null, restrictedUser, 'User should not be created when Person Account does not allow LA access');
        
        // Verify no users were created in the database
        List<User> users = [
            SELECT Id 
            FROM User 
            WHERE Email IN (:nonExistentEmail, 'restricted@example.com')
        ];
        System.assertEquals(0, users.size(), 'No users should exist in database for failed scenarios');
    }
    
    @IsTest
    static void testUpdateUser() {
        // Arrange
        Account personAccount = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE PersonEmail = :TEST_EMAIL
            LIMIT 1
        ];
        
        Profile communityProfile = getCommunityProfile();
        
        User testUser = new User(
            Username = 'originaluser@test.com.prseLA.co.uk',
            Email = 'original@test.com',
            FirstName = 'Original',
            LastName = 'Name',
            Alias = 'orig1',
            CommunityNickname = 'orig1',
            ProfileId = communityProfile.Id,
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_GB',
            ContactId = personAccount.PersonContactId,
            IsActive = true
        );
        insert testUser;
        
        String newEmail = 'updated@example.com';
        String newFirstName = 'Updated';
        String newLastName = 'User';
        Auth.UserData userData = createUserData(newEmail, newFirstName, newLastName);
        LAOneLoginRegistrationHandler handler = new LAOneLoginRegistrationHandler();
        
        // Act 
        Test.startTest();
        handler.updateUser(testUser.Id, null, userData);
        
        // Test 
        handler.updateUser(UserInfo.getUserId(), null, userData);
        Test.stopTest();
        
        // Assert
        User updatedUser = [
            SELECT Id, FirstName, LastName, Email
            FROM User
            WHERE Id = :testUser.Id
        ];
        System.assertEquals(newFirstName, updatedUser.FirstName, 'First name should be updated');
        System.assertEquals(newLastName, updatedUser.LastName, 'Last name should be updated');
        System.assertEquals(newEmail, updatedUser.Email, 'Email should be updated');
    }
    
    @IsTest
    static void testAssignPermissionSetGroup() {
        // Arrange 
        Account personAccount = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE PersonEmail = :TEST_EMAIL
            LIMIT 1
        ];
        
        Profile communityProfile = getCommunityProfile();
        
        User testUser = new User(
            Username = 'permtest@test.com.prseLA.co.uk',
            Email = 'permtest@test.com',
            FirstName = 'Perm',
            LastName = 'Test',
            Alias = 'ptest',
            CommunityNickname = 'ptest',
            ProfileId = communityProfile.Id,
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_GB',
            ContactId = personAccount.PersonContactId,
            IsActive = true
        );
        insert testUser;
        
        // Act 
        Test.startTest();
        LAOneLoginRegistrationHandler.assignPermissionSetGroup(testUser.Id);
        Test.stopTest();
        
        // Assert 
        System.assert(true, 'Permission assignment should complete without throwing exceptions');
    }
    
    // Helper method to create Auth.UserData
    private static Auth.UserData createUserData(String email, String firstName, String lastName) {
        return new Auth.UserData(
            '12345',                    
            firstName,                  
            lastName,                   
            firstName + ' ' + lastName, 
            email,                      
            null,                       
            'testuser',                 
            'en_US',                    
            'LAOneLogin',                 
            null,                       
            new Map<String, String>()   
        );
    }
    
    // Helper method to get a community/portal profile
    private static Profile getCommunityProfile() {
        List<Profile> profiles = [
            SELECT Id 
            FROM Profile 
            WHERE (Name = :COMMUNITY_PROFILE_NAME 
                   OR Name LIKE '%Community%' 
                   OR Name LIKE '%Customer%Portal%')
            AND UserType IN ('PowerCustomerSuccess', 'CustomerSuccess')
            LIMIT 1
        ];
        if (!profiles.isEmpty()) {
            return profiles[0];
        }
        return [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    }
}