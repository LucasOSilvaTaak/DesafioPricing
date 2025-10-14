import { LightningElement, api } from 'lwc';
import processIntegration from '@salesforce/apex/OrderController.processIntegration';

export default class ResendOrderButton extends LightningElement {
    @api orderId;

    handleClick() {
        const idList = [this.orderId];
        
        processIntegration({ orderIds: idList })
    }
}