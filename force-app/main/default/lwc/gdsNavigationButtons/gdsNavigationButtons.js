/**
 * Derived from GOV.UK Frontend v3.13.1
 * Source: https://github.com/alphagov/govuk-frontend
 **/
import {LightningElement, api, track, wire} from 'lwc';
import { FlowNavigationBackEvent, FlowNavigationNextEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { MessageContext, publish, subscribe, unsubscribe } from 'lightning/messageService';
import REGISTER_MC from '@salesforce/messageChannel/uxgovuk__registrationMessage__c';
import UNREGISTER_MC from '@salesforce/messageChannel/uxgovuk__unregistrationMessage__c';
import VALIDATE_MC from '@salesforce/messageChannel/uxgovuk__validateMessage__c';
import VALIDATION_STATE_MC from '@salesforce/messageChannel/uxgovuk__validationStateMessage__c';

export default class GdsNavigationButtons extends LightningElement {
    // flow actions
    @api availableActions = [];

    // messaging attributes
    @wire(MessageContext) messageContext;
    registrationSubscription;
    unRegistrationSubscription;
    validationStateSubscription;

    // flow inputs and outputs
    @api buttonLabelsString;
    @api buttonActionsString;
    @api buttonVariantsString;
    @api buttonAlignmentsString;
    @api action;
    @api fieldId = 'NavigationButtons';
    @api useFlowStyling;
    @api fullWidth = false;

    @api inline = false;

    // tracked attributes
    @track leftButtons = [];
    @track centerButtons = [];
    @track rightButtons = [];

    // other attributes
    components = [];

    // Lifecycle listeners

    connectedCallback() {
        // subscribe to registration events
        this.subscribeMCs();

        // bug out if no configuration string
        if(!this.buttonActionsString ||
            !this.buttonLabelsString ||
            !this.buttonVariantsString ||
            !this.buttonAlignmentsString) {
            return;
        }

        // create the object base on the csv
        const buttonAlignments = this.buttonAlignmentsString.split(',');
        const buttonLabels = this.buttonLabelsString.split(',');

        const buttonActions = this.buttonActionsString.split(',');
        const buttonVariant = this.buttonVariantsString.split(',');

        // create the button definition
        this.leftButtons = [];
        this.centerButtons = [];
        this.rightButtons = [];

        for(let i=0; i<buttonAlignments.length; i++) {
            let button = {};
            button.key = i;
            button.label = buttonLabels[i];
            button.action = buttonActions[i];
            button.variant = buttonVariant[i];
            button.link = false;

            if(button.variant.toUpperCase() === 'BRAND') {
                button.class = 'govuk-button-update govuk-!-margin-1';
            } else if(button.variant.toUpperCase() === 'SECONDARY') {
                button.class = 'govuk-button-update govuk-button-update--secondary govuk-!-margin-1';
            } else if(button.variant.toUpperCase() === 'WARNING') {
                button.class = 'govuk-button-update govuk-button-update--warning govuk-!-margin-1';
            } else if(button.variant.toUpperCase() === 'DISABLED'){
                button.class = 'govuk-button-update govuk-button-update--disabled govuk-!-margin-1';
            } else if(button.variant.toUpperCase() === 'LINK'){
                button.link = true;
                button.class = 'govuk-link-button govuk-link--no-visited-state';
            } else {
                button.class = 'govuk-button-update govuk-!-margin-1';
            }

            if(buttonAlignments[i].toUpperCase() === 'LEFT') {
                this.leftButtons.push(button);
            } else if(buttonAlignments[i].toUpperCase() === 'CENTER') {
                this.centerButtons.push(button);
            } else if(buttonAlignments[i].toUpperCase() === 'RIGHT') {
                this.rightButtons.push(button);
            } else {
                this.rightButtons.push(button);
            }
        }
    }

    renderedCallback() {
        
    }

    disconnectedCallback() {
        this.unsubscribeMCs();
    }

    // class related functions
    get containerWidthClass() {
        return (this.fullWidth) ? "" : "govuk-grid-column-two-thirds";
    }

    // Event handlers functions
    handleClick(event) {
        const currentAction = event.target.getAttribute('data-action').toUpperCase();
        const skipValidation = currentAction.includes('~SKIP');
        const normalizedAction = currentAction.replace('~SKIP', '').trim();
        
        //Sets output
        this.action = normalizedAction;

        const shouldValidate = !skipValidation && this.components.length > 0;
        const isAvailable = (action) => this.availableActions.includes(action);

        const dispatchFlowEvent = (FlowEventClass, clearStorage = false) => {
            if (clearStorage) this.clearSessionStorage();
            this.dispatchEvent(new FlowEventClass());
        };

        if ((normalizedAction === 'NEXT' || normalizedAction === 'FINISH') && shouldValidate) {
            this.components.forEach(component => component.isValid = false);
            publish(this.messageContext, VALIDATE_MC, { componentId: this.fieldId });
            return;
        }

        switch (normalizedAction) {
            case 'NEXT':
                if (isAvailable('NEXT')) {
                    dispatchFlowEvent(FlowNavigationNextEvent);
                }
                break;
            case 'FINISH':
                if (isAvailable('FINISH')) {
                    dispatchFlowEvent(FlowNavigationFinishEvent, true);
                }
                break;
            case 'CANCEL':
                if (isAvailable('NEXT')) {
                    dispatchFlowEvent(FlowNavigationNextEvent);
                } else if (isAvailable('FINISH')) {
                    dispatchFlowEvent(FlowNavigationFinishEvent, true);
                }
                break;
            case 'BACK':
                if (isAvailable('BACK')) {
                    dispatchFlowEvent(FlowNavigationBackEvent);
                }
                break;
            default:
                if (shouldValidate) {
                    this.components.forEach(component => component.isValid = false);
                    publish(this.messageContext, VALIDATE_MC, { componentId: this.fieldId });
                } else {
                    dispatchFlowEvent(FlowNavigationNextEvent);
                }
                break;

        }
    }


    validate(){
        this.components.forEach(component => {
            component.isValid = false;
        })
        publish(this.messageContext, VALIDATE_MC, { componentId: this.fieldId });
    }


    // Messaging related functions
    subscribeMCs() {
        if (this.registrationSubscription) {
            return;
        }
        this.registrationSubscription = subscribe (
            this.messageContext,
            REGISTER_MC, (message) => {
                this.handleRegistrationMessage(message);
        });

        if (this.unRegistrationSubscription) {
            return;
        }

        this.unRegistrationSubscription = subscribe (
            this.messageContext,
            UNREGISTER_MC, (message) => {
                this.handleUnRegistrationMessage(message);
            });
        if (this.validationStateSubscription) {
            return;
        }
        this.validationStateSubscription = subscribe (
            this.messageContext,
            VALIDATION_STATE_MC, (message) => {
                this.handleValidationUpdate(message);
            });
    }

    unsubscribeMCs() {
        unsubscribe(this.registrationSubscription);
        this.registrationSubscription = null;
        unsubscribe(this.unRegistrationSubscription);
        this.unRegistrationSubscription = null;
        unsubscribe(this.validationStateSubscription);
        this.validationStateSubscription = null;
    }


    handleRegistrationMessage(message) {
        const component = {};
        component.id = message.componentId;
        component.isValid = true;
        component.error = "";
        this.components.push(component);
    }

    handleUnRegistrationMessage(message) {
        //remove component from this.components array
        for(let i=0; i<this.components.length; i++ ){
            if(this.components[i].id == message.componentId){
                console.log('found component to remove: ' + this.components[i].id);
                this.components.splice(i,1);
            }
        }
    }

    handleValidationUpdate(message) {
        // update the component that sent the message
        // filtering components to find the one that matches the id
        const component = this.components.find(component => component.id === message.componentId);
        
        if(component) {
            component.isValid = message.isValid;
        } 
        for(let i=0; i<this.components.length; i++ ){
            if(this.components[i].id == undefined){
                // remove empty component form array
                this.components.splice(i,1);
            }
        }
         
        // check to see if we have all valid components
        const invalidComponents = this.components.filter(component => component.isValid === false);
    

        if(invalidComponents.length === 0) {
            if (this.action === 'NEXT' &&
                this.availableActions.find(action => action === 'NEXT')) {
                const event = new FlowNavigationNextEvent();
                this.dispatchEvent(event);
            } else if (this.action === 'NEXT' &&
                this.availableActions.find(action => action === 'FINISH')) {
                const event = new FlowNavigationFinishEvent();
                this.dispatchEvent(event);
            } else if (this.action === 'FINISH' &&
                this.availableActions.find(action => action === 'FINISH')) {
                const event = new FlowNavigationFinishEvent();
                this.dispatchEvent(event);
            } else {
                // catch all for actions other than NEXT and FINISH to progress forward
                const event = new FlowNavigationNextEvent();
                this.dispatchEvent(event);
            }
        } else {
            for(let i=0; i<invalidComponents.length; i++ ){
                 let myComp = invalidComponents[i];
            }
        }
    }

    clearSessionStorage() {
        sessionStorage.clear();
    }
}