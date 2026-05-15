import { LightningElement, api, track } from 'lwc';

const COOKIE_CATEGORIES = {
  NECESSARY: 'necessary',
  ANALYTICS: 'analytics',
  MARKETING: 'marketing'
};
	
class CookieSection {
    id;
    name;
    content;
    category;
    required;
    radioName;
    consent;
    yesId;
    noId;
    consentYes;
    consentNo;
    constructor(sectionName, sectionContent, category, consent) {
        this.id = generateId('section');
        this.name = sectionName;
        this.content = sectionContent;
        this.category = category;
        this.required = category === COOKIE_CATEGORIES.NECESSARY;
        this.radioName = `cookies[${this.category}]`;
        
        if(consent !== undefined) {
            this.consent = consent
        } else {
            this.consent = this.required
        }

        this.yesId = `${this.id}-yes`;
        this.noId = `${this.id}-no`;
        this.consentYes = this.consent === true;
        this.consentNo = this.consent === false;
    }

    withConsent(consent) {
        const updatedSection = new CookieSection(
            this.name,
            this.content,
            this.category,
            consent
        );

        updatedSection.id = this.id;
        updatedSection.yesId = this.yesId;
        updatedSection.noId = this.noId;

        return updatedSection;
    }
}

class TableRow {
    id;
    name;
    purpose;
    expiry;
    constructor(name, purpose, expiry) {
        this.id = generateId('section');
        this.name = name;
        this.purpose = purpose;
        this.expiry = expiry;
    }
}

function generateId(prefix = 'id') {
    return `${prefix}-${Math.random().toString(36).substring(2, 10)}-${Date.now()}`;
}

export default class GovCookiePage extends LightningElement {

    //misc apis
    @api cookieHeading = '';
    @api cookieDescription = '';
    @api enableRequiredCookiesSection = false;
    @api successText;

    //section apis
    @api cookieSectionHeading = '';
    @api sectionNames = '';
    @api sectionsContent = '';
    @api sectionsCategories = '';

    //essential cookies table apis
    @api showCookiesTable = false;
    @api cookieTableRowNames = '';
    @api cookieTableRowPurposes = '';
    @api cookieTableRowExpires = '';

    //fields to show consolidated user inputs
    @track finalSectionData = [];
    @track finalTableData = [];

    //other variables
    hasCookieSections = false;
    cookiesSet = false;
    

    connectedCallback() {
        this.handleSections();
        if(this.showCookiesTable) {
            this.handleTable();
        }
        // Changed from 'message' to 'civicresponse'
        window.addEventListener('civicresponse', this.handleConsentMessage);
        // Request consent state immediately
        this.sendCommand('CIVIC_GET_CONSENT');
    }

    disconnectedCallback() {
        // Was removing wrong listeners — fix to match what was added
        window.removeEventListener('civicresponse', this.handleConsentMessage);
    }

    handleConsentMessage = (event) => {
        // Changed from event.data to event.detail
        const data = event?.detail;
        if (!data || typeof data !== 'object') return;

        if (data.type === 'CIVIC_CONSENT_STATE') {
            let tempList;
            try {
                tempList = this.finalSectionData.map((section) => {
                    if (section.category === 'analytics') {
                        return section.withConsent(data.analyticsConsent);
                    } else if (section.category === 'marketing') {
                        return section.withConsent(data.marketingConsent);
                    }
                    return section;
                });
            } catch(error) {
                console.error('error: ', error.message);
            }
            this.finalSectionData = tempList;
        }

        if (data.type === 'CIVIC_READY') {
            this.sendCommand('CIVIC_GET_CONSENT');
        }
    }

    handleSections() {
        let sectionNamesList = this.handleSemicolonSplit(this.sectionNames);
        let sectionsContentList = this.handleSemicolonSplit(this.sectionsContent);
        let sectionsCategoriesList = this.handleSemicolonSplit(this.sectionsCategories);

        this.finalSectionData = sectionNamesList.map((sectionName, i) => {
            return new CookieSection(sectionName, sectionsContentList[i], sectionsCategoriesList[i]);
        });

        if(this.finalSectionData.length > 0) {
            this.hasCookieSections = true;
        }
    }

    handleTable() {
        let cookieTableNamesList = this.handleSemicolonSplit(this.cookieTableRowNames);
        let cookieTablePurposeList = this.handleSemicolonSplit(this.cookieTableRowPurposes);
        let cookieTableExpiryList = this.handleSemicolonSplit(this.cookieTableRowExpires);

        this.finalTableData = cookieTableNamesList.map((rowName, i) => {
            return new TableRow(rowName, cookieTablePurposeList[i], cookieTableExpiryList[i]);
        })
    }

    handleSemicolonSplit(string) {
        return string ? string.split(';') : [];
    }

    handleAcceptAll() {
        this.finalSectionData = this.finalSectionData.map(section =>
            section.required ? section : section.withConsent(true)
        );
    }

    handleRejectAll() {
        this.finalSectionData = this.finalSectionData.map(section =>
            section.required ? section : section.withConsent(false)
        );
    }

    handleCategoryUpdate(event) {
        const { category, consent } = event.detail;
        this.finalSectionData = this.finalSectionData.map(section => 
            section.category === category ? section.withConsent(consent) : section
        );
    }

    handleRadioChange(event) {
        const sectionId = event.target.dataset.sectionId;
        const consent = event.target.value === 'true';

        this.finalSectionData = this.finalSectionData.map((section) => {
            return section.id === sectionId ? section.withConsent(consent) : section;
        });

    }

    handleSubmit() {
        this.finalSectionData.map((section) => {
            if(section) {
                this.buildConsentCommand(section);
            }
        });
        this.cookiesSet = true;

        requestAnimationFrame(() => {
            const banner = this.template.querySelector('c-gov-uk-notification-banner');
            if (banner) {
                banner.focusBanner();
            }
        });
    }

    buildConsentCommand(cookie) {
        const cookieType = cookie.category.toUpperCase();
        if(cookie.consent) {
            this.sendCommand("CIVIC_ACCEPT_" + cookieType);
        } else {
            this.sendCommand("CIVIC_REJECT_" + cookieType);
        }
    }

    sendCommand(type) {
    window.dispatchEvent(
      new CustomEvent('civiccommand', {
        detail: { type }
      })
    );
  }
}