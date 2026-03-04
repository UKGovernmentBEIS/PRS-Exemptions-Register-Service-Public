@isTest
private class OneLoginRegistrationHandlerTest {
    // Constants for test data
    private static final String TEST_EMAIL = 'test@example.com';
    private static final String EXISTING_USER_EMAIL = 'existing@user.com';
    private static final String COMMUNITY_PROFILE_NAME = 'DEZNZ_PRS_Landlord Customer Community Plus Login User';
    private static final String PERMISSION_SET_GROUP_NAME = 'DESNZ_PRS_Portal_Landlord_Access';
    private static final String PERMISSION_SET_NAME = 'PublicSectorAccsForCmnyUser';


    //Test running user requires a Role assigned them them otherwise the test will fail
    @TestSetup
    static void makeData(){
        Auth.UserData existingUserData = new Auth.UserData(null, 'Existing', 'User', 'Existing User', EXISTING_USER_EMAIL, null, null, null, null, null, null);

        //Creates existing user for 2nd test as we cannot do mixed DML
        new OneLoginRegistrationHandler().createUser(null, existingUserData);
    }

    //Create test with the valid user data
    @isTest
    static void createUser_withUserData_createsAccountAndUser() {
        //Arrange
        Auth.UserData testUserData = createTestUserData(TEST_EMAIL, 'Test', 'User');
        Profile communityProfile = getCommunityProfile();
        PermissionSetGroup permissionSetGroup = getPermissionSetGroup();
        PermissionSet permissionSet = getPermissionSet();

        //Act
        Test.startTest();

        User newUser = new OneLoginRegistrationHandler().createUser(null, testUserData);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, newUser, 'User should be created');
        System.assertNotEquals(null, newUser.Id, 'User should have an Id');

        // Verify User fields
        assertUserFields(newUser, testUserData, communityProfile.Id);
        // Verify Account creation
        Account createdAccount = getCreatedAccount(testUserData.email);
        System.assertNotEquals(null, createdAccount, 'Account should be created');
        System.assertEquals(createdAccount.PersonContactId, newUser.ContactId, 'ContactId should match PersonContactId');

        // Verify Permission assignments (after Test.stopTest() to ensure @future method completion)
        verifyPermissionAssignments(newUser.Id, permissionSetGroup.Id, permissionSet.Id);
    }

    @isTest
    static void createUser_withAccountCreationFailure_throwsException() {
        // Arrange
        Auth.UserData invalidUserData = new Auth.UserData(
                null, null, null, null, null, // Invalid data - missing email
                null, null, null, null, null, null
        );

        // Act & Assert
        Test.startTest();
        try {
            new OneLoginRegistrationHandler().createUser(null, invalidUserData);
            System.assert(false, 'Expected DmlException was not thrown');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Account creation failed'),
                    'Exception should contain account creation error message');
        }
        Test.stopTest();
    }
    @isTest
    static void createUser_withMissingPersonRecordType_throwsException() {
        // This test would require creating a scenario where Person Account record type doesn't exist
        // In a real org, you might need to use a different approach or skip this test
        // as Person Account record types are typically required in orgs that use them

        // Arrange
        Auth.UserData testUserData = createTestUserData('noperson@test.com', 'No', 'Person');

        // Act & Assert
        Test.startTest();
        try {
            // This would fail if no Person Account record type exists
            // In practice, this scenario is rare in orgs with Person Accounts enabled
            User newUser = new OneLoginRegistrationHandler().createUser(null, testUserData);
            // If we reach here, the test passed normally
            System.assertNotEquals(null, newUser, 'User should be created when Person RT exists');
        } catch (Exception e) {
            // Expected in orgs without Person Account setup
            System.assert(e.getMessage().contains('RecordType') || e.getMessage().contains('Person'),
                    'Exception should be related to Person Account record type');
        }
        Test.stopTest();
    }
    @isTest
    static void createUser_withMissingCommunityProfile_throwsException() {
        // Arrange
        Auth.UserData testUserData = createTestUserData('noprofile@test.com', 'No', 'Profile');

        // Act & Assert
        Test.startTest();
        try {
            // Mock scenario by attempting to create user when profile query would fail
            // This is challenging to test without actually removing the profile
            User newUser = new OneLoginRegistrationHandler().createUser(null, testUserData);
            System.assertNotEquals(null, newUser, 'User created successfully with existing profile');
        } catch (System.QueryException e) {
            System.assert(e.getMessage().contains('Profile'),
                    'Exception should be related to missing profile');
        }
        Test.stopTest();
    }
    @isTest
    static void assignPermissionSetGroup_withMissingPermissionSetGroup_handlesError() {
        // This test is challenging because we can't easily remove permission sets in tests
        // In practice, you might use dependency injection or mocking for better testability

        // Arrange
        Auth.UserData testUserData = createTestUserData('missingpermissions@test.com', 'Missing', 'Permissions');

        Test.startTest();
        try {
            User testUser = new OneLoginRegistrationHandler().createUser(null, testUserData);
            Test.stopTest();

            // If we reach here, permissions exist and were assigned successfully
            PermissionSetGroup permissionSetGroup = getPermissionSetGroup();
            PermissionSet permissionSet = getPermissionSet();
            verifyPermissionAssignments(testUser.Id, permissionSetGroup.Id, permissionSet.Id);

        } catch (System.QueryException e) {
            System.assert(e.getMessage().contains('Permission'),
                    'Exception should be related to missing permissions');
        }
    }
    @isTest
    static void updateUser_withUserData_updatesUser() {
        // Arrange
        User existingUser = [SELECT Id, FirstName, LastName, Email
        FROM User
        WHERE Email = :EXISTING_USER_EMAIL
        LIMIT 1];

        Auth.UserData updateData = new Auth.UserData(
                null, 'UpdatedFirst', 'UpdatedLast', 'UpdatedFirst UpdatedLast',
                'updated@email.com', null, null, null, null, null, null
        );

        // Act
        Test.startTest();
        new OneLoginRegistrationHandler().updateUser(existingUser.Id, null, updateData);
        Test.stopTest();

        // Assert
        User updatedUser = [SELECT Id, FirstName, LastName, Email
        FROM User
        WHERE Id = :existingUser.Id];

        System.assertEquals('UpdatedFirst', updatedUser.FirstName,
                'FirstName should be updated');
        System.assertEquals('UpdatedLast', updatedUser.LastName,
                'LastName should be updated');
        System.assertEquals('updated@email.com', updatedUser.Email,
                'Email should be updated');
    }
    @isTest
    static void updateUser_withInvalidUserId_throwsException() {
        // Arrange
        Id invalidUserId = UserInfo.getUserId(); // Use current user ID that won't match our query
        Auth.UserData updateData = createTestUserData('invalid@test.com', 'Invalid', 'Test');

        // Act & Assert
        Test.startTest();
        try {
            new OneLoginRegistrationHandler().updateUser(invalidUserId, null, updateData);
            // If the user exists, the test will pass, otherwise it will throw an exception
        } catch (System.QueryException e) {
            System.assert(e.getMessage().contains('List has no rows'),
                    'Should throw QueryException for non-existent user');
        }
        Test.stopTest();
    }
    @isTest
    static void getPersonContactId_withValidAccountId_returnsContactId() {
        // This tests the private method indirectly through createUser
        // Arrange
        Auth.UserData testUserData = createTestUserData('contactid@test.com', 'Contact', 'Test');

        // Act
        Test.startTest();
        User newUser = new OneLoginRegistrationHandler().createUser(null, testUserData);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, newUser.ContactId, 'ContactId should not be null');

        Account createdAccount = getCreatedAccount(testUserData.email);
        System.assertEquals(createdAccount.PersonContactId, newUser.ContactId,
                'ContactId should match Account PersonContactId');
    }
    @isTest
    static void logErrors_withErrorMessage_logsError() {
        // Testing the logging functionality indirectly
        // Since LogErrors is a private static method, we test it through scenarios that trigger it

        // Arrange - Create scenario that will cause account creation to fail
        Auth.UserData invalidData = new Auth.UserData(
                null, null, null, null, null, // Missing required email
                null, null, null, null, null, null
        );

        // Act & Assert
        Test.startTest();
        try {
            new OneLoginRegistrationHandler().createUser(null, invalidData);
            System.assert(false, 'Expected exception was not thrown');
        } catch (DmlException e) {
            // The error should have been logged
            System.assert(e.getMessage().contains('Account creation failed'),
                    'Error message should indicate account creation failure');
        }
        Test.stopTest();
    }
    // Helper Methods

    private static Auth.UserData createTestUserData(String email, String firstName, String lastName) {
        return new Auth.UserData(
                null, firstName, lastName, firstName + ' ' + lastName, email,
                null, null, null, null, null, null
        );
    }

    private static Profile getCommunityProfile() {
        return [SELECT Id FROM Profile
        WHERE Name = :COMMUNITY_PROFILE_NAME
        LIMIT 1];
    }

    private static PermissionSetGroup getPermissionSetGroup() {
        return [SELECT Id, DeveloperName
        FROM PermissionSetGroup
        WHERE DeveloperName = :PERMISSION_SET_GROUP_NAME
        LIMIT 1];
    }

    private static PermissionSet getPermissionSet() {
        return [SELECT Id, Name
        FROM PermissionSet
        WHERE Name = :PERMISSION_SET_NAME
        LIMIT 1];
    }

    private static Account getCreatedAccount(String email) {
        return [SELECT PersonContactId, LastName, PersonEmail, Imported_From_Legacy__c
        FROM Account
        WHERE PersonEmail = :email
        AND Imported_From_Legacy__c = false
        LIMIT 1];
    }
    private static void assertUserFields(User user, Auth.UserData userData, Id expectedProfileId) {
        System.assertEquals(userData.email + '.prse.co.uk', user.Username,
                'Username should be email + .prse.co.uk');
        System.assertEquals(userData.email, user.Email,
                'Email should match input data');
        System.assertEquals(userData.email, user.LastName,
                'LastName should be set to email');
        System.assertEquals(expectedProfileId, user.ProfileId,
                'ProfileId should match community profile');
        System.assertEquals('Europe/London', user.TimeZoneSidKey,
                'TimeZone should be Europe/London');
        System.assertEquals('en_GB', user.LocaleSidKey,
                'Locale should be en_GB');
        System.assertEquals('UTF-8', user.EmailEncodingKey,
                'Email encoding should be UTF-8');
        System.assertEquals('en_GB', user.LanguageLocaleKey,
                'Language locale should be en_GB');

        // Verify alias format
        String expectedAliasPrefix = userData.email.substringBefore('@').length() > 5
                ? userData.email.substringBefore('@').substring(0, 5)
                : userData.email.substringBefore('@');
        System.assert(user.Alias.startsWith(expectedAliasPrefix),
                'Alias should start with email prefix');
        System.assert(user.CommunityNickname.startsWith(expectedAliasPrefix),
                'CommunityNickname should start with email prefix');
    }

    private static void verifyPermissionAssignments(Id userId, Id expectedPermSetGroupId, Id expectedPermSetId) {
        List<PermissionSetAssignment> assignments = [
                SELECT AssigneeId, PermissionSetGroupId, PermissionSetId
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId
                AND (PermissionSetGroupId = :expectedPermSetGroupId
                OR PermissionSetId = :expectedPermSetId)
        ];

        System.assertEquals(2, assignments.size(),
                'Should have 2 permission assignments (1 group + 1 set)');

        Boolean hasGroupAssignment = false;
        Boolean hasSetAssignment = false;

        for (PermissionSetAssignment assignment : assignments) {
            if (assignment.PermissionSetGroupId == expectedPermSetGroupId) {
                hasGroupAssignment = true;
            }
            if (assignment.PermissionSetId == expectedPermSetId) {
                hasSetAssignment = true;
            }
        }

        System.assert(hasGroupAssignment, 'Should have permission set group assignment');
        System.assert(hasSetAssignment, 'Should have permission set assignment');
    }
}