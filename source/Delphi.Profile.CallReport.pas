unit Delphi.Profile.CallReport;

interface

uses
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Classes,
  Delphi.Profile.CallInfo,
  Delphi.Profile.AggregateReport;

type

  TCallEntry = TPair<string, TCallInfo>;

  TCallReport = class
    private
      FReportPath     : string;
      FReportLines    : TStrings;
      FReportInfo     : TDictionary<string, TCallInfo>;
      FAggregateReport: TAggregateReport;

      function GetSortedEntries: TArray<TCallEntry>;
      procedure SaveReportToFile;
      procedure SaveAggregateReportToFile;
      procedure SetAggregateReportPath(const APath: string);

    public
      constructor Create;
      destructor Destroy; override;
      procedure Add(const FunctionName: string; elapsedTicks: Int64);
      procedure SaveToFile;

    public
      property ReportPath         : string write FReportPath;
      property AggregateReportPath: string write SetAggregateReportPath;
  end;

  TTotalTicksComparer = class(TComparer<TCallEntry>)
    public
      function Compare(const Left, Right: TCallEntry): Integer; override;
  end;

implementation

function TTotalTicksComparer.Compare(const Left, Right: TCallEntry): Integer;
begin
  if Left.value.TotalTicks < Right.value.TotalTicks then
    Result := 1 // sort in descending order
  else if Left.value.TotalTicks > Right.value.TotalTicks then
    Result := - 1
  else
    Result := 0;
end;

constructor TCallReport.Create;
begin
  FReportLines     := TStringList.Create;
  FReportInfo      := TObjectDictionary<string, TCallInfo>.Create([doOwnsValues]);
  FAggregateReport := TAggregateReport.Create;
end;

destructor TCallReport.Destroy;
begin
  FReportLines.Free;
  FReportInfo.Free;
  FAggregateReport.Free;
  inherited;
end;

procedure TCallReport.SaveToFile;
begin
  SaveReportToFile;
  SaveAggregateReportToFile;
end;

procedure TCallReport.SetAggregateReportPath(const APath: string);
begin
  FAggregateReport.ReportPath := APath;
end;

procedure TCallReport.SaveReportToFile;
var
  entry: TCallEntry;
begin
  FReportLines.Clear;
  FReportLines.Add(TCallInfo.CommaHeader);
  for entry in GetSortedEntries do
    FReportLines.Add(entry.value.CommaText);
  FReportLines.SaveToFile(FReportPath);
end;

function TCallReport.GetSortedEntries: TArray<TCallEntry>;
var
  comparer: IComparer<TCallEntry>;
begin
  Result   := FReportInfo.ToArray;
  comparer := TTotalTicksComparer.Create;
  TArray.Sort<TCallEntry>(Result, comparer);
end;

procedure TCallReport.SaveAggregateReportToFile;
var
  entry: TCallEntry;
begin
  for entry in FReportInfo do
    FAggregateReport.Add(entry.value);
  FAggregateReport.Compute;
  FAggregateReport.SaveToFile;
end;

procedure TCallReport.Add(const FunctionName: string; elapsedTicks: Int64);
begin
  if not FReportInfo.ContainsKey(FunctionName) then
    FReportInfo.Add(FunctionName, TCallInfo.Create(FunctionName));
  with FReportInfo[FunctionName] do
    begin
      TotalTicks := TotalTicks + elapsedTicks;
      TotalCalls := TotalCalls + 1;
    end;
end;

end.
