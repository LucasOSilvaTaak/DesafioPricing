global with sharing class DataIntegrationFields {
	public interface FieldData {
		List<String> getRequiredFields();
		String getFieldKey();
		String getFieldId();
		String getExternalId();
		SObject deserialize();
	}

	public interface FieldDataChild {
		List<String> getRequiredFields();
		String getFieldId();
		String getFieldExternal();
		String getParentId();
		String getParentKey();
		SObject deserialize();
	}

	global class OrderINData implements FieldData { // extends OrderBase
		public String id;
		public String clienteCode; //Order Account ExternalId
		public String accountAddress; //Order Account ExternalId
		public String conditionCode; //Payment conditiom
		public Date effectiveDate;
		public String freightType;
		public Id distributionCenter;
		public String orderNumber;
		public Date deliveryDate;
		public String deliveryDateERP; //DeliveryDate on ERP
		public String status;
		public String obs;
		public String priority;//priority *dont have
		public String representativeOrderNumber;//priority *dont have
		public List<OrderItemINData> orderItemList {get; set;}

		public Order deserialize() {
			return new Order(
				Id								= this.id,
				PaymentCondition__c				= this.conditionCode,
				EffectiveDate					= this.effectiveDate,
				DistributionCenter__c			= this.distributionCenter,
				ExternalId__c					= this.orderNumber,
				DeliveryDate__c					= this.deliveryDate,
				Status							= this.status,
				Observation__c					= this.obs,
				FreightType__c					= this.freightType,
				Account							= new Account(ExternalId__c = this.clienteCode),
				RepresentativeOrderNumber__c	= this.representativeOrderNumber,
				AccountAddress__c 				= this.accountAddress

			);
		}

		public List<String> getRequiredFields() {
			return new List<String>{
				'ExternalId__c',
				'PaymentCondition__c',
				'EffectiveDate',
				'Status'
			};
		}
		public List<String> getRequiredLookups() {
			return new List<String>{
				'AccountId',
				'DistributionCenter__c'

			};
		}

		public String getFieldKey() {
			return 'ExternalId__c';
		}
		public String getFieldId() {
			return 'Id';
		}
		public String getExternalId() {
			return this.orderNumber;
		}
	}
	global class OrderItemINData implements FieldDataChild { // extends OrderItemBase
		public String id;
		public String productCode; //Product Id
		public String orderitemCode; //External ID
		public Boolean totvsItem; //If it is a totvitem
		public Date deliveryDate;
		public Decimal unitPrice;
		public Decimal motorPrice; //ListPrice
		public Decimal quantity;
		public String status;
		public String OrderExternalId;

		public OrderItem deserialize() {
			OrderItem orderItem = new OrderItem(
				ExternalId__c	= this.orderitemCode,
				UnitPrice		= this.unitPrice,
				ListPrice		= this.motorPrice,
				Quantity		= this.quantity
			);

			if (this.id == null || this.id == '') {
				orderItem.Order				= new Order(ExternalId__c = this.OrderExternalId);
				orderItem.Product2			= new Product2(ExternalId__c = this.productCode);
			}
			else orderItem.Id = this.id;

			return orderItem;
		}

		public List<String> getRequiredFields() {
			return new List<String>{
				'UnitPrice',
				'Quantity',
				'ExternalId__c',
				'ListPrice'
			};
		}
		public List<String> getRequiredLookups() {
			return new List<String>{
				'OrderId',
				'Product2Id'
			};
		}

		public String getFieldId() {
			return 'Id';
		}
		public String getFieldExternal() {
			return 'ExternalId__c';
		}
		public String getParentId() {
			return 'OrderId';
		}
		public String getParentKey() {
			return this.orderitemCode;
		}
	}

	global virtual class Response {
		public String salesforceId;
		public String externalId;
		public String sobjectType;
		public Boolean hasError;
		public String errorMessage;

		public void success(String salesforceId, String externalId, String sobjectType){
			this.salesforceId	= salesforceId;
			this.externalId		= externalId;
			this.sobjectType	= sobjectType;
			this.hasError		= false;
		}

		public void error(String externalId, String errorMessage, String sobjectType){
			this.externalId		= externalId;
			this.sobjectType	= sobjectType;
			this.hasError		= true;
			this.errorMessage	= errorMessage;
		}

		public void error(String salesforceId, String externalId, String errorMessage, String sobjectType){
			this.salesforceId	= salesforceId;
			this.externalId		= externalId;
			this.sobjectType	= sobjectType;
			this.hasError		= true;
			this.errorMessage	= errorMessage;
		}
	}
	global class ResponseParent extends Response {
		public List<DataIntegrationFields.Response> items;
	}
}
