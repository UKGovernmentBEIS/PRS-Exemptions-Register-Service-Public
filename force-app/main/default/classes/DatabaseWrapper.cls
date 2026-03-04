public virtual with sharing class DatabaseWrapper {

    @TestVisible
    private static DatabaseWrapper instance;
    @TestVisible
    private static DatabaseWrapper privilegedInstance;

    public static DatabaseWrapper getInstance() {
        if(instance == null) {
            instance = new DatabaseWrapper();
        } 
        return instance;
    }

    public static DatabaseWrapper getPrivilegedInstance() {
        if(privilegedInstance == null) {
            privilegedInstance = new PrivilegedInstance();
        } 
        return privilegedInstance;
    }

    public virtual List<SObject> query(String queryString) {
        return Database.query(queryString);
    }

    public virtual List<SObject> queryWithBinds(String queryString, Map<String, Object> bindMap) {
        return Database.queryWithBinds(queryString, bindMap, AccessLevel.USER_MODE);
    }

    public Integer countQuery(String query) {
        return Database.countQuery(query);
    }

    public Integer countQueryWithBinds(String query, Map<String, Object> bindMap) {
        return Database.countQueryWithBinds(query, bindMap, AccessLevel.USER_MODE);
    }

    public Database.UpsertResult upsertRecord(SObject toUpsert) {
        return Database.upsert(toUpsert);
    }

    public Database.DeleteResult deleteRecordWithId(Id recordId) {
        return Database.delete(recordId);
    }

    private without sharing class PrivilegedInstance extends DatabaseWrapper {
        
        public override List<SObject> query(String queryString) {
            return Database.query(queryString, AccessLevel.SYSTEM_MODE);
        }

        public override List<SObject> queryWithBinds(String queryString, Map<String, Object> bindMap) {
            return Database.queryWithBinds(queryString, bindMap, AccessLevel.SYSTEM_MODE);
        }
    }
}