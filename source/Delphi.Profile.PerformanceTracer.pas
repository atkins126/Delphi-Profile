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

  TPerformanceTracer = class(TInterfacedObject, ITracer)
    private
      FCallStack          : TStack<string>;
      FPerformanceReport  : TPerformanceReport;
      FCriticalSection    : TCriticalSection;
      FUseScopeFilter     : Boolean;
      FScopeFilter        : TRegEx;
      FReportPath         : string;
      FAggregateReportPath: string;

      function OnEnterScope(AMetrics: TPerformanceMetrics; const AScopeName: string): Boolean;
      procedure OnLeaveScope(AMetrics: TPerformanceMetrics);

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
  FCallStack           := TStack<string>.Create;
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
  FCallStack.Free;
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

function TPerformanceTracer.OnEnterScope(AMetrics: TPerformanceMetrics; const AScopeName: string): Boolean;
begin
  Result := (not FUseScopeFilter) or FScopeFilter.IsMatch(AScopeName);
  if Result then
    begin
      FCriticalSection.Acquire;
      try
        if FCallStack.Count > 0 then
          FPerformanceReport.Add(FCallStack.Peek, AMetrics);
        FCallStack.Push(AScopeName);
      finally
        FCriticalSection.Release;
      end;
    end;
end;

procedure TPerformanceTracer.OnLeaveScope(AMetrics: TPerformanceMetrics);
begin
  FCriticalSection.Acquire;
  try
    Assert(FCallStack.Count > 0);
    FPerformanceReport.Add(FCallStack.Pop, AMetrics);
  finally
    FCriticalSection.Release;
  end;
end;

initialization

TTrace.Tracer := TPerformanceTracer.Create;

end.
