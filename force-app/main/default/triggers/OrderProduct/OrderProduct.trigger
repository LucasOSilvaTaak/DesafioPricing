trigger OrderProduct on OrderProduct (after insert) {
    System.debug('Order Product Trigger Start => ' + Trigger.operationType);
    OrderProductTriggerHandler handler = new OrderProductTriggerHandler(
        Trigger.old,
        Trigger.new,
        Trigger.oldMap,
        Trigger.newMap
    );

    if(AssociatedLocationTriggerHandler.IsTriggerEnabled()){
        switch on Trigger.operationType {
            when AFTER_INSERT{
                handler.AfterInsert();
            }
        }
    }
}