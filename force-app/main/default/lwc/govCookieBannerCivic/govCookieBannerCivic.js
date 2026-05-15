import { LightningElement, track, api, wire } from 'lwc';
import getCivicConfig from '@salesforce/apex/CivicConfigController.getCivicConfig';

export default class GovCookieBannerCivic extends LightningElement {

  @track isVisible = false;

  @api label;
  @api cookiePageUrl;
  @api acceptLabel;
  @api rejectLabel;
  @api bannerContent;

  consentResolved = false;

  @wire(getCivicConfig)
  wiredConfig({ data, error }) {
      if (data) {
          const config = JSON.parse(data);
          window.postMessage({
              type: 'CIVIC_CONFIG',
              config: config
          }, '*');
      } else if (error) {
          console.error('Failed to load Civic config:', error?.body?.message || error?.message);
      }
  }

  connectedCallback() {
      window.addEventListener('civicresponse', this.handleConsentMessage);
  }

  disconnectedCallback() {
    window.removeEventListener('civicresponse', this.handleConsentMessage);
  }

  handleConsentMessage = (event) => {
    const data = event?.detail;
    if (!data || typeof data !== 'object') {
      return;
    }

    if (data.type === 'CIVIC_CONSENT_STATE') {
      this.consentResolved = true;
      this.isVisible = data.showBanner;
    }

    if (data.type === 'CIVIC_READY') {
      this.sendCommand('CIVIC_GET_CONSENT');
    }
  }

  sendCommand(type) {
    window.dispatchEvent(
      new CustomEvent('civiccommand', {
        detail: { type }
      })
    );
  }

  handleAccept() {
    this.sendCommand('CIVIC_ACCEPT_ANALYTICS');
  }

  handleReject() {
    this.sendCommand('CIVIC_REJECT_ANALYTICS');
  }

  get isAcceptButtonVisible() {
    return this.acceptLabel !== '';
  }

  get isRejectButtonVisible() {
    return this.rejectLabel !== '';
  }

  get isCookiesPageLinkVisible() {
    return this.cookiePageUrl !== '';
  }
}