program ImgList;

uses
  Vcl.Forms,
  main in 'main.pas' {frmMain},
  SearchThread in 'SearchThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
