/**
 * Derived from GOV.UK Frontend v3.13.1
 * Source: https://github.com/alphagov/govuk-frontend
 */
import { LightningElement, api, track, wire } from 'lwc';
import { MessageContext, publish, subscribe, unsubscribe, createMessageContext } from 'lightning/messageService';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import REGISTER_MC from '@salesforce/messageChannel/uxgovuk__registrationMessage__c';
import UNREGISTER_MC from '@salesforce/messageChannel/uxgovuk__unregistrationMessage__c';
import VALIDATION_MC from '@salesforce/messageChannel/uxgovuk__validateMessage__c';
import VALIDATION_STATE_MC from '@salesforce/messageChannel/uxgovuk__validationStateMessage__c';
import SET_FOCUS_MC from '@salesforce/messageChannel/uxgovuk__setFocusMessage__c';
import { removeEmojis } from 'c/emojiUtils';

export default class GdsDateInput extends LightningElement {
    static delegatesFocus = true;

    @api fieldId = 'textField';
    @api textFieldId = 'input-text';
    @api label = '';
    @api labelFontSize = 'Medium';
    @api hintText = '';
    @api errorMessage = '';
    @api required = false;

    @api value = '';
    @api dayValue = '';
    @api monthValue = '';
    @api yearValue = '';

    @api allowPast = false;
    @api allowToday = false;
    @api allowFuture = false;

    @track hasErrors = false;

    @api h1Size = false;
    @api h2Size = false;
    @api h3Size = false;

    initialised = false;

    @wire(MessageContext) messageContext;
    validateSubscription;
    setFocusSubscription;

    get dayRegularExpression() {
        // 1–31
        return '^(0?[1-9]|[12][0-9]|3[01])$';
    }

    get monthRegularExpression() {
        // 1–12
        return '^(0?[1-9]|1[0-2])$';
    }

    get yearRegularExpression() {
        // 1900–2099
        return '^(19|20)[0-9]{2}$';
    }

    connectedCallback() {
        this.getHSize();

        this.subscribeMCs();

        this.updateCombinedValue();

        this.register();
    }

    renderedCallback() {
        this.textFieldId = this.template.querySelector('input').getAttribute('id');

        const htmlElement = this.template.querySelector('.html-element');
        if (htmlElement) {
            htmlElement.innerHTML = this.hintText;
            this.initialised = true;
        }

        const errorElement = this.template.querySelector('.html-error');
        if (errorElement) {
            const text = this.errorMessage || '';
            errorElement.innerHTML = text.replace(/\n/g, '<br>');
        }
    }

    disconnectedCallback() {
        this.unregister();
        this.unsubscribeMCs();
    }

    get groupClass() {
        let groupClass = 'govuk-form-group';
        groupClass = this.hasErrors ? groupClass + ' govuk-form-group--error' : groupClass;
        return groupClass;
    }

    get labelClass() {
        let labelClass;
        if (this.labelFontSize) {
            switch (this.labelFontSize.toLowerCase()) {
                case 'small':
                    labelClass = 'govuk-label govuk-label--s';
                    break;
                case 'medium':
                    labelClass = 'govuk-label govuk-label--m';
                    break;
                case 'large':
                    labelClass = 'govuk-label govuk-label--l';
                    break;
                default:
                    labelClass = 'govuk-label govuk-label--s';
            }
        } else {
            labelClass = 'govuk-label govuk-label--s';
        }
        return labelClass;
    }

    get getDayMonthInputClass() {
        return this.hasErrors
            ? 'govuk-input govuk-date-input__input govuk-input--width-2 govuk-input--error'
            : 'govuk-input govuk-date-input__input govuk-input--width-2';
    }

    get getYearInputClass() {
        return this.hasErrors
            ? 'govuk-input govuk-date-input__input govuk-input--width-4 govuk-input--error'
            : 'govuk-input govuk-date-input__input govuk-input--width-4';
    }

    getHSize() {
        if (this.labelFontSize) {
            switch (this.labelFontSize.toLowerCase()) {
                case 'small':
                    this.h3Size = true;
                    break;
                case 'medium':
                    this.h2Size = true;
                    break;
                case 'large':
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
        const { id, value } = event.target;
        if (id.startsWith('date-input-day')) {
            this.dayValue = value;
        } else if (id.startsWith('date-input-month')) {
            this.monthValue = value;
        } else if (id.startsWith('date-input-year')) {
            this.yearValue = value;
        }
        
        this.updateCombinedValue();
        this.dispatchTextInputEvent();
    }

    updateCombinedValue() {
        const day = (this.dayValue || '').padStart(2, '0');
        const month = (this.monthValue || '').padStart(2, '0');
        const year = this.yearValue || '';

        if (day && month && year) {
            this.value = `${day}-${month}-${year}`;
        } else {
            this.value = '';
        }
    }

    dispatchTextInputEvent() {
        const attributeChangeEvent = new FlowAttributeChangeEvent('value', this.value);
        this.dispatchEvent(attributeChangeEvent);

        const valueChangedEvent = new CustomEvent('valuechanged', {
            detail: {
                id: this.fieldId,
                value: this.value,
                day: this.dayValue,
                month: this.monthValue,
                year: this.yearValue
            }
        });
        this.dispatchEvent(valueChangedEvent);
    }

    subscribeMCs() {
        if (this.validateSubscription) {
            return;
        }

        this.validateSubscription = subscribe(
            this.messageContext,
            VALIDATION_MC,
            (message) => {
                this.handleValidateMessage(message);
            }
        );

        this.setFocusSubscription = subscribe(
            this.messageContext,
            SET_FOCUS_MC,
            (message) => {
                this.handleSetFocusMessage(message);
            }
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

    handleSetFocusMessage(message) {
        const myComponentId = message.componentId;

        if (myComponentId === this.textFieldId) {
            const myComponent = this.template.querySelector('input');
            requestAnimationFrame(() => myComponent.focus());
        }
    }

    handleValidateMessage() {
        this.handleValidate();
    }

    @api
    handleValidate() {
        this.dayValue = removeEmojis(this.dayValue);
        this.monthValue = removeEmojis(this.monthValue);
        this.yearValue = removeEmojis(this.yearValue);
        this.updateCombinedValue();

        this.hasErrors = false;
        let errorMessageToShow = this.formattedErrorMessage;

        if (this.required && !this.value) {
            this.hasErrors = true;
        } else if (this.value) {
            if (!this.isValidDate()) {
                this.hasErrors = true;
            }
        }

        if (!this.hasErrors) {
            errorMessageToShow = '';
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

    get formattedErrorMessage() {
        return (this.errorMessage || '').split('.').join('\n');
    }

    isValidDate() {
        const day = parseInt(this.dayValue, 10);
        const month = parseInt(this.monthValue, 10);
        const year = parseInt(this.yearValue, 10);
        if (Number.isNaN(day) || Number.isNaN(month) || Number.isNaN(year)) {
            return false;
        }

        return this.isValidDateCombination(day, month, year) && this.isDateAllowed(day, month, year);
    }

    isValidDateCombination(day, month, year) {
        if (year < 1900 || year > 2099) {
            return false;
        }
        if (month < 1 || month > 12) {
            return false;
        }
        if (day < 1 || day > 31) {
            return false;
        }

        const date = new Date(year, month - 1, day);
        return (
            date.getFullYear() === year &&
            date.getMonth() === month - 1 &&
            date.getDate() === day
        );
    }

    isDateAllowed(day, month, year) {
        const date = new Date(year, month - 1, day);
        date.setHours(0, 0, 0, 0);

        const dateToday = new Date();
        dateToday.setHours(0, 0, 0, 0);

        if(date.getTime() > dateToday.getTime()) {
            if(!this.allowFuture) {
                return false;
            }

        }
        if(date.getTime() < dateToday.getTime()) {
            if(!this.allowPast) {
                return false;
            }
        }
        if(date.getTime() === dateToday.getTime()) {
            if(!this.allowToday) {
                return false;
            }
        }
        return true;
    }

    @api
    clearError() {
        this.hasErrors = false;
    }
}