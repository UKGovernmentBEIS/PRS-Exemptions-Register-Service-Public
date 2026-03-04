import { LightningElement, track, wire, api } from 'lwc';
import { MessageContext, publish, subscribe, unsubscribe, APPLICATION_SCOPE } from 'lightning/messageService'
import localAuthorityMessage from '@salesforce/messageChannel/localAuthorityDashboard__c';
import getExemptionsByStatus from '@salesforce/apex/PRSE_LocalAuthorityDashboardController.getExemptionsByStatus';
import getExemptionsByType from '@salesforce/apex/PRSE_LocalAuthorityDashboardController.getExemptionsByType';
import getPenaltiesByType from '@salesforce/apex/PRSE_LocalAuthorityDashboardController.getPenaltiesByType';
import systemLog from '@salesforce/apex/digitalmodus.SystemLogLwcWrapper.systemLog';

export default class PrseLocalAuthorityDashbordFilters extends LightningElement {
    @track isLoading;
    @track numberOfExemptionsByStatus = {};
    @track exemptionsByType = [];

    @track selectedStatuses = [];
    @track selectedExemptionTypes = [];
    @track searchTerm = '';

    @track selectedPropertyType = '';
    selectedPropertyTypeValue = '';
    @track penaltiesByTypes = [];
    @track selectedPenaltyTypes = [];

    @track activeTab;
    @track localAuthorityCodes;

    @wire(MessageContext)
    messageContext;

    showExemptionFilterPanel = true;
    showFilterStatusSubheader = false;
    showFilterExemptionTypeSubheader = false;
    showFilterPropertyTypeSubheader = false;
    showFilterPenaltyTypeSubheader = false;
    showFilterHeader = false;
    hasAppliedUrlFilters = false;

    @track showClearFilters = false;
    @track disableFilterButtons = false;

    // Temporary holder for URL filters
    urlFilters = null;
    urlFiltersReadyToApply = false; // NEW: flag to apply once both statuses & exemptions are loaded

    @api focusHeading() {
        const heading = this.template.querySelector('[data-id="filter-heading"]');
        if (heading) {
            heading.focus();
        }
    }

    get numberOfReceivedExemptions() {
        return this.numberOfExemptionsByStatus['Received'] || 0;
    }

    get numberOfNeedsUpdateExemptions() {
        return this.numberOfExemptionsByStatus['Needs update'] || 0;
    }

    get numberOfUpdatedExemptions() {
        return this.numberOfExemptionsByStatus['Updated'] || 0;
    }

    get numberOfPenaltySentExemptions() {
        return this.numberOfExemptionsByStatus['Penalty sent'] || 0;
    }

    get numberOfApprovedExemptions() {
        return this.numberOfExemptionsByStatus['Approved'] || 0;
    }

    get numberOfEndedExemptions() {
        return this.numberOfExemptionsByStatus['Ended'] || 0;
    }

    get numberOfExpiredExemptions() {
        return this.numberOfExemptionsByStatus['Expired'] || 0;
    }

    get propertyType() {
        return this.activeTab === 'Domestic' ? 'Residential' : 'Commercial';
    }

    get selectedPropertyTypeHref() {
        return '#' + this.selectedPropertyType;
    }

    connectedCallback() {
        this.isLoading = true;
        this.disableFilterButtons = true;
        this.subscribeToMessageChannel();
        this.isLoading = false;
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    getExemptionsByStatus() {
        getExemptionsByStatus({ localAuthorityCodes: this.localAuthorityCodes, propertyType : this.propertyType })
            .then(result => {
                this.numberOfExemptionsByStatus = result;
                this.tryApplyUrlFilters();
            })
            .catch(error => { 
                this.handleError(error, 'getExemptionsByStatus');
            });
    }

    getExemptionsByType() {
        getExemptionsByType({ localAuthorityCodes: this.localAuthorityCodes, propertyType : this.propertyType })
            .then(results => {
                this.exemptionsByType = results.map(record => ({
                    ...record,
                    nameWithNumber: `${record.name} (${record.numberOfRecords})`,
                    href: `#${record.code}`,
                    key: `${record.code}-1`
                }));
                this.tryApplyUrlFilters();
            })
            .catch(error => {
                this.handleError(error, 'getExemptionsByType');
            });
    }

    getPenaltiesByType() {
        getPenaltiesByType({ localAuthorityCodes: this.localAuthorityCodes })
            .then(results => {
                this.penaltiesByTypes = results.map(record => ({
                    ...record,
                    nameWithNumber: `${record.name} (${record.numberOfRecords})`,
                    href: `#${record.code}`,
                    key: `${record.code}-1`
                }));
            })
            .catch(error => {
                this.handleError(error, 'getPenaltiesByType');
            });
    }



    handleCheckboxChange(event) {
        const value = event.target.value;
        
        const formattedValue = value
            .split(' ')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
            .join('');   
        const statusType = {
            name: value,
            key: `${formattedValue}-1`,
            href: `#${formattedValue}`
        };

        const isChecked = event.target.checked;

        if (isChecked) {
            const exists = this.selectedStatuses.some(item => item.name === value);
            if (!exists) {
                this.selectedStatuses.push(statusType);
            }
        } else {
            const index = this.selectedStatuses.findIndex(item => item.name === value);
            if (index > -1) {
                this.selectedStatuses.splice(index, 1);
            }
        }
        this.showClearFilters = this.shouldShowClearFilters();

        this.showFilterStatusSubheader = this.selectedStatuses.length > 0;
        this.showFilterHeader = this.shouldShowFilterHeader();
    }

    handleExemptionTypeCheckboxChange(event) {
        const code = event.target.name;
        const isChecked = event.target.checked;

        if (isChecked) {
            const exemption = this.exemptionsByType.find(item => item.code === code);
            const exists = this.selectedExemptionTypes.some(item => item.code === code);
            if (!exists && exemption) {
                this.selectedExemptionTypes.push(exemption);
            }
        } else {
            const index = this.selectedExemptionTypes.findIndex(item => item.code === code);
            if (index > -1) {
                this.selectedExemptionTypes.splice(index, 1);
            }
        }
        this.showClearFilters = this.shouldShowClearFilters();

        this.showFilterExemptionTypeSubheader = this.selectedExemptionTypes.length > 0;
        this.showFilterHeader = this.shouldShowFilterHeader();
    }


    handlePropertyTypeRadioChange(event) {
        this.template.querySelectorAll('.govuk-radios__input').forEach(radio => {
            if (radio !== event.target) {
                radio.checked = false;
            }
        });
        this.selectedPropertyType = event.target.checked ? event.target.name : '';
        this.selectedPropertyTypeValue = event.target.checked ? event.target.value : '';

        this.showClearFilters = this.shouldShowClearFilters();
        this.showFilterPropertyTypeSubheader = this.selectedPropertyType !== '';
        this.showFilterHeader = this.shouldShowFilterHeader();
    }

    handlePenaltyTypeCheckboxChange(event) {
        const code = event.target.name;
        const isChecked = event.target.checked;

        if (isChecked) {
            const penalty = this.penaltiesByTypes.find(item => item.code === code);
            const exists = this.selectedPenaltyTypes.some(item => item.code === code);
            if (!exists && penalty) {
                this.selectedPenaltyTypes.push(penalty);
            }
        } else {
            const index = this.selectedPenaltyTypes.findIndex(item => item.code === code);
            if (index > -1) {
                this.selectedPenaltyTypes.splice(index, 1);
            }
        }
        this.showClearFilters = this.shouldShowClearFilters();

        this.showFilterPenaltyTypeSubheader = this.selectedPenaltyTypes.length > 0;
        this.showFilterHeader = this.shouldShowFilterHeader();
    }

    handleKeywordsChange(event) {
        this.searchTerm = event.target.value;
        this.showClearFilters = this.shouldShowClearFilters();
    }

    handleApplyFilters(event) {
        event.preventDefault();
        this.publishMessageWithFilters();
    }

    handleClearFilters(event) {
        event.preventDefault();
        this.clearFilters();
    }

    shouldShowClearFilters () {
        return this.selectedStatuses.length > 0 || this.selectedExemptionTypes.length > 0 || 
            this.selectedPenaltyTypes.length > 0 || this.selectedPropertyType !== '' || this.searchTerm !== '';
    }

    shouldShowFilterHeader () {
        return this.showFilterStatusSubheader || this.showFilterExemptionTypeSubheader || 
            this.showFilterPropertyTypeSubheader || this.showFilterPenaltyTypeSubheader;
    }

    clearFilters() {
        this.selectedPropertyType = '';
        this.selectedPropertyTypeValue = '';
        this.selectedStatuses = [];
        this.selectedExemptionTypes = [];
        this.selectedPenaltyTypes = [];
        this.showFilterStatusSubheader = false;
        this.showFilterExemptionTypeSubheader = false;
        this.showFilterPropertyTypeSubheader = false;
        this.showFilterPenaltyTypeSubheader = false;
        this.showFilterHeader = this.shouldShowFilterHeader();
        this.clearCheckboxes();
        this.clearRadios();
        this.searchTerm = '';
        this.showClearFilters = false;
        this.publishMessageWithFilters();
    }

    clearCheckboxes() {
        const checkboxes = this.template.querySelectorAll('input[type="checkbox"]');
        checkboxes.forEach(checkbox => {
            checkbox.checked = false;
        });
    }

    clearRadios() {
        this.template.querySelectorAll('.govuk-radios__input').forEach(radio => {
            radio.checked = false;
        });
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                localAuthorityMessage,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE },
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage(message) {
        if(message.type === "tabType") {
            if(this.activeTab !== message.activeTab) {
                this.activeTab = message.activeTab;
                this.clearFilters();

                if(message.activeTab === 'Penalties') {
                    this.showExemptionFilterPanel = false;
                    this.getPenaltiesByType();
                } else {
                    this.showExemptionFilterPanel = true;
                    this.getExemptionsByStatus();
                    this.getExemptionsByType();
                }
            }
        }

        if(message.type === "loading" && this.activeTab === message.activeTab) {
            this.disableFilterButtons = message.isLoading;
        }

        if(message.type === "localAuthorityCodes") {
            this.localAuthorityCodes = message.localAuthorityCodes;
            if(this.activeTab) {
                this.getExemptionsByStatus();
                this.getExemptionsByType();
            }
        }

        // Handle URL filters message
        if(message.type === "filters" && this.activeTab === message.activeTab) {
            this.urlFilters = message;
            this.urlFiltersReadyToApply = true; // mark ready to apply once both datasets are loaded
        }
    }

    // NEW: apply URL filters safely
    tryApplyUrlFilters() {
        if (!this.urlFiltersReadyToApply || !this.urlFilters) {
            return;
        }

        // Only apply if exemptionsByType is loaded
        if (!this.exemptionsByType || this.exemptionsByType.length === 0) {
            return; // wait until Apex returns
        }

        // Status filters
        this.selectedStatuses = Array.isArray(this.urlFilters.statuses)
            ? this.urlFilters.statuses
                .filter(status => status)
                .map(status => ({ name: status, key: `${status}-1`, href: `#${status}` }))
            : [];

        // Exemption type filters (only map if exemptions are loaded)
        if (this.exemptionsByType.length > 0) {
            this.selectedExemptionTypes = Array.isArray(this.urlFilters.exemptionTypeCodes)
        ? this.urlFilters.exemptionTypeCodes
            .map(code => {
                const found = this.exemptionsByType.find(item => item.code === code);
                return found;
            })
            .filter(item => item)
            : [];
        }

        this.searchTerm = this.urlFilters.searchTerm ? this.urlFilters.searchTerm : '';
        this.showFilterStatusSubheader = this.selectedStatuses.length > 0;
        this.showFilterExemptionTypeSubheader = this.selectedExemptionTypes.length > 0;

        this.showFilterHeader = this.showFilterStatusSubheader || this.showFilterExemptionTypeSubheader;// || (this.searchTerm && this.searchTerm.trim() !== '');
        this.showClearFilters = this.shouldShowClearFilters();

        // **Wait for DOM to render before updating checkboxes**
        Promise.resolve().then(() => {
            this.updateCheckboxes();
        });

        // Publish **only once**
        if (!this.hasAppliedUrlFilters && (this.selectedStatuses.length || this.selectedExemptionTypes.length || this.searchTerm) ) {
            this.hasAppliedUrlFilters = true;
            this.publishMessageWithFilters();
        }


        this.urlFilters = null;
        this.urlFiltersReadyToApply = false;
    }

    renderedCallback() {}

    updateCheckboxes() {
        const checkboxes = this.template.querySelectorAll('input[type="checkbox"][id]');

        checkboxes.forEach(cb => {
        const shouldCheck = this.selectedStatuses.some(s => s.name === cb.value) ||
                            this.selectedExemptionTypes.some(e => cb.id.startsWith(e.code));
        cb.checked = shouldCheck;
        });

        const searchInput = this.template.querySelector('input[name="keywords"]');
        if(searchInput) {
            searchInput.value = this.searchTerm;
        }        
    }

    handleError(error, methodName) {
        let log = {
            relatedService : 'prseLocalAuthorityDashboardFilters.js',
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

    publishMessageWithFilters() {
        if(this.activeTab === 'Penalties') {
            publish(
                this.messageContext, 
                localAuthorityMessage, 
                { 
                    type: "filters",
                    propertyType: this.selectedPropertyTypeValue,
                    penaltyTypeCodes: this.selectedPenaltyTypes.map(item => item.code),
                    localAuthorityCodes: this.localAuthorityCodes,
                    searchTerm: this.searchTerm,
                    activeTab: this.activeTab
                }
            );
        } else {
            publish(
                this.messageContext, 
                localAuthorityMessage,
                { 
                    type: "filters",
                    statuses: this.selectedStatuses.map(item => item.name),
                    exemptionTypeCodes: this.selectedExemptionTypes.map(item => item.code),
                    searchTerm: this.searchTerm,
                    activeTab: this.activeTab
                }
            );   
        }
    }
}
