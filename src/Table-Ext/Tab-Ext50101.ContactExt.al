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
                    "DW No. Series" := '';
                end;
            end;
        }
        field(50101; "DW No. Series"; Code[20])
        {
            Caption = 'DW No. Series';
            Editable = false;
            TableRelation = "No. Series";
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
        if DWUserId = '' then begin
            CustomSetup.Get();
            CustomSetup.TestField("DW Id");
            NoSeriesMgt.InitSeries(CustomSetup."DW Id", xRec."DW No. Series", 0D, DWUserId, "DW No. Series");
        end;
    end;

    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
        CustomSetup: Record CustomFieldSetUp;

    /// <summary>
    /// DWUserEdit.
    /// </summary>
    /// <param name="OldCont">Record Contact.</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure DWAssistEdit(OldCont: Record Contact) Result: Boolean
    var
        Cont: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, OldCont, IsHandled, Result);
        if IsHandled then
            exit(Result);

#pragma warning disable AL0606
        with Cont do begin
#pragma warning restore AL0606
            Cont := Rec;
            CustomSetup.Get();
            CustomSetup.TestField("DW Id");
            if NoSeriesMgt.SelectSeries(CustomSetup."DW Id", OldCont."DW No. Series", "DW No. Series") then begin
                CustomSetup.Get();
                CustomSetup.TestField("DW Id");
                NoSeriesMgt.SetSeries(DWUserId);
                OnAssistEditOnAfterNoSeriesMgtSetSeries(Cont, OldCont);
                Rec := Cont;
                exit(true);
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var Contact: record Contact; OldContact: Record Contact; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditOnAfterNoSeriesMgtSetSeries(var Contact: Record Contact; OldContact: Record Contact)
    begin
    end;

}
