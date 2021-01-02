unit Delphi.Profile.FormViewer;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.Grids,
  Vcl.ExtCtrls;

type

  TFormViewer = class(TForm)
    CallsGrid: TStringGrid;
    AggregateSplitter: TSplitter;
    AggregateGrid: TStringGrid;
    procedure CallsGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure AggregateGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CallsGridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure AggregateGridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);

    private
      FLines  : TStrings;
      FMeans  : array [0 .. 3] of Double;
      FStddevs: array [0 .. 3] of Double;

      procedure HandleCreate(Sender: TObject);

      function GetHighlightColor(AValue: Double; ACol: Integer): TColor;
      procedure HighlightCell(const AText: string; ACanvas: TCanvas; ARect: TRect; AColor: TColor);
      procedure LoadGridFromFile(AGrid: TStringGrid; const APath: string);
      procedure AutoSizeGrid(AGrid: TStringGrid);
      procedure InitializeMeansAndStddevs;
      procedure CopySelectionToClipboard(AGrid: TStringGrid);

    public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
  end;

var
  FormViewer: TFormViewer;

implementation

{$R *.dfm}


uses
  Vcl.Clipbrd;

constructor TFormViewer.Create(AOwner: TComponent);
begin
  inherited;
  OnCreate                 := HandleCreate;

  FLines                   := TStringList.Create;
  FLines.TrailingLineBreak := false;
end;

destructor TFormViewer.Destroy;
begin
  FLines.Free;
  inherited;
end;

procedure TFormViewer.CallsGridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
  State: TGridDrawState);
var
  sValue        : Double;
  highlightColor: TColor;
begin
  if (ACol > 1) and (ARow > 0) then
    with Sender as TStringGrid do
      begin
        sValue := StrToFloat(Cells[ACol, ARow]);
        if sValue > FMeans[ACol] then
          begin
            highlightColor := GetHighlightColor(sValue, ACol);
            HighlightCell(Cells[ACol, ARow], Canvas, Rect, highlightColor);
          end;
      end;
end;

procedure TFormViewer.CallsGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = Ord('C')) then
    CopySelectionToClipboard(CallsGrid);
end;

procedure TFormViewer.AggregateGridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
begin
  if (ACol = 1) and (ARow = 2) then
    with Sender as TStringGrid do
      HighlightCell(Cells[ACol, ARow], Canvas, Rect, clWebLavender);
end;

procedure TFormViewer.AggregateGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = Ord('C')) then
    CopySelectionToClipboard(AggregateGrid);
end;

function TFormViewer.GetHighlightColor(AValue: Double; ACol: Integer): TColor;
begin
  if AValue > FMeans[ACol] + 3 * FStddevs[ACol] then
    Result := clWebTan
  else if AValue > FMeans[ACol] + 2 * FStddevs[ACol] then
    Result := clWebWheat
  else if AValue > FMeans[ACol] + FStddevs[ACol] then
    Result := clWebBeige
  else
    Result := clCream;
end;

procedure TFormViewer.HighlightCell(const AText: string; ACanvas: TCanvas; ARect: TRect; AColor: TColor);
var
  TopOffset: Integer;
begin
  ACanvas.Brush.color := AColor;
  ARect.Inflate(0, 0, 0, 0);
  ACanvas.FillRect(ARect);
  TopOffset := (ARect.Height - ACanvas.TextHeight(AText)) div 2;
  ACanvas.TextOut(ARect.Left + 6, ARect.Top + TopOffset, AText);
end;

procedure TFormViewer.CopySelectionToClipboard(AGrid: TStringGrid);
const
  CTabChar = #9;
var
  Line: string;
  I, K: Integer;
begin
  try
    with AGrid do
      for I          := Selection.Top to Selection.Bottom do
        begin
          Line       := '';
          for K      := Selection.Left to Selection.Right do
            begin
              Line   := Line + Cells[K, I];
              if K <> Selection.Right then
                Line := Line + CTabChar;
            end;
          FLines.Add(Line);
        end;
    Clipboard.AsText := FLines.text;
  finally
    FLines.Clear;
  end;
end;

procedure TFormViewer.HandleCreate(Sender: TObject);
begin
  LoadGridFromFile(CallsGrid, 'calls.csv');
  LoadGridFromFile(AggregateGrid, 'aggregate.csv');
  AggregateGrid.Cells[1, 1] := Trunc(AggregateGrid.Cells[1, 1].ToDouble).ToString;
  AggregateGrid.Cells[1, 3] := ''; // sum of average time does not make sense
  InitializeMeansAndStddevs;
end;

procedure TFormViewer.LoadGridFromFile(AGrid: TStringGrid; const APath: string);
var
  I: Integer;
begin
  try
    FLines.LoadFromFile(APath);
    AGrid.RowCount            := FLines.Count;
    for I                     := 0 to FLines.Count - 1 do
      AGrid.Rows[I].CommaText := FLines[I];
    AutoSizeGrid(AGrid);
  finally
    FLines.Clear;
  end;
end;

procedure TFormViewer.AutoSizeGrid(AGrid: TStringGrid);
const
  CColWidthMin = 10;
  CColWidthPad = 10;
var
  C, R, W    : Integer;
  ColWidthMax: Integer;
begin
  for C                  := 0 to AGrid.ColCount - 1 do
    begin
      ColWidthMax        := CColWidthMin;
      for R              := 0 to (AGrid.RowCount - 1) do
        begin
          W              := AGrid.Canvas.TextWidth(AGrid.Cells[C, R]);
          if W > ColWidthMax then
            ColWidthMax  := W;
        end;
      AGrid.ColWidths[C] := ColWidthMax + CColWidthPad;
    end;
end;

procedure TFormViewer.InitializeMeansAndStddevs;
const
  CMeanCol        = 2;
  CStddevCol      = 3;
  CTotalTimeRow   = 2;
  CAverageTimeRow = 3;
var
  Row: Integer;
begin
  for Row           := CTotalTimeRow to CAverageTimeRow do
    begin
      FMeans[Row]   := StrToFloat(AggregateGrid.Cells[CMeanCol, Row]);
      FStddevs[Row] := StrToFloat(AggregateGrid.Cells[CStddevCol, Row]);
    end;
end;

end.
