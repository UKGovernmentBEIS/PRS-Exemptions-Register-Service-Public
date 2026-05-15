import { LightningElement, api, track, wire } from 'lwc';
import getUserDisplayName from '@salesforce/apex/PRSE_LocalAuthorityDashboardController.getUserDisplayName';
import getAssociatedExemptionsNeedingReviewCount from '@salesforce/apex/PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsNeedingReviewCount';
import getAssociatedLocalAuthorities from '@salesforce/apex/PRSE_LocalAuthorityDashboardController.getAssociatedLocalAuthorities';
import systemLog from '@salesforce/apex/digitalmodus.SystemLogLwcWrapper.systemLog';

import { MessageContext, publish, subscribe, unsubscribe, APPLICATION_SCOPE } from 'lightning/messageService'
import localAuthorityMessage from '@salesforce/messageChannel/localAuthorityDashboard__c';

export default class PrseLocalAuthorityDashboard extends LightningElement {

    @api title = "";
    @api titleSize = "Large";
    @api tabNames = "";
    @api tabData = "";

    @track data = [];

    displayName = '';
    @track localAuthorityCount;
    @track localAuthorityCodes = [];
    @track localAuthorityNames;
    @track localAuthorities = [];
    @track domesticExemptionCount = 0;
    @track nonDomesticExemptionCount = 0;
    @track dataLoaded = false;

    @track showFilter = false;

    @wire(MessageContext)
    messageContext;

    @track hasPublished;

    filtersApplied = false;
    activeTabFromUrl = null;
    selectedStatuses = [];
    selectedExemptionTypes = [];
    searchTerm = '';
    pageNumber = null;

    @wire(getUserDisplayName)
    userDisplayName({ error, data }) {
        if (data) {
            this.displayName = data;
        } else if (error) {
            this.handleError(error, 'userDisplayName');
        }
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
        this.parseUrlFilters();
        this.loadData();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    parseUrlFilters() {
        const params = new URLSearchParams(window.location.search);

        this.activeTabFromUrl = params.get('filterTab');
        this.selectedStatuses = params.get('filterStatuses')?.split(',') || [];
        this.selectedExemptionTypes = params.get('filterExemptionTypes')?.split(',') || [];
        this.searchTerm = params.get('filterSearch') || '';
        this.pageNumber = params.get('page') ? parseInt(params.get('page'), 10) : null;

        // Show filter panel if any filter exists
        this.showFilter = this.selectedStatuses.length > 0 || this.selectedExemptionTypes.length > 0 || !!this.searchTerm;
    }

    renderedCallback() {
    
        if (!this.dataLoaded || this.filtersApplied) {
            return;
        }

        // Apply tab from URL if present, default to Domestic
        const tabId = this.activeTabFromUrl || 'Domestic';
        const tab = this.template.querySelector(`[data-id="${tabId}"]`);

        if (tab) {
            this.handleTabSelection({ currentTarget: tab, renderedCallback: true });
        }

        // Publish filters to children
        publish(this.messageContext, localAuthorityMessage, {
            type: "filters",
            statuses: this.selectedStatuses || [],
            exemptionTypeCodes: this.selectedExemptionTypes || [],
            searchTerm: this.searchTerm || '',
            activeTab: tabId,
            pageNumber: this.pageNumber || 1
        });

        this.filtersApplied = true;
    }

    get filterButtonLabel() {
        return this.showFilter ? 'Hide search and filter' : 'Search and filter';
    }

    get dataFinishedLoading() {
        return this.dataLoaded;
    }

    get isFilterHidden() {
        return !this.showFilter;
    }

    get dataTableClass() {
        return this.showFilter ? 'govuk-grid-column-three-quarters' : 'govuk-grid-column-full';
    }

    handleFilters() {
        this.showFilter = !this.showFilter;
        if(this.showFilter === true) {
             requestAnimationFrame(() => {
                const child = this.template.querySelector('c-prse-local-authority-dashboard-filters');
                if (child && child.focusHeading) {
                    child.focusHeading();
                }
            });
        }
    }

    async loadData() {
        try {
            this.localAuthorities = await getAssociatedLocalAuthorities();
            let entries = Object.entries(this.localAuthorities);

            // Sort by name (value)
            entries.sort((a, b) => 
                a[1].localeCompare(b[1], undefined, { sensitivity: 'base' })
            );

            // Rebuild arrays in sorted order
            this.localAuthorityNames = entries.map(e => e[1]).join(', ');
            this.localAuthorityCodes = entries.map(e => e[0]);
            this.localAuthorityCount = entries.length;

            const [domesticExemptionCount, nonDomesticExemptionCount] = await Promise.all([
                getAssociatedExemptionsNeedingReviewCount({ localAuthorityCodes: this.localAuthorityCodes, propertyType: 'Residential' }),
                getAssociatedExemptionsNeedingReviewCount({ localAuthorityCodes: this.localAuthorityCodes, propertyType: 'Commercial'}),
            ]);

            this.domesticExemptionCount = domesticExemptionCount;
            this.nonDomesticExemptionCount = nonDomesticExemptionCount;
            publish(this.messageContext, localAuthorityMessage, { type: "localAuthorityCodes", localAuthorityCodes: this.localAuthorityCodes });
        } catch (error) {
            this.handleError(error, 'getAssociatedExemptionsForLocalAuthorities');
        } finally {
            this.dataLoaded = true;
        }
    }

    handleTabSelection(event) {
        if(event && !event.renderedCallback) {
            event.preventDefault();
        }
        
        const activeTabId = event.currentTarget.dataset.id;
        publish(this.messageContext, localAuthorityMessage, { type: "tabType", activeTab: activeTabId });
        if(activeTabId === 'Penalties') {
            document.title = activeTabId;
        } else {
            document.title = activeTabId + ' exemptions';
        }
        
        this.template.querySelectorAll('.govuk-tabs__list-item--selected').forEach(element => {
            element.classList.remove("govuk-tabs__list-item--selected");
        });
        
        this.template.querySelectorAll('.govuk-tabs__tab').forEach(element => {
            element.classList.remove("govuk-tabs_focus");
            element.classList.add("govuk-tabs_underline");
            element.setAttribute('aria-selected', 'false');
        });

        this.template.querySelectorAll('.govuk-tabs__panel').forEach(element => {
            element.classList.remove("govuk-tabs__panel"); 
            element.classList.add("govuk-tabs__panel--hidden");
        });
        
        this.template.querySelectorAll(`[data-id="${activeTabId}"]`).forEach(element => {
            if(element.classList[0] === "govuk-tabs__list-item") {
                element.classList.remove("govuk-tabs_underline"); 
                element.classList.add("govuk-tabs__list-item--selected");     
            }
            if(element.classList[0] === "govuk-tabs__tab") {
                element.classList.remove("govuk-tabs_underline"); 
                element.classList.add("govuk-tabs_focus");  
                element.setAttribute('aria-selected', 'true');
            }
        });
        
        this.template.querySelectorAll(`[data-id="${activeTabId}"]`).forEach(element => {
                if(element.classList[0] === "govuk-tabs__panel--hidden") {
                    element.classList.remove("govuk-tabs__panel--hidden");
                    element.classList.add("govuk-tabs__panel"); 
                }
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
        if(message.type === "tabChange" && message.activeTab !== null) {
            this.activeTabFromUrl = message.activeTab;
            const tab = this.template.querySelector(`[data-id="${this.activeTabFromUrl}"]`);

            if (tab) {
                this.handleTabSelection({ currentTarget: tab, renderedCallback: true });
            }
        }
    }
    
    handleError(error, methodName){
        let log = {
            relatedService : 'prseLocalAuthorityDashboard.js',
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
}