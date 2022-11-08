/// <summary>
/// Page xmlRequestResponse (ID 50103).
/// </summary>
page 50103 xmlRequestResponse
{
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'XML Resquest And Response';
    PageType = Card;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(request; request)
                {
                    ApplicationArea = All;
                    Caption = 'Request';
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(x)
            {
                ApplicationArea = All;
                Caption = 'Get Response';
                Promoted = true;
                Image = Process;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    webService: Codeunit HtunWebService;
                    response: Text;
                begin
                    Clear(webService);
                    response := request;
                    webService.Process(response);
                    Message(response);
                end;
            }
        }
    }

    var
        request: Text;
}
