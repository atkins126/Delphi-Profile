unit Delphi.Profile.PerformanceTracer;

interface

uses
  Delphi.Profile.Trace,
  Delphi.Profile.PerformanceCounter,
  Delphi.Profile.PerformanceReport,
  System.Generics.Collections,
  System.RegularExpressions,
  System.SyncObjs;

type

  TCallStack = TStack<string>;

  TPerformanceTracer = class(TInterfacedObject, ITracer)
    private
      FCallStacks         : TDictionary<TThreadID, TCallStack>;
      FPerformanceReport  : TPerformanceReport;
      FCriticalSection    : TCriticalSection;
      FUseScopeFilter     : Boolean;
      FScopeFilter        : TRegEx;
      FReportPath         : string;
      FAggregateReportPath: string;

      function OnEnterScope(const AMetrics: TPerformanceMetrics; const AScopeName: string): Boolean;
      procedure OnLeaveScope(const AMetrics: TPerformanceMetrics);

      function GetCallStack(AThreadID: TThreadID): TCallStack;
      procedure SetScopeFilter(const APattern: string);

    public
      constructor Create;
      destructor Destroy; override;

      procedure SaveReport;

      property ScopeFilter: string write SetScopeFilter;
      property ReportPath: string write FReportPath;
      property AggregateReportPath: string write FAggregateReportPath;
  end;

implementation

uses
  System.SysUtils,
  System.Classes;

{ TPerformanceTracer }

constructor TPerformanceTracer.Create;
begin
  FCriticalSection     := TCriticalSection.Create;
  FCallStacks          := TObjectDictionary<TThreadID, TCallStack>.Create([doOwnsValues]);
  FPerformanceReport   := TPerformanceReport.Create;
  FReportPath          := 'performance.csv';
  FAggregateReportPath := 'aggregate.csv';
end;

destructor TPerformanceTracer.Destroy;
begin
  try
    SaveReport;
  except
    // we cannot not raise in destructor
  end;
  FPerformanceReport.Free;
  FCallStacks.Free;
  FCriticalSection.Free;
  inherited;
end;

procedure TPerformanceTracer.SaveReport;
var
  PerformanceLines: TStrings;
  AggregateLines  : TStrings;
begin
  PerformanceLines := TStringList.Create;
  AggregateLines   := TStringList.Create;
  try
    FPerformanceReport.GetLines(PerformanceLines, AggregateLines);
    PerformanceLines.SaveToFile(FReportPath);
    AggregateLines.SaveToFile(FAggregateReportPath);
  finally
    PerformanceLines.Free;
    AggregateLines.Free;
  end;
end;

procedure TPerformanceTracer.SetScopeFilter(const APattern: string);
begin
  FUseScopeFilter := not APattern.IsEmpty;
  if FUseScopeFilter then
    FScopeFilter  := TRegEx.Create(APattern);
end;

function TPerformanceTracer.OnEnterScope(const AMetrics: TPerformanceMetrics; const AScopeName: string): Boolean;
begin
  FCriticalSection.Acquire;
  try
    Result := (not FUseScopeFilter) or FScopeFilter.IsMatch(AScopeName);
    if Result then
      with GetCallStack(TThread.Current.ThreadID) do
        begin
          if Count > 0 then
            FPerformanceReport.Add(Peek, AMetrics);
          Push(AScopeName);
        end;
  finally
    FCriticalSection.Release;
  end;
end;

function TPerformanceTracer.GetCallStack(AThreadID: TThreadID): TCallStack;
begin
  if not FCallStacks.TryGetValue(AThreadID, Result) then
    begin
      Result := TCallStack.Create;
      FCallStacks.Add(AThreadID, Result);
    end;
end;

procedure TPerformanceTracer.OnLeaveScope(const AMetrics: TPerformanceMetrics);
begin
  FCriticalSection.Acquire;
  try
    with GetCallStack(TThread.Current.ThreadID) do
      begin
        Assert(Count > 0);
        FPerformanceReport.Add(Pop, AMetrics);
      end;
  finally
    FCriticalSection.Release;
  end;
end;

initialization

TTrace.Tracer := TPerformanceTracer.Create;

end.
