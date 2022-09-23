/// <summary>
/// Table Season (ID 50100).
/// </summary>
table 50100 Season
{
    Caption = 'Season';
    DataClassification = ToBeClassified;
    
    fields
    {
        field(1; "Season Code"; Code[10])
        {
            Caption = 'Season Code';
            DataClassification = ToBeClassified;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = ToBeClassified;
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = ToBeClassified;
        }
        field(4; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; "Season Code")
        {
            Clustered = true;
        }
    }
}
