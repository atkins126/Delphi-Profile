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
      FTraceInfo : TTraceInfo;
      FCallStack : TStack<string>;
      FCallReport: TCallReport;
      FMutex     : TCriticalSection;

      procedure HandleTrace;
      procedure HandleTraceEnter;
      procedure HandleTraceLeave;

      procedure Log(const ATraceInfo: TTraceInfo);

    public
      constructor Create;
      destructor Destroy; override;
  end;

implementation

constructor TCallTracer.Create;
begin
  FMutex                          := TCriticalSection.Create;
  FCallStack                      := TStack<string>.Create;
  FCallReport                     := TCallReport.Create;
  FCallReport.ReportPath          := 'calls.csv';
  FCallReport.AggregateReportPath := 'aggregate.csv';
end;

destructor TCallTracer.Destroy;
begin
  try
    FCallReport.SaveToFile;
  except
    // we cannot not raise in destructor
  end;
  FCallReport.Free;
  FCallStack.Free;
  FMutex.Free;
  inherited;
end;

procedure TCallTracer.Log(const ATraceInfo: TTraceInfo);
begin
  FMutex.Acquire;
  try
    FTraceInfo := ATraceInfo;
    HandleTrace;
  finally
    FMutex.Release;
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

SetTracer(TCallTracer.Create);

end.
