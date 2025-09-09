public with sharing class MakeKeys {
    private static Set<String> fields = new Set<String>{
        'City__c',
        'State__c',
        'Country__c',
        'Product__c',
        'ProductHierarchy__c',
        'Account__c',
        'AccountHierarchy__c'
    };

    public static String makeKey(SObject record){
        
        String key = '';

        Map<String,Object> fieldaMap = record.getPopulatedFieldsAsMap();

        for(String iString : fields){

            string value = String.valueOf(fieldaMap.get(iString));

            if(fields.contains(iString)){

                key += (value == null) ? '' : (value + '-');

            }
            

        }
        
        if(key.endsWith('-')){

            key = key.substring(0, key.length() - 1);

        }

        return key;
    }

    public static Map<String,Id> makeKeyMap(List<SObject> records){

        Map<String,Id> keyMap = new Map<String,Id>();
        
        for(SObject iRecord : records){
        
            keyMap.put(makeKey(iRecord), iRecord.Id);
        
        }
        
        return keyMap;
    }


}