/// <summary>
/// Codeunit DW_WebService (ID 50100).
/// </summary>
codeunit 50100 DW_WebService
{
    var
        NormalCaseMode: Boolean;
        GLSetup: Record "General Ledger Setup";

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
            else
                Error(StrSubstNo('Method %1 not found', xmlElement.LocalName()));
        end;
    end;

    local procedure GetEcomData(var Request: Text; XMLdocIn: XmlDocument)
    var
        XMLCurrNode: XmlNode;
        XMLdocOut: XmlDocument;
        XMLFilterNode: XmlNodeList;
    begin
        XMLdocOut := XmlDocument.Create();
        AddDeclaration(XMLdocOut, '1.0', 'utf-16', 'yes');
        XMLCurrNode := XmlElement.Create('tables').AsXmlNode();

        if (Get_TextFromNode(XMLdocIn.AsXmlNode(), '/GetEcomData/@SalesCode') <> '') then begin
            if (Get_TextFromNode(XMLdocIn.AsXmlNode(), '/GetEcomData/tables/SalesPrices/@type') = 'all') then
                Add_EcomSalesPrices(XMLCurrNode, true, XMLFilterNode);
            if (Get_TextFromNode(XMLdocIn.AsXmlNode(), '/GetEcomData/tables/SalesPrices/@type') = 'filter') then begin
                XMLdocIn.AsXmlNode().SelectNodes('/GetEcomData/tables/SalesPrices/SalesCode', XMLFilterNode);
                Add_EcomSalesPrices(XMLCurrNode, false, XMLFilterNode);
            end;
        end
        else begin
            if (Get_TextFromNode(XMLdocIn.AsXmlNode(), '/GetEcomData/tables/Season/@type') = 'all') then
                Add_SeasonXML(XMLCurrNode, true, XMLFilterNode);
        end;

        XMLdocOut.Add(XMLCurrNode);
        ConvertXmlToBigText(XMLdocOut, Request);
    end;

    local procedure Add_EcomSalesPrices(XMLCurrNode: XmlNode; GetAll: Boolean; FilterNodes: XmlNodeList)
    var
        SalesPrice: Record "Price List Line";
        XMLNewChild: XmlNode;
        xmlElement: XmlElement;
        FilterNode: XmlNode;
        i: Integer;
    begin
        Add_Element(XMLCurrNode, 'table', '', '', XMLNewChild, '');
        Add_Attribute(XMLNewChild, 'tableName', 'EcomSalesPrice');
        Clear(SalesPrice);

        if GetAll = false then begin
            for i := 1 to FilterNodes.Count() do begin
                FilterNodes.Get(i, FilterNode);
                if SalesPrice.Get(FilterNode.AsXmlElement().InnerText()) then
                    SalesPrice.Mark(true)
                else
                    Error(StrSubstNo('Sales price not found %1', FilterNode.AsXmlElement().InnerText()))
            end;
            SalesPrice.MarkedOnly(true);
        end;

        if SalesPrice.FindSet(false, false) then
            repeat
                Add_Element(XMLNewChild, 'item', '', '', XMLNewChild, '');
                Add_Attribute(XMLNewChild, 'table', 'EcomSalesPrice');

                Add_Field(XMLNewChild, 'Code', SalesPrice."Price List Code");
                Add_Field(XMLNewChild, 'ProductId', SalesPrice."Asset No.");
                Add_Field(XMLNewChild, 'ProductNumber', SalesPrice."Asset No.");
                if SalesPrice."Currency Code" = '' then
                    SalesPrice."Currency Code" := GLSetup."LCY Code";
                Add_Field(XMLNewChild, 'ProductPriceCurrency', SalesPrice."Currency Code");
                Add_Field(XMLNewChild, 'ProductUOM', SalesPrice."Unit of Measure Code");
                Add_Field(XMLNewChild, 'ProductPriceMinimumQuantity', FORMAT(SalesPrice."Minimum Quantity"));
                Add_Field(XMLNewChild, 'ProductPrice', FORMAT(SalesPrice."Unit Price"));
                if SalesPrice."Price Includes VAT" then
                    Add_Field(XMLNewChild, 'ProductGSTIncluded', 'True')
                else
                    Add_Field(XMLNewChild, 'ProductGSTIncluded', 'False');

                XMLNewChild.GetParent(xmlElement);
                XMLNewChild := xmlElement.AsXmlNode();
            until SalesPrice.Next() = 0;
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
            IF XMLnode.IsXmlAttribute() then
                exit(XMLnode.AsXmlAttribute().Value())
            else
                if XMLnode.IsXmlElement() then
                    exit(XMLnode.AsXmlElement().InnerText())
                else
                    exit('');
        exit('');
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

    local procedure SetNormalCase()
    begin
        NormalCaseMode := true;
    end;
}
