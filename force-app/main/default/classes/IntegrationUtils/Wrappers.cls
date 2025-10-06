global with sharing class Wrappers {
 global class OrderWrapper {
        
		public String id;
		public String accountCode; //Order Account ExternalId
		public String orderCode; //Order Account ExternalId
		public String paymentCode; //Payment conditiom
		public Date effectiveDate;
		public String addressCode;
		public String freightType;
		public String distributionCenterCode;
		public Date deliveryDate;
		public String status = 'Activated';
		public String obs;
		public List<OrderItemWrapper> orderItems {get; set;}


		public Order deserialize() {
			return new Order(
				Id								= this.id,
				PaymentCondition__r				= new PaymentCondition__c(ExternalId__c = this.paymentCode),
				EffectiveDate					= this.effectiveDate,
				DistributionCenter__r			= new DistributionCenter__c(ExternalId__c = this.distributionCenterCode),
				ExternalId__c					= this.orderCode,
				DeliveryDate__c					= this.deliveryDate,
				Status							= this.status,
				Observation__c					= this.obs,
				FreightType__c					= this.freightType,
				Account							= new Account(ExternalId__c = this.accountCode),
				AccountAddress__r				= new AccountAddress__c(ExternalId__c = this.addressCode)

			);
		}

    }

    public class OrderItemWrapper {
        
        public String id;
		public String productCode; //Product Id
		public String itemCode; //External ID
		public Boolean totvsItem; //If it is a totvitem
		public Decimal unitPrice;
		public Decimal listPrice; //ListPrice
		public Decimal quantity;
		public String orderCode;

		public OrderItem deserialize() {
			OrderItem orderItem = new OrderItem(
				ExternalId__c	= this.itemCode,
				UnitPrice		= this.unitPrice,
				Quantity		= this.quantity
			);

			if (this.id == null || this.id == '') {
				orderItem.Order				= new Order(ExternalId__c = this.OrderCode);
				ListPrice					= this.listPrice;
				orderItem.Product2			= new Product2(ExternalId__c = this.productCode);
			}
			else orderItem.Id = this.id;

			return orderItem;
		}
    }




}