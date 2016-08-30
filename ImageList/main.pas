unit main;

interface

{$WARN UNIT_PLATFORM OFF}
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.FileCtrl, ShellApi, SearchThread;
{$WARN UNIT_PLATFORM ON}

const
  IMAGES_EXT = '.jpg;.jpeg;.jpe;.bmp;.dib;.png;.tif;.tiff;.gif;'; // расширения файлов с изображениями

type
  TfrmMain = class(TForm)
    barStatus: TStatusBar;
    listImageFiles: TListBox;
    btScan: TButton;

    procedure btScanClick(Sender: TObject);
    procedure listImageFilesDblClick(Sender: TObject);
  private
    { Private declarations }
    SearchThread: TFileSearchThread; // поток поиска файлов с изображениями
    procedure WMFileSearchMsg(var Msg : TMessage); message WM_FILESEARCH_MSG; // процедура обработки сообщений от потока
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.btScanClick(Sender: TObject);
var
  strChosenDirectory : string;
  strCurPath : string;
begin

  // Проверяем не запущенли уже поиск
  if SearchThread <> nil then
    if not SearchThread.Finished then
    begin
      MessageBox(Self.Handle, PChar('Search in progress'), PChar('Information'), MB_OK + MB_ICONINFORMATION + MB_APPLMODAL);
      Exit;
    end;

  // Выбор каталога для поиска
  // Используютря разные диалоги выбора каталога для разных версий Windows
  strChosenDirectory := '';
  strCurPath := GetCurrentDir;
  {$WARN SYMBOL_PLATFORM OFF}
  if Win32MajorVersion >= 6 then // >= Vista
    with TFileOpenDialog.Create(nil) do
      try
        Title := 'Select Directory';
        Options := [fdoPickFolders, fdoPathMustExist, fdoForceFileSystem];
        OkButtonLabel := 'Select';
        DefaultFolder := strCurPath;
        FileName := strCurPath;
        if Execute then
          strChosenDirectory := FileName;
      finally
        Free;
      end
  else // XP
    if SelectDirectory('Select Directory', ExtractFileDrive(strCurPath), strCurPath, [sdNewUI, sdNewFolder]) then strChosenDirectory := strCurPath;
  {$WARN SYMBOL_PLATFORM ON}

  // Поиск файлов в выбранном каталоге
  if strChosenDirectory <> '' then
  begin
    listImageFiles.Clear;
    SearchThread := TFileSearchThread.Create(strChosenDirectory, LowerCase(IMAGES_EXT), frmMain.Handle);
    SearchThread.Start;
  end;
end;

procedure TfrmMain.listImageFilesDblClick(Sender: TObject);
var
  ExecInfo: TShellExecuteInfo;
begin
  if listImageFiles.ItemIndex > -1 then
  begin
//    ShellExecute(0, 'open', PWideChar(listImageFiles.Items[listImageFiles.ItemIndex]), nil, nil, SW_SHOWNORMAL);
    FillChar(ExecInfo, SizeOf(ExecInfo), 0);
    ExecInfo.cbSize := SizeOf(ExecInfo);
    ExecInfo.Wnd := 0;
    ExecInfo.lpVerb := nil;
    ExecInfo.lpFile := PChar(listImageFiles.Items[listImageFiles.ItemIndex]);
    ExecInfo.lpParameters := nil;
    ExecInfo.lpDirectory := nil;
    ExecInfo.nShow := SW_SHOWNORMAL;
    ExecInfo.fMask := SEE_MASK_NOASYNC or SEE_MASK_FLAG_NO_UI;
    if not ShellExecuteEx(@ExecInfo) then RaiseLastOSError;
  end;
end;


{*******************************************************************************
* Обработка сообщений от потока.
* В сообщении находится указатель на имя файла с полным путем к нему.
*******************************************************************************}

procedure TfrmMain.WMFileSearchMsg(var Msg : TMessage);
var
  strFileName: PString;
begin
  strFileName := PString(Msg.LParam);
  try
    listImageFiles.Items.Add(strFileName^);
  finally
     Dispose(strFileName);
  end;
end;


end.
