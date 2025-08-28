trigger ProductTrigger on SOBJECT (before insert) {
    System.debug('Product Trigger Start => ' + Trigger.operationType);
    OrderProductTriggerHandler handler = new OrderProductTriggerHandler(
        Trigger.old,
        Trigger.new,
        Trigger.oldMap,
        Trigger.newMap
    );

    if(AssociatedLocationTriggerHandler.IsTriggerEnabled()){
        switch on Trigger.operationType {
            when BEFORE_INSERT{
                handler.AfterInsert();
            }
        }
    }
}