global class OneLoginRegistrationHandler implements Auth.RegistrationHandler {
    final digitalmodus.SystemLogService logService = new digitalmodus.SystemLogService('OneLoginRegistrationHandler');
    
    // Implement the createUser method
    // This method creates a new user based on the provided Auth.UserData
    // It creates a Person Account, retrieves the associated Contact,
    // creates a Community User, and assigns necessary permissions
    global User createUser(Id portalId, Auth.UserData data) {
        System.debug('OneLoginRegistrationHandler CreateUser fired');
        try {
            // Check for existing user first to avoid duplicates
           /* List<User> existingUser = [
                SELECT Id 
                FROM User 
                WHERE FederationIdentifier = :data.identifier 
                AND Email = :data.email
                LIMIT 1
            ];
            
            if (!existingUser.isEmpty()) {
                System.debug('Existing user found: ' + existingUser[0].Id);
                // Update session for existing user
                 return existingUser[0];
            }*/

            RecordType personRt = [
                SELECT Id FROM RecordType
                WHERE SobjectType = 'Account' AND IsPersonType = TRUE
                LIMIT 1
            ];

            Account pa = createPersonAccount(data, personRt.Id);
            System.debug('Person Account to be created: ' + pa);

            Database.SaveResult accountResult = Database.insert(pa, false);
            if (!accountResult.isSuccess()) {
                String errorMessage = 'Account creation failed: ';
                for (Database.Error error : accountResult.getErrors()) {
                    errorMessage += error.getMessage() + ' ';
                }
                LogErrors('OneLoginRegistrationHandler.createPersonAccount - Account Creation', errorMessage);
                return null;
            } else {
                System.debug('Person Account successfully created ' + pa);
            }

            // Get the created PersonContact
            Id contactId = getPersonContactId(pa.Id);
            if (contactId == null) {
                String errorMessage = 'Failed to retrieve PersonContactId for account: ' + pa.Id;
                LogErrors('OneLoginRegistrationHandler.createUser - Contact Retrieval', errorMessage);
                return null;
            }

            Profile communityProfile = [
                SELECT Id FROM Profile
                WHERE Name = 'DEZNZ_PRS_Landlord Customer Community Plus Login User' 
                LIMIT 1
            ];

            // Create User
            User u = createCommunityUser(data, contactId, communityProfile.Id);
            System.debug('Community User to be created: ' + u);

            // Create user session for logout functionality
            createUserSessionToLogOut(data);
            System.debug('User Session created');

            // Insert User with error handling
            Database.SaveResult userResult = Database.insert(u, false);
            if (!userResult.isSuccess()) {
                String errorMessage = 'User creation failed: ';
                for (Database.Error error : userResult.getErrors()) {
                    errorMessage += error.getMessage() + ' ';
                }
                LogErrors('OneLoginRegistrationHandler.createUser - User Creation', errorMessage);
                return null;
            }

            // Assign Permission Set Group and Permission Set asynchronously
            assignPermissionSetGroup(u.Id);

            System.debug('OneLoginRegistrationHandler createUser completed successfully');
            return u;
            
        } catch (Exception ex) {
            String errorMessage = 'Unexpected error during user creation: ' + ex.getMessage();
            System.debug('OneLoginRegistrationHandler createUser ERROR: ' + ex.getMessage());
            LogErrors('OneLoginRegistrationHandler.createUser - Unexpected Error', errorMessage);
            return null;
        }
    }

    global void updateUser(Id userId, Id portalId, Auth.UserData data) {
        System.debug('OneLoginRegistrationHandler UpdateUser fired for userId: ' + userId);
        try {
            // Create/update user session on login
            createUserSessionToLogOut(data);

            User u = [SELECT Id, FirstName, LastName, Email, FederationIdentifier FROM User WHERE Id = :userId];
            u.FirstName = data.firstName;
            u.LastName = data.lastName;
            u.Email = data.email;
            u.FederationIdentifier = data.identifier;
            update u;
            System.debug('User successfully updated: ' + u);

        } catch (Exception ex) {
            String errorMessage = 'Failed to update user: ' + ex.getMessage();
            LogErrors('OneLoginRegistrationHandler.updateUser', errorMessage);
            // Log but don't throw exception to avoid blocking login
        }
    }
    private static void createUserSessionToLogOut(Auth.UserData data) {
        try {
            System.debug('Creating user session for logout');
            // Store OAuth token for logout functionality
            User_Session__c session = new User_Session__c(
                User__c = data.email,
                Id_Token__c = data.attributeMap.get('oauthSecretOrRefreshToken')
            );
            insert session;
            System.debug('User session created successfully');
        } catch (Exception ex) {
            String errorMessage = 'Failed to create user session: ' + ex.getMessage();
            LogErrors('OneLoginRegistrationHandler.createUserSessionToLogOut', errorMessage);
            // Don't fail the entire registration if session creation fails
        }
    }

    private static void LogErrors(String relatedService, String errorMessage) {
        digitalmodus.SystemLogService logService = new digitalmodus.SystemLogService(relatedService);
        logService.setLogCode('RegistrationError-001');
        logService.setMessage(errorMessage);
        logService.setLogType(digitalmodus.SystemLogService.LogType.ERROR);
        logService.publish();
    }

    // We need a future method due to mixed DML restrictions
    // Also, using future allows us to handle partial successes in permission assignment
    // and avoid hitting limits in case of bulk user creation
    // Note: Future methods do not support rollbacks, so any errors here will not affect
    // the user creation transaction
    @Future
    public static void assignPermissionSetGroup(Id userId) {
        try {
            // Security checks for permission assignment
            if (!Schema.SObjectType.PermissionSetAssignment.isCreateable()) {
                String errorMessage = 'No permission to assign permission sets';
                LogErrors('OneLoginRegistrationHandler.assignPermissionSetGroup - Security', errorMessage);
                return;
            }

            // Query required permission data
            PermissionData permData = queryPermissionData();
            if (permData == null) {
                String errorMessage = 'Failed to retrieve permission configuration';
                LogErrors('OneLoginRegistrationHandler.assignPermissionSetGroup - Config', errorMessage);
                return;
            }

            // Create permission assignments
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

            PermissionSetAssignment permissionGroupAssignment = new PermissionSetAssignment();
            permissionGroupAssignment.AssigneeId = userId;
            permissionGroupAssignment.PermissionSetGroupId = permData.permissionSetGroupId;
            assignments.add(permissionGroupAssignment);

            PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
            permissionSetAssignment.AssigneeId = userId;
            permissionSetAssignment.PermissionSetId = permData.permissionSetId;
            assignments.add(permissionSetAssignment);

            // Insert with partial success handling
            Database.SaveResult[] results = Database.insert(assignments, false);
            // Handle results
            handlePermissionAssignmentResults(results, userId);
            
        } catch (Exception ex) {
            String errorMessage = 'Unexpected error during permission assignment: ' + ex.getMessage();
            LogErrors('OneLoginRegistrationHandler.assignPermissionSetGroup - Unexpected Error', errorMessage);
        }
    }


    // Create Person Account
    private static Account createPersonAccount(Auth.UserData data, Id recordTypeId) {
        Account pa = new Account();
        pa.RecordTypeId = recordTypeId;
        pa.LastName = data.email;
        pa.PersonEmail = data.email;
        pa.Imported_From_Legacy__c = false;

        return pa;
    }

    // Get PersonContactId from created Account
    private Id getPersonContactId(Id accountId) {
        try {
            List<Account> reloadedAccounts = [
                SELECT PersonContactId
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];

            if (reloadedAccounts.isEmpty() || reloadedAccounts[0].PersonContactId == null) {
                String errorMessage = 'PersonContactId not found for created account';
                LogErrors('OneLoginRegistrationHandler.getPersonContactId', errorMessage);
                return null;
            }

            return reloadedAccounts[0].PersonContactId;

        } catch (QueryException ex) {
            String errorMessage = 'Failed to retrieve PersonContactId: ' + ex.getMessage();
            LogErrors('OneLoginRegistrationHandler.getPersonContactId', errorMessage);
            return null;
        }
    }

    // Create Community User
    private static User createCommunityUser(Auth.UserData data, Id contactId, Id profileId) {
        String rawAlias = data.email.substringBefore('@');
        String shortAlias = rawAlias.length() > 5 ? rawAlias.substring(0, 5) : rawAlias;
        Integer numForAlias = Math.mod(Math.abs(Crypto.getRandomInteger()), 1000);
        String modAlias = shortAlias + numForAlias;

        User u = new User();
        u.Username = data.email + '.prse.co.uk';
        u.FederationIdentifier = data.identifier;
        u.Email = data.email;
        u.Alias = modAlias;
        u.LastName = data.email;
        u.CommunityNickname = modAlias;
        u.ProfileId = profileId;
        u.TimeZoneSidKey = 'Europe/London';
        u.LocaleSidKey = 'en_GB';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_GB';
        u.ContactId = contactId;

        return u;
    }

    // Query permission data
    private static PermissionData queryPermissionData() {
        try {
            PermissionData permData = new PermissionData();

            // Query Permission Set Group
            List<PermissionSetGroup> permGroups = [
                SELECT Id, DeveloperName
                FROM PermissionSetGroup
                WHERE DeveloperName = 'DESNZ_PRS_Portal_Landlord_Access'
                LIMIT 1
            ];

            if (permGroups.isEmpty()) {
                String errorMessage = 'Permission Set Group not found: DESNZ_PRS_Portal_Landlord_Access';
                LogErrors('OneLoginRegistrationHandler.queryPermissionData - Permission Group', errorMessage);
                return null;
            }
            permData.permissionSetGroupId = permGroups[0].Id;

            // Query Permission Set
            List<PermissionSet> permSets = [
                SELECT Id, Name
                FROM PermissionSet
                WHERE Name = 'PublicSectorAccsForCmnyUser'
                LIMIT 1
            ];

            if (permSets.isEmpty()) {
                String errorMessage = 'Permission Set not found: PublicSectorAccsForCmnyUser';
                LogErrors('OneLoginRegistrationHandler.queryPermissionData - Permission Set', errorMessage);
                return null;
            }
            permData.permissionSetId = permSets[0].Id;

            return permData;

        } catch (QueryException ex) {
            String errorMessage = 'Failed to query permission configuration: ' + ex.getMessage();
            LogErrors('OneLoginRegistrationHandler.queryPermissionData - Query Error', errorMessage);
            return null;
        }
    }

    // Handle permission assignment results
    private static void handlePermissionAssignmentResults(Database.SaveResult[] results, Id userId) {
        List<String> errors = new List<String>();

        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult result = results[i];

            if (!result.isSuccess()) {
                String assignmentType = (i == 0) ? 'Permission Set Group' : 'Permission Set';
                for (Database.Error error : result.getErrors()) {
                    errors.add(assignmentType + ': ' + error.getMessage());
                }
            }
        }

        if (!errors.isEmpty()) {
            String errorMessage = 'Permission assignment failed for user ' + userId + ': ' + String.join(errors, '; ');
            LogErrors('OneLoginRegistrationHandler.handlePermissionAssignmentResults', errorMessage);
        } else {
            System.debug('Successfully assigned permissions to user: ' + userId);
        }
    }

    private class PermissionData {
        public Id permissionSetGroupId;
        public Id permissionSetId;
    }
}