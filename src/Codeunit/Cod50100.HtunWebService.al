/// <summary>
/// Codeunit DW_WebService (ID 50100).
/// </summary>
codeunit 50100 HtunWebService
{
    var
        NormalCaseMode: Boolean;
        GLSetup: Record "General Ledger Setup";
        CreateOrder: Boolean;
        Setup: Record CustomFieldSetUp;
        HasSetup: Boolean;
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
        VATPostingSetup: Record "VAT Posting Setup";
        customer: Record "Customer";
        item: Record "Item";
        T5054: Record "Contact Business Relation";
        T5050: Record "Contact";
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