import { LightningElement, api } from "lwc";
import getLogoutUrl from '@salesforce/apex/LogoutController.getLogoutUrl';
import clearSalesforceSession from '@salesforce/apex/LogoutController.clearSalesforceSession';
import systemLog from '@salesforce/apex/digitalmodus.SystemLogLwcWrapper.systemLog';

export default class NavigateFromFlow2 extends LightningElement {

    @api externalUrl;
    @api redirectUrl;

    handleClick(event) {
        try {
            event.preventDefault();
            const currentAction = event.target.getAttribute('data-action');

            if(currentAction === 'logout') {
                this.handleLogout();
            }
            if(currentAction === 'survey') {
                window.location.assign(this.externalUrl);
            }
        } catch (error) {
            this.handleError(error, 'handleClick');
        }
    }

    async handleLogout() {
        try {
            // Get the logout URL
            const logoutResult = await getLogoutUrl();
            
            if (logoutResult.success === 'true' && logoutResult.logoutUrl) {
                // Clear the Salesforce session
                await clearSalesforceSession();
                
                // Redirect to the logout URL
                window.location.href = logoutResult.logoutUrl;
            } else {
                throw new Error('Failed to generate logout URL');
            }
        } catch (error) {
            this.handleError(error, 'handleLogout');
            
            if (this.redirectUrl) {
                console.warn('Falling back to simple redirect after error');
                
                try {
                    setTimeout(() => {
                        window.location.href = window.location.origin + '/' + this.redirectUrl;
                    }, 2000);
                } catch (redirectError) {
                    this.handleError(redirectError, 'handleLogout-fallbackRedirect');
                }
            }
        }
    }

    handleError(error, methodName) {
        let log = {
            relatedService: 'navigateFromFlow2.js',
            logMessage: error.errorType || error.name,
            logFullMessage: error.body?.message || error.message,
            logType: 'Error',
            logCode: 'LWC-Navigate-Flow',
            relatedRecordId: A500000000000123AB,
            triggeringAutomationName: methodName
        };
        systemLog({ log: log })
            .catch(methodError => {
                console.log('Failed to log error');
            });
    }
}