import { LightningElement, api, track } from 'lwc';
import getAssociatedPenalties from '@salesforce/apex/PRSE_LADashboardPenaltiesController.getAssociatedPenalties';
import getAssociatedChildExemptions from '@salesforce/apex/PRSE_LADashboardPenaltiesController.getAssociatedChildExemptions';
import getPenaltyTypes from '@salesforce/apex/PRSE_LADashboardPenaltiesController.getPenaltyTypes';
import upsertPenalty from '@salesforce/apex/PRSE_LADashboardPenaltiesController.upsertPenalty';
import deletePenalty from '@salesforce/apex/PRSE_LADashboardPenaltiesController.deletePenalty';
import hasAccessToParentExemption from '@salesforce/apex/PRSE_LADashboardPenaltiesController.hasAccessToParentExemption';
import systemLog from '@salesforce/apex/digitalmodus.SystemLogLwcWrapper.systemLog';

export default class PrseLocalAuthorityDashboardPenaltiesTable extends LightningElement {

    @api panelHeading;
    @api noDataMessage;
    @api parentExemptionId;
    @track records = [];
    @track isLoading;
    @track showTable = false;
    @track totalDatabasePenalties = 0;
    @track pageNumber = 1;
    @track pageSize = 30;
    @track totalPages = 0;
    @track pageTitle = '';
    @track pageSubtitle = '';

    @track shouldEnableRecordNewPenaltyButton = false;

    exemptionTypes = [];
    exemptionTypeLabels = '';
    exemptionTypeValues = '';

    penaltyTypes = [];
    penaltyTypeLabels = '';
    penaltyTypeValues = '';

    currentPenalty = this.resetCurrentPenalty();

    @track filters = {};
    components = [];
    @track hasErrors = false;

    @track page = 0;
    @track previousPage = 0;

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

    async connectedCallback() {
        this.isLoading = true;
        this.showTable = true;
        this.initializePageNumber();
        this.hasAccessToParentExemption();
        
        await Promise.all([
            this.getAssociatedChildExemptions(),
            this.getPenaltyTypes(),
            this.getAssociatedPenalties()
        ]);
        
        this.isLoading = false;
    }

    generateFilteredPenaltyUrl(recordId) {
        const base = '/PRSELocalAuthority/view-exemption/';
        
        const params = [];

        params.push(`exemptionId=${encodeURIComponent(recordId)}`);

        if (this.filters.statuses?.length) {
            params.push(`filterStatuses=${encodeURIComponent(this.filters.statuses.join(','))}`);
        }

        if (this.filters.exemptionTypeCodes?.length) {
            params.push(`filterExemptionTypes=${encodeURIComponent(this.filters.exemptionTypeCodes.join(','))}`);
        }

        if (this.filters.searchTerm) {
            params.push(`filterSearch=${encodeURIComponent(this.filters.searchTerm)}`);
        }

        if (this.tabType) {
            params.push(`filterTab=${encodeURIComponent(this.tabType)}`);
        }

        if (this.pageNumber) {
            params.push(`filterPage=${encodeURIComponent(this.pageNumber)}`);
        }

        return `${base}?${params.join('&')}`;
    }

    hasAccessToParentExemption() {
        hasAccessToParentExemption({
            parentExemptionId: this.parentExemptionId,
        })
            .then(result => {
                this.shouldEnableRecordNewPenaltyButton = result;
            })
            .catch(error => {
                this.handleError(error, 'hasAccessToParentExemption');
            });
    }

    getAssociatedPenalties() {
        this.isLoading = true;
        getAssociatedPenalties({ 
            parentExemptionId: this.parentExemptionId,
            pageSize: this.pageSize,
            pageNumber: this.pageNumber
        })
            .then(result => {
                try {
                    this.totalDatabasePenalties = result.totalRecords;
                    this.totalPages = Math.ceil(this.totalDatabasePenalties / this.pageSize);
                    
                    if (this.pageNumber > this.totalPages && this.totalPages > 0) {
                        this.pageNumber = this.totalPages;
                        this.getAssociatedPenalties();
                        return;
                    }
                    this.records = result.records.map(record => ({
                        ...record,
                        unpublishDate: record.unpublishDate ? record.unpublishDate : 'Not published',
                        previouslyPublished: record.published
                    }));
                    this.updateUrlPageNumber();
                } catch (error) {
                    this.handleError(error, 'getAssociatedPenalties');
                }
            })
            .catch(error => {
                this.handleError(error, 'getAssociatedPenalties');
            })
            .finally(() => {
                this.isLoading = false;
            });
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

    getAssociatedChildExemptions() {
        getAssociatedChildExemptions({ 
            parentExemptionId: this.parentExemptionId
        })
            .then(result => {
                this.exemptionTypes = result.map(record => ({
                    ...record,
                    combinedName: record.Name + ': ' + record.Child_Exemption_Ref__c
                }));
                let labels = '';
                let values = '';
                result.forEach((record, index) => {
                    const valueToAdd = record.Name + ': ' + record.Child_Exemption_Ref__c;
                    labels += (index > 0 ? '|' : '') + valueToAdd;
                    values += (index > 0 ? '|' : '') + record.Id;
                });
                this.exemptionTypeLabels = labels;
                this.exemptionTypeValues = values;
            })
            .catch(error => {
                this.handleError(error, 'getAssociatedChildExemptions');
            });
    }

    upsertPenalty() {
        this.currentPenalty.exemptionId = this.parentExemptionId;
        upsertPenalty({ 
            penaltyAsJSON: JSON.stringify(this.currentPenalty)
        })
        .then(result => {
            this.currentPenalty.penaltyId = result;
            this.getAssociatedPenalties();
        })
        .catch(error => {
            this.handleError(error, 'upsertPenalty');
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

        if (id === 'exemptionType') {
            let valueAsString = String(value);
            let exemptionTypeObject = this.exemptionTypes.find(record => record.Id === valueAsString);
            this.currentPenalty.exemptionTypeId = exemptionTypeObject !== undefined ? exemptionTypeObject.Id : '';
            this.currentPenalty.exemptionType = exemptionTypeObject !== undefined ? exemptionTypeObject.combinedName : '';
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
        event.preventDefault();
        const recordId = event.target.dataset.recordId;
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
                return record;
            }
            return null;
        });
        if(this.currentPenalty) {
            this.page = 3;
            this.previousPage = this.page;
        } else {
            this.page = 0;
        }
    }

    handleDelete(event) {
        event.preventDefault();
        const recordId = event.target.dataset.recordId;
        this.currentPenalty = this.records.find(record => record.penaltyId === recordId);
        this.page = 4;
        this.previousPage = this.page;
    }

    handleRecordNewPenalty() {
        this.page = 1;
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
            const isNew = !this.currentPenalty.penaltyId;
            const published = this.currentPenalty.published;
            const previouslyPublished = this.currentPenalty.previouslyPublished;

            if (isNew) {
                if (published) {
                    this.page = 2;
                } else {
                    this.page = 3;
                    this.upsertPenalty();
                }
            } else {
                if (previouslyPublished && published) {
                    this.page = 3;
                    this.upsertPenalty();
                    this.currentPenalty.previouslyPublished = this.currentPenalty.published;
                } else if (previouslyPublished === true && published === false) {
                    this.page = 2;
                } else if (previouslyPublished === false && published === false) {
                    this.page = 3;
                    this.upsertPenalty();
                    this.currentPenalty.previouslyPublished = this.currentPenalty.published;
                } else if (previouslyPublished === false && published === true) {
                    this.page = 2;
                }
            }
        }
    }

    handleEditPenalty() {
        this.previousPage = this.page;
        this.page = 1;
        this.currentPenalty = {
            ...this.currentPenalty
        };
    }

    handlePublishPenalty() {
        this.page = 3;
        this.previousPage = this.page;
        if(this.currentPenalty.published === false) {
            this.currentPenalty.unpublishDate = null;
            this.currentPenalty.unpublishDateDayValue = '';
            this.currentPenalty.unpublishDateMonthValue = '';
            this.currentPenalty.unpublishDateYearValue = '';
        }
        this.upsertPenalty();
        this.currentPenalty.previouslyPublished = this.currentPenalty.published;
    }

    handleDeleteConfirm(event) {
        event.preventDefault();
        this.deletePenalty(this.currentPenalty.penaltyId);
        this.page = 5;
        this.previousPage = this.page;
    }

    handleViewAllPenalties() {
        const url = new URL(window.location.origin + '/PRSELocalAuthority/dashboard/');
        url.searchParams.set('filterTab', 'Penalties');
        window.location.href = url.href;
    }

    handleCancelAndGoBackToPage0() {
        this.page = 0;
        this.hasErrors = false;
        this.components = [];
        this.currentPenalty = this.resetCurrentPenalty();
        this.previousPage = this.page;
    }

    handleCancel() {
        if(this.previousPage === 2 || this.previousPage === 3) {
            this.page = 3;
            this.hasErrors = false;
            this.components = [];
        } else if (this.previousPage === 0) {
            this.page = 0;
            this.hasErrors = false;
            this.components = [];
            this.currentPenalty = this.resetCurrentPenalty();
        }
        this.previousPage = this.page;
    }

    handleViewPenaltiesForExemption() {
        this.page = 0;
        this.hasErrors = false;
        this.components = [];
        this.currentPenalty = this.resetCurrentPenalty();
        this.previousPage = this.page;
    }

    handleCancelAndGoBackToPenaltyDetails() {
        this.page = 1;
        this.hasErrors = false;
        this.components = [];
    }

    // Pagination methods
    handlePrevious() {
        if (this.hasPreviousPage) {
            this.pageNumber -= 1;
            this.getAssociatedPenalties();
            window.scrollTo(0, 0);
        }
    }

    handleNext() {
        if (this.hasNextPage) {
            this.pageNumber += 1;
            this.getAssociatedPenalties();
            window.scrollTo(0, 0);
        }
    }

    handlePageClick(event) {
        const selectedPage = parseInt(event.target.dataset.page, 10);
        if (selectedPage !== this.pageNumber) {
            this.pageNumber = selectedPage;
            this.getAssociatedPenalties();
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