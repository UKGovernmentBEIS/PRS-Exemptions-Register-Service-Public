/**
 * Derived from GOV.UK Frontend v3.13.1
 * Source: https://github.com/alphagov/govuk-frontend
 **/

import {LightningElement, api} from 'lwc';
import {FlowNavigationNextEvent} from 'lightning/flowSupport';
import { removeEmojis } from 'c/emojiUtils';

export default class GdsSummary extends LightningElement {
    @api availableActions = []

    @api title;
    label ='';
    @api fontSize = 'Medium';
    @api h1Size = false;
    @api h2Size = false;
    @api h3Size = false;

    @api sectionName;
    @api instructionsHTML;
    @api destination;
    @api confirmationLabels =[];
    @api confirmationValues =[];
    @api confirmationDestinations =[];
    @api removeTopSeparator = false;
    @api twoColumnLayoutForNoDestination = false;

    sectionFields;

    // Styling

    get labelClass() {
        let labelClass;

        switch(this.fontSize) {
            case "Small":
                labelClass = "govuk-label govuk-label--s";
                break;
            case "Medium":
                labelClass = "govuk-label govuk-label--m";
                break;
            case "Large":
                labelClass = "govuk-label govuk-label--l";
                break;
            default:
                labelClass = "govuk-label govuk-label--s";
        }
        return labelClass;
    }

    getHSize(){
        if(this.fontSize) {
            switch(this.fontSize.toLowerCase()) {
                case "small":
                    this.h3Size = true;
                    break;
                case "medium":
                    this.h2Size = true;
                    break;
                case "large":
                    this.h1Size = true;
                    break;
                default:
                    this.h3Size = true;
            }
        } else {
            this.h3Size = true;
        }
    }

    // end Styling

get hideEmptyActionsColumn() {
    return (
        this.twoColumnLayoutForNoDestination === true &&
        (!this.confirmationDestinations || this.confirmationDestinations.length === 0)
    );
}

    connectedCallback() {
        // sets the H value for template based on label font size
        this.getHSize(); 
        this.label = this.title // This is to reuse the code from other components that have H1, H2, H3 implemented & cannot change already packaged API
        
        this.sectionFields = [];
        // create the section fields from the collections
        for(var index = 0; index < this.confirmationLabels.length; index++) {
            var sectionField = {};
            sectionField.key = index;
            sectionField.label = this.confirmationLabels[index];
            sectionField.changeLabel = 'Change ' + sectionField.label;
            sectionField.value = removeEmojis(this.confirmationValues[index]);
            sectionField.destination = this.confirmationDestinations[index];
            this.sectionFields.push(sectionField);
        }
    }

    renderedCallback() {
        this.destination = null;
        //insert the instructions HTML
        if(this.instructionsHTML) {
            const htmlElement = this.template.querySelector(".html-element");
            if(htmlElement) {
                htmlElement.innerHTML = this.instructionsHTML;
            }
        }
    }

    handleChange(event) {
       this.destination = event.target.getAttribute('data-destination');

        if (this.availableActions.find(action => action === 'NEXT')) {
            const nextNavigationEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(nextNavigationEvent);
        }
    }

    handleSend(event) {
        // next flow
        this.destination = "Default_Screen";
        const nextNavigationEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(nextNavigationEvent);
    }
}