public class CreateInvoiceController {
    
    public String accountId { get; set; }
    public String lineItemDescription { get; set; }
    public String childRelationshipName { get; set; }
    public Decimal lineItemQuantity { get; set; }
    public Decimal lineItemUnitPrice { get; set; }
    public String invoiceDate { get; set; }
    public String invoiceDueDate { get; set; }
    public String originRecord { get; set; }
    public String orderId { get; set; }
    public List<OpportunityLineItem> lineItems { get; set; }
    public List<OrderItem> orderItems { get; set; }
    public Boolean isOpportunity { get; set; }
    	public Boolean isOrder { get; set; }

    
    public CreateInvoiceController() {
        
        accountId = ApexPages.currentPage().getParameters().get('account');
        lineItemDescription = ApexPages.currentPage().getParameters().get('line_item_description');
        
        invoiceDate = ApexPages.currentPage().getParameters().get('invoice_date');
        invoiceDueDate = ApexPages.currentPage().getParameters().get('invoice_due_date');
        originRecord = ApexPages.currentPage().getParameters().get('origin_record');
        orderId = ApexPages.currentPage().getParameters().get('order_id');
         childRelationshipName = ApexPages.currentPage().getParameters().get('child_relationship_name');
        
        
        
        System.debug('Child Relationship Name: ' + childRelationshipName);

        
        if (originRecord != null) {
            lineItems = [SELECT Description, Quantity, UnitPrice FROM OpportunityLineItem WHERE OpportunityId = :originRecord];
        }
        if (originRecord != null) {
            isOpportunity = true;
            
            lineItems = [SELECT Description, Quantity, UnitPrice FROM OpportunityLineItem WHERE OpportunityId = :originRecord];
        }

        if (orderId != null) {
            isOrder = true;
            
            orderItems = [SELECT Description, Quantity, UnitPrice FROM OrderItem WHERE OrderId = :orderId];
        }
        
    }

   
}
