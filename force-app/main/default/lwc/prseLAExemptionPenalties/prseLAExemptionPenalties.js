import { LightningElement, api } from 'lwc';

export default class PrseLAExemptionPenalties extends LightningElement {
    @api exemptionId;

    @api localAuthorityCodes;

    connectedCallback() {
        this.localAuthorityCodes = [];
    }
}
