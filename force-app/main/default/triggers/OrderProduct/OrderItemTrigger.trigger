trigger OrderItemTrigger on OrderItem (before insert) {
    System.debug('Order Product Trigger Start => ' + Trigger.operationType);
    OrderItemTriggerHandler handler = new OrderItemTriggerHandler(
        Trigger.old,
        Trigger.new,
        Trigger.oldMap,
        Trigger.newMap
    );

    if(AssociatedLocationTriggerHandler.IsTriggerEnabled()){
        switch on Trigger.operationType {
            when BEFORE_INSERT{
                handler.BeforeInsert();
            }
        }
    }
}