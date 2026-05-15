@isTest(IsParallel=true)
private class DatabaseWrapperTest {

    @TestSetup
    static void makeData() {
        Contact testContact = new Contact(LastName = 'WrapperTest');
        insert testContact;
    }

    @isTest
    static void getInstance_calledTwice_returnsSameInstance() {
        //Arrange
        DatabaseWrapper.instance = null;

        //Act
        DatabaseWrapper first  = DatabaseWrapper.getInstance();
        DatabaseWrapper second = DatabaseWrapper.getInstance();

        //Assert
        Assert.areEqual(first, second, 'getInstance should return same singleton');
    }

    @isTest
    static void getInstance_withNullInstance_createsNewInstance() {
        //Arrange
        DatabaseWrapper.instance = null;

        //Act
        DatabaseWrapper result = DatabaseWrapper.getInstance();

        //Assert
        Assert.isNotNull(result, 'getInstance should create a new instance when null');
    }

    @isTest
    static void getPrivilegedInstance_calledTwice_returnsSameInstance() {
        //Arrange
        DatabaseWrapper.privilegedInstance = null;

        //Act
        DatabaseWrapper first  = DatabaseWrapper.getPrivilegedInstance();
        DatabaseWrapper second = DatabaseWrapper.getPrivilegedInstance();

        //Assert
        Assert.areEqual(first, second, 'getPrivilegedInstance should return same singleton');
    }

    @isTest
    static void getPrivilegedInstance_withNullInstance_createsNewInstance() {
        //Arrange
        DatabaseWrapper.privilegedInstance = null;

        //Act
        DatabaseWrapper result = DatabaseWrapper.getPrivilegedInstance();

        //Assert
        Assert.isNotNull(result, 'getPrivilegedInstance should create a new instance when null');
    }

    @isTest
    static void query_withValidQuery_returnsResults() {
        //Arrange
        DatabaseWrapper db = DatabaseWrapper.getInstance();

        //Act
        List<SObject> results = db.query('SELECT Id, LastName FROM Contact WHERE LastName = \'WrapperTest\'');

        //Assert
        Assert.areEqual(1, results.size(), 'Should return one matching Contact');
    }

    @isTest
    static void query_withNoMatchingRecords_returnsEmptyList() {
        //Arrange
        DatabaseWrapper db = DatabaseWrapper.getInstance();

        //Act
        List<SObject> results = db.query('SELECT Id FROM Contact WHERE LastName = \'NonExistent_XYZ\'');

        //Assert
        Assert.areEqual(0, results.size(), 'Should return empty list when no records match');
    }

    @isTest
    static void queryWithBinds_withMatchingBind_returnsResults() {
        //Arrange
        DatabaseWrapper db = DatabaseWrapper.getInstance();
        Map<String, Object> binds = new Map<String, Object>{ 'lastName' => 'WrapperTest' };

        //Act
        List<SObject> results = db.queryWithBinds(
            'SELECT Id, LastName FROM Contact WHERE LastName = :lastName', binds
        );

        //Assert
        Assert.areEqual(1, results.size(), 'Should return one Contact matching the bind value');
    }

    @isTest
    static void queryWithBinds_withNonMatchingBind_returnsEmptyList() {
        //Arrange
        DatabaseWrapper db = DatabaseWrapper.getInstance();
        Map<String, Object> binds = new Map<String, Object>{ 'lastName' => 'NonExistent_XYZ' };

        //Act
        List<SObject> results = db.queryWithBinds(
            'SELECT Id FROM Contact WHERE LastName = :lastName', binds
        );

        //Assert
        Assert.areEqual(0, results.size(), 'Should return empty list for non-matching bind');
    }

    @isTest
    static void countQuery_withMatchingRecords_returnsCorrectCount() {
        //Arrange
        DatabaseWrapper db = DatabaseWrapper.getInstance();

        //Act
        Integer count = db.countQuery('SELECT COUNT() FROM Contact WHERE LastName = \'WrapperTest\'');

        //Assert
        Assert.areEqual(1, count, 'Count should be 1 for single inserted Contact');
    }

    @isTest
    static void countQuery_withNoMatchingRecords_returnsZero() {
        //Arrange
        DatabaseWrapper db = DatabaseWrapper.getInstance();

        //Act
        Integer count = db.countQuery('SELECT COUNT() FROM Contact WHERE LastName = \'NonExistent_XYZ\'');

        //Assert
        Assert.areEqual(0, count, 'Count should be 0 when no records match');
    }

    @isTest
    static void countQueryWithBinds_withMatchingBind_returnsCorrectCount() {
        //Arrange
        DatabaseWrapper db = DatabaseWrapper.getInstance();
        Map<String, Object> binds = new Map<String, Object>{ 'lastName' => 'WrapperTest' };

        //Act
        Integer count = db.countQueryWithBinds(
            'SELECT COUNT() FROM Contact WHERE LastName = :lastName', binds
        );

        //Assert
        Assert.areEqual(1, count, 'Count should be 1 for matching bind');
    }

    @isTest
    static void countQueryWithBinds_withNonMatchingBind_returnsZero() {
        //Arrange
        DatabaseWrapper db = DatabaseWrapper.getInstance();
        Map<String, Object> binds = new Map<String, Object>{ 'lastName' => 'NonExistent_XYZ' };

        //Act
        Integer count = db.countQueryWithBinds(
            'SELECT COUNT() FROM Contact WHERE LastName = :lastName', binds
        );

        //Assert
        Assert.areEqual(0, count, 'Count should be 0 for non-matching bind');
    }

    @isTest
    static void upsertRecord_withNewRecord_insertsSuccessfully() {
        //Arrange
        DatabaseWrapper db = DatabaseWrapper.getInstance();
        Contact newCon = new Contact(LastName = 'UpsertNew');

        //Act
        Database.UpsertResult result = db.upsertRecord(newCon);

        //Assert
        Assert.isTrue(result.isSuccess(), 'Upsert of new record should succeed');
        Assert.isTrue(result.isCreated(), 'New record should be marked as created');
    }

    @isTest
    static void upsertRecord_withExistingRecord_updatesSuccessfully() {
        //Arrange
        DatabaseWrapper db = DatabaseWrapper.getInstance();
        Contact con = [SELECT Id, LastName FROM Contact WHERE LastName = 'WrapperTest' LIMIT 1];
        con.LastName = 'WrapperTestUpdated';

        //Act
        Database.UpsertResult result = db.upsertRecord(con);

        //Assert
        Assert.isTrue(result.isSuccess(), 'Upsert of existing record should succeed');
        Assert.isFalse(result.isCreated(), 'Existing record should not be marked as created');
    }

    @isTest
    static void deleteRecordWithId_withValidId_deletesSuccessfully() {
        //Arrange
        DatabaseWrapper db = DatabaseWrapper.getInstance();
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'WrapperTest' LIMIT 1];

        //Act
        Database.DeleteResult result = db.deleteRecordWithId(con.Id);

        //Assert
        Assert.isTrue(result.isSuccess(), 'Delete should succeed for valid Id');
        List<Contact> remaining = [SELECT Id FROM Contact WHERE Id = :con.Id];
        Assert.areEqual(0, remaining.size(), 'Contact should no longer exist after delete');
    }

    @isTest
    static void privilegedQuery_withValidQuery_returnsResults() {
        //Arrange
        DatabaseWrapper db = DatabaseWrapper.getPrivilegedInstance();

        //Act
        List<SObject> results = db.query('SELECT Id, LastName FROM Contact WHERE LastName = \'WrapperTest\'');

        //Assert
        Assert.areEqual(1, results.size(), 'Privileged query should return matching Contact');
    }

    @isTest
    static void privilegedQuery_withNoMatchingRecords_returnsEmptyList() {
        //Arrange
        DatabaseWrapper db = DatabaseWrapper.getPrivilegedInstance();

        //Act
        List<SObject> results = db.query('SELECT Id FROM Contact WHERE LastName = \'NonExistent_XYZ\'');

        //Assert
        Assert.areEqual(0, results.size(), 'Privileged query should return empty list when no match');
    }

    @isTest
    static void privilegedQueryWithBinds_withMatchingBind_returnsResults() {
        //Arrange
        DatabaseWrapper db = DatabaseWrapper.getPrivilegedInstance();
        Map<String, Object> binds = new Map<String, Object>{ 'lastName' => 'WrapperTest' };

        //Act
        List<SObject> results = db.queryWithBinds(
            'SELECT Id, LastName FROM Contact WHERE LastName = :lastName', binds
        );

        //Assert
        Assert.areEqual(1, results.size(), 'Privileged queryWithBinds should return matching Contact');
    }

    @isTest
    static void privilegedQueryWithBinds_withNonMatchingBind_returnsEmptyList() {
        //Arrange
        DatabaseWrapper db = DatabaseWrapper.getPrivilegedInstance();
        Map<String, Object> binds = new Map<String, Object>{ 'lastName' => 'NonExistent_XYZ' };

        //Act
        List<SObject> results = db.queryWithBinds(
            'SELECT Id FROM Contact WHERE LastName = :lastName', binds
        );

        //Assert
        Assert.areEqual(0, results.size(), 'Privileged queryWithBinds should return empty list when no match');
    }
}
