/// <summary>
/// TableExtension ItemTableExt (ID 50100) extends Record Item.
/// </summary>
tableextension 50100 ItemTableExt extends Item
{
    fields
    {
        field(50100; Remark; Text[50])
        {
            Caption = 'Remark';
            DataClassification = ToBeClassified;
        }
        field(50101; "Sales Type"; Option)
        {
            Caption = 'Sales Type';
            OptionMembers = Regular,Special;
            DataClassification = ToBeClassified;
        }
        field(50102; Ecommerce; Boolean)
        {
            Caption = 'Ecommerce';
            DataClassification = ToBeClassified;
        }
        field(50103; MFG; Code[3])
        {
            Caption = 'MFG';
            DataClassification = ToBeClassified;
        }
        field(50104; "Competitive Price"; Decimal)
        {
            Caption = 'Competitive Price';
            DataClassification = ToBeClassified;
        }
        field(50105; Rate; Integer)
        {
            Caption = 'Rate';
            DataClassification = ToBeClassified;
        }
        field(50106; "Life Cycle Starting Date"; Date)
        {
            Caption = 'Life Cycle Starting Date';
            DataClassification = ToBeClassified;
        }
        field(50207; "Lead Time"; DateFormula)
        {
            Caption = 'Lead Time';
            DataClassification = ToBeClassified;
        }
        field(50208; "Life Cycle Ending Date"; Date)
        {
            Caption = 'Life Cycle Ending Date';
            DataClassification = ToBeClassified;
        }
        field(50209; "Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
        }
        field(50210; Season; Code[10])
        {
            Caption = 'Season';
            DataClassification = ToBeClassified;
        }
        field(50211; "Brand Code"; Code[20])
        {
            Caption = 'Brand Code';
            DataClassification = ToBeClassified;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(50212; "Repair Item"; Boolean)
        {
            Caption = 'Rapair Item';
            DataClassification = ToBeClassified;
        }
    }
}
