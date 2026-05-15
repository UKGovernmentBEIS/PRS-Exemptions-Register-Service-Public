import { LightningElement, api } from "lwc";
import basePath from '@salesforce/community/basePath';

export default class NavigateFromFlow extends LightningElement {

    @api redirectUrl;

    connectedCallback() {
        if(this.redirectUrl != '') {
            window.location.href = `${window.location.origin}${basePath}` + '/' + this.redirectUrl;
        }
    }
}