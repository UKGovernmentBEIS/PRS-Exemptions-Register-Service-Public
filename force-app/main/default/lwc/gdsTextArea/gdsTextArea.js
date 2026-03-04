/**
 * Derived from GOV.UK Frontend v3.13.1
 * Source: https://github.com/alphagov/govuk-frontend
 **/

import {LightningElement, api, track, wire} from 'lwc';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';
import { MessageContext, publish, subscribe, unsubscribe, createMessageContext } from 'lightning/messageService';
import REGISTER_MC from '@salesforce/messageChannel/uxgovuk__registrationMessage__c';
import UNREGISTER_MC from '@salesforce/messageChannel/uxgovuk__unregistrationMessage__c';
import VALIDATION_MC from '@salesforce/messageChannel/uxgovuk__validateMessage__c';
import VALIDATION_STATE_MC from '@salesforce/messageChannel/uxgovuk__validationStateMessage__c';
import SET_FOCUS_MC from '@salesforce/messageChannel/uxgovuk__setFocusMessage__c';
import { removeEmojis } from 'c/emojiUtils';

export default class GdsTextArea extends LightningElement {
    @api fieldId = "textAreaField";
    @api textAreaFieldId = "text-area";
    @api label;
    @api hint;
    @api value = '';
    @api characterLimit;
    @api required;
    @api errorMessage;
    @api fontSize = 'Medium';
    @api hintStyling = 'hint'
    @api maxCharacterCount = 32768;
    @api showCharacterCount;
    @api rowCount = 5;

    @track displayCharacterLimit;
    @track hasErrors;
    @track charCount;

    @api h1Size = false;
    @api h2Size = false;
    @api h3Size = false;
    @api caption;

    @wire(MessageContext) messageContext;
    validateSubscription;
    setFocusSubscription;

    get hasHtmlHint() {
        return this.hint && (this.hint.includes('<') || this.hint.includes('>'));
    }

    connectedCallback() {
        this.getHSize(); 

        this.value = (this.value === undefined) ? '' : this.value;

        this.charCount = (this.value) ? this.value.length : 0;

        this.subscribeMCs();

        this.register();
    }

    renderedCallback() {
        const textareaElement = this.template.querySelector('textarea');
        if (textareaElement) {
            this.textAreaFieldId = textareaElement.getAttribute('id');
        }

        if(this.hasHtmlHint) {
            const hintElement = this.template.querySelectorAll('.hint-with-html');
                hintElement.forEach(element => {
                    element.innerHTML = this.hint;
                });
        }
    }

    disconnectedCallback() {
        this.unregister();
        this.unsubscribeMCs();
    }

    get inputClass() {
        return this.hasErrors ? `govuk-textarea govuk-js-character-count govuk-textarea--error govuk-!-margin-bottom-0` : `govuk-textarea govuk-js-character-count govuk-!-margin-bottom-0`;
    }

    get groupClass() {
        let groupClass = "govuk-form-group";
        groupClass = (this.hasErrors) ? groupClass + " govuk-form-group--error" : groupClass;
        return groupClass;
    }

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

    get hintClass() {
        let hintClass;
        switch(this.hintStyling.toLowerCase()){
            case "hint":
                hintClass = "govuk-hint";
                break;
            case "subtitle small":
                hintClass = "govuk-label govuk-label--s";
                break;
            case "subtitle medium":
                hintClass = "govuk-label govuk-label--m";
                break;
            case "subtitle large":
                hintClass = "govuk-label govuk-label--l";
                break;
            default:
                hintClass = "govuk-hint";
            }
            return hintClass;
        }

    get characterCountText() {
        if(this.showCharacterCount) {
            if(this.charCount === 0 && this.maxCharacterCount) {
                return `${this.maxCharacterCount - this.charCount} characters remaining`;
            }
            let text = "";
            if(this.maxCharacterCount) {
                text =  `${this.maxCharacterCount - this.charCount} characters remaining`;
            } else {
                text = `${this.charCount} characters`;
            }
            return text;
        }
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

    handleKeyUp(event) {
        
        if(this.charCount <= this.maxCharacterCount) {
            this.value = event.target.value;
        }
        this.charCount = this.value.length;
        this.dispatchTextAreaEvent()
    }

    dispatchTextAreaEvent() {
        const attributeChangeEvent = new FlowAttributeChangeEvent('value', this.value);
        this.dispatchEvent(attributeChangeEvent);

        const valueChangedEvent = new CustomEvent('valuechanged', {
            detail: {
                id: this.fieldId,
                value: this.value,
            }
        });
        this.dispatchEvent(valueChangedEvent);
    }

    subscribeMCs() {
        if (this.validateSubscription) {
            return;
        }
        this.validateSubscription = subscribe (
            this.messageContext,
            VALIDATION_MC, (message) => {
                this.handleValidateMessage(message);
            });

        this.setFocusSubscription = subscribe (
            this.messageContext,
            SET_FOCUS_MC, (message) => {
                this.handleSetFocusMessage(message);
            }
        )
    }

    unsubscribeMCs() {
        unsubscribe(this.validateSubscription);
        this.validateSubscription = null;
        unsubscribe(this.setFocusSubscription);
        this.setFocusSubscription = null;
    }

    register(){
        setTimeout(() => {
            publish(this.messageContext, REGISTER_MC, {componentId:this.fieldId});
        }, 100);
    }

    unregister() {
        publish(createMessageContext(), UNREGISTER_MC, { componentId: this.fieldId });
    }

    handleSetFocusMessage(message){
        let myComponentId = message.componentId;
        if(myComponentId == this.textAreaFieldId){
            let myComponent = this.template.querySelector('textarea');
            if (myComponent) {
                myComponent.focus();
            }
        }
    }

    handleValidateMessage(message) {
        this.handleValidate()
    }

    @api handleValidate() {
        this.value = removeEmojis(this.value);
        this.hasErrors = false;

        if(this.required && this.value === "") {
            this.hasErrors = true;
        } else {
            this.hasErrors = false;
        }

        publish(this.messageContext, VALIDATION_STATE_MC, {
            componentId: this.fieldId,
            isValid: !this.hasErrors,
            error: this.errorMessage,
            focusId: this.textAreaFieldId
        });
    }

    @api clearError() {
        this.hasErrors = false;
    }
}