/**
 * Derived from GOV.UK Frontend v3.13.1
 * Source: https://github.com/alphagov/govuk-frontend
 **/
import { LightningElement, wire } from 'lwc';
import { MessageContext,publish, subscribe, unsubscribe } from 'lightning/messageService';
import VALIDATION_STATE_MC from '@salesforce/messageChannel/uxgovuk__validationStateMessage__c';
import VALIDATE_MC from '@salesforce/messageChannel/uxgovuk__validateMessage__c';
import SET_FOCUS_MC from '@salesforce/messageChannel/uxgovuk__setFocusMessage__c';
import './gdsErrorMessages.css';

export default class GdsErrorMessages extends LightningElement {
    highlightedLinkClass = '';
    
    components = [];
    errorPrefix = 'There is a problem';

    @wire(MessageContext) 
    messageContext;
    errorSubscription;
    validateSubscription;

    connectedCallback() {
        this.subscribeMCs();
    }

    disconnectedCallback() {
        this.unsubscribeMCs();
    }

    get hasErrors() {
        return (this.components.filter(component => component.isValid === false).length > 0);
    }

    subscribeMCs() {
        if (this.errorSubscription) {
            return;
        }
        this.errorSubscription = subscribe(
            this.messageContext,
            VALIDATION_STATE_MC, (message) => {
                this.handleValidationStateMessage(message);
            });
        
        if (this.validateSubscription) {
            return;
        }
        this.validateSubscription = subscribe(
            this.messageContext,
            VALIDATE_MC, (message) => {
                this.handleValidateMessage(message);
            });
    }

    unsubscribeMCs() {
        unsubscribe(this.errorSubscription);
        this.errorSubscription = null;
        unsubscribe(this.validateSubscription);
        this.validateSubscription = null;
    }

    handleValidationStateMessage(message) {
        let component = this.components.find(singleComponent => singleComponent.id === message.componentId);
        
        if(component) {
            if(message.isValid === true) {
                this.components = this.components.filter(singleComponent => singleComponent.id !== message.componentId);
            } else {
                component.isValid = message.isValid;
                component.error = message.error;
                component.focusId = message.focusId;
            }
        } else {
            if(message.isValid === false) {
                component = {
                    id: message.componentId,
                    isValid: message.isValid,
                    error: message.error,
                    componentType: message.componentType,
                    componentSelect: message.componentSelect,
                    focusId: message.focusId
                };
                this.components = [...this.components, component];
            }
        }
    }

    handleValidateMessage(message) {
        this.components = [];
        
        setTimeout(() => {
            this.putFocusOnError();
        }, 100);
    }

    handleClick(event) {
        event.preventDefault();
        let targetId = event.target.dataset.targetId;
        publish(this.messageContext, SET_FOCUS_MC, { componentId: targetId, focusId: targetId });
    }

    putFocusOnError(){
        const errorSummary = this.template.querySelector('.govuk-error-summary');
        if (errorSummary) {
            errorSummary.focus();
            errorSummary.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    }

    handleLinkFocus() {
        this.highlightedLinkClass = 'highlighted-link';
    }

    handleLinkBlur() {
        this.highlightedLinkClass = '';
    }
}