import { LightningElement, api } from 'lwc';

export default class GovUkNotificationBanner extends LightningElement {
    @api bannerTitle;
    @api bodyHeading;
    @api bodyContent;

    @api focusBanner() {
        const bannerDiv = this.template.querySelector('.govuk-notification-banner-custom');
        bannerDiv?.focus();
    }
}