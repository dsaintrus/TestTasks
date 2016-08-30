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
* Конструктор потока
* Параметры:
*   strPath - начальный каталог
*   strExtensions - строка со списком расширений
*   hWindow - хэндл окна которому передаются сообщения
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
* Метод поиска файлов по расширениям в указанном каталоге и его подкаталогах.
* Все параметры задаются в конструкторе потока
*******************************************************************************}
procedure TFileSearchThread.Execute;
const
  strFileMask = '*.*'; // маска для поиска файлов (все файлы)
var
  Rec: TSearchRec; // структура параметров поиска
  strCurPath: string; // текущий путь поиска
  lstFolders: TStringList; // список каталогов для поиска
  strFileName: PString;
begin
  // Создаем список каталогов для поиска, начиная с выбранного
  lstFolders := TStringList.Create;

  lstFolders.Append(FPath);

  // Осуществляем поиск по всем каталогам из списка
  while lstFolders.Count > 0 do
  begin
    // Получаем каталог для поиска файлов
    {$WARN SYMBOL_PLATFORM OFF}
    strCurPath := IncludeTrailingBackslash(lstFolders.Strings[0]);
    {$WARN SYMBOL_PLATFORM ON}
    lstFolders.Delete(0);

    // Поиск файлов по указанным расширениям
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

    // Поиск подкаталогов в текущем каталоге
    // Найденные подкаталоги добавляем в список каталогов для поиска
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
