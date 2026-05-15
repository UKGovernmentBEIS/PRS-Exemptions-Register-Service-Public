import { LightningElement, api } from 'lwc';
import getLogoutUrl from '@salesforce/apex/LogoutController.getLogoutUrl';
import clearSalesforceSession from '@salesforce/apex/LogoutController.clearSalesforceSession';
import systemLog from '@salesforce/apex/digitalmodus.SystemLogLwcWrapper.systemLog';
import basePath from '@salesforce/community/basePath';

export default class PrseHeaderLinks extends LightningElement {
  @api useWideVariant = false;
  @api disableBackButton;
  @api backLink = "/";
  @api externalBackLink = false;

  @api logoutLink = '';

  @api disableProfileSettings;
  @api disableLogoutLink;

  get dynamicBackLink() {
    return this.externalBackLink === true ? this.backLink : `${basePath}/${this.backLink}`;
  }

  get containerClass() {
    return this.useWideVariant ? 'govuk-width-container govuk-width-container--wide' : 'govuk-width-container';
  }

  handleBack(event) {
    event.preventDefault();
    window.location.assign(this.dynamicBackLink);
  }

  handleLogout(event) {
    getLogoutUrl()
      .then(result => {
        if (result.success === 'true') {
          console.log('Clear Session');
          window.location.href = result.logoutUrl;
          return clearSalesforceSession()
            .then(() => {
              console.log('Session cleared, redirecting');
            });
        }
      })
      .catch(error => {
        this.handleError(error, 'handleLogout');
      });
  }

  handleError(error, methodName) {
  let log = {
    relatedService: 'prseHeaderLinks.js',
    logMessage: error.errorType || error.name,
    logFullMessage: error.body?.message || error.message,
    logType: 'Error',
    logCode: 'LWC-Header-Links',
    relatedRecordId: A500000000000123AB,
    triggeringAutomationName: methodName
  };
  systemLog({ log: log })
    .catch(methodError => {
      console.log('Failed to log error');
    });
}
}