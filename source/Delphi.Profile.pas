unit Delphi.Profile;

interface

type

  TTraceInfo = record
    FScopeName: string;
    FEventType: (TraceEnter, TraceLeave);
    FElapsedTicks: Int64;
  end;

{$M+} // Enable RTTI for use in the unit tests

  ITracer = interface
    procedure Log(const ATraceInfo: TTraceInfo);
  end;

{$M-}


procedure SetTracer(ATracer: ITracer);
function Trace(const AScopeName: string): IInterface;

implementation

uses
  Delphi.Profile.Trace;

procedure SetTracer(ATracer: ITracer);
begin
  TTrace.Tracer := ATracer;
end;

function Trace(const AScopeName: string): IInterface;
begin
  if Assigned(TTrace.Tracer) then
    Result := TTrace.Create(AScopeName)
  else
    Result := nil;
end;

end.
