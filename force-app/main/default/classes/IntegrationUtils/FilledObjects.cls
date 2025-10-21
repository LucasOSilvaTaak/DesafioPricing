public with sharing virtual class FilledObjects {
    
    public with sharing virtual class FilledObject {
        
        public String externalId {get; set;}
        public Boolean hasError {get; set;}
        public String errorMessage {get; set;}

        public FilledObject(){

            this.hasError = false;
            
            this.errorMessage = '';
        
        }
        
    }
        
    public class FilledItem extends FilledObject {
        
        public OrderItem items;
        
        public Wrappers.OrderItemWrapper wrapper;

        public FilledItem(){
            super();
        }
    }

    public class FilledOrder extends FilledObject{
       
        public Order order;
       
        public Wrappers.OrderWrapper wrapper;

        public FilledOrder(){
            super();

        }
    }
    
}

