public with sharing class CompareSObjects {

    //COMPARA DOIS SOBJECTS COM BASE NOS CAMPOS INFORMADOS
    public static Boolean equals(SObject record1, SObject record2, Set<String> fields){
        
        Map<String,Object> map1 = record1.getPopulatedFieldsAsMap();
        Map<String,Object> map2 = record2.getPopulatedFieldsAsMap();

        for(String field : fields){
            
            Object value1 = map1.get(field);
        
            Object value2 = map2.get(field);

            if(value1 == null && value2 == null) continue;
        
            if(value1 == null || value2 == null) return false;

            if(value1 instanceof Decimal && value2 instanceof Decimal){
        
                if(!((Decimal)value1).setScale(6).equals(((Decimal)value2).setScale(6))) return false;
            
            }
            
            else if(value1 instanceof Date && value2 instanceof Date){
        
                if(!((Date)value1).equals((Date)value2)) return false;
        
            } 
            
            else if(value1 instanceof Datetime && value2 instanceof Datetime){
        
                if(!((Datetime)value1).equals((Datetime)value2)) return false;
        
            }
            
            else if(value1 instanceof String && value2 instanceof String){
        
                if(!((String)value1).trim().equals(((String)value2).trim())) return false;
        
            }
            
            else {
        
                if(value1 != value2) return false;
        
            }
        }

        return true;
    }

}
