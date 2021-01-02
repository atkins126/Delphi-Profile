program DelphiProfileViewer;

uses
  Vcl.Forms,
  Delphi.Profile.FormViewer in '..\source\Delphi.Profile.FormViewer.pas' {FormViewer};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormViewer, FormViewer);
  Application.Run;

end.
