/**
 * Derived from GOV.UK Frontend v3.13.1
 * Source: https://github.com/alphagov/govuk-frontend
 **/
import { LightningElement, api, track, wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { MessageContext, publish, subscribe, unsubscribe, createMessageContext } from 'lightning/messageService';
import getPicklistValuesMapByObjectField from '@salesforce/apex/GovComponentHelper.getPicklistValuesMapByObjectField';
import REGISTER_MC from '@salesforce/messageChannel/uxgovuk__registrationMessage__c';
import UNREGISTER_MC from '@salesforce/messageChannel/uxgovuk__unregistrationMessage__c';
import VALIDATION_MC from '@salesforce/messageChannel/uxgovuk__validateMessage__c';
import VALIDATION_STATE_MC from '@salesforce/messageChannel/uxgovuk__validationStateMessage__c';
import SET_FOCUS_MC from '@salesforce/messageChannel/uxgovuk__setFocusMessage__c';

export default class GdsSelect extends LightningElement {
    @api fieldId = "selectField";
    fieldIdToFocus;
    @api label;
    @api fontSize;
    @api hintText;
    @api value = "";
    @api valueAPIName = "";  
    @api isInset;
    @api required;
    @api errorMessage;
    @api optionLabels;
    @api optionValues;
    @api picklist;
    @api caption;

    @api
    updateOptions(labels, values) {
    
        if (!labels || !values || labels.length !== values.length) {
            return;
        }
        
        this.optionLabels = labels.join('|');
        this.optionValues = values.join('|');

        // Rebuild select options
        this.selectOptions = [];
        
        // Add "Please select" option
        this.selectOptions.push({
            key: 'csv-value-no-value',
            label: "Please select",
            value: ""
        });
        
        // Add all options
        labels.forEach((label, i) => {
            this.selectOptions.push({
                key: `csv-value-${i}`,
                label: label,
                value: values[i],
                selected: false
            });
        });

        // Reset value to first option
        this.value = values[0];
    }


    @api h1Size = false;
    @api h2Size = false;
    @api h3Size = false;

    @track selectOptions;

    hasErrors;

    // messaging attributes
    @wire(MessageContext) messageContext;
    validateSubscription;
    setFocusSubscription;

    // Check if label contains HTML
    get hasHtmlLabel() {
        const result = this.label && (this.label.includes('<') || this.label.includes('>'));
        return result;
    }

    // Check if hint text contains HTML
    get hasHtmlHint() {
        const result = this.hintText && (this.hintText.includes('<') || this.hintText.includes('>'));
        console.log('=== hasHtmlHint check ===');
        console.log('HintText value:', this.hintText);
        console.log('Has HTML?:', result);
        return result;
    }

    connectedCallback() {
        console.log('=== connectedCallback START ===');
        console.log('HintText:', this.hintText);
        console.log('Picklist:', this.picklist);
        
        // sets the H value for template based on labele font size  
        this.getHSize(); 

        if(this.picklist !== '' && this.picklist !== undefined && this.picklist !== null) {
            setTimeout(() => {
                //call the apex to get the values
                getPicklistValuesMapByObjectField({
                    strSObjectFieldName: this.picklist
                })
                .then(result => {
                    this.selectOptions = [];
                    let selectOption = {};
                    selectOption.key = `csv-value-no-value`;
                    selectOption.label = "Please select";
                    selectOption.value = "";
                    this.selectOptions.push(selectOption);

                    let i = 0;
                    for(const label in result) {
                        let selectOption = {};
                        selectOption.key = `picklist-value-${i}`;
                        selectOption.value = label; 
                        selectOption.label = label;
                        selectOption.APIName = result[label]; 
                        
                        selectOption.selected = (this.value === label); 
                        
                        this.selectOptions.push(selectOption);
                        
                        i++;
                    }
                })
                .catch(error => {
                    console.error(`Select:connectedCallback - could not get picklist values due to ${error.message}`);
                })
            }, 100);
        } else if(this.optionLabels && this.optionValues) {
            // use the option labels and option values
            const optionLabelsArray = this.optionLabels.split('|');
            const optionValuesArray = this.optionValues.split('|');
            this.selectOptions = [];
            let selectOption = {};
            selectOption.key = `csv-value-no-value`;
            selectOption.label = "Please select";
            selectOption.value = "";
            this.selectOptions.push(selectOption);

            for(let i=0; i<optionLabelsArray.length;i++) {
                let selectOption = {};
                selectOption.key = `csv-value-${i}`;
                selectOption.label = optionLabelsArray[i];
                selectOption.value = optionValuesArray[i];
                selectOption.selected = (this.value === optionValuesArray[i]);
                this.selectOptions.push(selectOption);
            }
        } else {
            // Neither picklist nor optionLabels/optionValues provided - initialize with empty dropdown
            this.selectOptions = [];
            let selectOption = {};
            selectOption.key = `csv-value-no-value`;
            selectOption.label = "Please select";
            selectOption.value = "";
            this.selectOptions.push(selectOption);
        }
        
        this.subscribeMCs();

        this.register();
    }

    renderedCallback(){
        try {
            // Handle HTML in label if present
            if(this.hasHtmlLabel) {
                console.log('Has HTML label:', this.label);
                const labelElements = this.template.querySelectorAll('.label-with-html');
                console.log('Found label elements:', labelElements.length);
                labelElements.forEach(element => {
                    console.log('Setting innerHTML on element');
                    element.innerHTML = this.label;
                });
            }

            // Handle HTML in hint text if present
            if(this.hasHtmlHint) {
                console.log('Has HTML hint:', this.hintText);
                const hintElements = this.template.querySelectorAll('.hint-with-html');
                console.log('Found hint elements:', hintElements.length);
                hintElements.forEach(element => {
                    console.log('Setting innerHTML on hint element');
                    element.innerHTML = this.hintText;
                });
            }
           
            const selectElements = this.template.querySelectorAll('select[name="'+this.fieldId+'"]');
            console.log('*** first el: ' + selectElements[0] + ' ***');
            
            if(selectElements && selectElements.length ==1){
                selectElements.forEach((element) => {
                    const id = element.getAttribute('id');
                    const name = element.getAttribute('name');
                    this.fieldIdToFocus = id;
                });
            } else {
                console.log('*** Error: Two elemements with same Name. Change name of components so they are unique.');
            }
        } catch(ex){
            console.error('Error!!!!!: ' + ex);
        }
    }

    disconnectedCallback() {
        this.unregister();
        this.unsubscribeMCs();
    }

    get groupClass() {
        let groupClass = "govuk-form-group";
        groupClass = (this.hasErrors) ? groupClass + " govuk-form-group--error" : groupClass;
        return groupClass;
    }

    get labelClass() {
        var labelClass;

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

    handleOnChange(event) {
        this.value = event.target.value;

        this.selectOptions.forEach(selectOption => {
            if(selectOption.value === this.value) {
                selectOption.selected = true;
                this.valueAPIName = selectOption.APIName;
            } else {
                selectOption.selected = false;
            }
        });

        this.dispatchSelectEvent();
    }

    dispatchSelectEvent() {
        // tell the flow engine about the change
        const attributeChangeEvent = new FlowAttributeChangeEvent('value', this.value);
        this.dispatchEvent(attributeChangeEvent);

        const attributeChangeEventAPIName = new FlowAttributeChangeEvent('valueAPIName', this.valueAPIName);
        this.dispatchEvent(attributeChangeEventAPIName);

        // tell any parent components about the change
        const valueChangedEvent = new CustomEvent('valuechanged', {
            detail: {
                id: this.fieldId,
                value: this.value,
                valueAPIName: this.valueAPIName
            }
        });
        this.dispatchEvent(valueChangedEvent);
    }

    @api setValue(newValue) {
        this.value = newValue;
        this.selectOptions.forEach( option => {
            if(option.value === newValue) {
                option.selected = true;
                this.valueAPIName = option.APIName;
            } else {
                option.selected = false;
            }
        })
    }


    // LMS functions

    subscribeMCs() {
        if (this.validateSubscription) {
            return;
        }
        this.validateSubscription = subscribe (
            this.messageContext,
            VALIDATION_MC, (message) => {
                console.log('message form validation '+ message);
                console.log('message form validation '+ message.isValid);
                console.log('message form validation '+ message.error);
                console.log('message form validation '+ message.componentSelect);
                console.log('message form validation '+ message.componentType);
                console.log('message form validation '+ message.componentId);
                console.dir(message);
                this.handleValidateMessage(message);
            });

        // Receive focus request with message.componentId
        this.setFocusSubscription = subscribe (
            this.messageContext,
            SET_FOCUS_MC, (message) => {
                console.log('*** from this.setFocusSubscription message:' + message);
                this.handleSetFocusMessage(message);
            }
        )
    }

    register(){
        // publish the registration message after 0.1 sec to give other components time to initialise
        setTimeout(() => {
            publish(this.messageContext, REGISTER_MC, {componentId:this.fieldId, focusId: this.fieldIdToFocus});
        }, 100);
    }

    //inform subscribers that this comoponent is no longer available
    unregister() {
        console.log('govSelectField: unregister',this.fieldId);
        publish(createMessageContext(), UNREGISTER_MC, { componentId: this.fieldId });
    }

    unsubscribeMCs() {
        unsubscribe(this.validateSubscription);
        this.validateSubscription = null;
        unsubscribe(this.setFocusSubscription);
        this.setFocusSubscription = null;
    }

    handleSetFocusMessage(message){
        let myComponentId = message.componentId;
        console.log('**** myComponentId: ' + myComponentId);
        console.log('**** this.fieldIdToFocus: ' + this.fieldIdToFocus);
        if(myComponentId == this.fieldIdToFocus){
            console.dir(message);
            let myComponent = this.template.querySelectorAll('select[name="'+this.fieldId+'"]');
            requestAnimationFrame(() =>  myComponent[0].focus());
        }
    }

    handleValidateMessage(message) {
        this.handleValidate();
    }

    @api handleValidate() {
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
            focusId: this.fieldIdToFocus
        });

        return !this.hasErrors;
    }

    @api clearError() {
        this.hasErrors = false;
    }
}