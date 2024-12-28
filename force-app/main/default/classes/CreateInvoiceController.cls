public class CreateInvoiceController {
    // Declare public properties to hold URL parameters and related data
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

    // Constructor to initialize properties based on URL parameters
    public CreateInvoiceController() {
        // Retrieve parameters from the URL
        accountId = ApexPages.currentPage().getParameters().get('account');
        lineItemDescription = ApexPages.currentPage().getParameters().get('line_item_description');
        //childRelationship = ApexPages.currentPage().getParameters().get('child_relationship_name');
        invoiceDate = ApexPages.currentPage().getParameters().get('invoice_date');
        invoiceDueDate = ApexPages.currentPage().getParameters().get('invoice_due_date');
        originRecord = ApexPages.currentPage().getParameters().get('origin_record');
        orderId = ApexPages.currentPage().getParameters().get('order_id');
         childRelationshipName = ApexPages.currentPage().getParameters().get('child_relationship_name');
        
        
        // Debug: Check if the parameter is received correctly
        System.debug('Child Relationship Name: ' + childRelationshipName);

        // Query OpportunityLineItems if originRecord (OpportunityId) is provided
        if (originRecord != null) {
            lineItems = [SELECT Description, Quantity, UnitPrice FROM OpportunityLineItem WHERE OpportunityId = :originRecord];
        }
        if (originRecord != null) {
            isOpportunity = true;
            // Query Opportunity Line Items if an originRecord (OpportunityId) is provided
            lineItems = [SELECT Description, Quantity, UnitPrice FROM OpportunityLineItem WHERE OpportunityId = :originRecord];
        }

        if (orderId != null) {
            isOrder = true;
            // Query Order Items if an orderId is provided
            orderItems = [SELECT Description, Quantity, UnitPrice FROM OrderItem WHERE OrderId = :orderId];
        }
        
    }

   
}