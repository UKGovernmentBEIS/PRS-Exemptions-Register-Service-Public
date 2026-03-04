/**
 * Handles logout functionality including session cleanup
 * Set as without sharing to allow session updates for deletion marking
 */
public without sharing class LogoutController {
    final static digitalmodus.SystemLogService errorLoggingService = new digitalmodus.SystemLogService('LogoutController');

    @AuraEnabled
    public static Map<String, String> getLogoutUrl() {
        try {
            String idTokenHint = getIdTokenFromAuthSession();

            if (String.isBlank(idTokenHint)) {
                System.debug('No active session found so no idTokenHint');
                throw new AuraHandledException('No active session found');
            }
            
            System.debug('Id token: ' + idTokenHint);
            String postLogoutRedirectUri = Site.getBaseUrl().replace('vforcesite', '').replaceAll('/$', '');
            String sitePrefix = postLogoutRedirectUri.substringAfterLast('/');

            String logoutUrl = 'https://oidc.integration.account.gov.uk/logout?id_token_hint=' + idTokenHint +
                    '&post_logout_redirect_uri=' + postLogoutRedirectUri + '/services/auth/rp/oidc/logout?post_logout_redirect_uri=/' + sitePrefix;

            return new Map<String, String>{
                    'logoutUrl' => logoutUrl,
                    'success' => 'true'
            };
        } catch (Exception ex) {
            errorLoggingService.setLogCode('LogoutController')
                .setTriggeringAutomationName('getLogoutUrl')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
            throw new AuraHandledException(
                'Could not generate logout URL. ' + ex.getMessage()
            );
        }
    }

    private static String getIdTokenFromAuthSession() {
        try {
            List<User_Session__c> userSessions = [
                SELECT Id, Id_Token__c, User__c, CreatedDate
                FROM User_Session__c
                WHERE User__c = :UserInfo.getUserEmail()
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (!userSessions.isEmpty()) {
                return userSessions[0].Id_Token__c;
            }
            
            return null;
        } catch (Exception ex) {
            errorLoggingService.setLogCode('LogoutController')
                .setTriggeringAutomationName('getIdTokenFromAuthSession')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
            return null;
        }
    }

    @AuraEnabled
    public static Map<String, Object> clearSalesforceSession() {
        Map<String, Object> result = new Map<String, Object>();
        try {
            List<User_Session__c> userSessions = [
                SELECT Id, User__c, Id_Token__c, CreatedDate, OwnerId
                FROM User_Session__c
                WHERE User__c = :UserInfo.getUserEmail()
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            if (userSessions.isEmpty()) {
                result.put('success', false);
                result.put('error', 'No active session found for user: ' + UserInfo.getUserEmail());
                return result;
            }
            
            delete userSessions[0];
            result.put('success', true);
            
            return result;
        } catch (Exception ex) {
            errorLoggingService.setLogCode('LogoutController')
                .setTriggeringAutomationName('clearSalesforceSession')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
            throw new AuraHandledException(
                'Could not clear session. Check user permissions ' + ex.getMessage()
            );
        }
    }
}