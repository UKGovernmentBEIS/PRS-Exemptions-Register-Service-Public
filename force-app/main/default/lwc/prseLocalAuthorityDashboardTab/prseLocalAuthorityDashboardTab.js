import { LightningElement, api, track, wire } from 'lwc';
import { MessageContext, publish, subscribe, unsubscribe, APPLICATION_SCOPE } from 'lightning/messageService'
import localAuthorityMessage from '@salesforce/messageChannel/localAuthorityDashboard__c';
import getAssociatedExemptionsForLocalAuthorities from '@salesforce/apex/PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsForLocalAuthorities';
import getAssociatedExemptionsCount from '@salesforce/apex/PRSE_LocalAuthorityDashboardController.getAssociatedExemptionsCount';
import systemLog from '@salesforce/apex/digitalmodus.SystemLogLwcWrapper.systemLog';

export default class PrseLocalAuthorityDashboardTab extends LightningElement {

    @api panelHeading;
    @api propertyType;
    @api localAuthorityCodes;
    @api noDataMessage;
    @track records = [];
    @track isLoading;
    @track preparingDownload = false;
    @track totalDatabaseChildRecords = 0;
    @track totalDatabaseParentRecords = 0;
    @track pageNumber = 1;
    @track pageSize = 30;
    @track totalPages = 0;
    @track pageTitle = '';
    @track pageSubtitle = '';

    @wire(MessageContext)
    messageContext;

    @track filters = {};

    get tabType() {
        return this.panelHeading.split(' ')[0];
    }

    get hasNoResults() {
        return this.records.length === 0;
    }

    get getTotalPages() {
        return Math.ceil(this.totalDatabaseParentRecords / this.pageSize);
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
        return Math.min(this.pageNumber * this.pageSize, this.totalDatabaseParentRecords);
    }

    handlePrevious() {
        if (this.hasPreviousPage) {
            this.pageNumber -= 1;
            this.getAssociatedExemptionsForLocalAuthorities();
            window.scrollTo(0, 0);
        }
    }

    handleNext() {
        if (this.hasNextPage) {
            this.pageNumber += 1;
            this.getAssociatedExemptionsForLocalAuthorities();
            window.scrollTo(0, 0);
        }
    }

    handlePageClick(event) {
        const selectedPage = parseInt(event.target.dataset.page, 10);
        if (selectedPage !== this.pageNumber) {
            this.pageNumber = selectedPage;
            this.getAssociatedExemptionsForLocalAuthorities();
            window.scrollTo(0, 0);
        }
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

    handleDownload() {
        this.preparingDownload = true;
        getAssociatedExemptionsForLocalAuthorities({ 
            localAuthorityCodes: this.localAuthorityCodes, 
            propertyType: this.propertyType, 
            pageSize: 50000,
            offsetValue: 0,
            filters: JSON.stringify({})
        })
            .then(result => {
                let headers = {
                    referenceNumber:"Reference Number",
                    landlordName:"Landlord name",
                    propertyAddress:"Property address",
                    exemptionTypes: "Exemption type(s)",
                    status: "Status",
                    registeredDate: "Date registered",
                }
                try {
                    this.exportCSVFile(headers, result.records, this.generateFileName(this.panelHeading));
                } catch (error) {
                    this.handleError(error, 'exportCSVFile');
                }
            })
            .catch(error => {
                this.handleError(error, 'getAssociatedExemptionsForLocalAuthorities');
            })
            .finally(() => {
                this.preparingDownload = false;
            });
    }

    handleMessage(message) {
        if(message.type === "filters" && this.tabType === message.activeTab) {
            this.filters = {
                statuses: [...message.statuses],
                exemptionTypeCodes: [...message.exemptionTypeCodes],
                searchTerm: message.searchTerm,
            };
            //this.pageNumber = 1;
            // NEW: set page number from message
            this.pageNumber = message.pageNumber || 1;
            this.getAssociatedExemptionsForLocalAuthorities();
            this.getAssociatedChildExemptionsCount();
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
        this.subscribeToMessageChannel();
        this.getAssociatedChildExemptionsCount();
        this.initializePageNumber();
        this.getAssociatedExemptionsForLocalAuthorities();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    generateFilteredExemptionUrl(recordId) {
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


    getAssociatedExemptionsForLocalAuthorities() {
        this.isLoading = true;
        publish(this.messageContext, localAuthorityMessage, { type: "loading", isLoading: true, activeTab: this.tabType });
        getAssociatedExemptionsForLocalAuthorities({ 
            localAuthorityCodes: this.localAuthorityCodes, 
            propertyType: this.propertyType, 
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            filters: JSON.stringify(this.filters)
        })
            .then(result => {
                try {
                    this.totalDatabaseParentRecords = result.totalRecords;
                    this.totalPages = Math.ceil(this.totalDatabaseParentRecords / this.pageSize);
                    
                    if (this.pageNumber > this.totalPages && this.totalPages > 0) {
                        this.pageNumber = this.totalPages;
                        this.getAssociatedExemptionsForLocalAuthorities();
                        return;
                    }
                    this.records = result.records.map(record => ({
                        ...record,
                        tagClass: this.getTagClass(record.status),
                        exemptionUrl: this.generateFilteredExemptionUrl(record.exemptionId)
                    }));
                    this.updateUrlPageNumber();
                } catch (error) {
                    this.handleError(error, 'getAssociatedExemptionsForLocalAuthorities');
                }
            })
            .catch(error => {
                this.handleError(error, 'getAssociatedExemptionsForLocalAuthorities');
            })
            .finally(() => {
                this.isLoading = false;
                publish(this.messageContext, localAuthorityMessage, { type: "loading", isLoading: false, activeTab: this.tabType });
            });
    }

    getAssociatedChildExemptionsCount() {
        getAssociatedExemptionsCount({ 
            localAuthorityCodes: this.localAuthorityCodes, 
            propertyType: this.propertyType,
            filters: JSON.stringify(this.filters)
        })
            .then(result => {
                this.totalDatabaseChildRecords = result;
            })
            .catch(error => {
                this.handleError(error, 'getAssociatedExemptionsCount');
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

    handleError(error, methodName){
        let log = {
            relatedService : 'prseLocalAuthorityDashboardTab.js',
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

    exportCSVFile(headers, totalData, fileTitle){
        if(!totalData || !totalData.length){
            return;
        }
        const jsonObject = JSON.stringify(totalData)
        const result = this.convertToCSV(jsonObject, headers)
        if(result === null) {
            return;
        }
        const BOM = '\uFEFF'
        const blob = new Blob([BOM + result])
        const exportedFilename = fileTitle ? fileTitle + '.csv' : 'export.csv'

        const link = document.createElement("a")
        const url = URL.createObjectURL(blob)
        link.href = url
        link.download = exportedFilename
        link.style.display = 'none'
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        URL.revokeObjectURL(url)
    }

    convertToCSV(objArray, headers){
        const columnDelimiter = ','
        const lineDelimiter = '\r\n'
        const actualHeaderKey = Object.keys(headers)
        const headerToShow = Object.values(headers)
        
        let str = headerToShow.map(header => this.escapeCSVValue(header)).join(columnDelimiter)
        str += lineDelimiter
        
        const data = typeof objArray !== 'object' ? JSON.parse(objArray) : objArray

        data.forEach(obj => {
            let line = ''
            actualHeaderKey.forEach(key => {
                if(line !== ''){
                    line += columnDelimiter
                }
                let value = obj[key]
                if(value === null || value === undefined){
                    value = ''
                } else {
                    value = value.toString()
                }
                line += this.escapeCSVValue(value)
            })
            str += line + lineDelimiter
        })
        return str
    }

    escapeCSVValue(value){
        if(!value){
            return ''
        }
        const stringValue = value.toString()
        
        //Force text format for dates to prevent Excel auto-conversion
        if(/^\d{1,2}\/\d{1,2}\/\d{4}$/.test(stringValue)){
            return `="${stringValue}"`
        }
        
        //If value contains comma, quote, or newline, wrap in quotes and escape internal quotes
        if(stringValue.includes(',') || stringValue.includes('"') || stringValue.includes('\n') || stringValue.includes('\r')){
            return `"${stringValue.replace(/"/g, '""')}"`
        }
        
        return stringValue
    }

    generateFileName(fileName) {
        const formattedFileName = fileName
            .trim()
            .split(/\s+/)
            .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
            .join('');
        
        const now = new Date();
        const date = now.toISOString().split('T')[0];
        const time = now.toTimeString().split(' ')[0].replace(/:/g, '-');
        
        return `${formattedFileName}-${date}-${time}`;
    }
}