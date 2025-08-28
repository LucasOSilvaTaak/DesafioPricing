public with sharing class FreightTriggerHandler {
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


    List<Freight__c> oldRecordList { get; set; }
	List<Freight__c> newRecordList { get; set; }
	Map<Id, Freight__c> oldRecordMap { get; set; }
	Map<Id, Freight__c> newRecordMap { get; set; }
    
    public FreightTriggerHandler(		List<Freight__c> oldRecordList,
		List<Freight__c> newRecordList,
		Map<Id, Freight__c> oldRecordMap,
		Map<Id, Freight__c> newRecordMap
	) 
    {
		this.oldRecordList = oldRecordList;
		this.newRecordList = newRecordList;
		this.oldRecordMap = oldRecordMap;
		this.newRecordMap = newRecordMap;
	}

    public void BeforeInsert(){
        FreightTriggerHelper.HandleInsertFreight(newRecordList);
    }
    public void BeforeUpdate(){
        FreightTriggerHelper.HandleUpdateFreight(oldRecordList, newRecordList);
    }
}