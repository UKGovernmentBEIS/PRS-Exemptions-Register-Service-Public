import { LightningElement, api, track } from 'lwc';
import getExemptionRecords from '@salesforce/apex/PRSE_DashboardController.getExemptionRecords';

export default class PrseLandlordExemptionsList extends LightningElement {
    @api status = 'draft'; // draft, registered, ended
    @track records = [];
    @track totalRecords = 0;
    @track pageNumber = 1;
    @track pageSize = 20;
    @track isLoading = false;
    @track totalPages = 0;
    @track pageTitle = '';
    @track pageSubtitle = '';

    connectedCallback() {
        this.initializePageType();
        this.initializePageNumber();
        this.loadRecords();
    }

    initializePageType(){
        if(this.status === 'draft'){
            this.pageTitle = "Your draft exemptions";
            this.pageSubtitle = "View, edit and delete your draft exemptions";
        } 
        else if(this.status === 'registered'){
            this.pageTitle = "Your registered exemptions";
            this.pageSubtitle = "View, edit when requested and end your registered exemptions";
        } 
        else if(this.status === 'ended'){
            this.pageTitle = "Your ended exemptions";
            this.pageSubtitle = "View your ended exemptions";
        }
    }

    initializePageNumber() {
        const urlParams = new URLSearchParams(window.location.search);
        const pageParam = urlParams.get('page');
        if (pageParam && !isNaN(pageParam) && parseInt(pageParam) > 0) {
            this.pageNumber = parseInt(pageParam);
        }
    }

    updateUrlPageNumber() {
        const url = new URL(window.location);
        url.searchParams.set('page', this.pageNumber);
        window.history.replaceState({}, '', url);
    }

    loadRecords() {
        console.log(this.status);
        this.isLoading = true;
        getExemptionRecords({ 
            pageSize: this.pageSize, 
            pageNumber: this.pageNumber, 
            status: this.status 
        })
        .then(result => {
            this.totalRecords = result.totalRecords;
            this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
            
            if (this.pageNumber > this.totalPages && this.totalPages > 0) {
                this.pageNumber = this.totalPages;
                this.loadRecords();
                return;
            }
            
            this.records = result.records.map(record => {
                let fullPropertyAddress = '';
                
                if (this.status === 'ended' && record.Exemption__r) {
                    const address = record.Exemption__r.PropertyAddress__c || '';
                    const postcode = record.Exemption__r.PropertyPostcode__c || '';
                    fullPropertyAddress = [address, postcode].filter(Boolean).join(', ');
                } else {
                    const address = record.PropertyAddress__c || '';
                    const postcode = record.PropertyPostcode__c || '';
                    fullPropertyAddress = [address, postcode].filter(Boolean).join(', ');
                }

                if (!fullPropertyAddress) {
                    fullPropertyAddress = 'Not yet provided';
}

                let dateToFormat;
                if (this.status === 'draft') {
                    dateToFormat = record.CreatedDate;
                } else if (this.status === 'ended') {
                    dateToFormat = record.End_Date__c;
                } else {
                    dateToFormat = record.Registered_Date__c;
                }
                
                return {
                    ...record,
                    formattedDate: this.formatDate(dateToFormat),
                    deleteExemptionUrl: `/PRSExemptionsRegister/delete-exemption/?r=${record.Id}`,
                    endExemptionUrl: `/PRSExemptionsRegister/end-exemption/?r=${record.Id}`,
                    resumeExemptionUrl: `/PRSExemptionsRegister/exemption-registration/?existingExemption=${record.Id}`,
                    viewEndedExemptionUrl: `/PRSExemptionsRegister/ended-exemption/?recordId=${record.Id}`,
                    viewRegisteredExemptionUrl: `/PRSExemptionsRegister/view-exemption/?r=${record.Id}`,
                    needsMoreInfo: record.Status__c === 'Needs update',
                    fullPropertyAddress: fullPropertyAddress
                };
            });
            
            this.updateUrlPageNumber();
        })
        .catch(error => {
            console.error('Error fetching exemptions:', error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    get getTotalPages() {
        return Math.ceil(this.totalRecords / this.pageSize);
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

    get hasNoResults(){
        return this.totalRecords === 0;
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

    get isDraft() {
        return this.status === 'draft';
    }

    get areChangesRequired() {
        return this.isRegistered && this.records.some(record => record.needsMoreInfo);
    }

    get isRegistered() {
        return this.status === 'registered';
    }

    get isEnded() {
        return this.status === 'ended';
    }

    get startIndex() {
        return (this.pageNumber - 1) * this.pageSize + 1;
    }

    get endIndex() {
        return Math.min(this.pageNumber * this.pageSize, this.totalRecords);
    }

    handlePrevious() {
        if (this.hasPreviousPage) {
            this.pageNumber -= 1;
            this.loadRecords();
            window.scrollTo(0, 0);
        }
    }

    handleNext() {
        if (this.hasNextPage) {
            this.pageNumber += 1;
            this.loadRecords();
            window.scrollTo(0, 0);
        }
    }

    handlePageClick(event) {
        const selectedPage = parseInt(event.target.dataset.page, 10);
        if (selectedPage !== this.pageNumber) {
            this.pageNumber = selectedPage;
            this.loadRecords();
            window.scrollTo(0, 0);
        }
    }

    formatDate(dateString) {
        if (!dateString) {
            return '';
        }
        const date = new Date(dateString);
        return date.toLocaleDateString('en-GB', {
            day: '2-digit',
            month: 'long',
            year: 'numeric'
        });
    } 
}