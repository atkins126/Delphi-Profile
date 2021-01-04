unit Delphi.Profile.Trace;

interface

uses
  Delphi.Profile.PerformanceCounter;

type

{$M+} // Enable RTTI for use in the unit tests

  ITracer = interface
    function OnEnterScope(AMetrics: TPerformanceMetrics; const AScopeName: string): Boolean;
    procedure OnLeaveScope(AMetrics: TPerformanceMetrics);
  end;

{$M-}

  TTrace = class(TInterfacedObject, IInterface)
    private
      class var FTracer: ITracer; // not protected by mutex because it should be set once during program initialization

      function _Release: Integer; stdcall;

    public
      class property Tracer: ITracer write FTracer;

      class function Create(const AScopeName: string): IInterface;
  end;

implementation

{ TTrace }

function TTrace._Release: Integer;
begin
  Result := AtomicDecrement(FRefCount);
  if Result = 0 then
    try
      FTracer.OnLeaveScope(TPerformanceCounter.GetMetrics);
    finally
      __MarkDestroying(Self);
      Destroy;
      TPerformanceCounter.Start;
    end;
end;

class function TTrace.Create(const AScopeName: string): IInterface;
begin
  Result := nil;
  if Assigned(FTracer) and FTracer.OnEnterScope(TPerformanceCounter.GetMetrics, AScopeName) then
    begin
      Result := inherited Create; // create a trace only if the scope name is not filtered by the tracer
      TPerformanceCounter.Start;  // start counting performance only if the trace was created
    end;
end;

end.
