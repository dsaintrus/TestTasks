unit SearchThread;

interface

{$WARN UNIT_PLATFORM OFF}
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;
{$WARN UNIT_PLATFORM ON}

const
  WM_FILESEARCH_MSG = WM_USER + 1;

type
  TFileSearchThread = class(TThread)
private
  FPath       : String;
  FExtensions : String;
  FHandle     : HWND;
protected
  procedure Execute; override;
public
  constructor Create (const strPath : String; const strExtensions : String; const hWindow : HWND);
  destructor Destroy; override;
end;

implementation

{*******************************************************************************
* ����������� ������
* ���������:
*   strPath - ��������� �������
*   strExtensions - ������ �� ������� ����������
*   hWindow - ����� ���� �������� ���������� ���������
*******************************************************************************}
constructor TFileSearchThread.Create (const strPath : String; const strExtensions : String; const hWindow : HWND);
begin
  inherited Create (True);
  FPath := strPath;
  FExtensions := strExtensions;
  FHandle := hWindow;
end;

destructor TFileSearchThread.Destroy;
begin
  inherited;
end;


{*******************************************************************************
* ����� ������ ������ �� ����������� � ��������� �������� � ��� ������������.
* ��� ��������� �������� � ������������ ������
*******************************************************************************}
procedure TFileSearchThread.Execute;
const
  strFileMask = '*.*'; // ����� ��� ������ ������ (��� �����)
var
  Rec: TSearchRec; // ��������� ���������� ������
  strCurPath: string; // ������� ���� ������
  lstFolders: TStringList; // ������ ��������� ��� ������
  strFileName: PString;
begin
  // ������� ������ ��������� ��� ������, ������� � ����������
  lstFolders := TStringList.Create;

  lstFolders.Append(FPath);

  // ������������ ����� �� ���� ��������� �� ������
  while lstFolders.Count > 0 do
  begin
    // �������� ������� ��� ������ ������
    {$WARN SYMBOL_PLATFORM OFF}
    strCurPath := IncludeTrailingBackslash(lstFolders.Strings[0]);
    {$WARN SYMBOL_PLATFORM ON}
    lstFolders.Delete(0);

    // ����� ������ �� ��������� �����������
    if FindFirst(strCurPath + strFileMask, faAnyFile - faDirectory, Rec) = 0 then
      try
        repeat
          if AnsiPos(LowerCase(ExtractFileExt(Rec.Name)), FExtensions) > 0 then
            begin
              New(strFileName);
              strFileName^ := strCurPath + Rec.Name;
              if not PostMessage (FHandle, WM_FILESEARCH_MSG, 0, LPARAM(strFileName)) then Dispose(strFileName);
              //PostMessage (FHandle, WM_FILESEARCH_MSG, 0, LPARAM(strCurPath + Rec.Name));
            end;
//            listImageFiles.Items.Add(strCurPath + Rec.Name);
        until FindNext(Rec) <> 0;
      finally
        {System.SysUtils.}FindClose(Rec);
      end;

    // ����� ������������ � ������� ��������
    // ��������� ����������� ��������� � ������ ��������� ��� ������
    if FindFirst(strCurPath + strFileMask, faDirectory, Rec) = 0 then
      try
        repeat
          if ((Rec.Attr and faDirectory) <> 0) and (Rec.Name <> '.') and
            (Rec.Name <> '..') then
            lstFolders.Append(strCurPath + Rec.Name);
        until FindNext(Rec) <> 0;
      finally
        FindClose(Rec);
      end;

  end;

end;

end.
