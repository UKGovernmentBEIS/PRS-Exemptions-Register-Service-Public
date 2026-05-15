import { LightningElement, api, track, wire } from 'lwc';
import getExemptionLandlordDetails from '@salesforce/apex/PRSE_LAViewExemptionController.getExemptionLandlordDetails';

export default class PrseLAExemptionLandlordDetails extends LightningElement {

    @api exemptionId;
    @track landlord;

    @wire(getExemptionLandlordDetails, { exemptionId: '$exemptionId' })
    wiredLandlord({ error, data }) {
        if (data) {
            this.landlord = data;
        } else if (error) {
            console.error('Landlord details error: ', error);
        }
    }

    get showBusinessName() {
        return (this.landlord && this.landlord.LandlordBusinessName && this.landlord.LandlordBusinessName !== '') ? true : false;
    }

    get digitallyAssistedRoute() {
        return this.landlord?.DigitallyAssisted === true;
    }

    get partyType() {
        return this.landlord?.LandlordType === 'Individual' ? 'landlord' : 'agent';        
    }

}
