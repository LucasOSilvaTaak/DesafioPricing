public with sharing class OrderItemTriggerHandler {
    private static Boolean isEnabled;
    static{
        isEnabled=true;
    }
    public static Boolean IsTriggerEnabled(){
        return isEnabled;
    }

    public static Boolean DisableTrigger(){
        return isEnabled = false;
    }

    public static Boolean EnableTrigger(){
        return isEnabled = true;
    }


    List<OrderItem> oldRecordList { get; set; }
	List<OrderItem> newRecordList { get; set; }
	Map<Id, OrderItem> oldRecordMap { get; set; }
	Map<Id, OrderItem> newRecordMap { get; set; }
    
    public OrderItemTriggerHandler(		List<OrderItem> oldRecordList,
		List<OrderItem> newRecordList,
		Map<Id, OrderItem> oldRecordMap,
		Map<Id, OrderItem> newRecordMap
	) 
    {
		this.oldRecordList = oldRecordList;
		this.newRecordList = newRecordList;
		this.oldRecordMap = oldRecordMap;
		this.newRecordMap = newRecordMap;
	}

    public void BeforeInsert(){
        OrderItemTriggerHelper.HandleBeforeInsertOrderProduct(newRecordList);
    }

    public void BeforeUpdate(){
        OrderItemTriggerHelper.HandleBeforeUpdateOrderProduct(oldRecordList, newRecordList);
    }

}