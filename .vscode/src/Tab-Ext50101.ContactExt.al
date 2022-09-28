/// <summary>
/// TableExtension ContactExt (ID 50101) extends Record Contact.
/// </summary>
tableextension 50101 ContactExt extends Contact
{
    fields
    {
        field(50100; DWUserId; Code[20])
        {
            Caption = 'DWUserId';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                if DWUserId <> Rec.DWUserId then begin
                    CustomSetup.Get();
                    NoSeriesMgt.TestManual(CustomSetup."DW Id");
                    "No. Series" := '';
                end;
            end;
        }
    }

    trigger OnInsert()
    begin
        if DWUserId = '' then begin
            CustomSetup.TestField("DW Id");
            NoSeriesMgt.InitSeries(CustomSetup."DW Id", xRec."No. Series", 0D, DWUserId, "No. Series");
        end;
    end;

    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
        CustomSetup: Record CustomFieldSetUp;

}


