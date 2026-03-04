import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getTotalExemptions from '@salesforce/apex/PRSE_DashboardController.getTotalExemptions';
import getUserDisplayName from '@salesforce/apex/PRSE_DashboardController.getUserDisplayName';

export default class PrseLandlordDashboard extends NavigationMixin(LightningElement) {
    displayName;

    handleRegisterExemption() {
        this[NavigationMixin.Navigate]({
        type: 'comm__namedPage',
        attributes: {
            name: 'ExemptionRegistration__c'
        }
        });
    }

    @track totals = {
        draft: 0,
        registered: 0,
        ended: 0
    };

    @wire(getUserDisplayName)
    userDisplayName({ error, data }) {
        if (data) {
            this.displayName = data;
        } else if (error) {
            console.error('Error fetching user data', error);
        }
    }

    connectedCallback() {
        this.loadTotals();
    }

    loadTotals() {
        // Drafts
        getTotalExemptions({ status: 'draft' })
            .then(result => {
                this.totals.draft = result;
            })
            .catch(error => {
                console.error('Error fetching draft total', error);
            });

        // Registered
        getTotalExemptions({ status: 'registered' })
            .then(result => {
                this.totals.registered = result;
            })
            .catch(error => {
                console.error('Error fetching registered total', error);
            });

        // Ended
        getTotalExemptions({ status: 'ended' })
            .then(result => {
                this.totals.ended = result;
            })
            .catch(error => {
                console.error('Error fetching ended total', error);
            });
    }
}