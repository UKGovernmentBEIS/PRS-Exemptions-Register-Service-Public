import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import mojCssStyle from '@salesforce/resourceUrl/mojfrontend';

export default class MojCSSProvider extends LightningElement {
    cssStylesLoaded = false;

    renderedCallback() {
        if (this.cssStylesLoaded) {
            return;
        }
        this.cssStylesLoaded = true;
        loadStyle(this, mojCssStyle + '/moj-frontend-7.1.0.min.css')
            .then(() => console.log('CSS File loaded.'))
            .catch(error => {
                console.error('Error loading CSS:', error);
                const message = (error && error.body && error.body.message) || error.message || JSON.stringify(error);
                console.log("Error: " + message);
            });
    }
}
