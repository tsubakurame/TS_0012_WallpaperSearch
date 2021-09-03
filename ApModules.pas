unit ApModules;

interface
uses
  FMX.ListView, FMX.ListView.Appearances, FMX.ListView.Types, FMX.Graphics
  ;

procedure ListViewItemAdd(var listview:TListView; path:string);

implementation

procedure ListViewItemAdd(var listview:TListView; path:string);
var
  image : TListItemImage;
  txt   : TListItemText;
  LItem : TListViewItem;
begin
  LItem := listview.Items.Add;
  image := LItem.Objects.FindDrawable('Image2') as TListItemImage;
  image.Bitmap  := TBitmap.Create;
  image.Bitmap.LoadFromFile(path);

  txt   := LItem.Objects.FindDrawable('Text1') as TListItemText;
  txt.Text  := path;
end;

end.
