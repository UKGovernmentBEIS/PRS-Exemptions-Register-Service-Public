import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getExemption from '@salesforce/apex/PRSE_LAViewExemptionController.getExemption';
import systemLog from '@salesforce/apex/digitalmodus.SystemLogLwcWrapper.systemLog';
import basePath from '@salesforce/community/basePath';

export default class PrseLocalAuthorityViewExemption extends LightningElement {

    @api exemptionId;               // final value used for Apex

    @api filterStatuses;
    @api filterExemptionTypes;
    @api filterSearch;
    @api filterTab;
    @api page;
    pageRefExemptionId = null;      // extracted from URL

    @track exemptionName = '';
    @track exemptionAddress = '';
    @track exemptionRecord;

    hasAgent = false;

    dataLoaded = false;

    // Extract exemptionId from URL: /ExemptionView?exemptionId=XXXX
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && currentPageReference.state) {
            const state = currentPageReference.state;

            // --- Required parameter ---
            const urlId = state.exemptionId;

            if (urlId && urlId !== this.exemptionId) {
                this.pageRefExemptionId = urlId;
                this.exemptionId = urlId;
                this.loadData(); // load immediately once id is known
            }

            // --- Optional filters ---
            this.filterStatuses       = state.filterStatuses || null;
            this.filterExemptionTypes = state.filterExemptionTypes || null;
            this.filterSearch         = state.filterSearch || null;
            this.filterTab            = state.filterTab || null;
            this.page                 = state.page || null;
        }
    }

    connectedCallback() {
        // If exemptionId is pre-set (rare), load immediately.
        // Otherwise load will start once URL param arrives.
        if (this.exemptionId) {
            this.loadData();
        }
    }

    get backLinkUrl() {
        // Only check the "real" filters
        const hasAnyFilter =
            (this.filterStatuses && this.filterStatuses.trim() !== '') ||
            (this.filterExemptionTypes && this.filterExemptionTypes.trim() !== '') ||
            (this.filterSearch && this.filterSearch.trim() !== '');

        const params = new URLSearchParams();

        // Always include tab and page
        if (this.filterTab) params.set('filterTab', this.filterTab);
        if (this.page) params.set('page', this.page);

        // Append filters only if any exist
        if (hasAnyFilter) {
            if (this.filterStatuses) params.set('filterStatuses', this.filterStatuses);
            if (this.filterExemptionTypes) params.set('filterExemptionTypes', this.filterExemptionTypes);
            if (this.filterSearch) params.set('filterSearch', this.filterSearch);
        }

        const queryString = params.toString();
        return queryString ? `${basePath}/dashboard/?${queryString}` : `${basePath}/dashboard/`;
    }


    get dataFinishedLoading() {
        return this.dataLoaded;
    }

    async loadData() {
        this.dataLoaded = false;

        try {
            const exemption = await getExemption({ exemptionId: this.exemptionId });

            if (exemption) {
                this.exemptionRecord = exemption;
                this.exemptionName = exemption.Ref_Number__c || '';
                this.exemptionAddress = exemption.Full_Property_Address__c || '';
                this.hasAgent = exemption.Account__r.Landlord_Type__c == 'Agent';
            }

        } catch (error) {
            this.handleError(error, 'loadData/getExemption');
        } finally {
            this.dataLoaded = true;
        }
    }

    // ----------------------------
    // GOV.UK Tab Switching Logic
    // ----------------------------
    handleTabSelection(event) {
        event.preventDefault();
        const activeTabId = event.currentTarget.dataset.id;
        document.title = activeTabId
            .replace(/([a-z])([A-Z])/g, '$1 $2')
            .replace(/^./, c => c.toUpperCase())
            .replace(/ ([A-Z])/, (m, c) => ' ' + c.toLowerCase());


        this.template.querySelectorAll('.govuk-tabs__list-item--selected')
            .forEach(el => el.classList.remove('govuk-tabs__list-item--selected'));

        this.template.querySelectorAll('.govuk-tabs__tab')
            .forEach(el => {
                el.classList.remove('govuk-tabs_focus');
                el.classList.add('govuk-tabs_underline');
                el.setAttribute('aria-selected', 'false');
            });

        this.template.querySelectorAll('.govuk-tabs__panel')
            .forEach(el => {
                el.classList.remove('govuk-tabs__panel');
                el.classList.add('govuk-tabs__panel--hidden');
            });

        this.template.querySelectorAll(`[data-id="${activeTabId}"]`)
            .forEach(el => {
                if (el.classList[0] === 'govuk-tabs__list-item') {
                    el.classList.add('govuk-tabs__list-item--selected');
                }
                if (el.classList[0] === 'govuk-tabs__tab') {
                    el.classList.remove('govuk-tabs_underline');
                    el.classList.add('govuk-tabs_focus');
                    el.setAttribute('aria-selected', 'true');
                }
            });

        this.template.querySelectorAll(`[data-id="${activeTabId}"]`)
            .forEach(el => {
                if (el.classList[0] === 'govuk-tabs__panel--hidden') {
                    el.classList.remove('govuk-tabs__panel--hidden');
                    el.classList.add('govuk-tabs__panel');
                }
            });
    }

    // ----------------------------
    // Error Handling + System Log
    // ----------------------------
    handleError(error, methodName) {
        let log = {
            relatedService: 'prseLocalAuthorityViewExemption.js',
            logMessage: error.errorType || error.name,
            logFullMessage: error.body?.message || error.message,
            logType: 'Error',
            logCode: 'LWC-LA-Exemption-View',
            relatedRecordId: this.exemptionId,
            triggeringAutomationName: methodName
        };

        systemLog({ log: log })
            .catch(() => {
                console.log('Failed to log error');
            });
    }
}
