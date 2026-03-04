import { LightningElement, api, track, wire } from 'lwc';
import getExemptionNotes from '@salesforce/apex/PRSE_LAViewExemptionController.getExemptionNotes';
import saveExemptionNotes from '@salesforce/apex/PRSE_LAViewExemptionController.saveExemptionNotes';
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

    handleTextareaChange(event) {
        this.editableNotes = event.target.value;
    }

    handleTextAreaOnInput(event) {
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
        saveExemptionNotes({ exemptionId: this.exemptionId, notes: this.editableNotes  })
            .then(() => {
                this.isEditing = false;
                return refreshApex(this.wiredNotesResult);
            })
            .catch(error => {
                console.error('Error saving notes:', error);
            });
    }
}
