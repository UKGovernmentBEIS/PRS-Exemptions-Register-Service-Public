/*
 This class will be used to handle user registration via OneLogin for Local Authority users.
 It checks for existing Person Accounts with Local Authority access permission before creating users.
 It also assigns the appropriate Permission Set Group and Permission Set to the newly created users.
 This class also used by the compliance hub site Auth provider.
 */
global class LAOneLoginRegistrationHandler implements Auth.RegistrationHandler {
    private static final digitalmodus.SystemLogService logService = new digitalmodus.SystemLogService('LAOneLoginRegistrationHandler');

    global User createUser(Id portalId, Auth.UserData data) {
        System.debug('LAOneLoginRegistrationHandler CreateUser fired');
        try {
            Account existingPersonAccount = findExistingPersonAccount(data.email);
            System.debug('existingPersonAccount ' + existingPersonAccount);
            if (existingPersonAccount == null) {
                String errorMessage = 'No existing Person Account found for email: ' + data.email + '. User creation not allowed.';
                LogErrors('createUser - No Account Found', errorMessage);
                return null;
            }
            Account pa = existingPersonAccount;
            Id contactId = existingPersonAccount.PersonContactId;

            Profile communityProfile = [
                    SELECT Id FROM Profile
                    WHERE Name = 'DEZNZ_PRS_Local Authority Customer Community Plus Login User'
                    LIMIT 1
            ];
            //We need to check if the user is already exists or not. It is strange that if user in one login created by the LA site
            //But trying to login in compliance will not work. In Compliance site it will try to run the createUser function. But login in LA calls the updateUser function. ???
            //So in login to the compliance site will throw and error due to existing identifier for the user. It should be unique.
            //String username  = data.email + '.prseLA.co.uk';
            List<User> existingUser = [SELECT Id FROM User WHERE FederationIdentifier =: data.identifier AND Email =:data.email];
            if(!existingUser.isEmpty()) {
                System.debug('existing user is found ' +existingUser);
                return existingUser[0];
            }
            createUserSessionToLogOut(data);
            System.debug('user Session is upserted');
            User u = createCommunityUser(data, contactId, communityProfile.Id, pa);
            Database.SaveResult userResult = Database.insert(u, false);
            if (!userResult.isSuccess()) {
                String errorMessage = 'User creation failed: ';
                for (Database.Error error : userResult.getErrors()) {
                    errorMessage += error.getMessage() + ' ';
                }
                LogErrors('createUser - User Creation', errorMessage);
                return null;
            }
            assignPermissionSetGroup(u.Id);
            System.debug('LAonelogin createCommunityUser fired and completed');
            return u;

        } catch (Exception ex) {
            String errorMessage = 'Unexpected error during user creation: ' + ex.getMessage();
            System.debug('LAonelogin createCommunityUser ERROR' +ex.getMessage());
            LogErrors('createUser - Unexpected Error', errorMessage);
            return null;
        }
    }

    //Create a logout session in a custom object. The Id_token is used to logout from the Onelogin
    private static void createUserSessionToLogOut(Auth.UserData data) {
         // Store for logout
        User_Session__c session = new User_Session__c(
                User__c = data.email,
                Id_Token__c = data.attributeMap.get('oauthSecretOrRefreshToken')
        );
        insert session;
    }
    private static Account findExistingPersonAccount(String email) {
        try {
            List<Account> existingAccounts = [
                    SELECT Id, PersonContactId, PersonEmail, FirstName, LastName, Allow_Local_Authority_Access__c
                    FROM Account
                    WHERE PersonEmail = :email
                    AND IsPersonAccount = TRUE
                    AND Allow_Local_Authority_Access__c = TRUE
                    LIMIT 1
            ];

            if (!existingAccounts.isEmpty()) {
                return existingAccounts[0];
            }

            return null;

        } catch (QueryException ex) {
            String errorMessage = 'Query exception while finding Person Account: ' + ex.getMessage();
            LogErrors('findExistingPersonAccount', errorMessage);
            return null;
        }
    }

    private static void LogErrors(String triggeringMethod, String errorMessage) {
        logService.setTriggeringAutomationName(triggeringMethod);
        logService.setLogCode('RegistrationError-001');
        logService.setMessage(errorMessage);
        logService.setLogType(digitalmodus.SystemLogService.LogType.ERROR);
        logService.publish();
    }

    @Future
    public static void assignPermissionSetGroup(Id userId) {
        try {
            if (!Schema.SObjectType.PermissionSetAssignment.isCreateable()) {
                String errorMessage = 'No permission to assign permission sets';
                LogErrors('assignPermissionSetGroup - Security', errorMessage);
                return;
            }

            PermissionData permData = queryPermissionData();
            if (permData == null) {
                String errorMessage = 'Failed to retrieve permission configuration';
                LogErrors('assignPermissionSetGroup - Config', errorMessage);
                return;
            }

            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

            PermissionSetAssignment permissionGroupAssignment = new PermissionSetAssignment();
            permissionGroupAssignment.AssigneeId = userId;
            permissionGroupAssignment.PermissionSetGroupId = permData.permissionSetGroupId;
            assignments.add(permissionGroupAssignment);

            PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
            permissionSetAssignment.AssigneeId = userId;
            permissionSetAssignment.PermissionSetId = permData.permissionSetId;
            assignments.add(permissionSetAssignment);

            Database.SaveResult[] results = Database.insert(assignments, false);
            handlePermissionAssignmentResults(results, userId);

        } catch (Exception ex) {
            String errorMessage = 'Unexpected error during permission assignment: ' + ex.getMessage();
            LogErrors('assignPermissionSetGroup - Unexpected Error', errorMessage);
        }
    }

    global void updateUser(Id userId, Id portalId, Auth.UserData data) {
        System.debug('LAOneLoginRegistrationHAndler UpdateUser Fired');
        try {
            //Create a user session record that will be accessed when logout is pressed. This function will fire on create and update user in the registration handler.
            createUserSessionToLogOut(data);
            
            //Check if the email address is changed on the Salesforce after the first registration is created. The email address can be changed on the User or personaAccount.
            List<Account> acc = [SELECT Id, PersonEmail FROM Account WHERE PersonEmail = :data.email];
            if(acc.isEmpty()) {
                String errorMessage = 'Email address is not matching with the onelogin username';
                LogErrors('updateUser', errorMessage);

                // Option 1: Use the full Experience Cloud page URL
                PageReference errorPage = new PageReference(Site.getBaseUrl() + '/denied-access?ErrorCode=DUPLICATE_EMAIL&ErrorMessage=' + errorMessage);

                // This will redirect but you need to return null or throw. This doesn't work because by default the urls is always. It does go tot eh denied access page but no custom message:
                // denied-access?ErrorCode=REGISTRATION_HANDLER_ERROR&ErrorDescription=Can+only+throw+this+exception+type+from+VisualForce+or+Aura+context&ProviderId=0SOPv0000004KZd&startURL=%2Fcompliance%2Flanding-page
                throw new AuraHandledException(errorPage.getUrl());
            }
            User u = [SELECT Id, FirstName, LastName, Email FROM User WHERE Id = :userId];
            u.FirstName = data.firstName;
            u.LastName = data.lastName;
            u.Email = data.email;
            update u;
        } catch (Exception ex) {
            String errorMessage = 'Failed to update user: ' + ex.getMessage();
            LogErrors('updateUser', errorMessage);
        }
    }

    private static User createCommunityUser(Auth.UserData data, Id contactId, Id profileId, Account personAccount) {
        String rawAlias = data.email.substringBefore('@');
        String shortAlias = rawAlias.length() > 5 ? rawAlias.substring(0, 5) : rawAlias;
        Integer numForAlias = Math.mod(Math.abs(Crypto.getRandomInteger()), 1000);
        String modAlias = shortAlias + numForAlias;

        User u = new User();
        u.Username = data.email + '.prseLA.co.uk';
        u.FederationIdentifier = data.identifier;
        u.Email = data.email;
        u.Alias = modAlias;
        u.FirstName = personAccount.FirstName;
        u.LastName = personAccount.LastName;
        u.CommunityNickname = modAlias;
        u.ProfileId = profileId;
        u.TimeZoneSidKey = 'Europe/London';
        u.LocaleSidKey = 'en_GB';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_GB';
        u.ContactId = contactId;

        return u;
    }

    private static PermissionData queryPermissionData() {
        try {
            PermissionData permData = new PermissionData();

            List<PermissionSetGroup> permGroups = [
                    SELECT Id, DeveloperName
                    FROM PermissionSetGroup
                    WHERE DeveloperName = 'DEZNZ_PRS_Portal_Local_Authority_Access'
                    LIMIT 1
            ];

            if (permGroups.isEmpty()) {
                String errorMessage = 'Permission Set Group not found: DEZNZ_PRS_Portal_Local_Authority_Access';
                LogErrors('queryPermissionData - Permission Group', errorMessage);
                return null;
            }
            permData.permissionSetGroupId = permGroups[0].Id;

            List<PermissionSet> permSets = [
                    SELECT Id, Name
                    FROM PermissionSet
                    WHERE Name = 'PublicSectorAccsForCmnyUser'
                    LIMIT 1
            ];

            if (permSets.isEmpty()) {
                String errorMessage = 'Permission Set not found: PublicSectorAccsForCmnyUser';
                LogErrors('queryPermissionData - Permission Set', errorMessage);
                return null;
            }
            permData.permissionSetId = permSets[0].Id;

            return permData;

        } catch (QueryException ex) {
            String errorMessage = 'Failed to query permission configuration: ' + ex.getMessage();
            LogErrors('queryPermissionData - Query Error', errorMessage);
            return null;
        }
    }

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
            LogErrors('handlePermissionAssignmentResults', errorMessage);
        }
    }

    private class PermissionData {
        public Id permissionSetGroupId;
        public Id permissionSetId;
    }
}