import { LightningElement, api, track, wire } from 'lwc';
import { MessageContext, publish, subscribe, unsubscribe, APPLICATION_SCOPE } from 'lightning/messageService'
import SET_FOCUS_MC from '@salesforce/messageChannel/uxgovuk__setFocusMessage__c';
import localAuthorityMessage from '@salesforce/messageChannel/localAuthorityDashboard__c';
import getAssociatedPenaltiesForLocalAuthorities from '@salesforce/apex/PRSE_LADashboardPenaltiesController.getAssociatedPenaltiesForLocalAuthorities';
import getPenaltyTypes from '@salesforce/apex/PRSE_LADashboardPenaltiesController.getPenaltyTypes';
import upsertPenaltyWithoutExemption from '@salesforce/apex/PRSE_LADashboardPenaltiesController.upsertPenaltyWithoutExemption';
import deletePenalty from '@salesforce/apex/PRSE_LADashboardPenaltiesController.deletePenalty';
import systemLog from '@salesforce/apex/digitalmodus.SystemLogLwcWrapper.systemLog';

export default class PrseLocalAuthorityDashboardPenaltiesTab extends LightningElement {

    @api panelHeading;
    @api localAuthorityCodes;
    @api noDataMessage;
    @track records = [];
    @track isLoading;
    @track showTable = false;
    @track totalDatabasePenalties = 0;
    @track pageNumber = 1;
    @track pageSize = 30;
    @track totalPages = 0;
    @track pageTitle = '';
    @track pageSubtitle = '';

    pageHistory = [];

    penaltyForExemptionLabel;
    penaltyForExemptionValue;
    penaltyForExemptionSummaryValue

    penaltyTypes = [];
    penaltyTypeLabels = '';
    penaltyTypeValues = '';

    currentPenalty = this.resetCurrentPenalty();

    @wire(MessageContext)
    messageContext;
    validateSubscription;
    setFocusSubscription;

    @track filters = {};
    components = [];
    @track hasErrors = false;

    @track page = 0;

    get isPage0() {
        return this.page === 0;
    }
    get isPage1() {
        return this.page === 1;
    }
    get isPage2() {
        return this.page === 2;
    }
    get isPage3() {
        return this.page === 3;
    }
    get isPage4() {
        return this.page === 4;
    }
    get isPage5() {
        return this.page === 5;
    }
    get isPage6() {
        return this.page === 6;
    }
    get isPage7() {
        return this.page === 7;
    }
    get isPage8() {
        return this.page === 8;
    }

    get tabType() {
        return this.panelHeading.split(' ')[0];
    }

    get hasNoResults() {
        return this.records.length === 0;
    }

    get getTotalPages() {
        return Math.ceil(this.totalDatabasePenalties / this.pageSize);
    }

    get hasPreviousPage() {
        return this.pageNumber > 1;
    }

    get hasNextPage() {
        return this.pageNumber < this.totalPages;
    }

    get hasMultiplePages(){
        return this.totalPages > 1;
    }

    get pageNumbers() {
        const pages = [];
        const delta = 1; 
        
        pages.push({
            key: '1',
            pageNum: 1,
            isActive: this.pageNumber === 1,
            isClickable: this.pageNumber !== 1,
            isEllipsis: false,
            ariaLabel: 'Page 1',
            liClass: this.pageNumber === 1 ? 'govuk-pagination__item govuk-pagination__item--current' : 'govuk-pagination__item'
        });
        
        const rangeStart = Math.max(2, this.pageNumber - delta);
        const rangeEnd = Math.min(this.totalPages - 1, this.pageNumber + delta);
        
        if (rangeStart > 2) {
            pages.push({
                key: 'ellipsis-start',
                pageNum: null,
                isActive: false,
                isClickable: false,
                isEllipsis: true,
                ariaLabel: null,
                liClass: 'govuk-pagination__item govuk-pagination__item--ellipsis'
            });
        }
        
        for (let i = rangeStart; i <= rangeEnd; i++) {
            pages.push({
                key: String(i),
                pageNum: i,
                isActive: i === this.pageNumber,
                isClickable: i !== this.pageNumber,
                isEllipsis: false,
                ariaLabel: `Page ${i}`,
                liClass: i === this.pageNumber ? 'govuk-pagination__item govuk-pagination__item--current' : 'govuk-pagination__item'
            });
        }
        
        if (rangeEnd < this.totalPages - 1) {
            pages.push({
                key: 'ellipsis-end',
                pageNum: null,
                isActive: false,
                isClickable: false,
                isEllipsis: true,
                ariaLabel: null,
                liClass: 'govuk-pagination__item govuk-pagination__item--ellipsis'
            });
        }
        
        if (this.totalPages > 1) {
            pages.push({
                key: String(this.totalPages),
                pageNum: this.totalPages,
                isActive: this.pageNumber === this.totalPages,
                isClickable: this.pageNumber !== this.totalPages,
                isEllipsis: false,
                ariaLabel: `Page ${this.totalPages}`,
                liClass: this.pageNumber === this.totalPages ? 'govuk-pagination__item govuk-pagination__item--current' : 'govuk-pagination__item'
            });
        }
        
        return pages;
    }

    get startIndex() {
        return (this.pageNumber - 1) * this.pageSize + 1;
    }

    get endIndex() {
        return Math.min(this.pageNumber * this.pageSize, this.totalDatabasePenalties);
    }

    resetCurrentPenalty() {
        return {
            addressLine1: '',
            addressLine2: '',
            propertyCity: '',
            propertyCounty: '',
            propertyPostcode: '',
            propertyType: '',
            landlordType: '',
            landlordFirstName: '',
            landlordLastName: '',
            landlordBusinessName: '',
            penaltyId: '',
            exemptionTypeId: '',
            exemptionType: '',
            reference: '',
            dateIssuedDayValue: '',
            dateIssuedMonthValue: '',
            dateIssuedYearValue: '',
            penaltyTypeId: '',
            penaltyType: '',
            penaltyAmount: '',
            published: false,
            previouslyPublished: false,
            unpublishDateDayValue: '',
            unpublishDateMonthValue:'',
            unpublishDateYearValue: ''
        };
    }

    getTagClass(status) {
        switch (status) {
            case 'Updated':
                return 'govuk-tag govuk-tag--orange';
            case 'Received':
                return 'govuk-tag govuk-tag--blue';
            case 'Approved':
                return 'govuk-tag govuk-tag--green';
            case 'Ended':
                return 'govuk-tag govuk-tag--grey';
            case 'Need Update':
                return 'govuk-tag govuk-tag--yellow';
            default:
                return 'govuk-tag govuk-tag--grey';
        }
    }

    handleMessage(message) {
        if(message.type === "filters" && this.tabType === message.activeTab) {
            this.filters = {
                propertyType: message.propertyType,
                penaltyTypeCodes: [...(message.penaltyTypeCodes ?? [])],
                localAuthorityCodes: [...(message.localAuthorityCodes ?? [])],
                searchTerm: message.searchTerm,
            };
            this.pageNumber = message.pageNumber || 1;
            this.getAssociatedPenaltiesForLocalAuthorities();
        } else if (message.type === 'tabType' && this.tabType !== message.activeTab) {
            this.page = 0;
            this.hasErrors = false;
            this.components = [];
            this.pageHistory = [];
            this.penaltyForExemptionValue = undefined;
            this.penaltyForExemptionLabel = undefined;
            this.currentPenalty = this.resetCurrentPenalty();
        }
    }

    initializePageNumber() {
        const urlParams = new URLSearchParams(window.location.search);
        const pageParam = urlParams.get('page');
        if (pageParam && !isNaN(pageParam) && parseInt(pageParam, 10) > 0) {
            this.pageNumber = parseInt(pageParam, 10);
        }
    }

    updateUrlPageNumber() {
        const url = new URL(window.location);
        url.searchParams.set('page', this.pageNumber);
        window.history.replaceState({}, '', url);
    }

    connectedCallback() {
        this.isLoading = true;
        this.showTable = true;
        this.subscribeToMessageChannel();
        this.initializePageNumber();
        this.loadData();
    }

    async loadData() {
        try {
            this.getAssociatedPenaltiesForLocalAuthorities();
            this.getPenaltyTypes();
        } catch (error) {
            this.handleError(error, 'loadData');
        } finally {
            this.isLoading = false;
        }
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    getAssociatedPenaltiesForLocalAuthorities() {
        this.isLoading = true;
        this.filters.localAuthorityCodes = this.localAuthorityCodes;
        publish(this.messageContext, localAuthorityMessage, { type: "loading", isLoading: true, activeTab: this.tabType });
        getAssociatedPenaltiesForLocalAuthorities({
            filters: JSON.stringify(this.filters),
            pageSize: this.pageSize,
            pageNumber: this.pageNumber
        })
            .then(result => {
                try {
                    this.totalDatabasePenalties = result.totalRecords;
                    this.totalPages = Math.ceil(this.totalDatabasePenalties / this.pageSize);
                    
                    if (this.pageNumber > this.totalPages && this.totalPages > 0) {
                        this.pageNumber = this.totalPages;
                        this.getAssociatedPenaltiesForLocalAuthorities();
                        return;
                    }
                    this.records = result.records.map(record => ({
                        ...record,
                        landlord: this.getLandlordName(record),
                        unpublishDate: record.unpublishDate ? record.unpublishDate : 'Not published'
                    }));
                    this.updateUrlPageNumber();
                } catch (error) {
                    this.handleError(error, 'getAssociatedPenaltiesForLocalAuthorities');
                }
            })
            .catch(error => {
                this.handleError(error, 'getAssociatedPenaltiesForLocalAuthorities');
            })
            .finally(() => {
                this.isLoading = false;
                publish(this.messageContext, localAuthorityMessage, { type: "loading", isLoading: false, activeTab: this.tabType });
            });
    }

    getLandlordName(record) {
        const hasBusinessName = record.landlordBusinessName != null && record.landlordBusinessName !== '';
        const hasFirstName = record.landlordFirstName != null && record.landlordFirstName !== '';
        const hasLastName = record.landlordLastName != null && record.landlordLastName !== '';

        const firstName = hasFirstName ? record.landlordFirstName : '';
        const lastName = hasLastName ? record.landlordLastName : '';

        if (!hasBusinessName && !hasFirstName && !hasLastName) {
            return '';
        }

        let toReturn = hasBusinessName ? 
            record.landlordBusinessName : 
            firstName + ' ' + lastName;

        return toReturn.trim();
    }

    getPenaltyTypes() {
        getPenaltyTypes()
            .then(result => {
                this.penaltyTypes = [...result];
                let labels = '';
                let values = '';
                result.forEach((record, index) => {
                    labels += (index > 0 ? '|' : '') + record.Name;
                    values += (index > 0 ? '|' : '') + record.Id;
                });
                this.penaltyTypeLabels = labels;
                this.penaltyTypeValues = values;
            })
            .catch(error => {
                this.handleError(error, 'getPenaltyTypes');
            });
    }

    upsertPenaltyWithoutExemption() {
        this.currentPenalty.propertyAddress = 
        this.currentPenalty.addressLine2 == null || this.currentPenalty.addressLine2 === '' ? this.currentPenalty.addressLine1 : 
            this.currentPenalty.addressLine1 + ', ' + this.currentPenalty.addressLine2;
        upsertPenaltyWithoutExemption({ 
            penaltyAsJSON: JSON.stringify(this.currentPenalty)
        })
        .then(result => {
            this.currentPenalty.penaltyId = result;
            this.getAssociatedPenaltiesForLocalAuthorities();
        })
        .catch(error => {
            this.handleError(error, 'upsertPenaltyWithoutExemption');
        });
    }

    deletePenalty(penaltyId) {
        deletePenalty({ 
            penaltyId: penaltyId
        })
        .then(() => {
                this.records = this.records.filter(record => record.penaltyId !== penaltyId);
                this.records = [...this.records];
            })
        .catch(error => {
            this.handleError(error, 'deletePenalty');
        });
    }

    subscribeToMessageChannel() {
        this.validateSubscription = subscribe (
            this.messageContext,
            localAuthorityMessage, (message) => {
                this.handleMessage(message);
        });

        this.setFocusSubscription = subscribe (
            this.messageContext,
            SET_FOCUS_MC, (message) => {
                this.handleFocusMessage(message);
            }
        )
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.validateSubscription);
        this.validateSubscription = null;
        unsubscribe(this.setFocusSubscription);
        this.setFocusSubscription = null;
    }

    validateAll() {
        this.hasErrors = false;
        this.components = [];
        // Validate all gds-selects
        this.template.querySelectorAll('c-gds-select').forEach((cmp) => {
            if (cmp.handleValidate && !cmp.handleValidate()) {
                this.hasErrors = true;
                this.components = [
                    ...this.components,
                    {
                        error: cmp.errorMessage,
                        fieldId: cmp.fieldId
                    }
                ];
            }
        });

        // Validate all gds-text-inputs
        this.template.querySelectorAll('c-gds-text-input').forEach((cmp) => {
            if (cmp.handleValidate && !cmp.handleValidate()) {
                this.hasErrors = true;
                this.components = [
                    ...this.components,
                    { 
                        error: cmp.errorMessage,
                        fieldId: cmp.fieldId
                    }
                ];
            }
        });

        // Validate all gds-date-inputs
        this.template.querySelectorAll('c-gds-date-input').forEach((cmp) => {
            if (cmp.handleValidate && !cmp.handleValidate()) {
                this.hasErrors = true;
                this.components = [
                    ...this.components,
                    { 
                        error: cmp.errorMessage,
                        fieldId: cmp.fieldId
                    }
                ];
            }
        });

        // Validate all radios
        this.template.querySelectorAll('c-gds-radios-white').forEach((cmp) => {
            if (cmp.handleValidate && !cmp.handleValidate()) {
                this.hasErrors = true;
                this.components = [
                    ...this.components,
                    { 
                        error: cmp.errorMessage,
                        fieldId: cmp.name
                    }
                ];
            }
        });
    }

    handleError(error, methodName) {
        let log = {
            relatedService : 'prseLocalAuthorityDashboardPenaltiesTable.js',
            logMessage : error.errorType || error.name,
            logFullMessage : error.body?.message || error.message,
            logType : 'Error',
            logCode : 'LWC-LA-Dashboard',
            relatedRecordId : '500A00000000123AAA',
            triggeringAutomationName : methodName
        }
        systemLog({log: log})
        .catch(methodError => {
            console.log('Failed to log error');
        });
    }

    handleChildValueChange(event) {
        const { id, value } = event.detail || {};

        if (id === 'penaltyWithExemption') {
            let valueAsString = String(value);
            this.penaltyForExemptionValue = valueAsString;
            this.penaltyForExemptionLabel = valueAsString === 'Yes' ? 'Yes' : 'No, the property does not have an exemption';
            this.penaltyForExemptionSummaryValue = 'This property does not have an exemption';
        }

        if (id === 'addressLine1') {
            let valueAsString = String(value);
            this.currentPenalty.addressLine1 = valueAsString;
        }

        if (id === 'addressLine2') {
            let valueAsString = String(value);
            this.currentPenalty.addressLine2 = valueAsString;
        }

        if (id === 'addressCity') {
            let valueAsString = String(value);
            this.currentPenalty.propertyCity = valueAsString;
        }

        if (id === 'addressCounty') {
            let valueAsString = String(value);
            this.currentPenalty.propertyCounty = valueAsString;
        }

        if (id === 'addressPostcode') {
            let valueAsString = String(value);
            this.currentPenalty.propertyPostcode = valueAsString;
        }

        if (id === 'propertyType') {
            let valueAsString = String(value);
            this.currentPenalty.propertyType = valueAsString;
            this.currentPenalty.frontEndPropertyType = valueAsString === 'Residential' ? 'Residential (domestic)' : 'Commercial (non-domestic)';
        }

        if (id === 'landlordType') {
            let valueAsString = String(value);
            this.currentPenalty.landlordType = valueAsString;
        }

        if (id === 'landlordFirstName') {
            let valueAsString = String(value);
            this.currentPenalty.landlordFirstName = valueAsString;
        }

        if (id === 'landlordLastName') {
            let valueAsString = String(value);
            this.currentPenalty.landlordLastName = valueAsString;
        }

        if (id === 'landlordBusinessName') {
            let valueAsString = String(value);
            this.currentPenalty.landlordBusinessName = valueAsString;
        }

        if (id === 'penaltyReference') {
            let valueAsString = String(value);
            this.currentPenalty.reference = valueAsString;
        }

        if(id === 'issueDate') {
            //Format is dd-mm-yyyy
            let valueAsString = String(value);
            this.currentPenalty.dateIssued = valueAsString.replaceAll("-", "/");

            const [dayValue, monthValue, yearValue] = valueAsString.split('-');
            this.currentPenalty.dateIssuedDayValue = dayValue || '';
            this.currentPenalty.dateIssuedMonthValue = monthValue || '';
            this.currentPenalty.dateIssuedYearValue = yearValue || '';
        }

        if(id === 'penaltyType') {
            let valueAsString = String(value);
            let penaltyTypeObject = this.penaltyTypes.find(record => record.Id === valueAsString);
            this.currentPenalty.penaltyTypeId = penaltyTypeObject !== undefined ? penaltyTypeObject.Id : '';
            this.currentPenalty.penaltyType = penaltyTypeObject !== undefined ? penaltyTypeObject.Name : '';
        }

        if(id === 'penaltyAmount') {
            let valueAsString = String(value);
            this.currentPenalty.penaltyAmount = valueAsString;
        }

        if(id === 'shouldPublish') {
            let valueAsString = String(value);
            this.currentPenalty.published = valueAsString === 'Yes' ? true : false;
            this.currentPenalty.publishedRadioValue = valueAsString === 'Yes' ? 'Yes' : 'No';
            this.currentPenalty.publishedRadioLabel = valueAsString === 'Yes' ? 'Yes, publish the penalty' : 'No, do not publish the penalty';
            this.currentPenalty = {... this.currentPenalty};
        }

        if(id === 'unpublishedDate') {
            //Format is dd-mm-yyyy
            let valueAsString = String(value);
            this.currentPenalty.unpublishDate = valueAsString.replaceAll("-", "/");
            this.currentPenalty.formattedUnpublishDate = valueAsString;

            const [dayValue, monthValue, yearValue] = valueAsString.split('-');
            this.currentPenalty.unpublishDateDayValue = dayValue || '';
            this.currentPenalty.unpublishDateMonthValue = monthValue || '';
            this.currentPenalty.unpublishDateYearValue = yearValue || '';
        }
    }

    // Navigation handlers
    handleView(event) {
        this.pageHistory.push(0);
        event.preventDefault();
        const recordId = event.target.dataset.recordId;
        this.currentPenalty = this.resetCurrentPenalty();
        this.currentPenalty = this.records.find(record => {
            if(record.penaltyId === recordId) {
                const [dateIssuedDayValue, dateIssuedMonthValue, dateIssuedYearValue] = record.dateIssued.split('/');
                record.dateIssuedDayValue = dateIssuedDayValue || '';
                record.dateIssuedMonthValue = dateIssuedMonthValue || '';
                record.dateIssuedYearValue = dateIssuedYearValue || '';

                record.unpublishDateDayValue = '';
                record.unpublishDateMonthValue = '';
                record.unpublishDateYearValue = '';
                if(record.unpublishDate !== 'Not published') {
                    const [unpublishDateDayValue, unpublishDateMonthValue, unpublishDateYearValue] = record.unpublishDate.split('/');
                    record.unpublishDateDayValue = unpublishDateDayValue || '';
                    record.unpublishDateMonthValue = unpublishDateMonthValue || '';
                    record.unpublishDateYearValue = unpublishDateYearValue || '';
                }

                record.previouslyPublished = record.published;
                record.publishedRadioValue = record.published === true ? 'Yes' : 'No';
                record.publishedRadioLabel = record.published === true ? 'Yes, publish the penalty' : 'No, do not publish the penalty';

                record.addressLine1 = record.propertyAddress;
                record.frontEndPropertyType = record.propertyType === 'Residential' ? 'Residential (domestic)' : 'Commercial (non-domestic)';
                record.landlordType = record.landlordBusinessName === null || record.landlordBusinessName === '' ? 'Individual' : 'Business';

                //Handle optional fields
                record.addressLine2 = this.handleOptionalField(record.addressLine2);
                record.propertyCounty = this.handleOptionalField(record.propertyCounty);
                record.landlordFirstName = this.handleOptionalField(record.landlordFirstName);
                record.landlordLastName = this.handleOptionalField(record.landlordLastName);
                record.landlordBusinessName = this.handleOptionalField(record.landlordBusinessName);
                return record;
            }
            return null;
        });
        if(this.currentPenalty) {
            this.page = 5;
        } else {
            this.page = 0;
        }
    }

    handleOptionalField(field) {
        return field == null || field === '' ? '' : field;
    }

    handleDelete(event) {
        this.pageHistory.push(0);
        event.preventDefault();
        const recordId = event.target.dataset.recordId;
        this.currentPenalty = this.records.find(record => record.penaltyId === recordId);
        if(this.currentPenalty) {
            this.page = 7;
        } else {
            this.page = 0;
        }
    }

    handleRecordNewPenalty() {
        this.pageHistory.push(0);
        this.page = 1;
    }

    handleSaveAndContinue(event) {
        this.validateAll();
        if(this.hasErrors === true) {
            event.target.blur();
            requestAnimationFrame(() => {
                const errorComponent = this.template.querySelector('c-gds-error-messages-imperative');
                errorComponent.scrollIntoView({ behavior: 'smooth', block: 'center' });
                errorComponent.focus();
            });
        } else if(this.hasErrors === false) {
            this.pageHistory.push(this.page);
            this.hasErrors = false;
            this.components = [];
            if(this.page === 1) {
                if(this.penaltyForExemptionValue === 'Yes') {
                    this.page = 6;
                } else if (this.penaltyForExemptionValue === 'No') {
                    this.page = 2;
                }
            } else if(this.page === 2) {
                this.page = 3;
            }
        }
    }

    handleViewDomesticExemptions() {
        this.page = 0;
        this.hasErrors = false;
        this.components = [];
        this.pageHistory = [];
        this.penaltyForExemptionValue = undefined;
        this.penaltyForExemptionLabel = undefined;
        this.currentPenalty = this.resetCurrentPenalty();
        publish(this.messageContext, localAuthorityMessage, { type: "tabChange", activeTab: 'Domestic' });
    }

    handleViewNonDomesticExemptions() {
        this.page = 0;
        this.hasErrors = false;
        this.components = [];
        this.pageHistory = [];
        this.penaltyForExemptionValue = undefined;
        this.penaltyForExemptionLabel = undefined;
        this.currentPenalty = this.resetCurrentPenalty();
        publish(this.messageContext, localAuthorityMessage, { type: "tabChange", activeTab: 'Non-domestic' });
    }

    handleRecordPenalty(event) {
        this.validateAll();
        if(this.hasErrors === true) {
            event.target.blur();
            requestAnimationFrame(() => {
                const errorComponent = this.template.querySelector('c-gds-error-messages-imperative');
                errorComponent.scrollIntoView({ behavior: 'smooth', block: 'center' });
                errorComponent.focus();
            });
        } else if(this.hasErrors === false) {
            this.pageHistory.push(this.page);

            const isNew = !this.currentPenalty.penaltyId;
            const published = this.currentPenalty.published;
            const previouslyPublished = this.currentPenalty.previouslyPublished;

            if (isNew) {
                if (published) {
                    this.page = 4;
                } else {
                    this.page = 5;
                    this.upsertPenaltyWithoutExemption();
                }
            } else {
                if (previouslyPublished && published) {
                    this.page = 5;
                    this.upsertPenaltyWithoutExemption();
                    this.currentPenalty.previouslyPublished = this.currentPenalty.published;
                } else if (previouslyPublished === true && published === false) {
                    this.page = 4;
                } else if (previouslyPublished === false && published === false) {
                    this.page = 5;
                    this.upsertPenaltyWithoutExemption();
                    this.currentPenalty.previouslyPublished = this.currentPenalty.published;
                } else if (previouslyPublished === false && published === true) {
                    this.page = 4;
                }
            }
        }
    }

    handleEditPenalty() {
        this.pageHistory.push(this.page);
        this.page = 2;
        this.currentPenalty = {
            ...this.currentPenalty
        };
    }

    handlePublishPenalty() {
        this.pageHistory.push(this.page);
        this.page = 5;

        if(this.currentPenalty.published === false) {
            this.currentPenalty.unpublishDate = null;
            this.currentPenalty.unpublishDateDayValue = '';
            this.currentPenalty.unpublishDateMonthValue = '';
            this.currentPenalty.unpublishDateYearValue = '';
        }
        this.upsertPenaltyWithoutExemption();
        this.currentPenalty.previouslyPublished = this.currentPenalty.published;
    }

    handleDeleteConfirm(event) {
        event.preventDefault();
        this.deletePenalty(this.currentPenalty.penaltyId);
        this.totalDatabasePenalties = this.totalDatabasePenalties - 1;
        this.page = 8;
    }

    handleViewAllPenalties() {
        this.page = 0;
        this.hasErrors = false;
        this.components = [];
        this.pageHistory = [];
        this.penaltyForExemptionValue = undefined;
        this.penaltyForExemptionLabel = undefined;
        this.currentPenalty = this.resetCurrentPenalty();
    }

    handleBackOrCancel() {
        this.hasErrors = false;
        this.components = [];
        this.page = this.pageHistory[this.pageHistory.length - 1];
        this.pageHistory.pop();
        if(this.isPage0) {
            this.penaltyForExemptionValue = undefined;
            this.penaltyForExemptionLabel = undefined;
            this.currentPenalty = this.resetCurrentPenalty();
        }
    }

    handleCancelAndGoBackToPenaltyDetails() {
        this.hasErrors = false;
        this.components = [];
        this.page = this.pageHistory[this.pageHistory.length - 1];
        this.pageHistory.pop();
    }

    // Pagination methods
    handlePrevious() {
        if (this.hasPreviousPage) {
            this.pageNumber -= 1;
            this.getAssociatedPenaltiesForLocalAuthorities();
            window.scrollTo(0, 0);
        }
    }

    handleNext() {
        if (this.hasNextPage) {
            this.pageNumber += 1;
            this.getAssociatedPenaltiesForLocalAuthorities();
            window.scrollTo(0, 0);
        }
    }

    handlePageClick(event) {
        const selectedPage = parseInt(event.target.dataset.page, 10);
        if (selectedPage !== this.pageNumber) {
            this.pageNumber = selectedPage;
            this.getAssociatedPenaltiesForLocalAuthorities();
            window.scrollTo(0, 0);
        }
    }

    handleFocusMessage(message) {
        const allDivs = this.template.querySelectorAll('[data-field-id]');
        const targetDiv = Array.from(allDivs).find(div => {
            const divFieldId = div.getAttribute('data-field-id');
            return divFieldId && divFieldId.startsWith(message.focusId);
        });
        
        if (targetDiv) {
            targetDiv.scrollIntoView({ behavior: 'smooth', block: 'center' });
            setTimeout(() => {
                const childComponent = targetDiv.querySelector(
                    'c-gds-select, c-gds-text-input, c-gds-date-input, c-gds-radios-white'
                );
                
                if (childComponent && typeof childComponent.focus === 'function') {
                    childComponent.focus();
                }
            }, 300);
        }
    }
}