import { LightningElement, api, track, wire } from 'lwc';
import getExemptionAgentDetails from '@salesforce/apex/PRSE_LAViewExemptionController.getExemptionAgentDetails';

export default class PrseLAExemptionAgentDetails extends LightningElement {
    @api exemptionId;

    @track agent;

    @wire(getExemptionAgentDetails, { exemptionId: '$exemptionId' })
    wiredAgent({ error, data }) {
        if (data) {
            this.agent = data;
        } else if (error) {
            console.error('Error loading agent details: ', error);
        }
    }

    get hasAgent() {
        return !!this.agent;
    }

    get digitallyAssistedRoute() {
        return this.agent?.DigitallyAssisted === true;
    }
}
