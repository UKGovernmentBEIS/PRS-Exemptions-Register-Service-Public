/**
 * Derived from GOV.UK Frontend v3.13.1
 * Source: https://github.com/alphagov/govuk-frontend
 **/
import {LightningElement, api, wire, track} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { MessageContext, publish, subscribe, unsubscribe } from 'lightning/messageService';
import REGISTER_MC from '@salesforce/messageChannel/uxgovuk__registrationMessage__c';
import VALIDATION_MC from '@salesforce/messageChannel/uxgovuk__validateMessage__c';
import VALIDATION_STATE_MC from '@salesforce/messageChannel/uxgovuk__validationStateMessage__c';
import SET_FOCUS_MC from '@salesforce/messageChannel/uxgovuk__setFocusMessage__c';

export default class GovCheckboxes extends LightningElement {
    // flow inputs and outputs
    @api fieldId = "checkboxField";
    checkboxFieldIdForFocus;
    @api errorMessage;
    @api headinglabel;
    @api headinghint;
    @api headinghint2;
    @api required = false;
    @api labels ;
    @api hints ;
    @api booleanValues;
    @api outputValueCollection = [];
    @api outputValueBoolean;
    @api outputValue;
    @api picklistField;

    @api h1Size = false;
    @api h2Size = false;
    @api h3Size = false;

    @api headingFontSize = '';
    @api smallerCheckboxes;

    @track checkboxArray = [];
    @track checked = false;

    @api clashingSelectionsConfig;
    clashingSelections = []; 

    // other attributes
    initialised;
    hasErrors;

    // messaging attributes
    @wire(MessageContext) messageContext;
    validateSubscription;
    setFocusSubscription;

    //Lifecycle functions

    get headingLabelClass() {
        let headingLabelClass;
        switch(this.headingFontSize.toLowerCase()) {
            case "small":
                headingLabelClass = "govuk-label govuk-label--s";
                break;
            case "medium":
                headingLabelClass = "govuk-label govuk-label--m";
                break;
            case "large":
                headingLabelClass = "govuk-label govuk-label--l";
                break;
            default:
                headingLabelClass = "govuk-label govuk-label--s";
        }
        return headingLabelClass;
    }

    get checkboxClass() {
        let checkboxClass = "govuk-checkboxes";
        checkboxClass = (this.smallerCheckboxes) ? checkboxClass + " govuk-checkboxes--small" : checkboxClass;
        return checkboxClass;
    }

    connectedCallback() {
        // sets the H value for template based on label font size  
        this.getHSize(); 

        let selectedLabels = [];
        if (this.outputValue && this.outputValue.length > 0) {
            selectedLabels = this.outputValue.split('|');
        }

        const labelsList = this.labels ? this.labels.split('|') : [];
        const hintList = this.hints ? this.hints.split('|') : [];
        this.checkboxArray = [];

        for (let i = 0; i < labelsList.length; i++) {
            const checkboxObj = {
                checkboxLabel: '',
                checkboxHint: '',
                checkboxValue: false
            };
            checkboxObj.checkboxLabel = labelsList[i].trim();
            checkboxObj.checkboxHint = hintList[i] ? hintList[i].trim() : '';

            checkboxObj.checkboxValue = selectedLabels.includes(labelsList[i].trim());
            this.checkboxArray.push(checkboxObj);
        }

        if (this.clashingSelectionsConfig) {
            this.clashingSelections = this.clashingSelectionsConfig
                .split(';')
                .map(rule => {
                    const parts = rule.split('|').map(p => p.trim());
                    if (parts.length < 3) {
                        return null;
                    }
                    const i1 = Number(parts[0]);
                    const i2 = Number(parts[1]);
                    const message = parts.slice(2).join('|');

                    if (Number.isNaN(i1) || Number.isNaN(i2)) {
                        return null;
                    }

                    return {
                        indexes: [i1, i2],
                        message
                    };
                })
                .filter(rule => rule !== null);
        } else {
            this.clashingSelections = [];
        }

        this.updateOutputValues();
        this.subscribeMCs();

        this.checkboxFieldIdForFocus = this.fieldId;
        setTimeout(() => {
            publish(this.messageContext, REGISTER_MC, {
                componentId: this.fieldId,
                focusId: this.checkboxFieldIdForFocus
            });
        }, 100);
    }

    updateOutputValues() {
        let checkedCount = 0;
        this.outputValueCollection = [];
        this.outputValueBoolean = '';
        this.outputValue = '';

        for(var i = 0; i < this.checkboxArray.length; i++) {
            if (i == 0) {
                this.outputValueBoolean = this.checkboxArray[i].checkboxValue;
            } else {
                this.outputValueBoolean = this.outputValueBoolean + ';' + this.checkboxArray[i].checkboxValue;
            }
            if(this.checkboxArray[i].checkboxValue == true){
                checkedCount++;
                let outputString = this.checkboxArray[i].checkboxLabel;
                this.outputValueCollection.push(outputString);
                if (this.outputValue === undefined || this.outputValue.length === 0) {
                    this.outputValue = outputString;
                } else {
                    this.outputValue = this.outputValue + '|' + outputString;
                }
            }
        }

        if(checkedCount > 0) {
            this.checked = true;
            this.dispatchCheckboxEvent();
        } else {
            this.checked = false;
        }
    }

    disconnectedCallback() {
        this.unsubscribeMCs();
    }

    renderedCallback() {
        setTimeout(() => {
            const firstChecboxName = this.checkboxArray[0].checkboxLabel;

            this.allCheckboxFieldComps = this.template.querySelectorAll('input[name="' + firstChecboxName + '"]');
            this.checkboxFieldIdForFocus = this.allCheckboxFieldComps[0].id;

            if(this.initialised) {
                return;
            }
            const labelText = this.template.querySelectorAll(".label-text").forEach(element => {
                element.innerHTML = this.label;
            })
            this.initialised = true;
            
        }, 100);
    }

    getHSize(){
        if(this.headingFontSize) {
            switch(this.headingFontSize.toLowerCase()) {
                case "small":
                    this.h3Size = true;
                    // labelClass = "govuk-label govuk-label--s";
                    break;
                case "medium":
                    this.h2Size = true;
                    // labelClass = "govuk-label govuk-label--m";
                    break;
                case "large":
                    this.h1Size = true;
                    // labelClass = "govuk-label govuk-label--l";
                    break;
                default:
                    this.h3Size = true;
                    // labelClass = "govuk-label govuk-label--s";
            }
        } else {
            this.h3Size = true;
            // labelClass = "govuk-label govuk-label--s";
        }
        //return labelClass;
    }

   handleClick(event) {
        const checkboxIndex = Number(event.target.dataset.index);
        const newCheckedValue = event.target.checked;

        this.checkboxArray[checkboxIndex].checkboxValue = newCheckedValue;

        const clashingRule = this.getClashingRule();
        if (clashingRule) {
            this.checkboxArray[checkboxIndex].checkboxValue = !newCheckedValue;
            event.target.checked = !newCheckedValue;

            this.hasErrors = true;
            this.errorMessage =
                clashingRule.message || 'You cannot select this combination of options.';

            publish(this.messageContext, VALIDATION_STATE_MC, {
                componentId: this.fieldId,
                isValid: false,
                error: this.errorMessage,
                focusId: this.checkboxFieldIdForFocus
            });

            return;
        }

        this.outputValueCollection = [];
        this.outputValueBoolean = '';
        this.outputValue = '';

        let checkedCount = 0;

        for (let i = 0; i < this.checkboxArray.length; i++) {
            const isChecked = this.checkboxArray[i].checkboxValue;

            if (i === 0) {
                this.outputValueBoolean = isChecked;
            } else {
                this.outputValueBoolean =
                    this.outputValueBoolean + ';' + isChecked;
            }

            if (isChecked) {
                checkedCount++;
                const label = this.checkboxArray[i].checkboxLabel;
                this.outputValueCollection.push(label);

                if (!this.outputValue || this.outputValue.length === 0) {
                    this.outputValue = label;
                } else {
                    this.outputValue = this.outputValue + '|' + label;
                }
            }
        }

        this.checked = checkedCount > 0;

        if (!this.getClashingRule()) {
            this.clearError();
        }

        this.dispatchCheckboxEvent();
    }


    dispatchCheckboxEvent() {
        // tell the flow engine about the change
        const attributeChangeEvent = new FlowAttributeChangeEvent('value', this.outputValue);
        this.dispatchEvent(attributeChangeEvent);

        // tell any parent components about the change
        const valueChangedEvent = new CustomEvent('valuechanged', {
            detail: {
                id: this.fieldId,
                value: this.outputValue,
            }
        });
        this.dispatchEvent(valueChangedEvent);
    }

    // Class functions

    get inputClass() {
        return this.hasErrors ? "govuk-input--error" : "govuk-input";
    }

    get groupClass() {
        let groupClass = "govuk-form-group";
        groupClass = (this.hasErrors) ? groupClass + " govuk-form-group--error" : groupClass;
        return groupClass;
    }


    // LMS functions

    subscribeMCs() {
        if (this.validateSubscription) {
            return;
        }
        this.validateSubscription = subscribe (
            this.messageContext,
            VALIDATION_MC, (message) => {
                this.handleValidateMessage(message);
            });
    
        // Receive focus request with message.componentId
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

    handleSetFocusMessage(message){
        // filter message to check if our component (id) needs to set focus
        let myComponentId = message.componentId;

        if(myComponentId == this.checkboxFieldIdForFocus){
            requestAnimationFrame(() => {
                this.allCheckboxFieldComps[0].focus();
            });
        }
    }

    handleValidateMessage(message) {
        this.handleValidation()
    }

    @api handleValidation() {
        this.clearError();

        if(this.required && this.checked === false) {
            this.hasErrors = true;
        } 
        else {
            this.hasErrors = false;
        }

        publish(this.messageContext, VALIDATION_STATE_MC, {
            componentId: this.fieldId, 
            isValid: !this.hasErrors,
            error: this.errorMessage,
            focusId: this.checkboxFieldIdForFocus
        });
        return !this.hasErrors;
    }

    @api clearError() {
        this.hasErrors = false;
    }

    getClashingRule() {
        const selectedIndexes = this.checkboxArray
            .map((c, index) => (c.checkboxValue ? index : -1))
            .filter(index => index !== -1);

        return this.clashingSelections.find(rule => {
            const [i1, i2] = rule.indexes;
            return selectedIndexes.includes(i1) && selectedIndexes.includes(i2);
        }) || null;
    }
}