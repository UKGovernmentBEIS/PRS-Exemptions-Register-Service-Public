import { LightningElement,api } from 'lwc';
import sendNotification from '@salesforce/apex/PRSE_ADSendNotificationController.sendNotification';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PrseConfirmEvidenceReceived extends LightningElement {
    _recordId;
    isExecuting = false;

    @api get recordId() {
        return this._recordId;
    }

    set recordId(recordId) {
        if (recordId !== this._recordId) {
            this._recordId = recordId;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    
    @api async invoke() {
        console.log('Invoking sendNotification for recordId:', this.recordId);
        if (this.isExecuting) {
            return;
        }

        this.isExecuting = true;
        this.showToast('Sending notification', 'Please wait...', 'info');

        try {
            await sendNotification({ recordId: this.recordId });
            await this.delay(1000);
            this.showToast('Success', 'Notification sent successfully.', 'success');
        } catch (error) {
            console.error('Apex error:', error);

            let message = 'Unknown error';

            if (error?.body?.message) {
                message = error.body.message;
            } else if (error?.message) {
                message = error.message;
            }

            await this.delay(1000);

            this.showToast('Error sending notification', message, 'error');
        } finally {
            this.isExecuting = false;
        }
    }
}
