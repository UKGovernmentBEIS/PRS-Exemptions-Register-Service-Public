/**
 * Derived from GOV.UK Frontend v3.13.1
 * Source: https://github.com/alphagov/govuk-frontend
 **/
import { LightningElement, track, api, wire} from 'lwc';
import uploadUiOverride from '@salesforce/resourceUrl/uploadUiOverride';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { MessageContext, publish, subscribe, unsubscribe } from 'lightning/messageService';
import getKey from '@salesforce/apex/FileUploadAdvancedHelper.getKey';
import encrypt from '@salesforce/apex/FileUploadAdvancedHelper.encrypt';
import createContentDocLink from '@salesforce/apex/FileUploadAdvancedHelper.createContentDocLink';
import deleteContentDoc from '@salesforce/apex/FileUploadAdvancedHelper.deleteContentDoc';
import getExistingFiles from '@salesforce/apex/FileUploadAdvancedHelper.getExistingFiles';
import updateFileName from '@salesforce/apex/FileUploadAdvancedHelper.updateFileName';

//message channels
import REGISTER_MC from '@salesforce/messageChannel/uxgovuk__registrationMessage__c';
import VALIDATION_MC from '@salesforce/messageChannel/uxgovuk__validateMessage__c';
import VALIDATION_STATE_MC from '@salesforce/messageChannel/uxgovuk__validationStateMessage__c';
import SET_FOCUS_MC from '@salesforce/messageChannel/uxgovuk__setFocusMessage__c';

export default class GovFileUploadEnhanced extends LightningElement {

    @api inputFieldId = "input-file"
    @track hasErrors        = false;
    @track displayFileList  = false; 
    @track docIds           = [];
    @track fileNames        = [];
    @track objFiles         = [];
    @track versIds          = [];
    @api errorMessage       = '';
    @api label;
    @api acceptedFormats;
    @api allowMultiple;
    @api overriddenFileName;    
    @api uploadedlabel;
    @api required;
    @api requiredMessage;
    @api sessionKey;
    @api uniqueFieldId = 'fileUploadEnhancedField';
    @api uploadedFileNames;
    @api contentDocumentIds;
    @api contentVersionIds;
    @api recordId;
    numberOfFilesToUpload = 0;
    loading = false;
    disabled = false;
    removeFileConfirmation = 'File {0} removed';

    //accessibility text
    message = '';

    @api filesUploadedCollection = []; 
    @api filesUploaded; 

    // messaging attributes
    @wire(MessageContext) messageContext;
    validateSubscription;
    setFocusSubscription;


    key;
    @wire(getKey)
    wiredKey({error,data}) {
        if(data){
            this.key = data;
        }
        else if (error){
            this.showErrors(this.reduceErrors(error).toString());
        }
    }

    value;
    @wire(encrypt,{recordId: '$recordId', encodedKey: '$key'})
    wiredValue({error,data}) {
        if(data){
            this.value = data;
        }
        else if (error){
            this.showErrors(this.reduceErrors(error).toString());
        }
    }

    get formGroupClass() {
        return this.hasErrors ? 'govuk-form-group govuk-form-group--error' : 'govuk-form-group';
    }

    renderedCallback() {
        this.displayExistingFiles();
       
        if(this.isCssLoaded) {
            return;
        }
        this.isCssLoaded = true;
        
        loadStyle(this,uploadUiOverride).then(()=>{
            
        })
        .catch(error=>{
            this.showErrors(this.reduceErrors(error).toString());
        });
    }

    handleSetFocusMessage(message){
        let myComponentId = message.componentId;
        if(myComponentId === this.inputFieldId) {
            let myComponent = this.template.querySelector('lightning-file-upload');
            requestAnimationFrame(() => myComponent.focus());
        }
    }

    connectedCallback() {
        if(this.recordId) {
            this.disabled = true;
            getExistingFiles({recordId: this.recordId})
                .then((files) => {
                    if(files !== undefined && files.length > 0) {
                        this.processFiles(files);
                        this.displayExistingFiles();
                    } else {
                        this.communicateEvent(this.docIds,this.versIds,this.fileNames);
                    }
                })
                .catch((error) => {
                    this.hasErrors = true;
                    this.errorMessage = 'There has been a problem loading your files. Please refresh the page. \n If the files do not load, contact support: [email address]';
                    this.disabled = false;
                })
        } else {
            this.communicateEvent(this.docIds,this.versIds,this.fileNames);        
        }
        this.disabled = false;
        this.displayExistingFiles();
        this.subscribeMCs();
        setTimeout(() => {
            publish(this.messageContext, REGISTER_MC, {componentId:this.inputFieldId});
        }, 100);
    }

    disconnectedCallback() {
        this.unsubscribeMCs();
    }

    displayExistingFiles() {
        if(this.objFiles.length > 0) {
            this.displayFileList = true;
        } else {
            this.displayFileList = false;
        }
    }

    handleUpload_lightningFile(event) {
        let files = event.detail.files;
        this.handleUploadFinished(files);
    }

    handleUploadFinished(files) {
        let objFiles = [];
        let versIds = [];

        files.forEach(file => {
            let name;
            if(this.overriddenFileName){
                name = this.overriddenFileName.substring(0,255) +'.'+ file.name.split('.').pop();
            } else {
                name = file.name;
            }
            
            let objFile = {
                name: name,
                documentId: file.documentId,
                contentVersionId: file.contentVersionId,
                removeFileAriaLabel: ' file ' + name
            }

            objFiles.push(objFile);
            versIds.push(file.contentVersionId);
        })

        if(this.overriddenFileName){
            updateFileName({versIds: versIds, fileName: this.overriddenFileName.substring(0,255)})
                .catch(error => {
                    this.showErrors(this.reduceErrors(error).toString());
                });
        }
        if(this.recordId) {
            createContentDocLink({versIds: versIds, encodedKey: this.key})
            .then(result => {})
            .catch(error => {
                    this.showErrors(this.reduceErrors(error).toString());
            });
        }
        this.processFiles(objFiles);
        this.displayExistingFiles();
    }

    processFiles(files) {
        files.forEach(file => {
            let objFile = {
                name: file.name,
                filetype: file.fileExtension,
                documentId: file.documentId,
                contentVersionId: file.contentVersionId,
                removeFileAriaLabel: ' file ' + file.name
            };
            
            this.objFiles = [...this.objFiles, objFile];
            this.docIds = [...this.docIds, file.documentId];
            this.versIds = [...this.versIds, file.contentVersionId];
            this.fileNames = [...this.fileNames, file.name];
        });
        this.checkDisabled();
        this.communicateEvent(this.docIds,this.versIds,this.fileNames);
    }

    deleteDocument(event) {
        this.loading = true;
        event.target.blur();

        let contentVersionId = event.target.dataset.contentversionid;    

        if(this.disableDelete) {
            this.removeFileFromUi(contentVersionId);
        } else {
            deleteContentDoc({versId: contentVersionId})
            .then(() => {
                this.removeFileFromUi(contentVersionId);
            })
            .catch((error) => {
                this.showErrors(this.reduceErrors(error).toString());
                this.loading = false;
            })
        }
        
    }

    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }
        return (
            errors
                // Remove null/undefined items
                .filter((error) => !!error)
                // Extract an error message
                .map((error) => {
                    // UI API read errors
                    if (Array.isArray(error.body)) {
                        return error.body.map((e) => e.message);
                    }
                    // Page level errors
                    else if (
                        error?.body?.pageErrors &&
                        error.body.pageErrors.length > 0
                    ) {
                        return error.body.pageErrors.map((e) => e.message);
                    }
                    // Field level errors
                    else if (
                        error?.body?.fieldErrors &&
                        Object.keys(error.body.fieldErrors).length > 0
                    ) {
                        const fieldErrors = [];
                        Object.values(error.body.fieldErrors).forEach(
                            (errorArray) => {
                                fieldErrors.push(
                                    ...errorArray.map((e) => e.message)
                                );
                            }
                        );
                        return fieldErrors;
                    }
                    // UI API DML page level errors
                    else if (
                        error?.body?.output?.errors &&
                        error.body.output.errors.length > 0
                    ) {
                        return error.body.output.errors.map((e) => e.message);
                    }
                    // UI API DML field level errors
                    else if (
                        error?.body?.output?.fieldErrors &&
                        Object.keys(error.body.output.fieldErrors).length > 0
                    ) {
                        const fieldErrors = [];
                        Object.values(error.body.output.fieldErrors).forEach(
                            (errorArray) => {
                                fieldErrors.push(
                                    ...errorArray.map((e) => e.message)
                                );
                            }
                        );
                        return fieldErrors;
                    }
                    // UI API DML, Apex and network errors
                    else if (error.body && typeof error.body.message === 'string') {
                        return error.body.message;
                    }
                    // JS errors
                    else if (typeof error.message === 'string') {
                        return error.message;
                    }
                    // Unknown error shape so try HTTP status text
                    return error.statusText;
                })
                // Flatten
                .reduce((prev, curr) => prev.concat(curr), [])
                // Remove empty strings
                .filter((message) => !!message)
        );
    }

    removeFileFromUi(contentVersionId) {
        const removeIndex = this.objFiles.findIndex(f => f.contentVersionId === contentVersionId);
        if (removeIndex === -1) {
            this.loading = false;
            return;
        }

        this.objFiles = this.objFiles.filter(f => f.contentVersionId !== contentVersionId);
        this.docIds = this.docIds.filter((_, i) => i !== removeIndex);
        this.versIds = this.versIds.filter((_, i) => i !== removeIndex);
        this.fileNames = this.fileNames.filter((_, i) => i !== removeIndex);

        this.displayExistingFiles();

        this.checkDisabled();
        this.communicateEvent(this.docIds, this.versIds, this.fileNames);
        this.loading = false;
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

    handleValidateMessage(message) {
        this.handleValidate();
    }

    @api handleValidate() {
        this.hasErrors = false;

        if(this.docIds.length === 0 && this.required === true){ 
            this.hasErrors = true;
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

    @api clearError() {
        this.hasErrors = false;
    }

    checkDisabled() {
        if(!this.allowMultiple && this.objFiles.length >= 1){
            this.disabled = true;
        } else {
            this.disabled = false;
        }
    }

    showErrors(errors) {
        if(this.embedExternally){
            this.showAlert(errors);
        } else {
            this.showToast(errors);
        }
    }

    showAlert(errors) {
        window.alert(errors);
    }

    showToast(errors) {
        let message = new ShowToastEvent({
            title: 'We hit a snag.',
            message: errors,
            variant: 'error',
        });
        this.dispatchEvent(message);
    }

    communicateEvent(docIds, versIds, fileNames) {
        this.dispatchEvent(new FlowAttributeChangeEvent('contentDocumentIds', [...docIds]));
        this.dispatchEvent(new FlowAttributeChangeEvent('contentVersionIds', [...versIds]));
        this.dispatchEvent(new FlowAttributeChangeEvent('uploadedFileNames', [...fileNames]));

        //update file names output variables
        this.filesUploadedCollection = fileNames;
        this.filesUploaded = fileNames.join(';');
    }
}