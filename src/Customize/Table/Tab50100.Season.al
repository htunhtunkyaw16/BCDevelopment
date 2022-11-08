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

            trigger OnValidate()
            begin
                if "Season Code" <> Rec."Season Code" then begin
                    CusFieldSetup.Get();
                    NoSeriesMgt.TestManual(CusFieldSetup."Season No");
                    "No. Series" := '';
                end;
            end;
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
        field(5; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
    }
    keys
    {
        key(PK; "Season Code")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled);
        if IsHandled then
            exit;
        if "Season Code" = '' then begin
            CusFieldSetup.Get();
            CusFieldSetup.TestField("Season No");
            NoSeriesMgt.InitSeries(CusFieldSetup."Season No", xRec."No. Series", WorkDate(), "Season Code", "No. Series");
        end;
    end;

    var
        CusFieldSetup: Record CustomFieldSetUp;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        sales: Record "Price List Header";

    /// <summary>
    /// AssitEdit.
    /// </summary>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure AssitEdit() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, xRec, Result, IsHandled);
        if IsHandled then
            exit(Result);
        CusFieldSetup.Get();
        CusFieldSetup.TestField("Season No");
        if NoSeriesMgt.SelectSeries(CusFieldSetup."Season No", xRec."No. Series", "No. Series") then begin
            NoSeriesMgt.SetSeries("Season Code");
            Validate("Season Code");
            exit(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var Season: Record Season; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var Season: Record Season; var xSeason: Record Season; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}
