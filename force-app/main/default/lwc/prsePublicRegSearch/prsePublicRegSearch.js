import { LightningElement, wire, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import systemLog from '@salesforce/apex/digitalmodus.SystemLogLwcWrapper.systemLog';
import { MessageContext, publish, subscribe, unsubscribe, APPLICATION_SCOPE } from 'lightning/messageService'
import SET_FOCUS_MC from '@salesforce/messageChannel/uxgovuk__setFocusMessage__c';
import localAuthorityMessage from '@salesforce/messageChannel/localAuthorityDashboard__c';

//import searchExemptionTypes from '@salesforce/apex/PRSE_PublicSearchController.searchExemptionTypes';
import getExemptionTypes from '@salesforce/apex/PRSE_PublicSearchController.getExemptionTypes';
import getPenaltyTypes from '@salesforce/apex/PRSE_PublicSearchController.getPenaltyTypes';


//import searchPropertyExemptions from '@salesforce/apex/PRSE_PublicSearchController.searchPropertyExemptions';
import searchPropertyExemptionsPaginated from '@salesforce/apex/PRSE_PublicSearchController.searchPropertyExemptionsPaginated';
import searchPropertyExemptionsOtherWaysPaginated from '@salesforce/apex/PRSE_PublicSearchController.searchPropertyExemptionsOtherWaysPaginated';
import searchPropertyPenaltiesPaginated from '@salesforce/apex/PRSE_PublicSearchController.searchPropertyPenaltiesPaginated';
import searchPropertyPenaltiesOtherWaysPaginated from '@salesforce/apex/PRSE_PublicSearchController.searchPropertyPenaltiesOtherWaysPaginated';

import basePath from '@salesforce/community/basePath';

export default class PrsePublicRegSearch extends LightningElement {

    // Design params
    @api allowOtherSearch;
    @api displayResultsAtPropertyLevel;

    // component state
    @track results = [];
    error;
    loading = false;
    showPropertyExemptions = false;
    showPropertyPenalties = false;
    showChildExemptions = false;
    searchByPostcode = true;
    propertyTypeLabels = "All Properties|Domestic|Non-domestic";
    propertyTypeValues = "All Properties|Domestic|Non-domestic";
    exemptionTypeLabels = "All types|All improvements made or cost cap met|High cost|Third party consent|Wall insulation|New landlord|Devaluation";
    exemptionTypeValues = "All types|All improvements made or cost cap met|High cost|Third party consent|Wall insulation|New landlord|Devaluation";
    penaltyTypeLabels = 'All types';
    penaltyTypeValues = 'All types';
    hasErrors = false;
    components = [];
    searchApplied = false;

    // form fields
    selectedRadioValue = "";
    searchPostcode = "";
    userSuppliedPostcode = "";
    resultsPostcode;
    searchPropertyAddress = "";
    searchTownOrCity = "";
    searchLandlordName = "";
    propertyType = 'All Properties';
    searchExemptionType = 'All types';
    searchPenaltyType = 'All types';
    resultsSummaryMessage = "";

    @track allExemptionTypes = [];
    @track domesticExemptionTypes = [];
    @track commercialExemptionTypes = [];

    @track allPenaltyTypes = [];
    @track domesticPenaltyTypes = [];
    @track commercialPenaltyTypes = [];

    //Pagination properties
    @track totalDatabaseParentRecords = 0;
    @track pageNumber = 1;
    @track pageSize = 20;
    @track totalPages = 0;

    @wire(getExemptionTypes)
    wiredExemptionTypes({ error, data }) {
        if (data) {
            this.allExemptionTypes = data;

            this.domesticExemptionTypes = data.filter(
                type => !type.IsCommercial__c
            );

            this.commercialExemptionTypes = data.filter(
                type => type.IsCommercial__c
            );
        } else if (error) {
            console.error('Error loading exemption types', error);
        }
    }

    @wire(getPenaltyTypes)
    wiredPenaltyTypes({ error, data }) {
        if (data) {
            this.allPenaltyTypes = data;

            this.penaltyTypeLabels = ['All types', ...data.map(t => t.Name)].join('|');
            this.penaltyTypeValues = ['All types', ...data.map(t => t.Code__c)].join('|');

        } else if (error) {
            console.error('Error loading penalty types', error);
        }
    }

    updateExemptionTypeOptions(isCommercial) {
        const baseLabel = 'All types';

        const types = isCommercial
            ? this.commercialExemptionTypes
            : this.domesticExemptionTypes;

        const labels = [baseLabel];
        const values = [baseLabel];

        types.forEach(type => {
            labels.push(type.Name);
            values.push(type.Name);
        });

        this.exemptionTypeLabels = labels.join('|');
        this.exemptionTypeValues = values.join('|');
        this.searchExemptionType = baseLabel;

        let exemptionTypeComp = null;
        setTimeout(() => {
            const allSelects = this.template.querySelectorAll('c-gds-select');
            allSelects.forEach(select => {
                if (select.fieldId === 'searchExemptionType') {
                    exemptionTypeComp = select;
                }
            });

            if (exemptionTypeComp) {
                exemptionTypeComp.updateOptions(labels, values);
                exemptionTypeComp.setValue(baseLabel);
            }
        }, 100);
    }


    updatePenaltyTypeOptions() {
        const baseLabel = 'All types';
        const baseValue = 'All types';

        const types = this.allPenaltyTypes;

        const labels = [baseLabel];
        const values = [baseValue];

        types.forEach(type => {
            labels.push(type.Name);
            values.push(type.Code__c);
        });

        this.penaltyTypeLabels = labels.join('|');
        this.penaltyTypeValues = values.join('|');
        this.searchPenaltyType = baseValue;

        let penaltyTypeComp = null;
        setTimeout(() => {
            const allSelects = this.template.querySelectorAll('c-gds-select');
            allSelects.forEach(select => {
                if (select.fieldId === 'searchPenaltyType') {
                    penaltyTypeComp = select;
                }
            });

            if (penaltyTypeComp) {
                penaltyTypeComp.updateOptions(labels, values);
                penaltyTypeComp.setValue(baseValue);
            }
        }, 100);
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

    handleSearchClick() {
        this.pageNumber = 1;
        this.totalPages = 0;
        this.results = [];
        this.showPropertyExemptions = false;
        this.showPropertyPenalties = false;
        this.handleSearch();
    }

    handlePrevious() {
        if (this.hasPreviousPage) {
            this.pageNumber -= 1;
            this.handleSearch();
            window.scrollTo(0, 0);
        }
    }

    handleNext() {
        if (this.hasNextPage) {
            this.pageNumber += 1;
            this.handleSearch();
            window.scrollTo(0, 0);
        }
    }

    handlePageClick(event) {
        const selectedPage = parseInt(event.target.dataset.page, 10);
        if (selectedPage !== this.pageNumber) {
            this.pageNumber = selectedPage;
            this.handleSearch();
            window.scrollTo(0, 0);
        }
    }



    get hasNoResults() {
        return this.records.length === 0;
    }

    get getTotalPages() {
        return Math.ceil(this.totalDatabaseParentRecords / this.pageSize);
    }

    get startIndex() {
        return (this.pageNumber - 1) * this.pageSize + 1;
    }

    get endIndex() {
        return Math.min(this.pageNumber * this.pageSize, this.totalDatabaseParentRecords);
    }
    
    @wire(MessageContext) messageContext;

    connectedCallback() {
        document.title = 'Search the PRS exemptions and penalties register';
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
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

    get isExemptionSearch() {
        return this.selectedRadioValue === 'Exemptions';
    }

    get isPenaltySearch() {
        return this.selectedRadioValue === 'Penalties';
    }

    get isSearchTypeSelected() {
        return !!this.selectedRadioValue;
    }

    get resultCount() {
        return this.results ? this.results.length : 0;
    }

    get resultSummaryMessage() {
        let summaryMessage;
        const start = this.startIndex;
        const end = this.endIndex;
        const total = this.totalDatabaseParentRecords;

        if(this.searchByPostcode){
            summaryMessage = 'No '+this.selectedRadioValue.toLowerCase()+' found for ' + this.userSuppliedPostcode;
            if (this.results && this.results.length > 0) {
                if(this.isExemptionSearch){
                    summaryMessage = `Showing ${start}-${end} of ${total} exemption${this.results.length === 1 ? '' : 's'} for ${this.userSuppliedPostcode}`;
                } else if(this.isPenaltySearch){
                    summaryMessage = `Showing ${start}-${end} of ${total} ${this.results.length === 1 ? 'penalty' : 'penalties'} for ${this.userSuppliedPostcode}`;
                } else {
                    summaryMessage = `Showing ${start}-${end} of ${total} record${this.results.length === 1 ? '' : 's'} for ${this.userSuppliedPostcode}`;
                }
            }
        } else {
            summaryMessage = 'No '+this.selectedRadioValue.toLowerCase()+' found for ';
            let searchTerms = [];

            if (this.searchPropertyAddress) {
                searchTerms.push(this.searchPropertyAddress);
            }
            if (this.searchTownOrCity) {
                searchTerms.push(this.searchTownOrCity);
            }
            if (this.searchLandlordName) {
                searchTerms.push(this.searchLandlordName);
            }
            if (this.propertyType && this.propertyType !== 'All Properties' && this.propertyType !== 'Please select') {
                searchTerms.push(this.propertyType);

                if (this.isExemptionSearch && this.searchExemptionType) {
                    searchTerms.push(this.searchExemptionType);
                } else if (this.isPenaltySearch && this.searchPenaltyType) {
                    // Map the Code__c back to Name for display
                    const selectedPenalty = this.allPenaltyTypes.find(pt => pt.Code__c === this.searchPenaltyType);
                    searchTerms.push(selectedPenalty ? selectedPenalty.Name : this.searchPenaltyType);
                }

            }

            let formattedSearchTerms = '';
            const termCount = searchTerms.length;

            if (termCount > 0) {
                if (termCount === 1) {
                    formattedSearchTerms = searchTerms[0];
                } else {
                    const lastTerm = searchTerms[termCount - 1];
                    const precedingTerms = searchTerms.slice(0, termCount - 1);

                    formattedSearchTerms = precedingTerms.join(', ');
                    
                    if (termCount > 2) {
                        formattedSearchTerms += ',';
                    }
                    
                    formattedSearchTerms += ' and ' + lastTerm;
                }

                if (this.results && this.results.length > 0) {
                    if(this.isExemptionSearch){
                        summaryMessage = `Showing ${start}-${end} of ${total} exemption${this.results.length === 1 ? '' : 's'} for ${formattedSearchTerms}.`;
                    } else if(this.isPenaltySearch){
                        summaryMessage = `Showing ${start}-${end} of ${total} ${this.results.length === 1 ? 'penalty' : 'penalties'} for ${formattedSearchTerms}.`;
                    } else {
                        summaryMessage = `Showing ${start}-${end} of ${total} record${this.results.length === 1 ? '' : 's'} for ${formattedSearchTerms}.`;
                    }   
                } else {
                    summaryMessage = `No ${this.selectedRadioValue.toLowerCase()} found for ${formattedSearchTerms}.`;
                }
            } else {
                if (this.results && this.results.length > 0) {
                    if(this.isExemptionSearch){
                        summaryMessage = `Showing ${start}-${end} of ${total} exemption${this.results.length === 1 ? '' : 's'}.`;
                    } else if(this.isPenaltySearch){
                        summaryMessage = `Showing ${start}-${end} of ${total} ${this.results.length === 1 ? 'penalty' : 'penalties'}.`;
                    } else {
                        summaryMessage = `Showing ${start}-${end} of ${total} record${this.results.length === 1 ? '' : 's'}.`;
                    }
                } else {
                    summaryMessage = `No ${this.selectedRadioValue.toLowerCase()}s found.`;
                }
            }
        }

        return summaryMessage;
    }

    get tableHasResults(){
        return Array.isArray(this.results) && this.results.length > 0;
    }


    get showResults() {
        if(this.showPropertyExemptions || this.showPropertyPenalties){
            return true;
        } else {
            return false;
        }
    }

    announceSearchStatus() {
        const liveRegion = this.template.querySelector('[data-id="searchStatusAnnouncement"]');
        if (liveRegion) {
            // Clear first so the same message re-announces on repeated searches
            liveRegion.textContent = '';
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                liveRegion.textContent = this.resultsSummaryMessage;
            }, 100);
        }
    }

    // Event handlers
    handleChildValueChange(event) {
        const { id, value } = event.detail || {};
        const decodedValue = decodeURIComponent(value || '');

        switch (id) {

            case 'searchPostcode' :
                this.searchPostcode = decodedValue.replace(/\s+/g, '').toUpperCase();
                break;

            case 'selectSearchType':
                this.selectedRadioValue = decodedValue;

                // Update page title to reflect selected search type
                document.title = decodedValue === 'Exemptions'
                    ? 'Search for exemptions – PRS register'
                    : 'Search for penalties – PRS register';

                // Clear old results and table flags
                this.results = [];
                this.showPropertyExemptions = false;
                this.showPropertyPenalties = false;
                this.resultsSummaryMessage = "";
                this.searchApplied = false;
                this.error = null;
                this.totalDatabaseParentRecords = 0;
                this.pageNumber = 1;
                this.totalPages = 0;
                break;

            case 'searchPropertyAddress':
                this.searchPropertyAddress = decodedValue;
                break;

            case 'searchTownOrCity':
                this.searchTownOrCity = decodedValue;
                break;

            case 'searchLandlordName':
                this.searchLandlordName = decodedValue;
                break;

            case 'searchPropertyType':
                this.propertyType = decodedValue;

                if (this.propertyType === 'All Properties') {

                    this.searchExemptionType = 'All types';
                    this.exemptionTypeLabels = 'All types';
                    this.exemptionTypeValues = 'All types';

                    this.searchPenaltyType = 'All types';
                    this.penaltyTypeLabels = 'All types';
                    this.penaltyTypeValues = 'All types';

                    let exemptionTypeComp = null;

                    let allSelects = this.template.querySelectorAll('c-gds-select');
                    allSelects.forEach(select => {
                        if (select.fieldId === 'searchExemptionType') {
                            select.updateOptions([this.exemptionTypeLabels], [this.exemptionTypeValues]);
                            select.setValue(this.searchExemptionType);
                        }
                        if (select.fieldId === 'searchPenaltyType') {
                            select.updateOptions([this.penaltyTypeLabels], [this.penaltyTypeValues]);
                            select.setValue(this.searchPenaltyType);
                        }
                    });

                } else if (this.propertyType === 'Domestic') {

                    if (this.isExemptionSearch) {
                        this.updateExemptionTypeOptions(false);
                    } else if (this.isPenaltySearch) {
                        this.updatePenaltyTypeOptions();
                    }

                } else if (this.propertyType === 'Non-domestic') {

                    if (this.isExemptionSearch) {
                        this.updateExemptionTypeOptions(true);
                    } else if (this.isPenaltySearch) {
                        this.updatePenaltyTypeOptions();
                    }
                }
                break;

            case 'searchExemptionType':
                this.searchExemptionType = decodedValue;
                break;

            case 'searchPenaltyType':
                this.searchPenaltyType = decodedValue;
                break;    

            default:
                console.warn(`Unhandled field id: ${id}`);
                
        }
    }

    async handleSearch() {
        this.searchApplied = true;
        const componentsAreValid = this.validateComponents();

        if(!componentsAreValid){
            event.target.blur();
            requestAnimationFrame(() => {
                const errorComponent = this.template.querySelector('c-gds-error-messages-imperative');
                errorComponent.scrollIntoView({ behavior: 'smooth', block: 'center' });
                errorComponent.focus();
            });
            return;
        }

        // basic client-side validation
        const pc = (this.searchPostcode || '').trim();

        this.loading = true;

        if(this.isExemptionSearch){
            if(this.searchByPostcode){
                this.userSuppliedPostcode = this.template.querySelector('[data-id="searchByPostcode"]').value;
                try {
                    const result = await searchPropertyExemptionsPaginated({
                        postcode: pc,
                        pageSize: this.pageSize,
                        pageNumber: this.pageNumber
                    });

                    this.results = result.records;
                    this.totalDatabaseParentRecords = result.totalRecords;
                    this.totalPages = Math.ceil(
                        this.totalDatabaseParentRecords / this.pageSize
                    );
                    this.resultsPostcode = pc;
                    this.showPropertyExemptions = true;
                    this.resultsSummaryMessage = this.resultSummaryMessage;
                    document.title = 'View exemptions – search results';
                    this.announceSearchStatus();
                } catch (e) {
                    this.results = [];
                    this.error = e?.body?.message || e?.message || 'An unexpected error occurred';
                    console.error('Search error', e);
                    this.handleError(e, 'handleSearch');
                } finally {
                    this.loading = false;
                }
            } else {
                let commercialOrResidential = "";
                if(this.propertyType === "Domestic"){
                    commercialOrResidential = "Residential";
                } else if(this.propertyType === "Non-domestic"){
                    commercialOrResidential = "Commercial";
                }
                try {
                    const data = await searchPropertyExemptionsOtherWaysPaginated({
                        propertyAddress: this.searchPropertyAddress,
                        townOrCity: this.searchTownOrCity,
                        landlordsName: this.searchLandlordName,
                        propertyType: commercialOrResidential,
                        exemptionType: this.searchExemptionType,
                        pageSize: this.pageSize,
                        pageNumber: this.pageNumber
                    });

                    this.results = data.records;
                    this.totalDatabaseParentRecords = data.totalRecords;
                    this.totalPages = Math.ceil(
                        this.totalDatabaseParentRecords / this.pageSize
                    );
                    this.showPropertyExemptions = true;
                    this.resultsSummaryMessage = this.resultSummaryMessage;
                    document.title = 'View exemptions – search results';
                    this.announceSearchStatus();
                } catch (e) {
                    this.results = [];
                    this.error = e?.body?.message || e?.message || 'An unexpected error occurred';
                    console.error('Search error', e);
                    this.handleError(e, 'handleSearchClick');
                } finally {
                    this.loading = false;
                }
            }
        }

        if(this.isPenaltySearch){
            if(this.searchByPostcode){
                this.userSuppliedPostcode = this.template.querySelector('[data-id="searchByPostcode"]').value;
                try {
                    const data = await searchPropertyPenaltiesPaginated({
                        postcode: pc,
                        pageSize: this.pageSize,
                        pageNumber: this.pageNumber
                    });

                    this.results = data.records;
                    this.totalDatabaseParentRecords = data.totalRecords;
                    this.totalPages = Math.ceil(
                        this.totalDatabaseParentRecords / this.pageSize
                    );
                    this.resultsPostcode = pc;
                    this.showPropertyPenalties = true;
                    this.resultsSummaryMessage = this.resultSummaryMessage;
                    document.title = 'View penalties – search results';
                    this.announceSearchStatus();
                } catch (e) {
                    this.results = [];
                    this.error = e?.body?.message || e?.message || 'An unexpected error occurred';
                    console.error('Search error', e);
                    this.handleError(e, 'handleSearch');
                } finally {
                    this.loading = false;
                }
            } else {
                let commercialOrResidential = "";
                if(this.propertyType === "Domestic"){
                    commercialOrResidential = "Residential";
                } else if(this.propertyType === "Non-domestic"){
                    commercialOrResidential = "Commercial";
                }
                try {

                    const data = await searchPropertyPenaltiesOtherWaysPaginated({
                        propertyAddress: this.searchPropertyAddress,
                        townOrCity: this.searchTownOrCity,
                        landlordsName: this.searchLandlordName,
                        propertyType: commercialOrResidential,
                        penaltyType: this.searchPenaltyType,
                        pageSize: this.pageSize,
                        pageNumber: this.pageNumber
                    });

                    this.results = data.records;
                    this.totalDatabaseParentRecords = data.totalRecords;
                    this.totalPages = Math.ceil(
                        this.totalDatabaseParentRecords / this.pageSize
                    );
                    this.showPropertyPenalties = true;
                    this.resultsSummaryMessage = this.resultSummaryMessage;
                    document.title = 'View penalties – search results';
                    this.announceSearchStatus();
                } catch (e) {
                    this.results = [];
                    this.error = e?.body?.message || e?.message || 'An unexpected error occurred';
                    console.error('Search error', e);
                    this.handleError(e, 'handleSearch');
                } finally {
                    this.loading = false;
                }
            }
        }
    }

    handleViewClick(event) {
        event.preventDefault(); // keep focus/scroll stable, avoid hash-jump
        const recordId = event.currentTarget?.dataset?.id || null;
        if (!recordId) {
            // defensive: nothing to navigate to
            // optionally surface a toast or error
            // eslint-disable-next-line no-console
            console.warn('No record id found on clicked element.');
            return;
        }

                // Build the relative URL — adjust the base path to match your community page name
        let relativeUrl;
        if(this.isExemptionSearch){
            relativeUrl = `${basePath}/exemption-details?recordId=${recordId}&displayResultsAtPropertyLevel=${this.displayResultsAtPropertyLevel}`;
        } else if(this.isPenaltySearch){
            relativeUrl = `${basePath}/penalty-details?recordId=${recordId}&displayResultsAtPropertyLevel=${this.displayResultsAtPropertyLevel}`;
        }

        // Navigate within the site
        if (relativeUrl) {
           window.open(relativeUrl, '_blank');
        }
    }

    toggleSearchByPostcode(){
        this.hasErrors = false;
        this.components = [];

        let searchTypeComponent = this.template.querySelector('[data-id="selectSearchType"]');
        if(searchTypeComponent){
            searchTypeComponent.clearError();
        }

        let postcodeComponent = this.template.querySelector('[data-id="searchByPostcode"]');
        if(postcodeComponent){
            postcodeComponent.clearError();
        }

        if(this.searchByPostcode) {
            // Switching **from postcode -> Other ways**
            this.searchPostcode = '';
            this.userSuppliedPostcode = '';

            // Also clear the input component visually
            const postcodeComponent = this.template.querySelector('[field-id="searchByPostcode"]');
            if (postcodeComponent) postcodeComponent.value = '';
        } else {
            // Switching **from Other ways -> postcode**
            this.searchPropertyAddress = '';
            this.searchTownOrCity = '';
            this.searchLandlordName = '';
            this.propertyType = 'All Properties';
            this.searchExemptionType = 'All types';

            const addressComponent = this.template.querySelector('[field-id="searchPropertyAddress"]');
            if(addressComponent) addressComponent.value = '';
            const townComponent = this.template.querySelector('[field-id="searchTownOrCity"]');
            if(townComponent) townComponent.value = '';
            const landlordComponent = this.template.querySelector('[field-id="searchLandlordName"]');
            if(landlordComponent) landlordComponent.value = '';
            const propertyTypeComponent = this.template.querySelector('[field-id="searchPropertyType"]');
            if (propertyTypeComponent) propertyTypeComponent.value = 'All Properties';
            const exemptionTypeComponent = this.template.querySelector('[field-id="searchExemptionType"]');
            if (exemptionTypeComponent) exemptionTypeComponent.value = 'All types';            
        }

        this.searchByPostcode = this.searchByPostcode ? false : true;
    }

    get displayTypeFilter(){
        if(this.propertyType === "Domestic" || this.propertyType === "Non-domestic"){
            return true;
        } else {
            return false;
        }
    }

    validateComponents(){
        this.hasErrors = false;
        this.components = [];
        let searchTypeComponent = this.template.querySelector('[data-id="selectSearchType"]');
        let searchTypeValid = searchTypeComponent.handleValidate();

        if(!searchTypeValid){
            this.hasErrors = true;
            this.components.push({error: searchTypeComponent.errorMessage,fieldId: searchTypeComponent.fieldId});
        }

        if(this.searchByPostcode){
            let postcodeComponent = this.template.querySelector('[data-id="searchByPostcode"]');
            let postcodeValid = postcodeComponent.handleValidate();

            if(!postcodeValid){
                this.hasErrors = true;
                this.components.push({error: postcodeComponent.errorMessage,fieldId: postcodeComponent.fieldId});
            }

            if(searchTypeValid && postcodeValid){
                return true;
            } else {
                return false;
            }
        } else { // Other ways to search
            // Fields are optional
            return true;
        }
    }

    handleError(error, methodName){
        let log = {
            relatedService : 'PrsePublicRegSearch.js',
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