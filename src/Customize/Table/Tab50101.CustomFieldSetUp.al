/// <summary>
/// Table CustomFieldSetUp (ID 50101).
/// </summary>
table 50101 CustomFieldSetUp
{
    Caption = 'CustomFieldSetUp';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            DataClassification = ToBeClassified;
        }
        field(2; "External Id"; Code[20])
        {
            Caption = 'External Id';
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
        }
        field(3; "Season No"; Code[20])
        {
            Caption = 'Season No';
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
        }
        field(4; "Default Location Code"; Code[20])
        {
            Caption = 'Default Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location;
        }
        field(5; "Default Shipping Service"; Code[20])
        {
            Caption = 'Default Shipping Service';
            DataClassification = CustomerContent;
            TableRelation = Item where(Type = filter(Service));
        }
    }
    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}
