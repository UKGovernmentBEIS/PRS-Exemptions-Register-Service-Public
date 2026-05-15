import { LightningElement, api, track, wire } from 'lwc';
import getExemptionDetails from '@salesforce/apex/PRSE_LAViewExemptionController.getExemptionDetails';
import updateExemptionStatus from '@salesforce/apex/PRSE_LAViewExemptionController.updateExemptionStatus';
import getExemptionStatusOptions from '@salesforce/apex/PRSE_LAViewExemptionController.getExemptionStatusOptions';
import getExemptionEpcOrFile from '@salesforce/apex/PRSE_LAViewExemptionController.getExemptionEpcOrFile';
import systemLog from '@salesforce/apex/digitalmodus.SystemLogLwcWrapper.systemLog';
import basePath from '@salesforce/community/basePath';
import { refreshApex } from '@salesforce/apex';
export default class PrseLAExemptionExemptionDetails extends LightningElement {
    @api exemptionId;
    @track details;
    @track parentExemption;
    @track childExemptions = [];
    formattedRegisterredDate;
    @track statusOptions = [];
    @track selectOptions = [];
    @track statusValue;
    @track originalStatusValue;
    @track epcLink = { url: null, sourceType: 'none', fileName: null };
    @track statusDescription = '';
    @track statusSavedMessage = '';
    
    get isCertificateFromAPI() {
        return this.epcLink?.sourceType === 'api';
    }

    get isCertificate() {
        return this.epcLink?.sourceType === 'certificate';
    }

    get isFile() {
        return this.epcLink?.sourceType === 'file';
    }

    get isNone() {
        return this.epcLink?.sourceType === 'none';
    }

    get isEndedExemption() {
        return this.originalStatusValue === 'Ended' || this.originalStatusValue === 'Expired';
    }

    get endedOrExpired() {
        if (this.originalStatusValue === 'Ended') {
            return 'ended';
        } else if (this.originalStatusValue === 'Expired') {
            return 'expired';
        }
        return '';
    }

    get statusReady() {
        return this.statusOptions.length > 0 && this.statusValue !== undefined;
    }

    get showStatusDescription() {
        return !!this.statusDescription;
    }

    statusInitialized = false;

    // Allowed statuses (excluding the current status, which we'll add dynamically)
    ALLOWED_STATUSES = ['Needs update', 'Penalty sent', 'Approved'];

    STATUS_LABELS = {
        'Needs update': 'Needs update: more information needed from landlord',
        'Approved': 'Approved',
        'Penalty sent': 'Penalty sent'
    };

    @wire(getExemptionStatusOptions)
    wiredStatusOptions({ data, error }) {
        if (data) {
            // Always include the current record status
            const currentStatus = this.parentExemption?.Status__c?.trim();
            const filteredStatuses = data.filter(
                status => this.ALLOWED_STATUSES.includes(status) || status === currentStatus
            ); 

            this.statusOptions = filteredStatuses.map(opt => ({
                label: this.STATUS_LABELS[opt] || opt,
                value: opt
            }));

            this.initializeStatusValue();
        } else if (error) {
            console.error('Error loading status options: ', error);
            this.handleError(error, 'getExemptionStatusOptions');
        }
    }

    wiredExemptionResult;

    @wire(getExemptionDetails, { exemptionId: '$exemptionId' })
    wiredExemptionDetails(result) {
        this.wiredExemptionResult = result;
        const { data, error } = result;

        if (data) {
            this.details = data;
            this.parentExemption = data.parentExemption;
            this.statusValue = this.parentExemption.Status__c;
            this.originalStatusValue = this.parentExemption.Status__c;

            this.formattedRegisterredDate =  this.formatDate(this.parentExemption.Registered_Date__c);
            this.childExemptions = data.childExemptions.map(c => {
                return {
                    ...c,
                    formattedEndDate: this.formatDate(c.EndDate),
                    statusClass: this.getTagClass(c.Status),
                    typeRowClass: c.EndDate ? 'govuk-summary-list__row no-border-bottom' : 'govuk-summary-list__row'
                };
            });
            this.initializeStatusValue();

            this.loadEpcOrFileUrl( this.parentExemption.PropertyUPRN__c, this.parentExemption.PropertyType__c);
        
        } else if (error) {
           console.error('Error loading exemption details: ', error);
           this.handleError(error, 'getExemptionDetails');
        }
    }

    loadEpcOrFileUrl(UPRN,propertyType) {
        if (!this.exemptionId) return;

        getExemptionEpcOrFile({ exemptionId: this.exemptionId, UPRN:UPRN, propertyType: propertyType })
        .then(wrapper => {
            this.epcLink = {
            ...wrapper,
            DocumentUrl:
                wrapper?.sourceType === 'file' &&
                wrapper?.contentDocumentId
                    ? `${basePath}/sfc/servlet.shepherd/document/download/${wrapper.contentDocumentId}?operationContext=S1`
                    : null
            }; 
        })
        .catch(error => {
            console.error('Error loading EPC or file URL', error);
            this.handleError(error, 'getExemptionEpcOrFile');
            this.epcLink = { url: null, sourceType: 'none' };
        });
    }

    // Initialize status value once both record and options exist
    initializeStatusValue() {
        if (!this.statusInitialized && this.parentExemption && this.statusOptions.length > 0) {
            const recordStatus = this.parentExemption.Status__c?.trim();

            // Ensure current status is in the selectOptions
            const exists = this.statusOptions.some(opt => opt.value === recordStatus);
            if (!exists) {
                this.statusOptions.unshift({
                    label: this.STATUS_LABELS[recordStatus] || recordStatus,
                    value: recordStatus
                });
            }           
            
            this.selectOptions = this.statusOptions.map(opt => ({
                ...opt,
                selected: opt.value === recordStatus
            }));

            // Keep these for save / disable logic
            this.statusValue = recordStatus;
            this.originalStatusValue = recordStatus;

            this.statusInitialized = true;
        }
    }

    renderedCallback() {
        if (this.statusInitialized) {
            const selectEl = this.template.querySelector('select[data-id="statusSelect"]');
            if (selectEl && selectEl.value !== this.statusValue) {
                selectEl.value = this.statusValue;
            }
        }
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        return `${day}/${month}/${year}`;
    }

    get hasDetails() {
        return !!this.details;
    }

    // --- New Methods for status editing ---
    handleStatusChange(event) {
        this.statusValue = event.target.value;
        // Update the selected flags dynamically if needed
        this.statusSavedMessage = '';

        this.selectOptions = this.selectOptions.map(opt => ({
            ...opt,
            selected: opt.value === this.statusValue
        }));

        const descriptions = {
            'Approved': 'You have checked the exemption, and it is valid.',
            'Needs update': 'You need further information from the landlord. The landlord will be able to edit their exemption. Contact the landlord separately to tell them what information you need.',
            'Penalty sent': 'You have issued a financial or publication penalty to the landlord.'
        };
        this.statusDescription = descriptions[this.statusValue] || '';
    }

    get isSaveDisabled() {
        return this.statusValue === this.originalStatusValue;
    }

    saveStatusChange() {
        updateExemptionStatus({ exemptionId: this.exemptionId, status: this.statusValue })
            .then(() => {
                this.originalStatusValue = this.statusValue;
                this.statusDescription = '';
                this.statusSavedMessage = 'Your changes have been saved';
                return refreshApex(this.wiredExemptionResult);
            })
            .catch(error => {
                console.error('Error updating exemption status: ', error);
                this.handleError(error, 'saveStatusChange-updateExemptionStatus');
            });
    }

    getTagClass(status) {
        switch (status) {
            case 'Active':
                return 'govuk-tag govuk-tag--green';
            case 'Ended':
                return 'govuk-tag govuk-tag--orange';
            case 'Expired':
                return 'govuk-tag govuk-tag--grey';
            default:
                return 'govuk-tag govuk-tag--grey';
        }
    }

    handleError(error, methodName){
        let log = {
            relatedService : 'prseLAExemptionExemptionDetails.js',
            logMessage : error.errorType || error.name,
            logFullMessage : error.body?.message || error.message,
            logType : 'Error',
            logCode : 'LWC-LA-Exemption-Details',
            relatedRecordId : '500A00000000123AAA',
            triggeringAutomationName : methodName
        }
        systemLog({log: log})
        .catch(methodError => {
            console.log('Failed to log error');
        });
    }

}