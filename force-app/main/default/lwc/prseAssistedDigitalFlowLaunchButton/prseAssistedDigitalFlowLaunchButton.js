import { LightningElement } from 'lwc';

export default class PrseAssistedDigitalFlowLaunchButton extends LightningElement {
    showFlow = false;

    handleClick() {
        this.showFlow = true;
    }

    closeModal() {
        this.showFlow = false;
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.showFlow = false;
        }
    }
}