/**
 * gdsTextInput.js
 * Extended GOV.UK Text Input with Flow integration and type-ahead Person Account search
 */
import { LightningElement, api, track, wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { MessageContext, publish, subscribe, unsubscribe, createMessageContext } from 'lightning/messageService';
import REGISTER_MC from '@salesforce/messageChannel/uxgovuk__registrationMessage__c';
import UNREGISTER_MC from '@salesforce/messageChannel/uxgovuk__unregistrationMessage__c';
import VALIDATION_MC from '@salesforce/messageChannel/uxgovuk__validateMessage__c';
import VALIDATION_STATE_MC from '@salesforce/messageChannel/uxgovuk__validationStateMessage__c';
import SET_FOCUS_MC from '@salesforce/messageChannel/uxgovuk__setFocusMessage__c';
import { removeEmojis } from 'c/emojiUtils';
import searchPersonAccounts from '@salesforce/apex/PRSE_PersonAccountSearchController.searchPersonAccounts';

 
export default class PrseADAccountSearch extends LightningElement {
    static delegatesFocus = true;
    @api fieldId = 'textField';
    textFieldId = "input-text";
    @api label = '';
    @api labelFontSize = 'Medium';
    @api widthLengthWise = '20';
    @api widthQuarterWise = '';
    @api hintText = '';
    @api prefix = '';
    @api suffix = '';
    @api autocompleteType = '';
    @api spellcheckRequired = false;
    @api errorMessage = '';
    @api required = false;
    @api searchMode;
    @api selectedRecordId;

    internalValue = '';
    internalSelectedRecordId;

    @api
    get value() {
        return this.internalValue;
    }

    set value(v) {
        this.internalValue = v;
    }

    @track charCount = 0;
    @track hasErrors = false;
    @track searchResults = [];
    @track showResults = false;

    @api h1Size = false;
    @api h2Size = false;
    @api h3Size = false;

    initialised = false;
    searchTimeout;

    // --- Message context ---
    @wire(MessageContext) messageContext;
    validateSubscription;
    setFocusSubscription;
    searchRequestId = 0;

    connectedCallback() {
        this.getHSize();
        
        this.subscribeMCs();

        this.register();
    }

    disconnectedCallback() {
        this.unregister();
        this.unsubscribeMCs();
    }

    renderedCallback() {
        this.textFieldId = this.template.querySelector('input').getAttribute('id'); 
        
        const htmlElement = this.template.querySelector(".html-element");
        if (htmlElement) {
            htmlElement.innerHTML = this.hintText;
            this.initialised = true;
        }
    }

    get groupClass() {
        return this.hasErrors ? 'govuk-form-group govuk-form-group--error' : 'govuk-form-group';
    }

    get labelClass() {
        switch (this.labelFontSize?.toLowerCase()) {
            case 'small': return 'govuk-label govuk-label--s';
            case 'medium': return 'govuk-label govuk-label--m';
            case 'large': return 'govuk-label govuk-label--l';
            default: return 'govuk-label govuk-label--s';
        }
    }

    get inputClass() {
        let base = this.hasErrors ? 'govuk-input govuk-input--error' : 'govuk-input';
        if (this.widthLengthWise) {
            return `${base} govuk-input--width-${this.widthLengthWise}`;
        } else if (this.widthQuarterWise) {
            return `${base} govuk-input--width-${this.widthQuarterWise}`;
        }
        return `${base} govuk-input--width-20`;
    }

    getHSize() {
        switch (this.labelFontSize?.toLowerCase()) {
            case 'small': this.h3Size = true; break;
            case 'medium': this.h2Size = true; break;
            case 'large': this.h1Size = true; break;
            default: this.h3Size = true;
        }
    }

    handleKeyUp(event) {
        this.internalValue = event.target.value;

        this.dispatchTextInputEvent();
        if (this.searchMode) {
            this.performSearch();
        }
    }

    performSearch() {
        clearTimeout(this.searchTimeout);
        console.log('searching');

        if (!this.internalValue || this.internalValue.trim().length < 2) {
            this.showResults = false;
            return;
        }

        const searchKey = this.internalValue.trim();
        const requestId = ++this.searchRequestId;

        this.searchTimeout = setTimeout(() => {
            searchPersonAccounts({ searchKey })
                .then(result => {

                    // reject old responses
                    if (requestId !== this.searchRequestId) {
                        return;
                    }

                    this.searchResults = result;
                    this.showResults = result.length > 0;
                })
                .catch(error => console.error(error));
        }, 300);
    }

    handleSelect(event) {
        const recordId = event.currentTarget.dataset.id;
        const recordName = event.currentTarget.dataset.name;

        this.internalValue = recordName;
        this.internalSelectedRecordId = recordId;

        this.dispatchEvent(new FlowAttributeChangeEvent('value', recordName));
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedRecordId', recordId));

        this.showResults = false;        
    }

    handleBlur() {
        setTimeout(() => {
            this.showResults = false;
        }, 200);
    }

    dispatchTextInputEvent() {
        this.dispatchEvent(new FlowAttributeChangeEvent('value', this.internalValue));

        this.dispatchEvent(new CustomEvent('valuechanged', {
            detail: { id: this.fieldId, value: this.internalValue }
        }));
    }

    subscribeMCs() {
        if (this.validateSubscription) { return; }

        this.validateSubscription = subscribe(
            this.messageContext,
            VALIDATION_MC,
            message => { this.handleValidateMessage(message); }
        );
        
        this.setFocusSubscription = subscribe(
            this.messageContext,
            SET_FOCUS_MC,
            message => { this.handleSetFocusMessage(message); }
        );
        
    }

    unsubscribeMCs() {
        unsubscribe(this.validateSubscription);
        this.validateSubscription = null;
        unsubscribe(this.setFocusSubscription);
        this.setFocusSubscription = null;
    }

    register() {
        setTimeout(() => {
            publish(this.messageContext, REGISTER_MC, { componentId: this.textFieldId });
        }, 100);
    }

    unregister() {
        publish(createMessageContext(), UNREGISTER_MC, { componentId: this.textFieldId });
    }

    handleSetFocusMessage(message){
        if(message.componentId == this.textFieldId){
            const myComponent = this.template.querySelector('input');
            requestAnimationFrame(() => myComponent.focus());
        }
    }

    handleValidateMessage() {
        this.handleValidate();
    }

    @api handleValidate() {
        this.internalValue = removeEmojis(this.internalValue);
        this.hasErrors = false;
        let errorMessageToShow = this.errorMessage;
        if (this.required && !this.internalValue) {
            this.hasErrors = true;
        }        

        publish(this.messageContext, VALIDATION_STATE_MC, {
            componentId: this.textFieldId,
            componentSelect: 'INPUT',
            isValid: !this.hasErrors,
            error: errorMessageToShow,
            focusId: this.textFieldId
        });

        return !this.hasErrors;
    }

    @api clearError() {
        this.hasErrors = false;
    }
}