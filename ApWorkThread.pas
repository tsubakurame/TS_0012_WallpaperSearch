unit ApWorkThread;

interface
uses
  System.IOUtils, System.Types, System.SysUtils, System.Classes,
  FMX.Graphics, FMX.StdCtrls,
  FMX.ListView, FMX.ListView.Appearances, FMX.ListView.Types, FMX.Types,
  TsuThreadEx
  ;

type
  TApListViewAddMethod  = procedure (path:string; listview:TListView) of object;
  TApWorkThreadParams = record
    SearchDir   : string;
    CopyToDir   : string;
    ThreshWidth : Integer;
    Aspect      : Double;
    Allowable   : Double;
    ListView    : TListView;
    ProgresBar  : TProgressBar;
    TotalLabel  : TLabel;
    FinishedLabel : TLabel;
    ImgPathList : TStringList;
    ImgPathListPath : string;
    RemovePathList  : TStringList;
    RemovePathListPath  : string;
    ListViewAddMethod   : TApListViewAddMethod;
  end;
  TApWorkThread = class(TTscThreadEx)
    protected
      FParams : TApWorkThreadParams;
      FFileNames  : TStringDynArray;
      FCount      : Integer;
    private
      procedure Initialize;override;
      procedure ThreadMain;override;
      procedure DeInitialize;override;
      procedure InitMainComponent;
      procedure ListViewAddImage(path:string);
      procedure SetMainComponent;
      function CheckImgList(path:string):Boolean;
      function CheckRemoveList(path:string):Boolean;
      function CheckList(path:string):Boolean;
    public
      constructor Create(callbacks:TTsrThreadCallBacks; params:TApWorkThreadParams);
  end;
  TApWorkThreadCtrl = class(TTscThreadExCtrl)
    protected
      FParams : TApWorkThreadParams;
      procedure ExecuteThread;override;
    public
      procedure SetUp(callbacks:TTsrThreadCallBacks; params:Pointer);override;
  end;

implementation

constructor TApWorkThread.Create(callbacks: TTsrThreadCallBacks; params: TApWorkThreadParams);
begin
  FParams := params;
  inherited Create(callbacks);
end;

procedure TApWorkThread.Initialize;
begin
  FFileNames  := TDirectory.GetFiles(FParams.SearchDir);
  FCount      := 0;
  Synchronize(InitMainComponent);
end;

procedure TApWorkThread.DeInitialize;
begin
  Synchronize(nil, procedure begin FParams.ImgPathList.SaveToFile(FParams.ImgPathListPath) end);
end;

procedure TApWorkThread.InitMainComponent;
begin
  FParams.ProgresBar.Max  := Length(FFileNames);
  FParams.TotalLabel.Text := IntToStr(Length(FFileNames));
end;

procedure TApWorkThread.ThreadMain;
var
  ext : string;
  filename  : string;
  bmp : TBitmap;
  asp : Double;
begin
  filename  := FFileNames[FCount];
  if not CheckList(filename) then
    begin
      ext := LowerCase(TPath.GetExtension(filename));
      if (ext = '.jpg') or (ext = '.bmp') or (ext = '.gif') or (ext = '.png') then
        begin
          bmp := TBitmap.Create;
          bmp.LoadFromFile(filename);
          if bmp.Width >= FParams.ThreshWidth then
            begin
              asp := bmp.Width / bmp.Height;
              if (asp <= (FParams.Aspect+FParams.Allowable)) and (asp >= (FParams.Aspect-FParams.Allowable)) then
                begin
                  Synchronize(nil, procedure begin FParams.ImgPathList.Add(filename) end);
//                  Synchronize(nil, procedure begin ListViewAddImage(filename) end);
                  Synchronize(nil, procedure begin FParams.ListViewAddMethod(filename, FParams.ListView) end);
//                  if not FileExists(filename) then
//                    TFile.Copy(filename, IncludeTrailingPathDelimiter(FParams.CopyToDir)+ExtractFileName(filename));
                end;
            end;
          bmp.Free;
        end;
    end
  else Log.d(filename);
  Inc(FCount);
  Synchronize(nil, procedure begin SetMainComponent end);
  if FCount >= Length(FFileNames) then LoopBreak  := True;
end;

function TApWorkThread.CheckImgList(path: string): Boolean;
var
  I: Integer;
begin
  Result  := FParams.ImgPathList.IndexOf(path) >= 0;
end;

function TApWorkThread.CheckRemoveList(path: string): Boolean;
var
  I: Integer;
begin
  Result  := FParams.RemovePathList.IndexOf(path) >= 0;
end;

function TApWorkThread.CheckList(path: string): Boolean;
begin
  Result  := CheckRemoveList(path) or CheckImgList(path);
end;

procedure TApWorkThread.SetMainComponent;
begin
  FParams.ProgresBar.Value    := FCount;
  FParams.FinishedLabel.Text  := IntToStr(FCount);
end;

procedure TApWorkThread.ListViewAddImage(path: string);
var
  LItem : TListViewItem;
  image : TListItemImage;
  txt   : TListItemText;
begin
  LItem := FParams.ListView.Items.Add;
  image := LItem.Objects.FindDrawable('Image2') as TListItemImage;
  image.Bitmap  := TBitmap.Create;
  image.Bitmap.LoadFromFile(path);

  txt   := LItem.Objects.FindDrawable('Text1') as TListItemText;
  txt.Text  := path;
end;

procedure TApWorkThreadCtrl.SetUp(callbacks: TTsrThreadCallBacks; params: Pointer);
begin
  FParams := TApWorkThreadParams(params^);
  inherited SetUp(callbacks, params);
end;

procedure TApWorkThreadCtrl.ExecuteThread;
begin
  FThread := TApWorkThread.Create(FCallBacks, FParams);
end;

end.
