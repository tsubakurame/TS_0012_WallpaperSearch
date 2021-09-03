unit Unit2;

interface

uses
  System.IOUtils, System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math, System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Memo, FMX.Layouts, FMX.ListBox, FMX.Edit, FMX.EditBox, FMX.NumberBox,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, FMX.TabControl, FMX.Platform,
  ApWorkThread, TsuThreadEx, TsuIniFileUtils, TsuAppData, TsuPathUtilsFMX,
  ApProfileSettingComponentList
  ;

type
  TForm2 = class(TForm)
    Memo1: TMemo;
    V: TPanel;
    Panel1: TPanel;
    ProgressBar1: TProgressBar;
    Layout1: TLayout;
    Label2: TLabel;
    LbFinished: TLabel;
    Label4: TLabel;
    LbTotal: TLabel;
    Label6: TLabel;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    LvPicList: TListView;
    Layout2: TLayout;
    Label3: TLabel;
    CbProfile: TComboBox;
    GroupBox1: TGroupBox;
    Layout3: TLayout;
    Layout4: TLayout;
    Label1: TLabel;
    NbWidth: TNumberBox;
    Layout5: TLayout;
    Label7: TLabel;
    NbAspWid: TNumberBox;
    Label5: TLabel;
    NbAspHgt: TNumberBox;
    Layout6: TLayout;
    Label8: TLabel;
    NbAllowable: TNumberBox;
    Button1: TButton;
    Layout7: TLayout;
    Label9: TLabel;
    Layout8: TLayout;
    Label10: TLabel;
    EdSearchDir: TEdit;
    BtSearchDirSel: TButton;
    EdMoveDir: TEdit;
    BtMoviDirSel: TButton;
    Layout9: TLayout;
    BtSaveProfile: TButton;
    EdProfileName: TEdit;
    Label11: TLabel;
    LvRemoveList: TListView;
    TabItem3: TTabItem;
    LvMoved: TListView;
    CheckBox1: TCheckBox;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure IniFileInit;
    procedure SetDirEdit(edit:TEdit);
    procedure BtMoviDirSelClick(Sender: TObject);
    procedure BtSearchDirSelClick(Sender: TObject);
    procedure SaveIni(filename:string);
    procedure BtSaveProfileClick(Sender: TObject);
    procedure LoadProfile;
    procedure CbProfileChange(Sender: TObject);
    procedure ListLoadAndAdd(listpath: string; var list: TStringList; var listview:TListView);
    procedure ListAdd(path:string; listview:TListView);
//    procedure LvPicListDeleteItem(Sender: TObject; AIndex: Integer);
    procedure ListViewDeleteItem(Sender: TObject; AIndex: Integer);
    procedure ListSave;
    procedure LvPicListButtonClick(const Sender: TObject;
      const AItem: TListItem; const AObject: TListItemSimpleControl);
    procedure MoveImage(filename:string);
    procedure ProfileSettingsChange(Sender:TObject);
  private
    { private 宣言 }
  public
    { public 宣言 }
    WorkThread  : TApWorkThreadCtrl;
    ProfileIni  : TTscIniFile;
    AppData     : TTscAppData;
    ProfileRootDir  : string;
    ImgPathList : TStringList;
    ImgPathListPath : string;
    RemoveImgPathList : TStringList;
    RemoveImgPathListPath : string;
    MovedImgPathList  : TStringList;
    MovedImgPathListPath  : string;
    ProfileSettingsComponentList  : TApProfileSettingsComponentList;
    ChangeAgree : Boolean;
  end;

var
  Form2: TForm2;

implementation

{$R *.fmx}

procedure TForm2.BtMoviDirSelClick(Sender: TObject);
begin
  SetDirEdit(EdMoveDir);
end;

procedure TForm2.BtSaveProfileClick(Sender: TObject);
begin
  if EdProfileName.Text = '' then
    SaveIni(CbProfile.Items[CbProfile.ItemIndex])
  else
    SaveIni(EdProfileName.Text);
end;

procedure TForm2.BtSearchDirSelClick(Sender: TObject);
begin
  SetDirEdit(EdSearchDir);
end;

procedure TForm2.Button1Click(Sender: TObject);
var
  search_dir, move_dir  : string;
  callbacks : TTsrThreadCallBacks;
  params    : TApWorkThreadParams;
begin
    begin
      callbacks.Clear;
      params.SearchDir    := EdSearchDir.Text;
      params.ThreshWidth  := Floor(NbWidth.Value);
      params.Aspect       := NbAspWid.Value / NbAspHgt.Value;
      params.Allowable    := NbAllowable.Value;
      params.ListView     := LvPicList;
      params.ProgresBar   := ProgressBar1;
      params.TotalLabel   := LbTotal;
      params.FinishedLabel:= LbFinished;
      params.ImgPathList  := ImgPathList;
      params.RemovePathList := RemoveImgPathList;
      params.ImgPathListPath:= ImgPathListPath;
      params.RemovePathListPath := RemoveImgPathListPath;
      params.ListViewAddMethod  := ListAdd;
      params.CopyToDir    := EdMoveDir.Text;
      WorkThread.SetUp(callbacks, @params);
      WorkThread.Execute;
    end;
end;

procedure TForm2.CbProfileChange(Sender: TObject);
var
  prf_dir : string;
  I: Integer;
begin
  ProfileSettingsComponentList.OnChangeOff;
  prf_dir := IncludeTrailingPathDelimiter(ProfileRootDir)+CbProfile.Items[CbProfile.ItemIndex];
  ProfileIni.OpenIniFile(prf_dir, CbProfile.Items[CbProfile.ItemIndex]+'.ini');

  ImgPathListPath := IncludeTrailingPathDelimiter(prf_dir)+CbProfile.Items[CbProfile.ItemIndex]+'.ilt';
  ListLoadAndAdd(ImgPathListPath, ImgPathList, LvPicList);

  RemoveImgPathListPath := IncludeTrailingPathDelimiter(prf_dir)+CbProfile.Items[CbProfile.ItemIndex]+'.rlt';
  ListLoadAndAdd(RemoveImgPathListPath, RemoveImgPathList, LvRemoveList);

  MovedImgPathListPath  := IncludeTrailingPathDelimiter(prf_dir)+CbProfile.Items[CbProfile.ItemIndex]+'.mlt';
  ListLoadAndAdd(MovedImgPathListPath, MovedImgPathList, LvMoved);
  ProfileSettingsComponentList.OnChangeOn;
end;

procedure TForm2.ListLoadAndAdd(listpath: string; var list: TStringList; var listview:TListView);
var
  filename  : string;
begin
  if FileExists(listpath) then
    begin
      list.LoadFromFile(listpath);
      for filename in list do ListAdd(filename, listview);
    end;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  AppData     := TTscAppData.Create('WallPaperSearch', 'BirdHouse');
  ProfileRootDir  := IncludeTrailingPathDelimiter(AppData.AppDataPath)+'Profile';
  TspDirectoryExistsForce(ProfileRootDir);

  ProfileSettingsComponentList  := TApProfileSettingsComponentList.Create;
  ProfileSettingsComponentList.Add(NbWidth);
  ProfileSettingsComponentList.Add(NbAspWid);
  ProfileSettingsComponentList.Add(NbAspHgt);
  ProfileSettingsComponentList.Add(NbAllowable);
  ProfileSettingsComponentList.Add(EdSearchDir);
  ProfileSettingsComponentList.Add(EdMoveDir);
  ProfileSettingsComponentList.OnChange := ProfileSettingsChange;

  ImgPathList := TStringList.Create;
  ImgPathList.CaseSensitive := True;

  RemoveImgPathList := TStringList.Create;
  RemoveImgPathList.CaseSensitive := True;

  MovedImgPathList  := TStringList.Create;
  MovedImgPathList.CaseSensitive  := True;

  LoadProfile;
  ProfileIni  := TTscIniFile.Create;
//  ProfileIni.AppData  := AppData;
  IniFileInit;
  WorkThread  := TApWorkThreadCtrl.Create;
end;

procedure TForm2.IniFileInit;
begin
  ProfileIni.DataListAdd('Value', 'Width',      1920, @NbWidth,     IVT_NUMBERBOX_VALUE);
  ProfileIni.DataListAdd('Value', 'AspWid',     16,   @NbAspWid,    IVT_NUMBERBOX_VALUE);
  ProfileIni.DataListAdd('Value', 'AspHgt',     9,    @NbAspHgt,    IVT_NUMBERBOX_VALUE);
  ProfileIni.DataListAdd('Value', 'Allowable',  0.1,  @NbAllowable, IVT_NUMBERBOX_VALUE);
  ProfileIni.DataListAdd('Dir',   'SearchDir',  System.IOUtils.TPath.GetPicturesPath,  @EdSearchDir, IVT_EDIT_TEXT);
  ProfileIni.DataListAdd('Dir',   'MoveDir',    '',   @EdMoveDir,   IVT_EDIT_TEXT);
end;

procedure TForm2.SetDirEdit(edit: TEdit);
var
  dir : string;
begin
  if SelectDirectory('フォルダを選択', '', dir) then
    edit.Text := dir;
end;

procedure TForm2.SaveIni(filename: string);
var
  prf_dir : string;
begin
  ProfileIni.WriteIniValue;
  prf_dir := IncludeTrailingPathDelimiter(ProfileRootDir)+filename;
  TspDirectoryExistsForce(prf_dir);
  ProfileIni.SaveIniFile(prf_dir, filename);
end;

procedure TForm2.LoadProfile;
var
  FileNames : TStringDynArray;
  filename  : string;
begin
  CbProfile.Items.Add('　');
  FileNames := TDirectory.GetFiles(ProfileRootDir, '*.ini', TSearchOption.soAllDirectories);
  for filename in FileNames do
    begin
      CbProfile.Items.Add(System.IOUtils.TPath.GetFileNameWithoutExtension(FileName));
    end;
  CbProfile.OnChange  := nil;
  CbProfile.ItemIndex := 0;
  CbProfile.OnChange  := CbProfileChange;
end;

procedure TForm2.LvPicListButtonClick(const Sender: TObject;
  const AItem: TListItem; const AObject: TListItemSimpleControl);
begin
  MovedImgPathList.Add(ImgPathList[AItem.Index]);
  ListAdd(ImgPathList[AItem.Index], LvMoved);
  MoveImage(ImgPathList[AItem.Index]);
  ImgPathList.Delete(AItem.Index);
  LvPicList.Items.Delete(AItem.Index);
  ListSave;
end;

procedure TForm2.ListViewDeleteItem(Sender: TObject; AIndex: Integer);
var
  LItem : TListViewItem;
begin
  if TListView(Sender) = LvPicList then
    begin
      RemoveImgPathList.Add(ImgPathList[AIndex]);
      ListAdd(ImgPathList[AIndex], LvRemoveList);
      ImgPathList.Delete(AIndex);
    end
  else if TListView(Sender) = LvMoved then
    begin
      MovedImgPathList.Delete(AIndex);
    end
  else if TListView(Sender) = LvRemoveList then
    begin
      RemoveImgPathList.Delete(AIndex);
    end;
  ListSave;
end;

procedure TForm2.ListAdd(path: string; listview: TListView);
var
  LItem : TListViewItem;
  image : TListItemImage;
  txt   : TListItemText;
begin
  LItem := listview.Items.Add;
  image := LItem.Objects.FindDrawable('Image2') as TListItemImage;
  image.Bitmap  := TBitmap.Create;
  image.Bitmap.LoadFromFile(path);

  txt   := LItem.Objects.FindDrawable('Text1') as TListItemText;
  txt.Text  := path;
end;

procedure TForm2.ListSave;
begin
  ImgPathList.SaveToFile(ImgPathListPath);
  RemoveImgPathList.SaveToFile(RemoveImgPathListPath);
  MovedImgPathList.SaveToFile(MovedImgPathListPath);
end;

procedure TForm2.MoveImage(filename:string);
var
  movepath  : string;
begin
  movepath  := IncludeTrailingPathDelimiter(EdMoveDir.Text)+ExtractFileName(filename);
  if (not FileExists(movepath)) and FileExists(filename) then
    TFile.Copy(filename, movepath);
end;

procedure TForm2.ProfileSettingsChange(Sender: TObject);
var
  btns : TMsgDlgButtons;
  res : Integer;
  change  : Boolean;
  service : IFMXDialogServiceSync;
begin
  btns := [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbYesToAll, TMsgDlgBtn.mbNo];
  if CbProfile.ItemIndex <> 0 then
    begin
      if not ChangeAgree then
        begin
          if TPlatformServices.Current.SupportsPlatformService(IFMXDialogServiceSync, IInterface(service)) then
            begin
              res := service.MessageDialogSync(
                            '現在選択しているプロファイルの値を書き換えますがよろしいですか？'+#13+
                            '[すべてはい]を選択すると、このプロファイル上での以降の編集をすべて許可します。',
                            TMsgDlgType.mtWarning,
                            btns,
                            TMsgDlgBtn.mbYes,
                            0);
              if res = mrYesToAll then
                begin
                  change      := True;
                  ChangeAgree := True;
                end
              else if res = mrYes then
                change  := True
              else change := False;
            end;
//          res := MessageDlg('現在選択しているプロファイルの値を書き換えますがよろしいですか？'+#13+
//                            '[すべてはい]を選択すると、このプロファイル上での以降の編集をすべて許可します。',
//                            TMsgDlgType.mtWarning,
//                            Buttons,
//                            0);

        end
      else
        change  := True;
      if change then SaveIni(CbProfile.Items[CbProfile.ItemIndex])
      else           CbProfile.ItemIndex  := 0;
    end;
end;

end.
