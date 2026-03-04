import { LightningElement, api } from 'lwc';

export default class PrseRedirect extends LightningElement {
    @api redirectUrl;

    connectedCallback() {
        if(this.redirectUrl !== '') {
            //window.location.href = window.location.origin + '/PRSExemptionsRegister';
            window.location.href = window.location.origin + this.redirectUrl;
        }
    }
}