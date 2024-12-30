public with sharing class CreateInvoiceController {
    public String accountId { get; set; }
    public String accountIdFinal { get; set; }
    public String originRecord { get; set; }
    public String orderId { get; set; }
    public String invoiceDate { get; set; }
    public String invoiceDueDate { get; set; }
    public String childRelationshipName { get; set; }
    public String lineItemDescription { get; set; }
    public String lineItemQuantity { get; set; }
    public String lineItemUnitPrice { get; set; }
    public List<OpportunityLineItem> opportunityLineItems { get; set; }
    public List<OrderItem> orderItems { get; set; }
    public String invoiceJson { get; set; }


    public CreateInvoiceController() {
        
        accountId = ApexPages.currentPage().getParameters().get('account');
        invoiceDate = ApexPages.currentPage().getParameters().get('invoice_date');
        invoiceDueDate = ApexPages.currentPage().getParameters().get('invoice_due_date');
        originRecord = ApexPages.currentPage().getParameters().get('origin_record');
        orderId = ApexPages.currentPage().getParameters().get('order_id');
        childRelationshipName = ApexPages.currentPage().getParameters().get('child_relationship_name');
        lineItemDescription = ApexPages.currentPage().getParameters().get('line_item_description');
        lineItemQuantity = ApexPages.currentPage().getParameters().get('line_item_quantity');
        lineItemUnitPrice = ApexPages.currentPage().getParameters().get('line_item_unit_price');
        
        opportunityLineItems = new List<OpportunityLineItem>();
        orderItems = new List<OrderItem>();

        // Fetch the line items dynamically based on the passed parameters
        if (originRecord != null) {

            List<SObject> sObjectList = queryLineItems('Opportunity', originRecord); 
            // Type-casting the generic SObject list to OpportunityLineItem list
            for (SObject obj : sObjectList) {
                opportunityLineItems.add((OpportunityLineItem) obj); // Type-casting
            }
        } else if (orderId != null) {

            List<SObject> sObjectList = queryLineItems('Order', orderId); 
            accountIdFinal = [SELECT Id FROM Account WHERE AccountNumber = :accountId].Id;
            // Type-casting the generic SObject list to OrderItem list
            for (SObject obj : sObjectList) {
                orderItems.add((OrderItem) obj); // Type-casting
            }
        }
    }

    // Dynamic SOQL query to fetch line items
    private List<SObject> queryLineItems(String parentObject, String recordId) {
        String query = 'SELECT ' + lineItemDescription + ', ' + lineItemQuantity + ', ' + lineItemUnitPrice + 
                       ' FROM ' + childRelationshipName +
                       ' WHERE ' + parentObject + 'Id = :recordId';
        return Database.query(query);
    }

    public void generateJson() {
        Map<String, Object> invoice = new Map<String, Object>();
        invoice.put('Type', 'ACCREC');
        invoice.put('Contact', new Map<String, Object>{ 'ContactID' => '0000000' });
        invoice.put('Date', invoiceDate);
        invoice.put('DueDate', invoiceDueDate);

        List<Map<String, Object>> invoiceLineItems = new List<Map<String, Object>>();
        
        // Adding OpportunityLineItems to the JSON
        for (OpportunityLineItem lineItem : opportunityLineItems) {
            invoiceLineItems.add(new Map<String, Object> {
                'Description' => lineItem.Description,
                'Quantity' => lineItem.Quantity,
                'UnitAmount' => lineItem.UnitPrice,
                'AccountCode' => '200'
            });
        }

        // Adding OrderItems to the JSON
        for (OrderItem lineItem : orderItems) {
            invoiceLineItems.add(new Map<String, Object> {
                'Description' => lineItem.Description,
                'Quantity' => lineItem.Quantity,
                'UnitAmount' => lineItem.UnitPrice,
                'AccountCode' => '200'
            });
        }

        invoice.put('LineItems', invoiceLineItems);
        invoiceJson = JSON.serializePretty(invoice);
    }

    public PageReference createInvoice() {
        Invoice__c newInvoice = new Invoice__c();
        if (originRecord != null){
            newInvoice.Account__c = accountId;
        } else if (orderId != null) {
            newInvoice.Account__c = accountIdFinal;
        }       
            
        newInvoice.Invoice_Date__c = parseDate(invoiceDate);
        newInvoice.Due_Date__c = parseDate(invoiceDueDate);

        insert newInvoice;

        List<Line_Item__c> lineItemsToInsert = new List<Line_Item__c>();

        // Inserting OpportunityLineItems
        for (OpportunityLineItem lineItem : opportunityLineItems) {
            lineItemsToInsert.add(new Line_Item__c(
                Invoice__c = newInvoice.Id,
                Line_Description__c = lineItem.Description,
                Quantity__c = lineItem.Quantity,
                Unit_Price__c = lineItem.UnitPrice
            ));
        }

        // Inserting OrderItems
        for (OrderItem lineItem : orderItems) {
            lineItemsToInsert.add(new Line_Item__c(
                Invoice__c = newInvoice.Id,
                Line_Description__c = lineItem.Description,
                Quantity__c = lineItem.Quantity,
                Unit_Price__c = lineItem.UnitPrice
            ));
        }

        if (!lineItemsToInsert.isEmpty()) {
            insert lineItemsToInsert;
        }

        PageReference invoicePage = new PageReference('/' + newInvoice.Id);
        invoicePage.setRedirect(true);
        return invoicePage;
    }

    private Date parseDate(String dateString) {
        try {
            return Date.valueOf(dateString);
        } catch (Exception e) {
            return Date.today();
        }
    }
}
