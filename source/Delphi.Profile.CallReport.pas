unit Delphi.Profile.CallReport;

interface

uses
  Delphi.Profile.CallInfo,
  Delphi.Profile.AggregateReport,
  System.Generics.Collections,
  System.Classes;

type

  TReportEntry = TPair<string, TCallInfo>;

  TCallReport = class
    private
      FReportEntries  : TDictionary<string, TCallInfo>;
      FAggregateReport: TAggregateReport;

      function GetSortedEntries: TArray<TReportEntry>;
      procedure GetLines(ACallLines: TStrings); overload;

    public
      constructor Create;
      destructor Destroy; override;

      procedure Add(const AScopeName: string; AElapsedTicks: Int64);
      procedure GetLines(ACallLines, AAggregateLines: TStrings); overload;
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

{ TCallReport }

constructor TCallReport.Create;
begin
  FReportEntries   := TObjectDictionary<string, TCallInfo>.Create([doOwnsValues]);
  FAggregateReport := TAggregateReport.Create;
end;

destructor TCallReport.Destroy;
begin
  FReportEntries.Free;
  FAggregateReport.Free;
  inherited;
end;

procedure TCallReport.GetLines(ACallLines, AAggregateLines: TStrings);
begin
  FAggregateReport.Clear;
  GetLines(ACallLines);
  FAggregateReport.Compute;
  FAggregateReport.GetLines(AAggregateLines);
end;

procedure TCallReport.GetLines(ACallLines: TStrings);
var
  ReportEntry: TReportEntry;
begin
  ACallLines.Clear;
  ACallLines.Add(TCallInfo.CommaHeader);
  for ReportEntry in GetSortedEntries do
    begin
      ACallLines.Add(ReportEntry.Value.CommaText);
      FAggregateReport.Add(ReportEntry.Value);
    end;
end;

function TCallReport.GetSortedEntries: TArray<TReportEntry>;
var
  Comparer: IComparer<TReportEntry>;
begin
  Result   := FReportEntries.ToArray;
  Comparer := TTotalTicksComparer.Create;
  TArray.Sort<TReportEntry>(Result, Comparer);
end;

procedure TCallReport.Add(const AScopeName: string; AElapsedTicks: Int64);
var
  CallInfo: TCallInfo;
begin
  if not FReportEntries.TryGetValue(AScopeName, CallInfo) then
    begin
      CallInfo := TCallInfo.Create(AScopeName);
      FReportEntries.Add(AScopeName, CallInfo);
    end;
  with CallInfo do
    begin
      TotalTicks := TotalTicks + AElapsedTicks;
      TotalCalls := TotalCalls + 1;
    end;
end;

end.
