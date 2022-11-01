/// <summary>
/// Codeunit DW_WebService (ID 50100).
/// </summary>
codeunit 50100 HtunWebService
{
    var
        Setup: Record CustomFieldSetUp;
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        Currency: Record "Currency";
        NormalCaseMode: Boolean;
        AllowLineDisc: Boolean;
        AllowInvDisc: Boolean;
        QtyPerUOM: Decimal;
        Qty: Decimal;
        Text002_Lbl: Label 'Prices including VAT cannot be calculated when %1 is %2.';
        VATCalcType: Enum "Tax Calculation Type";
        PricesInclVAT: Boolean;
        VATBusPostingGr: Code[10];
        VATPerCent: Decimal;
        PricesInCurrency: Boolean;
        ExchRateDate: Date;
        CurrencyFactor: Decimal;
        Order_OrderPriceWithVAT: Decimal;
        Order_OrderPriceWithoutVAT: Decimal;
        Order_OrderPriceVAT: Decimal;
        Order_OrderSalesDiscount: Decimal;
        VoucherNo: Text[100];
        VoucherAmount: Decimal;
        HasSalesSetup: Boolean;
        HasSetup: Boolean;
        CustCreditAmountLCY: Decimal;
        OutstandingRetOrdersLCY: Decimal;
        RcdNotInvdRetOrdersLCY: Decimal;
        OrderAmountTotalLCY: Decimal;
        ShippedRetRcdNotIndLCY: Decimal;
        Order_OrderPriceWithVATLCY: Decimal;
        CreateOrder: Boolean;
        Text003_Lbl: Label '%1 %2';
        Text004_Lbl: Label '%1|%2';
        Text005_Lbl: Label '''''';

    /// <summary>
    /// Process.
    /// </summary>
    /// <param name="Request">VAR Text.</param>
    procedure Process(var Request: Text)
    var
        XMLdocIn: XmlDocument;
        xmlElement: XmlElement;
    begin
        ConvertBigTestToXml(XMLdocIn, Request);
        XMLdocIn.GetRoot(xmlElement);

        case xmlElement.LocalName() of
            'GetEcomData':
                GetEcomData(Request, XMLdocIn);
            'CalculateOrder':
                APAC_PutEcomOrdersLive(Request, XMLdocIn);
            else
                Error(StrSubstNo('Method %1 not found', xmlElement.LocalName()));
        end;
    end;

    local procedure GetEcomData(var Request: Text; XMLdocIn: XmlDocument)
    var
        XMLCurrNode: XmlNode;
        XMLdocOut: XmlDocument;
        XMLFilterNode: XmlNodeList;
        XMLItemFilterNode: XmlNodeList;
        XMLCustFilterNode: XmlNodeList;
    begin
        XMLdocOut := XmlDocument.Create();
        AddDeclaration(XMLdocOut, '1.0', 'utf-16', 'yes');
        XMLCurrNode := XmlElement.Create('tables').AsXmlNode();

        if ((Get_TextFromNode(XMLdocIn.AsXmlNode(), '/GetEcomData/@ExternalUserId') <> '') or (Get_TextFromNode(XMLdocIn.AsXmlNode(), '/GetEcomData/@SalesCode') <> '')) then begin
            if (Get_TextFromNode(XMLdocIn.AsXmlNode(), '/GetEcomData/tables/SalesPrices/@type') = 'all') then
                //XMLdocIn.AsXmlNode().SelectNodes('/GetEcomData/@ExternalUserId', XMLCustFilterNode);
                //XMLdocIn.AsXmlNode().SelectNodes('/GetEcomData/tables/SalesPrices/Product', XMLItemFilterNode);
                Add_EcomSalesPrices(XMLCurrNode, XMLFilterNode, copystr(Get_TextFromNode(XMLdocIn.AsXmlNode(), '/GetEcomData/@ExternalUserId'), 1, 20), copystr(Get_TextFromNode(XMLdocIn.AsXmlNode(), '/GetEcomData/@SalesCode'), 1, 20));
        end
        else begin
            if (Get_TextFromNode(XMLdocIn.AsXmlNode(), '/GetEcomData/tables/Season/@type') = 'all') then
                Add_SeasonXML(XMLCurrNode, true, XMLFilterNode);
            if (Get_TextFromNode(XMLdocIn.AsXmlNode(), '/GetEcomData/tables/Season/@type') = 'filter') then begin
                XMLdocIn.AsXmlNode().SelectNodes('/GetEcomData/tables/Season/SeasonCode', XMLFilterNode);
                Add_SeasonXML(XMLCurrNode, false, XMLFilterNode);
            end;
        end;

        XMLdocOut.Add(XMLCurrNode);
        ConvertXmlToBigText(XMLdocOut, Request);
    end;

    local procedure Add_EcomSalesPrices(var XMLCurrNode: XmlNode; XMLFilterNode: XmlNodeList; CustomerNo: Code[20]; SalesCode: Code[20])
    var
        SalesPrice: Record "Price List Line";
        tempSalesPrice: Record "Price List Line" temporary;
        Customer: Record Customer;
        tempCust: Record Customer temporary;
        XMLNewChild: XmlNode;
        xmlElement: XmlElement;
    begin
        tempCust.DeleteAll();
        tempSalesPrice.DeleteAll();
        Clear(SalesPrice);

        if CustomerNo <> '' then
            if not tempCust.Get(CustomerNo) then begin
                if not Customer.Get(CustomerNo) then
                    Error(StrSubstNo('Customer not found %1', CustomerNo));
                tempCust.Init();
                tempCust."No." := CustomerNo;
                tempCust.Insert();
            end;

        if CustomerNo <> '' then begin
            if tempCust.FindSet(false, false) then
                repeat
                    Customer.Get(tempCust."No.");
                    SalesPrice.Reset();

                    if SalesCode <> '' then
                        SalesPrice.SetRange(SalesPrice."Price List Code", SalesCode);
                    SalesPrice.SetRange("Source No.", tempCust."No.");
                    if SalesPrice.FindSet(false, false) then
                        repeat
                            tempSalesPrice := SalesPrice;
                            tempSalesPrice.Insert();
                        until SalesPrice.Next() = 0;
                until tempCust.Next() = 0;
        end
        else
            if SalesCode <> '' then begin
                SalesPrice.Reset();

                SalesPrice.SetRange(SalesPrice."Price List Code", SalesCode);
                if SalesPrice.FindSet(false, false) then
                    repeat
                        tempSalesPrice := SalesPrice;
                        tempSalesPrice.Insert();
                    until SalesPrice.Next() = 0;
            end;

        Add_Element(XMLCurrNode, 'table', '', '', XMLNewChild, '');
        Add_Attribute(XMLNewChild, 'tableName', 'EcomSalesPrice');

        GLSetup.Get();
        if tempSalesPrice.FindSet(false, false) then
            repeat
                Add_Element(XMLNewChild, 'item', '', '', XMLNewChild, '');
                Add_Attribute(XMLNewChild, 'table', 'EcomSalesPrice');

                Add_Field(XMLNewChild, 'ExternalUserId', tempSalesPrice."Source No.");
                Add_Field(XMLNewChild, 'SalesCode', tempSalesPrice."Price List Code");
                Add_Field(XMLNewChild, 'ProductId', tempSalesPrice."Asset No.");
                Add_Field(XMLNewChild, 'ProductName', tempSalesPrice.Description);
                if tempSalesPrice."Currency Code" = '' then
                    tempSalesPrice."Currency Code" := GLSetup."LCY Code";
                Add_Field(XMLNewChild, 'ProductPriceCurrency', tempSalesPrice."Currency Code");
                Add_Field(XMLNewChild, 'ProductUOM', tempSalesPrice."Unit of Measure Code");
                Add_Field(XMLNewChild, 'ProductPriceMinimumQuantity', FORMAT(tempSalesPrice."Minimum Quantity"));
                Add_Field(XMLNewChild, 'ProductPrice', FORMAT(tempSalesPrice."Unit Price"));
                if tempSalesPrice."Price Includes VAT" then
                    Add_Field(XMLNewChild, 'ProductGSTIncluded', 'True')
                else
                    Add_Field(XMLNewChild, 'ProductGSTIncluded', 'False');

                XMLNewChild.GetParent(xmlElement);
                XMLNewChild := xmlElement.AsXmlNode();
                TempSalesPrice."Currency Code" := '';
            until tempSalesPrice.Next() = 0;
    end;

    local procedure Add_SeasonXML(XMLCurrNode: XmlNode; GetAll: Boolean; FilterNodes: XmlNodeList)
    var
        Season: Record Season;
        XMLNewChild: XmlNode;
        xmlElement: XmlElement;
        FilterNode: XmlNode;
        i: Integer;
    begin
        Add_Element(XMLCurrNode, 'table', '', '', XMLNewChild, '');
        Add_Attribute(XMLNewChild, 'tableName', 'Season');
        Clear(Season);

        if GetAll = false then begin
            for i := 1 to FilterNodes.Count() do begin
                FilterNodes.Get(i, FilterNode);
                if Season.Get(FilterNode.AsXmlElement().InnerText()) then
                    Season.Mark(true)
                else
                    Error(StrSubstNo('Season not found %1', FilterNode.AsXmlElement().InnerText()))
            end;
            Season.MarkedOnly(true);
        end;

        if Season.FindSet(false, false) then
            repeat
                Add_Element(XMLNewChild, 'item', '', '', XMLNewChild, '');
                Add_Attribute(XMLNewChild, 'table', 'Season');

                Add_Field(XMLNewChild, 'SeasonCode', Season."Season Code");
                Add_Field(XMLNewChild, 'Description', Season.Description);

                XMLNewChild.GetParent(xmlElement);
                XMLNewChild := xmlElement.AsXmlNode();
            until Season.Next() = 0;
    end;

    local procedure APAC_PutEcomOrdersLive(var Request: Text; XMLdocIn: XmlDocument)
    var
        salesheader: Record "Sales Header";
        salesline: Record "Sales Line";
        salesSetup: Record "Sales & Receivables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        customer: Record "Customer";
        item: Record "Item";
        ContactBusRel: Record "Contact Business Relation";
        Contact1: Record "Contact";
        Contact: Record Contact;
        ItemLackStock: Record "Item" temporary;
        Cust: Record "Customer";
        CustTemplate: Record "Customer Templ.";
        ShippingMethod: Record "Shipment Method";
        PaymentMethod: Record "Payment Method";
        DefaultDim: Record "Default Dimension";
        DefaultDim2: Record "Default Dimension";
        Shipto: Record "Ship-to Address";
        ItemUOM: Record "Item Unit of Measure";
        CurrExchRate: Record "Currency Exchange Rate";
        XMLNodeList: XmlNodeList;
        XMLNodeListLines: XmlNodeList;
        XMLElement2: XmlElement;
        i: Integer;
        u: Integer;
        XMLNode: XmlNode;
        XMLdocOut: XmlDocument;
        XMLCurrNode: XmlNode;
        XMLNewChild: XmlNode;
        lineno: Integer;
        Discount: Decimal;
        Total: Decimal;
        XMLStockNodeListLines: XmlNodeList;
        XMLStockNode: XmlNode;
        OrderShippingFee: Decimal;
        OrderShippingFeeWGST: Decimal;
        ChangeAddress: Boolean;
        LocationFilter: Text[1024];
        CreateCustmer_: Boolean;
        CreateContact: Boolean;
        UseExternaID: Boolean;
    begin
        GetSetup();

        XMLdocOut := XmlDocument.Create();
        AddDeclaration(XMLdocOut, '1.0', 'utf-16', 'yes');
        XMLCurrNode := XmlElement.Create('tables').AsXmlNode();
        CreateOrder := false;
        XMLdocIn.AsXmlNode().SelectNodes('/CalculateOrder/Orders/Order', XMLNodeList);

        for i := 1 to XMLNodeList.Count() do begin
            XMLNodeList.Get(i, XMLNode);
            if (Get_TextFromNode(XMLNode, 'column[@columnName="CreateOrder"]') = 'True') then begin
                CreateOrder := true;
                ItemLackStock.DeleteAll();
                XMLdocIn.AsXmlNode().SelectNodes('/CalculateOrder/OrderLines/OrderLine', XMLStockNodeListLines);
                if LocationFilter = '' then
                    LocationFilter := GetLocationFilter();

                for u := 1 to XMLStockNodeListLines.Count() do begin
                    XMLStockNodeListLines.Get(i, XMLStockNode);
                    // if LocationFilter = '' then
                    // LocationFilter := GetLocationFilter();

                    item.Get(Get_TextFromNode(XMLStockNode, 'column[@columnName=''OrderLineProductID'']'));
                    if not (item.Type = item.Type::Service) then begin
                        if not Cust.Get(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAccessUserExternalId'']')) then
                            item.SetFilter("Location Filter", LocationFilter)
                        else
                            if Cust."Location Code" <> '' then
                                item.SetFilter("Location Filter", Cust."Location Code")
                            else
                                item.SetFilter("Location Filter", LocationFilter);
                        item.CalcFields(Inventory, "Qty. on Sales Order");

                        if item."Base Unit of Measure" <> item."Sales Unit of Measure" then begin
                            ItemUOM.Reset();
                            ItemUOM.SetRange(ItemUOM."Item No.", item."No.");
                            ItemUOM.SetRange(Code, item."Sales Unit of Measure");
                            ItemUOM.FindFirst();
                        end else
                            ItemUOM."Qty. per Unit of Measure" := 1;

                        if ((item.Inventory + item."Qty. on Sales Order") / ItemUOM."Qty. per Unit of Measure") < Get_DecimalFromNode(XMLStockNode, 'column[@columnName=''OrderLineQuantity'']') then begin
                            ItemLackStock.Init();
                            ItemLackStock."No." := item."No.";
                            ItemLackStock."Safety Stock Quantity" := ((item.Inventory + item."Qty. on Sales Order") / ItemUOM."Qty. per Unit of Measure");
                            ItemLackStock.Insert();
                        end;
                    end;
                end;

                if ItemLackStock.FindFirst() then begin
                    Add_Element(XMLCurrNode, 'table', '', '', XMLNewChild, '');
                    Add_Attribute(XMLNewChild, 'tableName', 'EcomOrderError');

                    repeat
                        Add_Element(XMLNewChild, 'item', '', '', XMLNewChild, '');
                        Add_Attribute(XMLNewChild, 'table', 'EcomOrderError');
                        Add_Field(XMLNewChild, 'ErrorProductId', ItemLackStock."No.");
                        Add_Field(XMLNewChild, 'Stock', FORMAT(ItemLackStock."Safety Stock Quantity"));
                        XMLNewChild.GetParent(XMLElement2);
                        XMLNewChild := XMLElement2.AsXmlNode();
                    until ItemLackStock.Next() = 0;

                    XMLdocOut.Add(XMLCurrNode);
                    ConvertXmlToBigText(XMLdocOut, Request);
                    exit;
                end;

                Total := 0;
                Discount := 0;
                Clear(salesheader);
                salesheader.Init();

                salesheader."Document Type" := salesheader."Document Type"::Order;
                salesheader."No." := '';
                salesheader."No. Series" := salesSetup."Order Nos.";
                salesheader.Insert(true);

                CreateContact := false;
                UseExternaID := false;

                if UpperCase(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAccessUserExternalId'']')) <> '' then
                    Cust.Get(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAccessUserExternalId'']'))
                else
                    if Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerNumber'']') <> '' then begin
                        if not Contact.Get(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerNumber'']')) then begin
                            CreateContact := true;
                            UseExternaID := false;
                        end;
                    end
                    else
                        if not Contact.Get(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAccessUserExternalId'']')) then begin
                            CreateContact := true;
                            UseExternaID := true;
                        end;

                if CreateContact then begin
                    Contact.Init();

                    if UseExternaID then
                        Contact."No." := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAccessUserExternalId'']'), 1, 20)
                    else
                        Contact."No." := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerNumber'']'), 1, 20);
                    Contact.Validate(Name, Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerName'']'));
                    Contact.Address := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAddress'']'), 1, 100);
                    Contact."Address 2" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAddress2'']'), 1, 50);
                    Contact.City := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerCity'']'), 1, 30);
                    Contact."Country/Region Code" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerCountryCode'']'), 1, 10);
                    Contact."E-Mail" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerEmail'']'), 1, 80);
                    Contact."Fax No." := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerFax'']'), 1, 30);
                    Contact."Phone No." := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerPhone'']'), 1, 30);
                    Contact."Post Code" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerZip'']'), 1, 20);

                    Contact.Insert(true);
                    Contact.Validate(Type, Contact.Type::Person);
                    ContactBusRel.Reset();
                    ContactBusRel.SetCurrentKey("Link to Table", "No.");
                    ContactBusRel.SetRange("Link to Table", ContactBusRel."Link to Table"::Customer);
                    //T5054.SETRANGE("No.", DynamicwebSetup."Anonymous Customer No.");

                    if ContactBusRel.FindFirst() then begin
                        Contact.Validate("Company No.", ContactBusRel."Contact No.");
                    end;
                    Contact.Modify(true);
                end;

                if not Shipto.Get(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAccessUserExternalId'']'), Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryID'']')) then begin
                    Shipto.Init();
                    Shipto."Customer No." := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAccessUserExternalId'']'), 1, 20);
                    Shipto.Code := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryID'']'), 1, 10);
                    Shipto.Name := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryName'']'), 1, 100);
                    Shipto.Address := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryAddress'']'), 1, 100);
                    Shipto."Address 2" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryAddress2'']'), 1, 50);
                    Shipto.City := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryCity'']'), 1, 30);
                    Shipto."Country/Region Code" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryCountryCode'']'), 1, 10);
                    Shipto."E-Mail" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryEmail'']'), 1, 80);
                    Shipto."Fax No." := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryFax'']'), 1, 30);
                    Shipto."Phone No." := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryPhone'']'), 1, 30);
                    Shipto."Post Code" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryZip'']'), 1, 20);
                    Shipto.Insert();
                end;

                salesheader.Validate("Sell-to Customer No.", Cust."No.");
                ChangeAddress := true;

                if UpperCase(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAccessUserExternalId'']')) <> '' then
                    if Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerNumber'']') <> '' then
                        if Contact1.Get(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerNumber'']')) then begin
                            salesheader.SetHideValidationDialog(true);
                            salesheader.Validate("Sell-to Contact No.", Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerNumber'']'));
                        end;

                if ChangeAddress then begin
                    salesheader."Sell-to Customer Name" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerName'']'), 1, 100);
                    salesheader.Validate("Sell-to Address", Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAddress'']'));
                    salesheader.Validate("Sell-to Address 2", Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAddress2'']'));
                    salesheader.Validate("Sell-to Post Code", Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerZip'']'));
                    salesheader.Validate("Sell-to City", Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerCity'']'));
                    //salesheader."Sell-to Contact No." := Get_TextFromNode(XMLNode,'column[@columnName=''OrderCustomerNumber'']');
                    //salesheader."Sell-to Contact" := Get_TextFromNode(XMLNode,'column[@columnName=''OrderDeliveryName'']');
                end;

                salesheader."Sell-to Phone No." := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerPhone'']'), 1, 30);
                salesheader."Sell-to E-Mail" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerEmail'']'), 1, 100);

                if not ChangeAddress then
                    salesheader.Validate("Ship-to Name", Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryCompany'']'))
                else
                    salesheader.Validate("Ship-to Name", Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryName'']'));

                salesheader.Validate("Ship-to Address", Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryAddress'']'));
                salesheader.Validate("Ship-to Address 2", Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryAddress2'']'));
                salesheader.Validate("Ship-to Post Code", Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryZip'']'));
                salesheader.Validate("Ship-to City", Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryCity'']'));
                salesheader."Ship-to Contact" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryName'']'), 1, 100);

                if Currency.GET(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCurrencyCode'']')) then
                    salesheader.Validate("Currency Code", Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCurrencyCode'']'));

                if salesheader."Location Code" = '' then
                    if Setup."Default Location Code" <> '' then
                        salesheader.Validate("Location Code", Get_TextFromNode(XMLNode, Setup."Default Location Code"));
                /*
                OrderShippingFee := Get_DecimalFromNode(XMLNode, 'column[@columnName=''OrderShippingFee'']');
                OrderShippingFeeWGST := Get_DecimalFromNode(XMLNode, 'column[@columnName=''OrderShippingFeeWithGST'']');
                VoucherNo := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderVoucherNo'']'), 1, 100);
                VoucherAmount := Get_DecimalFromNode(XMLNode, 'column[@columnName=''OrderVoucherAmount'']');
                */
                if Shipto.Code <> '' then
                    salesheader.Validate("Ship-to Code", Shipto.Code);

                salesheader."External Document No." := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderID'']'), 1, 35);

                if not ShippingMethod.Get(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderShippingMethodName'']')) then begin
                    ShippingMethod.Init();
                    ShippingMethod.Code := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderShippingMethodName'']'), 1, 10);
                    ShippingMethod.Insert();
                end;

                if not PaymentMethod.Get(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderPaymentMethodName'']')) then begin
                    PaymentMethod.Init();
                    PaymentMethod.Code := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderPaymentMethodName'']'), 1, 10);
                    PaymentMethod.Insert();
                end;

                salesheader."Shipment Method Code" := ShippingMethod.Code;
                salesheader."Payment Method Code" := PaymentMethod.Code;

                if (salesheader."Sell-to Customer No." = 'ANONYMOUS') then begin
                    salesheader."Sell-to Customer Name" := Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerName'']');
                    salesheader."Sell-to Contact" := Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerName'']');
                    salesheader."Sell-to Address" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAddress'']'), 1, 100);
                    salesheader."Sell-to Address 2" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAddress2'']'), 1, 50);
                    salesheader."Sell-to City" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerCity'']'), 1, 30);
                    salesheader."Sell-to Country/Region Code" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerCountryCode'']'), 1, 10);
                    salesheader."Sell-to Post Code" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerZip'']'), 1, 20);
                    salesheader."Bill-to Name" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerName'']'), 1, 100);
                    salesheader."Bill-to Contact" := Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerName'']');
                    salesheader."Bill-to Address" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAddress'']'), 1, 100);
                    salesheader."Bill-to Address 2" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAddress2'']'), 1, 50);
                    salesheader."Bill-to City" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerCity'']'), 1, 30);
                    salesheader."Bill-to Country/Region Code" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerCountryCode'']'), 1, 10);
                    salesheader."Bill-to Post Code" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerZip'']'), 1, 20);
                    salesheader."Ship-to Name" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryName'']'), 1, 100);
                    salesheader."Ship-to Contact" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryName'']'), 1, 100);
                    salesheader."Ship-to Address" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryAddress'']'), 1, 100);
                    salesheader."Ship-to Address 2" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryAddress2'']'), 1, 50);
                    salesheader."Ship-to City" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryCity'']'), 1, 30);
                    salesheader."Ship-to Country/Region Code" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryCountryCode'']'), 1, 10);
                    salesheader."Ship-to Post Code" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryZip'']'), 1, 20);
                end;

                salesheader.Modify(true);
                lineno := 10000;
                XMLdocIn.AsXmlNode().SelectNodes('/CalculateOrder/OrderLines/OrderLine', XMLNodeListLines);
                Add_Element(XMLCurrNode, 'table', '', '', XMLNewChild, '');
                Add_Attribute(XMLNewChild, 'tableName', 'EcomOrderLines');

                for u := 1 to XMLNodeListLines.Count() do begin
                    XMLNodeListLines.Get(U, XMLNode);
                    salesline.Init();
                    salesline."Document Type" := salesheader."Document Type";
                    salesline."Document No." := salesheader."No.";
                    salesline."Line No." := lineno;
                    salesline.Type := salesline.Type::Item;

                    salesline.Validate("No.", Get_TextFromNode(XMLNode, 'column[@columnName=''OrderLineProductID'']'));
                    salesline.Validate(salesline."Unit of Measure Code", Get_TextFromNode(XMLNode, 'column[@columnName=''OrderLineUnitID'']'));
                    salesline.Validate(Quantity, Get_DecimalFromNode(XMLNode, 'column[@columnName=''OrderLineQuantity'']'));
                    /*
                              IF salesheader."Prices Including VAT" THEN
                                salesline.VALIDATE("Unit Price",Get_DecimalFromNode(XMLNode,'column[@columnName=''OrderLineUnitPriceWithVAT'']'))
                              ELSE
                                salesline.VALIDATE("Unit Price",Get_DecimalFromNode(XMLNode,'column[@columnName=''OrderLineUnitPriceWithoutVAT'']'));
                              */
                    salesline.Insert(true);
                    Add_SalesLine(salesline, salesheader, XMLNewChild, '');

                    if (salesline."Line Discount Amount" <> 0) then
                        Add_SalesLine(salesline, salesheader, XMLNewChild, salesline."No.");
                    lineno += 10000;
                end;

                if (OrderShippingFee <> 0) OR (OrderShippingFeeWGST <> 0) then begin
                    Setup.TestField("Default Shipping Service");

                    salesline.Init();
                    salesline."Document Type" := salesheader."Document Type";
                    salesline."Document No." := salesheader."No.";
                    salesline."Line No." := lineno;
                    salesline.Type := salesline.Type::Item;

                    salesline.Validate("No.", Setup."Default Shipping Service");
                    salesline.Validate(Quantity, 1);

                    if salesheader."Prices Including VAT" then
                        salesline.Validate("Unit Price", OrderShippingFeeWGST)
                    else
                        salesline.Validate("Unit Price", OrderShippingFee);
                    salesline.Insert(true);
                    Add_SalesLine(salesline, salesheader, XMLNewChild, '');

                    if (salesline."Line Discount Amount" <> 0) then
                        Add_SalesLine(salesline, salesheader, XMLNewChild, salesline."No.");
                    lineno += 10000;
                end;
                Add_SalesHeader(salesheader, XMLCurrNode, false, Total, Discount);
            end
            else begin
                ItemLackStock.DeleteAll();
                XMLdocIn.AsXmlNode().SelectNodes('/CalculateOrder/OrderLines/OrderLine', XMLStockNodeListLines);
                if LocationFilter = '' then
                    LocationFilter := GetLocationFilter();

                for u := 1 to XMLStockNodeListLines.Count() do begin
                    XMLStockNodeListLines.Get(U, XMLStockNode);
                    item.Get(Get_TextFromNode(XMLStockNode, 'column[@columnName="OrderLineProductID"]'));
                    if (not (item.Type = item.Type::Service)) then begin
                        if not Cust.Get(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAccessUserExternalId'']')) then
                            item.SetFilter("Location Filter", LocationFilter)
                        else
                            if Cust."Location Code" <> '' then
                                item.SetFilter("Location Filter", Cust."Location Code")
                            else
                                item.SetFilter("Location Filter", LocationFilter);

                        item.CalcFields(Inventory, "Qty. on Sales Order");

                        if item."Base Unit of Measure" <> item."Sales Unit of Measure" then begin
                            ItemUOM.Reset();
                            ItemUOM.SetRange(ItemUOM."Item No.", item."No.");
                            ItemUOM.SetRange(Code, item."Sales Unit of Measure");
                            ItemUOM.FindFirst();
                        end
                        else
                            ItemUOM."Qty. per Unit of Measure" := 1;
                        if ((item.Inventory + item."Qty. on Sales Order") / ItemUOM."Qty. per Unit of Measure") < Get_DecimalFromNode(XMLStockNode, 'column[@columnName=''OrderLineQuantity'']') then begin
                            ItemLackStock.Init();
                            ItemLackStock."No." := item."No.";
                            ItemLackStock."Safety Stock Quantity" := ((item.Inventory + item."Qty. on Sales Order") / ItemUOM."Qty. per Unit of Measure");
                            ItemLackStock.Insert();
                        end;
                    end;
                end;

                if ItemLackStock.FINDFIRST() then begin
                    Add_Element(XMLCurrNode, 'table', '', '', XMLNewChild, '');
                    Add_Attribute(XMLNewChild, 'tableName', 'EcomOrderError');

                    repeat
                        Add_Element(XMLNewChild, 'item', '', '', XMLNewChild, '');
                        Add_Attribute(XMLNewChild, 'table', 'EcomOrderError');
                        Add_Field(XMLNewChild, 'ErrorProductId', ItemLackStock."No.");
                        Add_Field(XMLNewChild, 'Stock', FORMAT(ItemLackStock."Safety Stock Quantity"));
                        XMLNewChild.GetParent(XMLElement2);
                        XMLNewChild := XMLElement2.AsXmlNode();
                    until ItemLackStock.Next() = 0;

                    XMLdocOut.Add(XMLCurrNode);
                    ConvertXmlToBigText(XMLdocOut, Request);
                    exit;
                end;

                salesheader.Init();
                salesheader."Document Type" := salesheader."Document Type"::Order;
                salesheader."No." := '';
                salesheader."Sell-to Customer No." := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAccessUserExternalId'']'), 1, 20);
                salesheader."Sell-to Customer Name" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerName'']'), 1, 100);
                salesheader."Sell-to Address" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAddress'']'), 1, 100);
                salesheader."Sell-to Address 2" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAddress2'']'), 1, 50);
                salesheader."Sell-to Post Code" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerZip'']'), 1, 20);
                salesheader."Sell-to City" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerCity'']'), 1, 30);
                salesheader."Ship-to Name" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryName'']'), 1, 100);
                salesheader."Ship-to Address" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryAddress'']'), 1, 100);
                salesheader."Ship-to Address 2" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryAddress2'']'), 1, 50);
                salesheader."Ship-to Post Code" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryZip'']'), 1, 20);
                salesheader."Ship-to City" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderDeliveryCity'']'), 1, 30);
                salesheader."Sell-to Phone No." := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerPhone'']'), 1, 30);

                if Currency.Get(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCurrencyCode'']')) then
                    salesheader.Validate("Currency Code", Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCurrencyCode'']'));
                if salesheader."Location Code" = '' then
                    if Setup."Default Location Code" <> '' then
                        salesheader.Validate("Location Code", Setup."Default Location Code");
                /*
                OrderShippingFee := Get_DecimalFromNode(XMLNode, 'column[@columnName=''OrderShippingFee'']');
                OrderShippingFeeWGST := Get_DecimalFromNode(XMLNode, 'column[@columnName=''OrderShippingFeeWithGST'']');
                VoucherNo := CopyStr(get_TextFromNode(XMLNode, 'column[@columnName=''OrderVoucherNo'']'), 1, 100);
                VoucherAmount := Get_DecimalFromNode(XMLNode, 'column[@columnName=''OrderVoucherAmount'']');
                */
                salesheader."Ship-to Code" := Shipto.Code;
                salesheader."External Document No." := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderID'']'), 1, 35);

                if not ShippingMethod.Get(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderShippingMethodName'']')) then begin
                    ShippingMethod.Init();
                    ShippingMethod.Code := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderShippingMethodName'']'), 1, 10);
                    ShippingMethod.Insert();
                end;

                if not PaymentMethod.Get(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderPaymentMethodName'']')) then begin
                    PaymentMethod.Init();
                    PaymentMethod.Code := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderPaymentMethodName'']'), 1, 10);
                    PaymentMethod.Insert();
                end;

                salesheader."Shipment Method Code" := ShippingMethod.Code;
                salesheader."Payment Method Code" := PaymentMethod.Code;

                customer.Get(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderCustomerAccessUserExternalId'']'));
                salesheader."Prices Including VAT" := customer."Prices Including VAT";
                lineno := 10000;
                XMLdocIn.AsXmlNode().SelectNodes('/CalculateOrder/OrderLines/OrderLine', XMLNodeListLines);
                Add_Element(XMLCurrNode, 'table', '', '', XMLNewChild, '');
                Add_Attribute(XMLNewChild, 'tableName', 'EcomOrderLines');

                for u := 1 to XMLNodeListLines.Count() do begin
                    XMLNodeListLines.Get(u, XMLNode);
                    item.Get(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderLineProductID'']'));
                    salesline.Init();

                    salesline."Document Type" := salesheader."Document Type";
                    salesline."Document No." := salesheader."No.";
                    salesline."Line No." := lineno;
                    salesline.Type := salesline.Type::Item;
                    salesline."No." := item."No.";
                    salesline."Unit of Measure Code" := CopyStr(Get_TextFromNode(XMLNode, 'column[@columnName=''OrderLineUnitID'']'), 1, 10);
                    salesline.Quantity := Get_DecimalFromNode(XMLNode, 'column[@columnName=''OrderLineQuantity'']');
                    salesline."Qty. per Unit of Measure" := 1;

                    customer.Get(salesheader."Sell-to Customer No.");
                    item.Get(salesline."No.");
                    VATPostingSetup.Get(customer."VAT Bus. Posting Group", item."VAT Prod. Posting Group");
                    AllowLineDisc := customer."Allow Line Disc.";
                    AllowInvDisc := false;
                    Qty := salesline.Quantity;
                    QtyPerUOM := 1;
                    VATCalcType := VATPostingSetup."VAT Calculation Type";
                    PricesInclVAT := customer."Prices Including VAT";
                    VATBusPostingGr := customer."VAT Bus. Posting Group";
                    VATPerCent := VATPostingSetup."VAT %";
                    PricesInCurrency := true;
                    salesline."VAT %" := VATPostingSetup."VAT %";
                    ExchRateDate := Today();
                    GLSetup.Get();
                    if Currency.Get(salesheader."Currency Code") then begin
                        Currency.SetRecFilter();
                        CurrencyFactor := CurrExchRate.ExchangeRate(ExchRateDate, Currency.Code);
                    end
                    else
                        CurrencyFactor := 1;
                    /*
                    CLEAR(TempSalesPrice);
                    CLEAR(TempSalesLineDisc);
                    TempSalesPrice.DELETEALL();
                    TempSalesLineDisc.DELETEALL();
                    pricemgt.FindSalesLineDisc(TempSalesLineDisc, customer."No.", '', customer."Customer Disc. Group", '', item."No.", item."Item Disc. Group", '', salesline."Unit of Measure Code", Currency.Code, ExchRateDate, FALSE);
                    CalcBestLineDisc(TempSalesLineDisc);
                    LineDiscPerCent := TempSalesLineDisc."Line Discount %";
                    salesline."Line Discount %" := TempSalesLineDisc."Line Discount %";
                    pricemgt.FindSalesPrice(TempSalesPrice, customer."No.", '', customer."Customer Price Group", '', item."No.", '', salesline."Unit of Measure Code", Currency.Code, ExchRateDate, FALSE);
                    CalcBestUnitPrice(TempSalesPrice, item);
                    LineDiscPerCent := 0;
                    salesline."Unit Price" := CalcLineAmount(TempSalesPrice);
                    LineDiscPerCent := TempSalesLineDisc."Line Discount %";
                    salesline."Line Discount Amount" := ROUND(ROUND(salesline.Quantity * TempSalesPrice."Unit Price", Currency."Amount Rounding Precision") * LineDiscPerCent / 100, Currency."Amount Rounding Precision");
                    Add_SalesLine(salesline, salesheader, XMLNewChild, '');
                    IF (salesline."Line Discount Amount" <> 0) THEN Add_SalesLine(salesline, salesheader, XMLNewChild, salesline."No.");
                    lineno += 10000;
                    */
                end;

                Add_SalesHeader(salesheader, XMLCurrNode, TRUE, Total, Discount);
            end;
        end;
        XMLdocOut.Add(XMLCurrNode);
        ConvertXmlToBigText(XMLdocOut, Request);
    end;

    local procedure Add_SalesHeader(salesheader: Record "Sales Header"; var XMLCurrNode: XmlNode; tempoary: Boolean; var Total: Decimal; var Discount: Decimal)
    var
        XMLNewChild: XmlNode;
    begin
        Add_Element(XMLCurrNode, 'table', '', '', XMLNewChild, '');
        Add_Attribute(XMLNewChild, 'tableName', 'EcomOrders');
        Add_Element(XMLNewChild, 'item', '', '', XMLNewChild, '');
        Add_Attribute(XMLNewChild, 'table', 'EcomOrders');

        if tempoary = false then
            Add_Field(XMLNewChild, 'OrderCreated', 'True')
        else
            Add_Field(XMLNewChild, 'OrderCreated', 'False');
        Add_Field(XMLNewChild, 'OrderID', salesheader."No.");
        Add_Field(XMLNewChild, 'OrderCurrencyCode', salesheader."Currency Code");
        Add_Field(XMLNewChild, 'OrderDate', Format(salesheader."Order Date"));
        Add_Field(XMLNewChild, 'OrderPaymentMethodName', salesheader."Payment Method Code");
        Add_Field(XMLNewChild, 'OrderShippingMethodName', salesheader."Shipment Method Code");
        Add_Field(XMLNewChild, 'OrderCustomerName', salesheader."Sell-to Customer Name");
        Add_Field(XMLNewChild, 'OrderCustomerAddress', salesheader."Sell-to Address");
        Add_Field(XMLNewChild, 'OrderCustomerAddress2', salesheader."Sell-to Address 2");
        Add_Field(XMLNewChild, 'OrderCustomerCity', salesheader."Sell-to City");
        Add_Field(XMLNewChild, 'OrderCustomerNumber', salesheader."Sell-to Contact No.");
        Add_Field(XMLNewChild, 'OrderCustomerEmail', salesheader."Sell-to E-Mail");
        Add_Field(XMLNewChild, 'OrderCustomerFax', salesheader.GetSellToCustomerFaxNo());
        Add_Field(XMLNewChild, 'OrderCustomerPhone', salesheader."Sell-to Phone No.");
        Add_Field(XMLNewChild, 'OrderCustomerZip', salesheader."Ship-to Post Code");
        Add_Field(XMLNewChild, 'OrderDeliveryName', salesheader."Ship-to Name");
        Add_Field(XMLNewChild, 'OrderDeliveryAddress', salesheader."Ship-to Address");
        Add_Field(XMLNewChild, 'OrderDeliveryAddress2', salesheader."Ship-to Address 2");
        Add_Field(XMLNewChild, 'OrderDeliveryCity', salesheader."Ship-to City");
        Add_Field(XMLNewChild, 'OrderDeliveryCountryCode', salesheader."Ship-to Country/Region Code");
        Add_Field(XMLNewChild, 'OrderDeliveryEmail', salesheader."Ship-to Email");
        Add_Field(XMLNewChild, 'OrderDeliveryFax', '');
        Add_Field(XMLNewChild, 'OrderDeliveryPhone', salesheader."Ship-to Phone No");
        Add_Field(XMLNewChild, 'OrderDeliveryZip', salesheader."Ship-to Post Code");
        Add_Field(XMLNewChild, 'OrderPriceWithVAT', Format(Order_OrderPriceWithVAT));
        Add_Field(XMLNewChild, 'OrderPriceWithoutVAT', Format(Order_OrderPriceWithoutVAT));
        Add_Field(XMLNewChild, 'OrderPriceVAT', Format(Order_OrderPriceVAT));
        Add_Field(XMLNewChild, 'OrderSalesDiscount', Format(Order_OrderSalesDiscount));
        Add_Field(XMLNewChild, 'OrderVoucherNo', Format(VoucherNo));
        Add_Field(XMLNewChild, 'OrderVoucherAmount', Format(VoucherAmount));

        Order_OrderPriceWithVATLCY := Order_OrderPriceWithVAT;
        if salesheader."Currency Factor" <> 0 then
            Order_OrderPriceWithVATLCY := Order_OrderPriceWithVATLCY / salesheader."Currency Factor";
        if not CreateOrder then begin
            if CheckCrLimit(salesheader."Sell-to Customer No.") then
                Add_Field(XMLNewChild, 'CreditLimit', 'True')
            else
                Add_Field(XMLNewChild, 'CreditLimit', 'False');
        end
        else
            Add_Field(XMLNewChild, 'CreditLimit', '');
    end;

    local procedure Add_SalesLine(salesLine: Record "Sales Line"; salesheader: Record "Sales Header"; var XMLNewChild: XmlNode; Parent: Code[20])
    var
        TempWithWAT: Decimal;
        TempWithoutWAT: Decimal;
        XMLElement: XmlElement;
    begin
        if salesheader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(salesheader."Currency Code");

        Add_Element(XMLNewChild, 'item', '', '', XMLNewChild, '');
        Add_Attribute(XMLNewChild, 'table', 'EcomOrderLines');
        Add_Field(XMLNewChild, 'OrderLineProductNumber', salesLine."No.");
        Add_Field(XMLNewChild, 'OrderLineProductVariantID', salesLine."Variant Code");
        Add_Field(XMLNewChild, 'StockUnitID', salesLine."Unit of Measure Code");

        if Parent <> '' then begin
            Add_Field(XMLNewChild, 'OrderLineParentLineID', Format(salesLine."Line No."));
            Add_Field(XMLNewChild, 'OrderLineType', '3');
            Add_Field(XMLNewChild, 'OrderLineQuantity', '1');

            if salesheader."Prices Including VAT" then begin
                TempWithWAT := salesLine."Line Discount Amount";
                Order_OrderSalesDiscount := Order_OrderSalesDiscount + salesLine."Line Discount Amount";
                Add_Field(XMLNewChild, 'OrderLinePriceWithVAT', Format(salesLine."Line Discount Amount"));
                TempWithoutWAT := salesLine."Line Discount Amount" / (1 + (salesLine."VAT %" / 100));
                Add_Field(XMLNewChild, 'OrderLinePriceWithoutVAT', Format(TempWithoutWAT));
            end
            else begin
                TempWithoutWAT := salesLine."Line Discount Amount";
                Order_OrderSalesDiscount := Order_OrderSalesDiscount + salesLine."Line Discount Amount";
                Add_Field(XMLNewChild, 'OrderLinePriceWithoutVAT', Format(salesLine."Line Discount Amount"));
                TempWithWAT := salesLine."Line Discount Amount" * (1 + (salesLine."VAT %" / 100));
                Add_Field(XMLNewChild, 'OrderLinePriceWithVAT', Format(TempWithWAT));
            end;

            Order_OrderPriceWithoutVAT := Order_OrderPriceWithoutVAT - TempWithoutWAT;
            Order_OrderPriceWithVAT := Order_OrderPriceWithVAT - TempWithWAT;
            Add_Field(XMLNewChild, 'OrderLineDiscountPercentage', Format(salesLine."Line Discount %"));
            Add_Field(XMLNewChild, 'OrderLinePriceVAT', Format(TempWithWAT - TempWithoutWAT));
            Order_OrderPriceVAT := Order_OrderPriceVAT - (TempWithWAT - TempWithoutWAT);
            Add_Field(XMLNewChild, 'OrderLinePriceVATPercent', Format(salesLine."VAT %"));
            Add_Field(XMLNewChild, 'OrderLineUnitPriceVATPercent', Format(salesLine."VAT %"));
        end
        else begin
            Add_Field(XMLNewChild, 'OrderLineID', Format(salesLine."Line No."));
            Add_Field(XMLNewChild, 'OrderLineQuantity', Format(salesLine.Quantity));
            Add_Field(XMLNewChild, 'OrderLineType', '0');
            if salesheader."Prices Including VAT" then begin
                TempWithWAT := salesLine."Unit Price" * salesLine.Quantity;
                Add_Field(XMLNewChild, 'OrderLinePriceWithVAT', Format(TempWithWAT));
                Order_OrderPriceWithVAT := Order_OrderPriceWithVAT + TempWithWAT;

                Add_Field(XMLNewChild, 'OrderLineUnitPriceWithVAT', Format(salesLine."Unit Price"));

                TempWithoutWAT := ((salesLine."Unit Price" * salesLine.Quantity) / (1 + (salesLine."VAT %" / 100)));
                Add_Field(XMLNewChild, 'OrderLinePriceWithoutVAT', Format(TempWithoutWAT));
                Order_OrderPriceWithoutVAT := Order_OrderPriceWithoutVAT + TempWithoutWAT;
                Add_Field(XMLNewChild, 'OrderLineUnitPriceWithoutVAT', Format(salesLine."Unit Price" / (1 + (salesLine."VAT %" / 100))));
            end
            else begin
                TempWithoutWAT := salesLine."Unit Price" * salesLine.Quantity;
                Add_Field(XMLNewChild, 'OrderLinePriceWithoutVAT', Format(TempWithoutWAT));
                Order_OrderPriceWithoutVAT := Order_OrderPriceWithoutVAT + TempWithoutWAT;

                Add_Field(XMLNewChild, 'OrderLineUnitPriceWithoutVAT', Format(salesLine."Unit Price"));

                TempWithWAT := ((salesLine."Unit Price" * salesLine.Quantity) * (1 + (salesLine."VAT %" / 100)));
                Add_Field(XMLNewChild, 'OrderLinePriceWithVAT', Format(TempWithWAT));
                Order_OrderPriceWithVAT := Order_OrderPriceWithVAT + TempWithWAT;
                Add_Field(XMLNewChild, 'OrderLineUnitPriceWithVAT', Format(salesLine."Unit Price" * (1 + (salesLine."VAT %" / 100))));
            end;

            Add_Field(XMLNewChild, 'OrderLinePriceVAT', Format(TempWithWAT - TempWithoutWAT));
            Order_OrderPriceVAT := Order_OrderPriceVAT + (TempWithWAT - TempWithoutWAT);
            Add_Field(XMLNewChild, 'OrderLineUnitPriceVAT', Format((TempWithWAT - TempWithoutWAT) / salesLine.Quantity));
            Add_Field(XMLNewChild, 'OrderLinePriceVATPercent', Format(salesLine."VAT %"));
            Add_Field(XMLNewChild, 'OrderLineUnitPriceVATPercent', Format(salesLine."VAT %"));
        end;
        XMLNewChild.GetParent(XMLElement);
        XMLNewChild := XMLElement.AsXmlNode();
    end;

    /// <summary>
    /// AddDeclaration.
    /// </summary>
    /// <param name="pXMLDocument">VAR XmlDocument.</param>
    /// <param name="pVersion">Text.</param>
    /// <param name="pEncoding">Text.</param>
    /// <param name="pStandalone">Text.</param>
    Local procedure AddDeclaration(var pXMLDocument: XmlDocument; pVersion: Text; pEncoding: Text; pStandalone: Text)
    var
        lXmlDeclaration: XmlDeclaration;
    begin
        lXmlDeclaration := XmlDeclaration.Create(pVersion, pEncoding, pStandalone);
        pXMLDocument.SetDeclaration(lXmlDeclaration);
    end;

    local procedure ConvertBigTestToXml(var XMLdoc: XmlDocument; var bigtext: Text)
    begin
        XmlDocument.ReadFrom(bigtext, XMLdoc);
    end;

    local procedure ConvertXmlToBigText(XMLdoc: XmlDocument; var bigtext: Text)
    begin
        CLEAR(bigtext);
        XMLdoc.WriteTo(bigtext);
    end;

    local procedure Get_TextFromNode(XMLnode: XmlNode; xpath: Text[1024]): Text
    begin
        if XMLnode.SelectSingleNode(xpath, XMLnode) then
            if XMLnode.IsXmlAttribute() then
                exit(XMLnode.AsXmlAttribute().Value())
            else
                if XMLnode.IsXmlElement() then
                    exit(XMLnode.AsXmlElement().InnerText())
                else
                    exit('');
        exit('');
    end;

    local procedure Get_DecimalFromNode(XMLnode: XmlNode; xpath: Text[1024]): Decimal
    var
        tempdecimal: Decimal;
    begin
        if not Evaluate(tempdecimal, Get_TextFromNode(XMLnode, xpath)) then exit(0);
        exit(tempdecimal);
    end;

    /// <summary>
    /// CheckCrLimit.
    /// </summary>
    /// <param name="CustNo">Code[20].</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure CheckCrLimit(CustNo: Code[20]): Boolean
    var
        Cust: Record "Customer";
    begin
        GetSalesSetup();
        if SalesSetup."Credit Warnings" = SalesSetup."Credit Warnings"::"No Warning" then
            exit(true);

        if CustNo = '' then
            exit(true);

        Cust.Get(CustNo);
        if SalesSetup."Credit Warnings" in [SalesSetup."Credit Warnings"::"Both Warnings", SalesSetup."Credit Warnings"::"Credit Limit"] THEN BEGIN
            CalcCreditLimitLCY(Cust);
            if (CustCreditAmountLCY > Cust."Credit Limit (LCY)") and (Cust."Credit Limit (LCY)" <> 0) then
                exit(false);
        end;
        exit(true);
    end;

    local procedure CalcCreditLimitLCY(var Cust: Record "Customer")
    begin
        if Cust.GetFilter(Cust."Date Filter") = '' then
            Cust.SetFilter(Cust."Date Filter", '..%1', WorkDate());

        Cust.CalcFields(Cust."Balance (LCY)", Cust."Shipped Not Invoiced (LCY)", Cust."Serv Shipped Not Invoiced(LCY)");
        CalcReturnAmounts(OutstandingRetOrdersLCY, RcdNotInvdRetOrdersLCY, Cust."No.");
        OrderAmountTotalLCY := CalcTotalOutstandingAmt(Cust) - OutstandingRetOrdersLCY;
        ShippedRetRcdNotIndLCY := Cust."Shipped Not Invoiced (LCY)" + Cust."Serv Shipped Not Invoiced(LCY)" - RcdNotInvdRetOrdersLCY;
        CustCreditAmountLCY := Cust."Balance (LCY)" + Cust."Shipped Not Invoiced (LCY)" + Cust."Serv Shipped Not Invoiced(LCY)" - RcdNotInvdRetOrdersLCY + OrderAmountTotalLCY + Order_OrderPriceWithVATLCY - Cust.GetInvoicedPrepmtAmountLCY();
    end;

    /// <summary>
    /// CalcReturnAmounts.
    /// </summary>
    /// <param name="OutstandingRetOrdersLCY2">VAR Decimal.</param>
    /// <param name="RcdNotInvdRetOrdersLCY2">VAR Decimal.</param>
    /// <param name="CustNo">Code[20].</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure CalcReturnAmounts(var OutstandingRetOrdersLCY2: Decimal; var RcdNotInvdRetOrdersLCY2: Decimal; CustNo: Code[20]): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Reset();
        SalesLine.SetCurrentKey("Document Type", "Bill-to Customer No.", "Currency Code");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Bill-to Customer No.", CustNo);
        SalesLine.CalcSums("Outstanding Amount (LCY)", "Return Rcd. Not Invd. (LCY)");
        OutstandingRetOrdersLCY2 := SalesLine."Outstanding Amount (LCY)";
        RcdNotInvdRetOrdersLCY2 := SalesLine."Return Rcd. Not Invd. (LCY)";
    end;

    local procedure CalcTotalOutstandingAmt(var Cust: Record "Customer"): Decimal
    var
    begin
        Cust.CalcFields(Cust."Outstanding Invoices (LCY)", Cust."Outstanding Orders (LCY)", Cust."Outstanding Serv.Invoices(LCY)", Cust."Outstanding Serv. Orders (LCY)");
        exit(Cust."Outstanding Orders (LCY)" + Cust."Outstanding Invoices (LCY)" + Cust."Outstanding Serv. Orders (LCY)" + Cust."Outstanding Serv.Invoices(LCY)");
    end;

    local procedure GetSalesSetup()
    begin
        if not HasSalesSetup then SalesSetup.Get();
        HasSalesSetup := TRUE;
    end;

    local procedure Add_Element(var XMLNode: XmlNode; NodeName: Text[250]; NodeText: Text; NameSpace: Text[1000]; var CreatedXMLNode: XmlNode; prefix: Text[30])
    var
        NewChildNode: XmlNode;
    begin
        if not NormalCaseMode then if prefix <> '' then NodeName := Copystr(prefix + ':' + NodeName, 1, 250);
        NewChildNode := XmlElement.Create(NodeName, NodeText).AsXmlNode();
        XMLNode.AsXmlElement().Add(NewChildNode);
        CreatedXMLNode := NewChildNode;
    end;

    local procedure Add_Attribute(var XMLNode: XmlNode; Name: Text[260]; NodeValue: Text[260])
    var
    begin
        XMLNode.AsXmlElement().SetAttribute(Name, NodeValue);
    end;

    local procedure Add_Field(var XMLNode: XmlNode; "Field": Text[1024]; Value: Text[1024])
    var
        XmlNewChild: XmlNode;
        xmlElement: XmlElement;
    begin
        Add_Element(XMLNode, 'column', '', '', XmlNewChild, '');
        Add_Attribute(XmlNewChild, 'columnName', copystr(Field, 1, 260));
        Add_CdataElement(XmlNewChild, Value);
        XmlNewChild.GetParent(xmlElement);
        XmlNewChild := xmlElement.AsXmlNode();
    end;

    local procedure Add_CdataElement(var XMLNode: XmlNode; NodeText: Text[1024])
    var
        cdata: XmlCData;
    begin
        cdata := XmlCData.Create(NodeText);
        XMLNode.AsXmlElement().Add(cdata);
    end;

    local procedure Get_SingleNodevalue(xmlnode: XmlNode; id: text): Text
    var
        datanode: XmlNode;
    begin
        xmlnode.AsXmlElement().SelectSingleNode(id, datanode);
        exit(datanode.AsXmlElement().InnerText());
    end;

    local procedure SetNormalCase()
    begin
        NormalCaseMode := true;
    end;

    local procedure GetLocationFilter() LocationFilter: Text[1024]
    var
        lLocation: Record "Location";
    begin
        Clear(LocationFilter);
        GetSetup();
        if Setup."Default Location Code" <> '' then
            LocationFilter := Setup."Default Location Code"
        else
            LocationFilter := Text005_Lbl;
        lLocation.Reset();
    end;

    local procedure GetSetup()
    begin
        if not HasSetup then Setup.GET();
        HasSetup := true;
    end;
}