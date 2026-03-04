import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import govukfrontend from '@salesforce/resourceUrl/govukfrontend513';

let cssStylesLoaded = false;

export default class PrseThemeCSSProvider extends LightningElement {
    constructor() {
        super();

        if (cssStylesLoaded === true) {
            return;
        }

        cssStylesLoaded = true;
        
        loadStyle(this, `${govukfrontend}/govuk-frontend-5.13.0.min.css`)
        .then(() => console.log('CSS File loaded.'))
        .catch(error => console.log("Error " + error.body.message));
    }

    connectedCallback(){
        document.documentElement.classList.add('govuk-template--rebranded');
    }
}