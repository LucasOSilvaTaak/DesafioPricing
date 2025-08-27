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


    List<AssociatedLocation__c> oldRecordList { get; set; }
	List<AssociatedLocation__c> newRecordList { get; set; }
	Map<Id, AssociatedLocation__c> oldRecordMap { get; set; }
	Map<Id, AssociatedLocation__c> newRecordMap { get; set; }
    
    public OrderProductTriggerHandler(		List<AssociatedLocation__c> oldRecordList,
		List<AssociatedLocation__c> newRecordList,
		Map<Id, AssociatedLocation__c> oldRecordMap,
		Map<Id, AssociatedLocation__c> newRecordMap
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