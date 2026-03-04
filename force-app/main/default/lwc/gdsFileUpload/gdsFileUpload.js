/**
 * Derived from GOV.UK Frontend v3.13.1
 * Source: https://github.com/alphagov/govuk-frontend
 **/
import { LightningElement, wire, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveFiles from '@salesforce/apex/FileUploadHelper.saveFiles';
import getExistingFiles from '@salesforce/apex/FileUploadHelper.getExistingFiles';
import deleteContentDoc from '@salesforce/apex/FileUploadHelper.deleteContentDoc';
import { MessageContext, publish, subscribe, unsubscribe } from 'lightning/messageService';
import REGISTER_MC from '@salesforce/messageChannel/uxgovuk__registrationMessage__c';
import VALIDATION_MC from '@salesforce/messageChannel/uxgovuk__validateMessage__c';
import VALIDATION_STATE_MC from '@salesforce/messageChannel/uxgovuk__validationStateMessage__c';
import SET_FOCUS_MC from '@salesforce/messageChannel/uxgovuk__setFocusMessage__c';

const BYTES_PER_MB = 1000000;

export default class GdsFileUpload extends LightningElement {
    // Public API
    @api inputFieldId = 'uploadField';
    @api fileUploadLabel = 'Upload a file';
    @api uploadedlabel = 'Uploaded files';
    @api acceptedFormats = '.png,.pdf,.jpg,.jpeg,.doc,.docx';
    @api maxFileSizeInMB = 10;
    @api required = false;
    @api errorMessage = 'Select a file';
    @api useApexToSaveFile;
    @api recordId = '';
    @api sessionKey = 'GdsFileUpload';
    @api renderExistingFiles;

    @api filesUploaded;
    @api uploadedFileNames;
    @api contentDocumentIds;
    @api contentVersionIds;

    @api allowMultipleFiles;
    @api maxFilesAllowed;

    @track objFiles = []; // [{ name, documentId, contentVersionId, base64? }]
    @track uploadedObjFiles = [];

    @track uploadDisabled = false;

    // UI state
    @track hasErrors = false;

    // LMS
    @wire(MessageContext) messageContext;
    validateSubscription;
    setFocusSubscription;

    get docIds() {
        const ids = this.uploadedObjFiles.map(f => {
            return f.documentId;
        }).filter(Boolean);
        return ids;
    }
    get versIds() {
        return this.uploadedObjFiles.map(f => f.contentVersionId).filter(Boolean);
    }
    get fileNamesArray() {
        return this.uploadedObjFiles.map(f => f.name);
    }
    get fileNames() {
        return this.fileNamesArray.join(', ');
    }
    get filesUploadedString() {
        return this.fileNamesArray.join(';');
    }
    get displayFileList() {
        return this.uploadedObjFiles.length > 0;
    }

    get formGroupClass() {
        return this.hasErrors ? 'govuk-form-group govuk-form-group--error' : 'govuk-form-group';
    }
    get inputClass() {
        return this.hasErrors ? 'govuk-file-upload govuk-file-upload--error' : 'govuk-file-upload';
    }

    /* ===== Lifecycle ===== */
    connectedCallback() {
        this.renderExistingFiles = true;
        
        if (this.recordId && this.renderExistingFiles) {
            this.toggleButtonDisabledStatus(true);
            getExistingFiles({ recordId: this.recordId })
                .then(files => {
                    
                    if (files && files.length > 0) {
                        // Process existing files - ensure we map all necessary properties
                        const processedFiles = files.map(f => {
                            return {
                                name: f.Title || f.name || 'Unknown File',
                                documentId: f.ContentDocumentId || f.documentId,
                                contentVersionId: f.Id || f.contentVersionId
                            };
                        });
                        
                        // Set both arrays - they should be the same for existing files
                        this.uploadedObjFiles = [...processedFiles];
                    }
                    this.notifyFlow();
                    this.toggleButtonDisabledStatus(false);
                })
                .catch(error => {
                    this.hasErrors = true;
                    this.errorMessage = 'There has been a problem loading your files. Please refresh the page. \n If the files do not load, contact support: [email address]';
                    this.notifyFlow();
                    this.toggleButtonDisabledStatus(false);
                });
        }

        this.subscribeMCs();

        setTimeout(() => {
            publish(this.messageContext, REGISTER_MC, { componentId: this.inputFieldId });
        }, 100);

        this.template.addEventListener('click', (event) => {
            if (event.target.type === 'file') {
                event.target.value = '';
            }
        });
    }

    renderedCallback() {
        // Track the actual input id for focus messages
        const input = this.template.querySelector('input');
        if (input) {
            this.inputFieldId = input.getAttribute('id') || this.inputFieldId;
        }
    }

    disconnectedCallback() {
        this.unsubscribeMCs();
    }

    /* ===== File handling ===== */
    async handleFilesChange(event) {
        this.toggleButtonDisabledStatus(true);
        this.clearError();
        const files = event?.target?.files || [];
        if (!files.length) {
            this.toggleButtonDisabledStatus(false);
            return;
        }
        let allowedExtensions = this.getAllowedExtensions();
        
        if (this.uploadedObjFiles.length + files.length > this.maxFilesAllowed) {
            this.hasErrors = true;
            this.errorMessage = `You can only upload ${this.maxFilesAllowed} file(s), please review what you would like to upload.`;
            this.toggleButtonDisabledStatus(false);
            return;
        }

        for (let i = 0; i < files.length; i++) {
            let filePath = files[i].name;
            if (!allowedExtensions.test(filePath)) { 
                this.hasErrors = true;
                this.errorMessage = 'The file is not in the right format.';
                this.toggleButtonDisabledStatus(false);
                return;
            } 
        }

        const existingNames = this.uploadedObjFiles.map(f => f.name.toLowerCase());
        for (let i = 0; i < files.length; i++) {
            if (existingNames.includes(files[i].name.toLowerCase())) {
                this.hasErrors = true;
                this.errorMessage = `File "${files[i].name}" has already been uploaded.`;
                this.toggleButtonDisabledStatus(false);
                return;
            }
        }

        for (let i = 0; i < files.length; i++) {
            if (files[i].size > this.maxFileSizeInMB * BYTES_PER_MB) {
                this.hasErrors = true;
                this.errorMessage = `The selected file(s) must be smaller than ${this.maxFileSizeInMB} MB`;
                this.toggleButtonDisabledStatus(false);
                return;
            }
        }

        // Read files sequentially to maintain order
        for (let i = 0; i < files.length; i++) {
            // eslint-disable-next-line no-await-in-loop
            const fileContents = await this.readFileAsBase64(files[i]);
            if (!fileContents) {
                this.hasErrors = true;
                this.errorMessage = 'The selected file is empty';
                this.toggleButtonDisabledStatus(false);
                return;
            }

            const name = files[i].name;

            // Temporary contentVersionId for UI tracking (unique enough)
            const tempContentVersionId = `${Date.now()}_${i}_${Math.random().toString(36).slice(2)}`;

            this.objFiles = [
                ...this.objFiles,
                {
                    name,
                    documentId: tempContentVersionId,
                    contentVersionId: tempContentVersionId,
                    fileContents // keep locally for Apex save if needed
                }
            ];
        }

        this.useApexToSaveFile = true;
        if (this.recordId && this.useApexToSaveFile) {
            this.toggleButtonDisabledStatus(true);
            saveFiles({ filesToInsert: this.objFiles, strRecId: this.recordId })
            .then(savedFiles => {
                this.uploadedObjFiles = [
                    ...this.uploadedObjFiles,
                    ...savedFiles.map(obj => {
                        return { ...obj };
                    })
                ];

            })
            .catch(error => {
                this.hasErrors = true;
                this.errorMessage = 'There has been a problem saving the files. Please try again. \n If you are unable to upload your files, contact support: [email address]';
                this.notifyFlow();
            })
            .finally(() => {
                this.objFiles = [];
                this.toggleButtonDisabledStatus(false);
            });
        }

        this.notifyFlow();
        this.dispatchUploadEvent();
    }

    async deleteDocument(event) {
        event.preventDefault();
        const contentVersionId = event.currentTarget?.dataset?.contentversionid;
        const documentId = event.currentTarget?.dataset?.documentid;
        if (!contentVersionId || !documentId) {
            return;
        }
        
        deleteContentDoc({versId: contentVersionId})
        .then(() => {
            this.removeFileByDocumentId(documentId);
            this.hasErrors = false;
            this.errorMessage = '';
        })
        .catch(error => {
            this.hasErrors = true;
            this.errorMessage = 'There has been a problem deleting the files. Please try again. \n If you are unable to delete your files, contact support: [email address]';
            this.notifyFlow();
        })
        .finally(() => {
            this.toggleButtonDisabledStatus(false);
        });
    }

    removeFileByDocumentId(documentId) {
        const beforeLen = this.uploadedObjFiles.length;
        
        // Remove from both arrays to keep them in sync
        //this.objFiles = this.objFiles.filter(f => f.documentId !== documentId);
        this.uploadedObjFiles = this.uploadedObjFiles.filter(f => f.documentId !== documentId);
        
        if (this.uploadedObjFiles.length !== beforeLen) {
            this.notifyFlow();
        }
    }

    /* ===== Validation ===== */
    handleValidateMessage() {
        this.handleValidate();
    }

    @api
    handleValidate() {
        this.hasErrors = false;
        if(this.docIds.length === 0 && this.required === true){ 
            this.hasErrors = true;
            this.errorMessage = 'Select a file';
        } else {
            this.hasErrors = false;
        }
        publish(this.messageContext, VALIDATION_STATE_MC, {
            componentId: this.inputFieldId,
            isValid: !this.hasErrors,
            error: this.errorMessage,
            focusId: this.inputFieldId
        });
    }

    showErrors(errors){
        if(this.embedExternally){
            this.showAlert(errors);
        } else {
            this.showToast(errors);
        }
    }

    showAlert(errors){
        window.alert(errors);
    }

    showToast(errors){
        let message = new ShowToastEvent({
            title: 'We hit a snag.',
            message: errors,
            variant: 'error',
        });
        this.dispatchEvent(message);
    }

    @api
    clearError() {
        this.hasErrors = false;
    }

    /* ===== Flow + Messaging ===== */
    notifyFlow() {
        // Keep Flow attributes in sync
        this.dispatchEvent(new FlowAttributeChangeEvent('contentDocumentIds', [...this.docIds]));
        this.dispatchEvent(new FlowAttributeChangeEvent('contentVersionIds', [...this.versIds]));
        this.dispatchEvent(new FlowAttributeChangeEvent('uploadedFileNames', [...this.fileNamesArray]));
    }

    dispatchUploadEvent() {
        // Legacy "value" propagation for Flows listening to a string
        const value = this.filesUploadedString;
        this.dispatchEvent(new FlowAttributeChangeEvent('value', JSON.stringify(value)));
        this.dispatchEvent(new CustomEvent('fileUpload', {
            detail: { id: this.inputFieldId, value: JSON.stringify(value) }
        }));
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
        let myComponentId = message.componentId;
        if(myComponentId == this.inputFieldId) {
            let myComponent = this.template.querySelector('input');
            myComponent.focus();
        }
    }

    /* ===== Utilities ===== */
    readFileAsBase64(file) {
        return new Promise(resolve => {
            const reader = new FileReader();
            reader.onload = () => {
                const base64Marker = 'base64,';
                const idx = reader.result.indexOf(base64Marker);
                if (idx === -1) return resolve('');
                resolve(reader.result.substring(idx + base64Marker.length));
            };
            reader.onerror = () => resolve('');
            reader.readAsDataURL(file);
        });
    }

    getAllowedExtensions() {
        const extensions = this.acceptedFormats.split(',').map(ext => ext.trim().replace('.', '\\.'));
        const pattern = `^.*(${extensions.join('|')})$`;
        return new RegExp(pattern, 'i');
    }

    toggleButtonDisabledStatus(uploadButtonDisabled) {
        this.uploadDisabled = uploadButtonDisabled;
        let defaultFileUploadLabel = 'Upload a file';
        let uploadingFilesLabel = 'Loading files...';
        if (this.uploadDisabled) {
            this.fileUploadLabel = uploadingFilesLabel;
        } else {
            this.fileUploadLabel = defaultFileUploadLabel;
        }
    }
}
