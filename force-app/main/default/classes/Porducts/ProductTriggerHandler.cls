public with sharing class ProductTriggerHandler {
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


    List<Product2> oldRecordList { get; set; }
	List<Product2> newRecordList { get; set; }
	Map<Id, Product2> oldRecordMap { get; set; }
	Map<Id, Product2> newRecordMap { get; set; }
    
    public ProductTriggerHandler(
        List<Product2> oldRecordList,
		List<Product2> newRecordList,
		Map<Id, Product2> oldRecordMap,
		Map<Id, Product2> newRecordMap
	) 
    {
		this.oldRecordList = oldRecordList;
		this.newRecordList = newRecordList;
		this.oldRecordMap = oldRecordMap;
		this.newRecordMap = newRecordMap;
	}

    public void AfterInsert(){
        ProductTriggerHelper.HandleAfterInsertOrder(newRecordList);
    }

    public void AfterUpdate(){
        ProductTriggerHelper.HandleAfterUpdateOrder(oldRecordList, newRecordList);
    }
}