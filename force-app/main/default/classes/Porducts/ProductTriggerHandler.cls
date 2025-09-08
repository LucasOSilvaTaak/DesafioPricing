public with sharing class ProductTriggerHandler {
private static Boolean isEnabled;
    static{
        isEnabled=true;
    }
    public static Boolean isTriggerEnabled(){
        return isEnabled;
    }

    public static Boolean disableTrigger(){
        return isEnabled = false;
    }

    public static Boolean enableTrigger(){
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

    public void afterInsert(){
        ProductTriggerHelper.handleAfterInsertOrder(newRecordList);
    }

    public void afterUpdate(){
        ProductTriggerHelper.handleAfterUpdateOrder(oldRecordList, newRecordList);
    }
}