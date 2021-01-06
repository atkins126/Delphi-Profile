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
    PerformanceGrid: TStringGrid;
    AggregateSplitter: TSplitter;
    AggregateGrid: TStringGrid;
    procedure PerformanceGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure AggregateGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PerformanceGridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure AggregateGridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);

    private
      FLines  : TStrings;
      FMeans  : array [0 .. 5] of Double;
      FStddevs: array [0 .. 5] of Double;

      procedure HandleCreate(Sender: TObject);

      class function ParamOrDefault(AIndex: Integer; const ADefault: string): string;

      function GetHighlightColor(AValue: Double; ACol: Integer): TColor;
      class function GetGradientColor(AFirst, ASecond: TColor; APercentage: Double): TColor;
      class function GetGradientComponent(AFirst, ASecond: Byte; ARatio: Double): Byte; inline;
      class procedure HighlightCell(const AText: string; ACanvas: TCanvas; ARect: TRect; AColor: TColor);

      procedure LoadGridFromFile(AGrid: TStringGrid; const APath: string);
      procedure CopyGridSelectionToClipboard(AGrid: TStringGrid);
      class procedure AutoSizeGrid(AGrid: TStringGrid);

      procedure InitializeMeansAndStddevs;
      procedure FixAggregateGridValues;

    public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
  end;

var
  FormViewer: TFormViewer;

implementation

{$R *.dfm}


uses
  System.Math,
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

procedure TFormViewer.PerformanceGridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
  State: TGridDrawState);
var
  sValue        : Double;
  highlightColor: TColor;
begin
  if (ACol > 1) and (ARow > 0) and not (gdSelected in State) then
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

procedure TFormViewer.PerformanceGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = Ord('C')) then
    CopyGridSelectionToClipboard(PerformanceGrid);
end;

procedure TFormViewer.AggregateGridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
begin
  if (ACol = 1) and (ARow = 2) and not (gdSelected in State) then
    with Sender as TStringGrid do
      HighlightCell(Cells[ACol, ARow], Canvas, Rect, clWebLavender);
end;

procedure TFormViewer.AggregateGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = Ord('C')) then
    CopyGridSelectionToClipboard(AggregateGrid);
end;

function TFormViewer.GetHighlightColor(AValue: Double; ACol: Integer): TColor;
const
  CMaxScore    = 3.0;
  CFirstColor  = $F5FFFA; // MintCream
  CSecondColor = $8CB4D2; // WebTan
var
  ZScore: Double;         // the standard score (standard deviations from the mean)
begin
  ZScore   := (AValue - FMeans[ACol]) / FStddevs[ACol];
  if ZScore > 0 then
    Result := GetGradientColor(CFirstColor, CSecondColor, Min(ZScore, CMaxScore) / CMaxScore)
  else
    Result := clWhite;
end;

class function TFormViewer.GetGradientColor(AFirst, ASecond: TColor; APercentage: Double): TColor;
var
  R, G, B: Byte;
begin
  R      := GetGradientComponent(GetRValue(AFirst), GetRValue(ASecond), APercentage);
  G      := GetGradientComponent(GetGValue(AFirst), GetGValue(ASecond), APercentage);
  B      := GetGradientComponent(GetBValue(AFirst), GetBValue(ASecond), APercentage);
  Result := RGB(R, G, B);
end;

class function TFormViewer.GetGradientComponent(AFirst, ASecond: Byte; ARatio: Double): Byte;
begin
  Result := Trunc(AFirst + (ASecond - AFirst) * ARatio);
end;

class procedure TFormViewer.HighlightCell(const AText: string; ACanvas: TCanvas; ARect: TRect; AColor: TColor);
var
  TopOffset: Integer;
begin
  ACanvas.Brush.color := AColor;
  ARect.Inflate(0, 0, 0, 0);
  ACanvas.FillRect(ARect);
  TopOffset := (ARect.Height - ACanvas.TextHeight(AText)) div 2;
  ACanvas.TextOut(ARect.Left + 6, ARect.Top + TopOffset, AText);
end;

procedure TFormViewer.CopyGridSelectionToClipboard(AGrid: TStringGrid);
const
  CTabChar = #9;
var
  Line: string;
  Row : Integer;
  Col : Integer;
begin
  FLines.Clear;
  for Row        := AGrid.Selection.Top to AGrid.Selection.Bottom do
    begin
      Line       := '';
      for Col    := AGrid.Selection.Left to AGrid.Selection.Right do
        begin
          Line   := Line + AGrid.Cells[Col, Row];
          if Col <> AGrid.Selection.Right then
            Line := Line + CTabChar;
        end;
      FLines.Add(Line);
    end;
  Clipboard.AsText := FLines.text;
end;

procedure TFormViewer.HandleCreate(Sender: TObject);
begin
  LoadGridFromFile(PerformanceGrid, ParamOrDefault(1, 'performance.csv'));
  LoadGridFromFile(AggregateGrid, ParamOrDefault(2, 'aggregate.csv'));
  InitializeMeansAndStddevs;
  FixAggregateGridValues;
  AutoSizeGrid(PerformanceGrid);
  AutoSizeGrid(AggregateGrid);
end;

procedure TFormViewer.FixAggregateGridValues;
begin
  AggregateGrid.Cells[1, 1] := Trunc(AggregateGrid.Cells[1, 1].ToDouble).ToString;
  AggregateGrid.Cells[1, 2] := Trunc(AggregateGrid.Cells[1, 2].ToDouble).ToString;
  AggregateGrid.Cells[1, 3] := ''; // sum of average time does not make sense
  AggregateGrid.Cells[1, 4] := Trunc(AggregateGrid.Cells[1, 4].ToDouble).ToString;
  AggregateGrid.Cells[1, 5] := ''; // sum of average cycles does not make sense
end;

procedure TFormViewer.LoadGridFromFile(AGrid: TStringGrid; const APath: string);
var
  Row: Integer;
begin
  FLines.LoadFromFile(APath);
  AGrid.RowCount              := FLines.Count;
  for Row                     := 0 to FLines.Count - 1 do
    AGrid.Rows[Row].CommaText := FLines[Row];
end;

class function TFormViewer.ParamOrDefault(AIndex: Integer; const ADefault: string): string;
begin
  if AIndex <= ParamCount then
    Result := ParamStr(AIndex)
  else
    Result := ADefault;
end;

class procedure TFormViewer.AutoSizeGrid(AGrid: TStringGrid);
const
  CWidthMin = 10;
  CWidthPad = 10;
var
  Col, Row: Integer;
  Width   : Integer;
  WidthMax: Integer;
begin
  for Col                  := 0 to AGrid.ColCount - 1 do
    begin
      WidthMax             := CWidthMin;
      for Row              := 0 to AGrid.RowCount - 1 do
        begin
          Width            := AGrid.Canvas.TextWidth(AGrid.Cells[Col, Row]);
          if Width > WidthMax then
            WidthMax       := Width;
        end;
      AGrid.ColWidths[Col] := WidthMax + CWidthPad;
    end;
end;

procedure TFormViewer.InitializeMeansAndStddevs;
const
  CMeanCol   = 2;
  CStddevCol = 3;
  CFirstRow  = 2; // total time
  CLastRow   = 5; // average cycles
var
  Row: Integer;
begin
  for Row           := CFirstRow to CLastRow do
    begin
      FMeans[Row]   := StrToFloat(AggregateGrid.Cells[CMeanCol, Row]);
      FStddevs[Row] := StrToFloat(AggregateGrid.Cells[CStddevCol, Row]);
    end;
end;

end.
