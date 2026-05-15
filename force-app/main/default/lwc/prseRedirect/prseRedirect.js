import { LightningElement, api } from 'lwc';
import basePath from '@salesforce/community/basePath'

export default class PrseRedirect extends LightningElement {
    @api redirectUrl;
    @api externalLink;

    connectedCallback() {
        if (window.location.origin.includes('live-preview')) {
            return;
        }

        if (this.redirectUrl !== '') {
            if(this.externalLink === true) {
                window.location.href = this.redirectUrl;
            } else {
                window.location.href = window.location.origin + this.redirectUrl;
            }
        } else {
            window.location.href = `${window.location.origin}${basePath}`;
        }
    }
}