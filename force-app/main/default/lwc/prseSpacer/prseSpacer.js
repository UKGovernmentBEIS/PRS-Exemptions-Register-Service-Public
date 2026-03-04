import { LightningElement, api } from 'lwc';

export default class PrseSpacer extends LightningElement {
    @api divHeight = "3.125";

    renderedCallback() {
        const div = this.template.querySelector('.dynamic-div');
        if (div) {
            div.style.height = `${this.divHeight}rem`;
        }
    }
}