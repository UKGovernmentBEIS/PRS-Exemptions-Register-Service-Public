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
        if(this.outputValue && this.outputValue.length > 0) {
            selectedLabels = this.outputValue.split('|');
        }

        //user provided values
        let labelsList = this.labels ? this.labels.split('|') : [];
        let hintList = this.hints ? this.hints.split('|') : [];
        for(let i=0; i<labelsList.length;i++){
            let checkboxObj = {
                checkboxLabel : '',
                checkboxHint : '',
                checkboxValue : false
                };
            checkboxObj.checkboxLabel = labelsList[i].trim();
            checkboxObj.checkboxHint = hintList[i] ? hintList[i].trim() : '';
            
            if(selectedLabels.includes(labelsList[i].trim())) {
                checkboxObj.checkboxValue = true;
            } else {
                checkboxObj.checkboxValue = false;
            }
            this.checkboxArray.push(checkboxObj);
        }

        this.updateOutputValues();

        this.subscribeMCs();

        this.checkboxFieldIdForFocus = this.fieldId;
        setTimeout(() => {
            publish(this.messageContext, REGISTER_MC, {componentId:this.fieldId, focusId: this.checkboxFieldIdForFocus});
        }, 100);
    }

    updateOutputValues() {
        let checkedCount = 0;
        this.outputValueCollection = [];
        this.outputValueBoolean = '';
        this.outputValue = '';

        for(var i=0; i<this.checkboxArray.length; i++){
            if (i==0) {
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

        if(checkedCount > 0){
            this.checked = true;
            this.dispatchCheckboxEvent();
        } else {
            this.checked = false;
        }
    }

    disconnectedCallback() {
        this.unsubscribeMCs();
    }

    allCheckboxFieldComps; //// 
    renderedCallback() {
        setTimeout(() => {
            // for(let i=0; i<this.checkboxArray.length; i++){
            //     console.log('checkboxArray[i].label: ' + this.checkboxArray[i].label);
            //     console.log('checkboxArray[i].value: ' + this.checkboxArray[i].checkboxValue);
            // }
            const firstChecboxName = this.checkboxArray[0].checkboxLabel;
            // console.log('firstCheckoxName: ' + firstChecboxName);

            this.allCheckboxFieldComps = this.template.querySelectorAll('input[name="'+firstChecboxName+'"]');

            this.checkboxFieldIdForFocus = allCheckboxFieldComps[0].id;

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

    // Event Functions

    handleClick(event) {
        
        this.outputValueCollection = [];
        this.outputValueBoolean = '';
        this.outputValue = '';
        let outputString = '';
        let checkboxId = event.target.dataset.id;
        let checkedCount = 0;

        for(var i=0; i<this.checkboxArray.length; i++){
            if(this.checkboxArray[i].checkboxLabel == checkboxId){
                this.checkboxArray[i].checkboxValue = event.target.checked;
            }
            if (i==0) {
                this.outputValueBoolean = this.checkboxArray[i].checkboxValue;
            } else {
                this.outputValueBoolean = this.outputValueBoolean + ';' + this.checkboxArray[i].checkboxValue;
            }
            if(this.checkboxArray[i].checkboxValue == true){
                checkedCount ++;
                outputString = this.checkboxArray[i].checkboxLabel;
                this.outputValueCollection.push(outputString);
                if (this.outputValue.length==0) {
                    this.outputValue = outputString;
                } else {
                    this.outputValue = this.outputValue + '|' + outputString;
                }
                outputString = '';
            }
        }
        if(checkedCount>0){
            this.checked = true;
            
        }else{
            this.checked = false;
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
                // console.log('validation_MC response in govCheckboxes:');
                // console.log(message.componentId);
                // console.log(message.focusId);
                this.handleValidateMessage(message);
            });
    
        // Receive focus request with message.componentId
        this.setFocusSubscription = subscribe (
            this.messageContext,
            SET_FOCUS_MC, (message) => {
                // console.log('setFocus_MC response in govCheckboxes:');
                // console.log(message.componentId);
                // console.log(message.focusId);
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
        // console.log('************');
    // console.log(message.componentId);
    // console.log('this.fieldId' + this.fieldId);
    //     if (myComponentId == this.fieldId) {
    //         // set focus
    //         let myComponent = this.template.querySelector('input');
    //         myComponent.focus();
    //     }
    // console.log('************');

        // console.log('Setting FOCUS: ');
        // console.log('myComponentId: '+myComponentId);
        // console.log('this.checkboxFieldIdForFocus: '+this.checkboxFieldIdForFocus);
        // console.log('this.fieldId: '+this.fieldId);

        if(myComponentId == this.checkboxFieldIdForFocus){
            
            //console.log('Setting FOCUS on: ' + this.checkboxFieldIdForFocus);
            // console.dir(message);
            //let myComponent = this.template.querySelector('input');
            //console.log('what component:' + this.allCheckboxFieldComps);

            requestAnimationFrame(() => {
                this.allCheckboxFieldComps[0].focus();
            });
            // myComponent.focus();
        }
    }

    handleValidateMessage(message) {
        this.handleValidation()
    }

    @api handleValidation() {
        this.clearError();
        // this.hasErrors = false;

        if(this.required && this.checked === false) {
            this.hasErrors = true;
        } 
        else {
            this.hasErrors = false;
        }
         console.log('inside handleValidation in govCheckboxes');
         console.log('this.required:  ' + this.required);
         console.log('this.checked:  ' + this.checked);
         console.log('this.hasErrors:  ' + this.hasErrors);
         console.log('this.errorMessage:  ' + this.errorMessage);
         console.log('this.fieldId:  ' + this.fieldId);

         console.log('handleValidation : this.checkboxFieldIdForFocus: '+this.checkboxFieldIdForFocus);
        console.log('CHECKBOX: Sending validation state message');
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
}