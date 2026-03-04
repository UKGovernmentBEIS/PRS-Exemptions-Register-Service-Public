String userEmail = UserInfo.getUserEmail();

List<Map<String, String>> sampleUsers = new List<Map<String, String>>{
    // Internal Users
    new Map<String, String>{'FirstName' => 'Alice', 'LastName' => 'Anderson', 'Email' => 'alice.anderson@example.com', 'Username' => 'alice.anderson@example.com', 'Profile' => 'DEZNZ_PRS_Policy User', 'PSG' => 'PRSE Internal - DEZNZ Policy User Access'},
     new Map<String, String>{'FirstName' => 'Bob', 'LastName' => 'Bennett', 'Email' => 'bob.bennet@example.com', 'Username' => 'bob.bennet@example.com', 'Profile' => 'DEZNZ_PRS_Assisted Digital Customer Advisory User', 'PSG' => 'PRSE Internal - DESNZ Assisted Digital Customer Advisory User Access'},

    // Customer Community Plus Users
    new Map<String, String>{'FirstName' => 'Carol', 'LastName' => 'Chen', 'Email' => 'carol.chen@example.com', 'Username' => 'carol.chen@example.com', 'Profile' => 'PRSE Landlord Customer Community Plus Login User', 'PSG' => 'PRSE Portal - Landlord Person Access'},
    new Map<String, String>{'FirstName' => 'Geremy', 'LastName' => 'Willis', 'Email' => 'geremy.willis@example.com', 'Username' => 'geremy.willis@example.com', 'Profile' => 'PRSE Landlord Customer Community Plus Login User', 'PSG' => 'PRSE Portal - Landlord Organisation Access'},
    new Map<String, String>{'FirstName' => 'Eva', 'LastName' => 'Evans', 'Email' => 'eva.evans@example.com', 'Username' => 'eva.evans@example.com', 'Profile' => 'PRSE Landlord Customer Community Plus Login User', 'PSG' => 'PRSE Portal - Landlord Agent Access'},

    // Partner User
    new Map<String, String>{'FirstName' => 'Frank', 'LastName' => 'Jaeger', 'Email' => 'frank.jaeger@example.com', 'Username' => 'frank.jaeger@example.com', 'Profile' => 'PRSE Local Authority Customer Community Plus Login User', 'PSG' => 'PRSE Portal - Local Authority Access'}
};

// Get Person Account Record Type
Id personAccountRecordTypeId = [
    SELECT Id FROM RecordType 
    WHERE SObjectType = 'Account' AND IsPersonType = true 
    LIMIT 1
].Id;

// Load Profiles
Set<String> profileNames = new Set<String>();
for (Map<String, String> u : sampleUsers) profileNames.add(u.get('Profile'));

Map<String, Id> profileMap = new Map<String, Id>();
for (Profile p : [SELECT Id, Name FROM Profile WHERE Name IN :profileNames]) {
    profileMap.put(p.Name, p.Id);
}

// Load PSGs
Set<String> psgNames = new Set<String>();
for (Map<String, String> u : sampleUsers) psgNames.add(u.get('PSG'));

Map<String, Id> psgMap = new Map<String, Id>();
for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE PermissionSetGroupId != null AND Name IN :psgNames]) {
    psgMap.put(ps.Name, ps.Id);
}

// Check existing Users
Set<String> usernames = new Set<String>();
for (Map<String, String> u : sampleUsers) usernames.add(u.get('Username'));

Map<String, User> existingUsers = new Map<String, User>();
for (User u : [SELECT Id, Username FROM User WHERE Username IN :usernames]) {
    existingUsers.put(u.Username, u);
}

// Check existing Accounts
Set<String> accountNames = new Set<String>();
for (Map<String, String> u : sampleUsers) {
    if (u.get('Profile').contains('Community')) {
        accountNames.add(u.get('Profile') + ' Account');
    }
}

Map<String, Account> existingAccounts = new Map<String, Account>();
for (Account a : [SELECT Id, Name, PersonContactId FROM Account WHERE Name IN :accountNames]) {
    existingAccounts.put(a.Name, a);
}

// Create missing Accounts and store ContactIds
Map<String, Id> accountContactMap = new Map<String, Id>();

for (Map<String, String> u : sampleUsers) {
    String profile = u.get('Profile');
    if (profile.contains('Community')) {
        String accountName = profile + ' Account';

        if (!existingAccounts.containsKey(accountName)) {
            Account acc = new Account(
                FirstName = u.get('FirstName'),
                LastName = u.get('LastName'),
                RecordTypeId = personAccountRecordTypeId
            );

            if (profile.contains('Partner')) acc.IsPartner = true;

            insert acc;

            acc = [SELECT Id, Name, PersonContactId FROM Account WHERE Id = :acc.Id LIMIT 1];
            existingAccounts.put(accountName, acc);
        }

        accountContactMap.put(accountName, existingAccounts.get(accountName).PersonContactId);
    }
}

// Create Users
List<User> usersToInsert = new List<User>();
for (Map<String, String> userData : sampleUsers) {
    String username = userData.get('Username');
    if (existingUsers.containsKey(username)) continue;

    String profile = userData.get('Profile');
    String accountName = profile + ' Account';
    Id profileId = profileMap.get(profile);

    String rawAlias = (userData.get('FirstName').substring(0,1) + userData.get('LastName')).toLowerCase();
    String alias = rawAlias.length() > 8 ? rawAlias.substring(0, 8) : rawAlias;

    User u = new User(
        FirstName = userData.get('FirstName'),
        LastName = userData.get('LastName'),
        Email = userData.get('Email'),
        Username = username,
        Alias = alias,
        CommunityNickname = userData.get('FirstName').toLowerCase() + '.' + userData.get('LastName').toLowerCase(),
        ProfileId = profileId,
        TimeZoneSidKey = 'Europe/London',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US'
    );

    // Assign ContactId for portal users
    if (profile.contains('Community')) {
        u.ContactId = accountContactMap.get(accountName);
    }

    usersToInsert.add(u);
}

insert usersToInsert;

// Assign PSGs
List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
Map<String, Id> insertedUserMap = new Map<String, Id>();
for (User u : [SELECT Id, Username FROM User WHERE Username IN :usernames]) {
    insertedUserMap.put(u.Username, u.Id);
}

for (Map<String, String> userData : sampleUsers) {
    String username = userData.get('Username');
    if (insertedUserMap.containsKey(username) && psgMap.containsKey(userData.get('PSG'))) {
        psaList.add(new PermissionSetAssignment(
            AssigneeId = insertedUserMap.get(username),
            PermissionSetId = psgMap.get(userData.get('PSG'))
        ));
    }
}

insert psaList;
