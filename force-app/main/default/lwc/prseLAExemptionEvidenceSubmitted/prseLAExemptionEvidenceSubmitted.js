import { LightningElement, api, track, wire } from 'lwc';
import basePath from '@salesforce/community/basePath';
import getExemptionEvidenceDocumentsGrouped from '@salesforce/apex/PRSE_LAViewExemptionController.getExemptionEvidenceDocumentsGrouped';

export default class PrseLAExemptionEvidenceSubmitted extends LightningElement {

    @api exemptionId;
    @track groupedDocuments = [];
    @track isLoaded = false;
    @track error;

    formatDate(isoString) {
        if (!isoString) return '';
        const date = new Date(isoString);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        return `${day}/${month}/${year}`;
    }

    @wire(getExemptionEvidenceDocumentsGrouped, { exemptionId: '$exemptionId' })
    wiredEvidence({ error, data }) {
        if (data) {
            // Map CreatedDate to FormattedDate
            const clonedData = data.map(group => {
                return {
                    ...group,
                    Documents: group.Documents.map(doc => {
                        const hasDocument = doc.ContentDocumentId && doc.ContentDocumentId.trim() !== '';
                        return {
                            ...doc,
                            FormattedDate: doc.CreatedDate
                                ? this.formatDate(doc.CreatedDate)
                                : '',
                            DocumentUrl: hasDocument
                            ? `${basePath}/sfc/servlet.shepherd/document/download/${doc.ContentDocumentId}?operationContext=S1`
                            : null
                        };
                    })
                };
            });
            this.groupedDocuments = clonedData;
            this.isLoaded = true;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.groupedDocuments = [];
            this.isLoaded = true;
        }
    }
}