/// <summary>
/// Table CustomFieldSetUp (ID 50101).
/// </summary>
table 50101 CustomFieldSetUp
{
    Caption = 'CustomFieldSetUp';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = ToBeClassified;
        }
        field(2; "DW Id"; Code[20])
        {
            Caption = 'DW Id';
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
        }
        field(3; "Season No"; Code[20])
        {
            Caption = 'Season No';
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
        }
    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
