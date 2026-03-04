import { LightningElement, api } from 'lwc';

export default class SearchParamSetter extends LightningElement {

    @api searchParamKey = '';
    @api searchParamValue = '';

    connectedCallback() {
        if (this.searchParamKey && this.searchParamValue) {
            let urlParams = new URLSearchParams(window.location.search);

            if (!urlParams.has(this.searchParamKey)) {
                urlParams.set(this.searchParamKey, this.searchParamValue);
                const newUrl = `${window.location.pathname}?${urlParams.toString()}`;
                window.history.replaceState({}, '', newUrl);
            }
        }
    }
}