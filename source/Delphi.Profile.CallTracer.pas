unit Delphi.Profile.CallTracer;

interface

uses
  Delphi.Profile,
  Delphi.Profile.CallReport,
  System.Generics.Collections,
  System.SyncObjs;

type

  TCallTracer = class(TInterfacedObject, ITracer)
    private
      FTraceInfo          : TTraceInfo;
      FCallStack          : TStack<string>;
      FCallReport         : TCallReport;
      FCriticalSection    : TCriticalSection;
      FCallReportPath     : string;
      FAggregateReportPath: string;

      procedure HandleTrace;
      procedure HandleTraceEnter;
      procedure HandleTraceLeave;

      procedure Log(const ATraceInfo: TTraceInfo);

    public
      constructor Create;
      destructor Destroy; override;

      procedure SaveReport;

      property CallReportPath: string write FCallReportPath;
      property AggregateReportPath: string write FAggregateReportPath;
  end;

implementation

uses
  System.Classes,
  Delphi.Profile.Trace;

{ TCallTracer }

constructor TCallTracer.Create;
begin
  FCriticalSection     := TCriticalSection.Create;
  FCallStack           := TStack<string>.Create;
  FCallReport          := TCallReport.Create;
  FCallReportPath      := 'calls.csv';
  FAggregateReportPath := 'aggregate.csv';
end;

destructor TCallTracer.Destroy;
begin
  try
    SaveReport;
  except
    // we cannot not raise in destructor
  end;
  FCallReport.Free;
  FCallStack.Free;
  FCriticalSection.Free;
  inherited;
end;

procedure TCallTracer.SaveReport;
var
  CallLines     : TStrings;
  AggregateLines: TStrings;
begin
  CallLines      := TStringList.Create;
  AggregateLines := TStringList.Create;
  try
    FCallReport.GetLines(CallLines, AggregateLines);
    CallLines.SaveToFile(FCallReportPath);
    AggregateLines.SaveToFile(FAggregateReportPath);
  finally
    CallLines.Free;
    AggregateLines.Free;
  end;
end;

procedure TCallTracer.Log(const ATraceInfo: TTraceInfo);
begin
  FCriticalSection.Acquire;
  try
    FTraceInfo := ATraceInfo;
    HandleTrace;
  finally
    FCriticalSection.Release;
  end;
end;

procedure TCallTracer.HandleTrace;
begin
  if FTraceInfo.FEventType = TraceEnter then
    HandleTraceEnter
  else
    HandleTraceLeave;
end;

procedure TCallTracer.HandleTraceEnter;
begin
  if FCallStack.Count > 0 then
    FCallReport.Add(FCallStack.Peek, FTraceInfo.FElapsedTicks);
  FCallStack.Push(FTraceInfo.FScopeName);
end;

procedure TCallTracer.HandleTraceLeave;
begin
  Assert(FCallStack.Count > 0);
  Assert(FCallStack.Peek = FTraceInfo.FScopeName);
  FCallReport.Add(FCallStack.Pop, FTraceInfo.FElapsedTicks);
end;

initialization

TTrace.Tracer := TCallTracer.Create;

end.
