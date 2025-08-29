public with sharing class MarginTriggerHandler {
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


    List<Margin__c> oldRecordList { get; set; }
	List<Margin__c> newRecordList { get; set; }
	Map<Id, Margin__c> oldRecordMap { get; set; }
	Map<Id, Margin__c> newRecordMap { get; set; }
    
    public MarginTriggerHandler(
        List<Margin__c> oldRecordList,
		List<Margin__c> newRecordList,
		Map<Id, Margin__c> oldRecordMap,
		Map<Id, Margin__c> newRecordMap
	) 
    {
		this.oldRecordList = oldRecordList;
		this.newRecordList = newRecordList;
		this.oldRecordMap = oldRecordMap;
		this.newRecordMap = newRecordMap;
	}

    public void BeforeInsert(){
        MarginTriggerHelper.HandleInsertMargin(newRecordList);
    }
    public void BeforeUpdate(){
        MarginTriggerHelper.HandleUpdateMargin(oldRecordList, newRecordList);
    }
}