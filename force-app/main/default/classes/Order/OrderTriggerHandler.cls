public with sharing class OrderTriggerHandler {
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


    List<Order> oldRecordList { get; set; }
	List<Order> newRecordList { get; set; }
	Map<Id, Order> oldRecordMap { get; set; }
	Map<Id, Order> newRecordMap { get; set; }
    
    public OrderTriggerHandler(
        List<Order> oldRecordList,
		List<Order> newRecordList,
		Map<Id, Order> oldRecordMap,
		Map<Id, Order> newRecordMap
	) 
    {
		this.oldRecordList = oldRecordList;
		this.newRecordList = newRecordList;
		this.oldRecordMap = oldRecordMap;
		this.newRecordMap = newRecordMap;
	}

    public void BeforeUpdate(){
        OrderTriggerHelper.HandleUpdateOrder(oldRecordList, newRecordList);
    }
}