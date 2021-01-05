unit Delphi.Profile.PerformanceReport;

interface

uses
  Delphi.Profile.PerformanceCounter,
  Delphi.Profile.ScopeInfo,
  Delphi.Profile.AggregateReport,
  System.Generics.Collections,
  System.Classes;

type

  TReportEntry = TPair<string, TScopeInfo>;

  TPerformanceReport = class
    private
      FReportEntries  : TDictionary<string, TScopeInfo>;
      FAggregateReport: TAggregateReport;

      function GetSortedEntries: TArray<TReportEntry>;
      procedure GetLines(ALines: TStrings); overload;

    public
      constructor Create;
      destructor Destroy; override;

      procedure Add(const AScopeName: string; const AMetrics: TPerformanceMetrics);
      procedure GetLines(APerformanceLines, AAggregateLines: TStrings); overload;
  end;

implementation

uses
  System.Generics.Defaults;

type
  TTotalTicksComparer = class(TComparer<TReportEntry>)
    public
      function Compare(const Left, Right: TReportEntry): Integer; override;
  end;

{ TTotalTicksComparer }

function TTotalTicksComparer.Compare(const Left, Right: TReportEntry): Integer;
begin
  if Left.Value.TotalTicks < Right.Value.TotalTicks then
    Result := 1 // sort in descending order
  else if Left.Value.TotalTicks > Right.Value.TotalTicks then
    Result := - 1
  else
    Result := 0;
end;

{ TPerformanceReport }

constructor TPerformanceReport.Create;
begin
  FReportEntries   := TObjectDictionary<string, TScopeInfo>.Create([doOwnsValues]);
  FAggregateReport := TAggregateReport.Create;
end;

destructor TPerformanceReport.Destroy;
begin
  FReportEntries.Free;
  FAggregateReport.Free;
  inherited;
end;

procedure TPerformanceReport.GetLines(APerformanceLines, AAggregateLines: TStrings);
begin
  FAggregateReport.Clear;
  GetLines(APerformanceLines);
  FAggregateReport.Compute;
  FAggregateReport.GetLines(AAggregateLines);
end;

procedure TPerformanceReport.GetLines(ALines: TStrings);
var
  ReportEntry: TReportEntry;
begin
  ALines.Clear;
  ALines.Add(TScopeInfo.CommaHeader);
  for ReportEntry in GetSortedEntries do
    begin
      ALines.Add(ReportEntry.Value.CommaText);
      FAggregateReport.Add(ReportEntry.Value);
    end;
end;

function TPerformanceReport.GetSortedEntries: TArray<TReportEntry>;
var
  Comparer: IComparer<TReportEntry>;
begin
  Result   := FReportEntries.ToArray;
  Comparer := TTotalTicksComparer.Create;
  TArray.Sort<TReportEntry>(Result, Comparer);
end;

procedure TPerformanceReport.Add(const AScopeName: string; const AMetrics: TPerformanceMetrics);
var
  ScopeInfo: TScopeInfo;
begin
  if not FReportEntries.TryGetValue(AScopeName, ScopeInfo) then
    begin
      ScopeInfo := TScopeInfo.Create(AScopeName);
      FReportEntries.Add(AScopeName, ScopeInfo);
    end;
  with ScopeInfo do
    begin
      TotalTicks := TotalTicks + AMetrics.FRealClockTime;
      TotalHits  := TotalHits + 1;
    end;
end;

end.
