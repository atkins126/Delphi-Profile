unit Delphi.Profile.Trace;

interface

uses
  Delphi.Profile;

type

  TTrace = class(TInterfacedObject, IInterface)
    private
      FTraceInfo                   : TTraceInfo;
      class threadvar FStartTime   : Int64;
      class threadvar FElapsedTicks: Int64;
      class var FTracer            : ITracer;

      class procedure StartClock; inline;
      class procedure StopClock; inline;

      function _AddRef: Integer; stdcall;
      function _Release: Integer; stdcall;

    public
      class function NewInstance: TObject; override; final;

      constructor Create(const AScopeName: string);
      destructor Destroy; override; final;

      class property Tracer: ITracer read FTracer write FTracer;
  end;

implementation

uses
  System.Diagnostics;

{ TTrace }

class procedure TTrace.StartClock;
begin
  FStartTime := TStopwatch.GetTimeStamp;
end;

class procedure TTrace.StopClock;
begin
  FElapsedTicks := TStopwatch.GetTimeStamp - FStartTime;
end;

class function TTrace.NewInstance: TObject;
begin
  StopClock;
  Result := inherited;
end;

function TTrace._AddRef: Integer;
begin
  Result := inherited;
  Assert(Result = 1, 'The trace object should not be referenced in client code');
  StartClock;
end;

function TTrace._Release: Integer;
begin
  StopClock;
  Result := inherited;
  Assert(Result = 0, 'The trace object should not be referenced in client code');
  StartClock;
end;

constructor TTrace.Create(const AScopeName: string);
begin
  FTraceInfo.FScopeName    := AScopeName;
  FTraceInfo.FEventType    := TraceEnter;
  FTraceInfo.FElapsedTicks := FElapsedTicks;
  FTracer.Log(FTraceInfo);
end;

destructor TTrace.Destroy;
begin
  FTraceInfo.FEventType    := TraceLeave;
  FTraceInfo.FElapsedTicks := FElapsedTicks;
  FTracer.Log(FTraceInfo);
end;

initialization

TStopwatch.Create; // initialize the stopwatch type

end.
