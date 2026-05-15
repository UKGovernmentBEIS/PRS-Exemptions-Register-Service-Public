import { LightningElement, api, track, wire } from 'lwc';
import getExemptionNotes from '@salesforce/apex/PRSE_LAViewExemptionController.getExemptionNotes';
import saveExemptionNotes from '@salesforce/apex/PRSE_LAViewExemptionController.saveExemptionNotes';
import systemLog from '@salesforce/apex/digitalmodus.SystemLogLwcWrapper.systemLog';
import { refreshApex } from '@salesforce/apex';

export default class PrseLAExemptionNotes extends LightningElement {
    @api exemptionId;

    @track notes = '';
    @track editableNotes = '';
    @track isEditing = false;
    maxChars = 2000;
    @track remainingChars = 2000;

    wiredNotesResult;

    @wire(getExemptionNotes, { exemptionId: '$exemptionId' })
    wiredNotes(result) {
        this.wiredNotesResult = result;
        const { data, error } = result;
        
        if (data) {
            this.notes = data;
        } else if (error) {
            console.error('Error loading exemption notes:', error);
        }
    }

    // Computed property: does the exemption have any notes?
    get hasNotes() {
        return this.notes && this.notes.trim().length > 0;
    }

    // Button label for read-only mode
    get editButtonLabel() {
        return this.hasNotes ? 'Edit notes' : 'Add notes';
    }

    // Enable editing
    handleEditClick() {
        this.editableNotes = this.notes;
        this.isEditing = true;
        this.updateRemainingChars();
    }

    handleKeyUp(event) {
        this.editableNotes = event.target.value;
        this.updateRemainingChars();
    }

    updateRemainingChars() {
        const len = this.editableNotes ? this.editableNotes.length : 0;
        this.remainingChars = this.maxChars - len;
    }

    get remainingCharsStyle() {
        return this.isOverLimit ? 'color: red;' : '';
    }
    get isOverLimit() {
        return this.remainingChars < 0;
    }

    // Save changes to Apex
    handleSaveClick() {
        saveExemptionNotes({ exemptionId: this.exemptionId, notes: this.editableNotes })
            .then(() => {
                this.isEditing = false;
                this.notes = this.editableNotes;
                return refreshApex(this.wiredNotesResult);
            })
            .catch(error => {
                console.error('Error saving notes:', error);
                this.handleError(error, 'handleSaveClick-saveExemptionNotes');
            });
    }

    handleError(error, methodName){
        let log = {
            relatedService : 'prseLAExemptionNotes.js',
            logMessage : error.errorType || error.name,
            logFullMessage : error.body?.message || error.message,
            logType : 'Error',
            logCode : 'LWC-LA-Exemption-Notes',
            relatedRecordId : '500A00000000123AAA',
            triggeringAutomationName : methodName
        }
        systemLog({log: log})
        .catch(methodError => {
            console.log('Failed to log error');
        });
    }
}