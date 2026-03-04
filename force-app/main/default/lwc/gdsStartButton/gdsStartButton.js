/**
 * Derived from GOV.UK Frontend v3.13.1
 * Source: https://github.com/alphagov/govuk-frontend
 **/
import {LightningElement, api} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class GdsStartButton extends NavigationMixin(LightningElement) {
    @api label;
    @api communityLink;
    @api externalLink;

    handleClick(event) {
        if(this.communityLink !== '') {
            if(this.externalLink === true) {
                window.location.href = window.location.origin + '/' + this.communityLink;
            } else {
                this[NavigationMixin.Navigate]({
                    type: 'comm__namedPage',
                    attributes: {
                        name: this.communityLink
                    },
                    state: {
                    }
                });
            }
        }
    }
}