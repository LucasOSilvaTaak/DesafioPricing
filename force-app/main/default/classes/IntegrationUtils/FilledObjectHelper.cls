public with sharing class FilledObjectHelper {

    private static Map<String, Type> filledObjectsMap = new Map<String, Type>{
        'Order' => FilledObjects.FilledOrder.class,
        'OrderItem' => FilledObjects.FilledItem.class
    };

    public static List<FilledObjects.FilledObject> verifyRequiredFields (List<Wrappers.Wrapper> request){
        
        List<FilledObjects.FilledObject> filledList = new List<FilledObjects.FilledObject>();

        for (Wrappers.Wrapper iWrapper : request) {
            
            String type =  iWrapper.deserialize().getSObjectType().getDescribe().getName();

            FilledObjects.FilledObject filledObject = (FilledObjects.FilledObject) filledObjectsMap.get(type).newInstance();

            SObject deserializedOrder = iWrapper.deserialize();
            
            Set<String> allFields = iWrapper.getRequiredFields();

            Set<String> missingFields = VerifyRequiredFields.verifyRequiredFields(deserializedOrder, allFields);

            if(!missingFields.isEmpty()){

                filledObject.hasError = true;
                filledObject.errorMessage = 'Missing required fields on ' + filledObject.record.getSObjectType().getDescribe().getName() + ' with code "'
                     + iWrapper.getExternalId() + '"  : ' + String.join(new List<String>(missingFields), ', ');
            
            }

            filledObject.wrapper = iWrapper;
            filledObject.record = deserializedOrder;
            filledObject.externalId = iWrapper.getExternalId();

            filledList.add(filledObject);
            
        }

        return filledList;
    }

    public static Boolean verifyHasErrors(List<FilledObjects.FilledObject> objects){
        
        for(FilledObjects.FilledObject iObject : objects){
            if(iObject.hasError){
                return true;
            }
        }

        return false;

    }
}