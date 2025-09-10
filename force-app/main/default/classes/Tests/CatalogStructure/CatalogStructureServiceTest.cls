@IsTest
private with sharing class CatalogStructureServiceTest {
	@TestSetup
	static void makeData() {
		TestFactorySObject testFactory = TestFactorySObject.getInstance();
		Id pricebookId = TestFactorySObject.getStandardPricebookId();
		update new Pricebook2(Id = pricebookId, ExternalId__c = 'CatalogStructureTest');
		CatalogStructure__c catalogStructure = (CatalogStructure__c)testFactory.createSObject(new CatalogStructure__c(
			Name = 'Test Catalog Structure',
			ExternalId__c = 'TEST_STRUCTURE_001'
		));
		insert catalogStructure;
		CatalogStructure__c childCatalogStructure = (CatalogStructure__c)testFactory.createSObject(new CatalogStructure__c(
			Name = 'Test Child Catalog Structure',
			ExternalId__c = 'TEST_CHILD_STRUCTURE_001',
			ParentId__c = catalogStructure.Id
		));
		insert childCatalogStructure;
	}
	@IsTest
	static void testDoGetWithStructureId() {
		CatalogStructure__c testStructure = getCatalogStructure('TEST_STRUCTURE_001');
		Id pricebookId = TestFactorySObject.getStandardPricebookId();
		RestRequest request = new RestRequest();
		request.params.put('structureId', testStructure.Id);
		request.params.put('pricebookId', pricebookId);
		RestContext.request = request;
		RestResponse response = new RestResponse();
		RestContext.response = response;
		Test.startTest();
			CatalogStructureService.doGet();
		Test.stopTest();
		Assert.isNotNull(response.responseBody, 'Response body should not be null');
		Assert.areEqual('application/json', response.headers.get('Content-Type'), 'Content-Type should be application/json');
		String responseBody = response.responseBody.toString();
		Assert.isTrue(responseBody.contains('structures'), 'Response should contain structures data');
	}
	@IsTest
	static void testDoGetWithoutStructureId() {
		RestRequest request = new RestRequest();
		request.params.put('pricebookId', TestFactorySObject.getStandardPricebookId());
		RestContext.request = request;
		RestResponse response = new RestResponse();
		RestContext.response = response;
		Test.startTest();
		CatalogStructureService.doGet();
		Test.stopTest();
		Assert.isNotNull(response.responseBody, 'Response body should not be null');
		Assert.areEqual('application/json', response.headers.get('Content-Type'), 'Content-Type should be application/json');
		String responseBody = response.responseBody.toString();
		Assert.isTrue(responseBody.contains('sections'), 'Response should contain sections data');
	}
	@IsTest
	static void testDoGetWithInvalidStructureId() {
		RestRequest request = new RestRequest();
		request.params.put('structureId', '001000000000000');
		request.params.put('pricebookId', TestFactorySObject.getStandardPricebookId());
		RestContext.request = request;
		RestResponse response = new RestResponse();
		RestContext.response = response;
		Test.startTest();
		CatalogStructureService.doGet();
		Test.stopTest();
		Assert.isNotNull(response.responseBody, 'Response body should not be null');
		Assert.areEqual('application/json', response.headers.get('Content-Type'), 'Content-Type should be application/json');
		String responseBody = response.responseBody.toString();
		Assert.isFalse(responseBody.contains('error'), 'Response should not contain error for invalid structureId');
	}
	@IsTest
	static void testDoGetWithException() {
		RestRequest request = new RestRequest();
		request.params.put('structureId', null);
		request.params.put('pricebookId', null);
		RestContext.request = request;
		RestResponse response = new RestResponse();
		RestContext.response = response;
		Test.startTest();
		CatalogStructureService.doGet();
		Test.stopTest();
		Assert.isNotNull(response.responseBody, 'Response body should not be null');
		Assert.areEqual('application/json', response.headers.get('Content-Type'), 'Content-Type should be application/json');
		String responseBody = response.responseBody.toString();
		Assert.isTrue(responseBody.contains('sections'), 'Response should contain sections data even with null parameters');
	}
	@IsTest
	static void testDoGetWithValidPricebookId() {
		CatalogStructure__c testStructure = getCatalogStructure('TEST_STRUCTURE_001');
		Id pricebookId = TestFactorySObject.getStandardPricebookId();
		RestRequest request = new RestRequest();
		request.params.put('structureId', testStructure.Id);
		request.params.put('pricebookId', pricebookId);
		RestContext.request = request;
		RestResponse response = new RestResponse();
		RestContext.response = response;
		Test.startTest();
		CatalogStructureService.doGet();
		Test.stopTest();
		Assert.isNotNull(response.responseBody, 'Response body should not be null');
		Assert.areEqual('application/json', response.headers.get('Content-Type'), 'Content-Type should be application/json');
		String responseBody = response.responseBody.toString();
		Assert.isTrue(responseBody.contains('structures'), 'Response should contain structures data');
	}
	static CatalogStructure__c getCatalogStructure(String externalId) {
		CatalogStructure__c currentStructure;
		for (CatalogStructure__c retrievedStructure : [
			SELECT Id, Name, ExternalId__c, ParentId__c
			FROM CatalogStructure__c
			WHERE ExternalId__c = :externalId
			LIMIT 1
		]) {
			currentStructure = retrievedStructure;
		}
		return currentStructure;
	}
}