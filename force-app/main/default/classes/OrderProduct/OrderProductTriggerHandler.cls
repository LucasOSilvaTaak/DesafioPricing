public with sharing class OrderProductTriggerHandler {
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


    List<OrderProduct> oldRecordList { get; set; }
	List<OrderProduct> newRecordList { get; set; }
	Map<Id, OrderProduct> oldRecordMap { get; set; }
	Map<Id, OrderProduct> newRecordMap { get; set; }
    
    public OrderProductTriggerHandler(		List<OrderProduct> oldRecordList,
		List<OrderProduct> newRecordList,
		Map<Id, OrderProduct> oldRecordMap,
		Map<Id, OrderProduct> newRecordMap
	) 
    {
		this.oldRecordList = oldRecordList;
		this.newRecordList = newRecordList;
		this.oldRecordMap = oldRecordMap;
		this.newRecordMap = newRecordMap;
	}

    public void afterInsert(){
        
    }

}