import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import SET_FOCUS_MC from '@salesforce/messageChannel/uxgovuk__setFocusMessage__c';

export default class GdsErrorMessagesImperative extends LightningElement {
    @api components;
    
    @wire(MessageContext)
    messageContext;


    hasErrors() {
        if (Array.isArray(this.components) && this.components.length > 0) {
            return true;
        }
        return false;
    }

    handleErrorLinkClick(event) {
        event.preventDefault();
        const fieldId = event.target.dataset.fieldId;

        event.target.blur();
        
        publish(this.messageContext, SET_FOCUS_MC, { componentId: fieldId, focusId: fieldId });
    }
}
