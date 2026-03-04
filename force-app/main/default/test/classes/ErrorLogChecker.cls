@isTest
public with sharing class ErrorLogChecker {

    public static void checkNoErrors() {
        List<digitalmodus__System_Log__c> errorLogs = [
            SELECT Id, digitalmodus__Log_Message__c, digitalmodus__Log_Code__c,  digitalmodus__Related_Service__c 
            FROM digitalmodus__System_Log__c
        ];
        Assert.isTrue(errorLogs.isEmpty(), 'Expected no errors to be logged');
    }

    public static void checkNoErrorsForService(String serviceName) {
        List<digitalmodus__System_Log__c> errorLogs = [
            SELECT Id, digitalmodus__Log_Message__c, digitalmodus__Log_Code__c,  digitalmodus__Related_Service__c 
            FROM digitalmodus__System_Log__c
            WHERE digitalmodus__Related_Service__c = :serviceName
        ];
        Assert.isTrue(errorLogs.isEmpty(), 'Expected no errors to be logged for ' + serviceName);
    }

    public static void checkNoErrorsForServiceAndMethod(String serviceName, String methodName) {
        List<digitalmodus__System_Log__c> errorLogs = [
            SELECT Id, digitalmodus__Log_Message__c, digitalmodus__Log_Code__c,  digitalmodus__Related_Service__c, digitalmodus__Triggering_Automation_Name__c
            FROM digitalmodus__System_Log__c
            WHERE digitalmodus__Related_Service__c = :serviceName
            AND digitalmodus__Triggering_Automation_Name__c = :methodName
        ];
        Assert.isTrue(errorLogs.isEmpty(), 'Expected no errors to be logged for ' + serviceName + '.' + methodName);
    }

    public static void checkErrorForServiceAndMethod(String serviceName, String methodName) {
        List<digitalmodus__System_Log__c> errorLogs = [
            SELECT Id, digitalmodus__Log_Message__c, digitalmodus__Log_Code__c,  digitalmodus__Related_Service__c, digitalmodus__Triggering_Automation_Name__c
            FROM digitalmodus__System_Log__c
            WHERE digitalmodus__Related_Service__c = :serviceName
            AND digitalmodus__Triggering_Automation_Name__c = :methodName
        ];
        Assert.isTrue(!errorLogs.isEmpty(), 'Expected errors to be logged for ' + serviceName + '.' + methodName);
        Assert.areEqual(1, errorLogs.size(), 'Expected 1 error to be logged for ' + serviceName + '.' + methodName);
        Assert.areEqual(serviceName, errorLogs[0].digitalmodus__Related_Service__c, 'Expected related service to be ' + serviceName);
        Assert.areEqual(methodName, errorLogs[0].digitalmodus__Triggering_Automation_Name__c, 'Expected triggering automation name to be ' + methodName);
    }

    public static void checkErrorForServiceAndMethod(String serviceName, String methodName, String errorMessage) {
        List<digitalmodus__System_Log__c> errorLogs = [
            SELECT Id, digitalmodus__Log_Message__c, digitalmodus__Log_Code__c,  digitalmodus__Related_Service__c, digitalmodus__Triggering_Automation_Name__c
            FROM digitalmodus__System_Log__c
            WHERE digitalmodus__Related_Service__c = :serviceName
            AND digitalmodus__Triggering_Automation_Name__c = :methodName
        ];
        Assert.isTrue(!errorLogs.isEmpty(), 'Expected errors to be logged for ' + serviceName + '.' + methodName);
        Assert.areEqual(1, errorLogs.size(), 'Expected 1 error to be logged for ' + serviceName + '.' + methodName);
        Assert.areEqual(serviceName, errorLogs[0].digitalmodus__Related_Service__c, 'Expected related service to be ' + serviceName);
        Assert.areEqual(methodName, errorLogs[0].digitalmodus__Triggering_Automation_Name__c, 'Expected triggering automation name to be ' + methodName);
        Assert.areEqual(errorMessage, errorLogs[0].digitalmodus__Log_Message__c, 'Expected error message to be ' + errorMessage);
    }
}