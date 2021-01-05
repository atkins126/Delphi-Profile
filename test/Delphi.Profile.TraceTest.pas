unit Delphi.Profile.TraceTest;

interface

uses
  DUnitX.TestFramework,
  Delphi.Mocks,
  Delphi.Profile.Trace,
  Delphi.Profile.PerformanceCounter,
  System.Generics.Collections;

type

  TTraceEvent = record
    FEventType: (TraceEnter, TraceLeave);
    FMetrics: TPerformanceMetrics;
    FScopeName: string;
  end;

  [TestFixture]
  TTraceTest = class
    private
      FTracer: TMock<ITracer>;
      FTraces: TStack<TTraceEvent>;

      procedure SetupMock;

    const
      CMaximumTickCount        = 3;
      CMaximumTickCountWithWmi = 10;

    public
      [Setup]
      procedure Setup;
      [TearDown]
      procedure TearDown;

      [Test]
      procedure TestSetTrace;

      [Test]
      procedure TestTrace;

      [Test]
      procedure TestTraceWithWmi;

      [Test]
      procedure TestNestedTrace;
  end;

implementation

uses
  System.Rtti;

procedure TTraceTest.Setup;
begin
  FTracer       := TMock<ITracer>.Create;
  FTraces       := TStack<TTraceEvent>.Create;
  TTrace.Tracer := FTracer;
  SetupMock;

  TPerformanceCounter.EnableWmi := False;
end;

procedure TTraceTest.SetupMock;
begin
  FTracer.Setup.WillExecute('OnEnterScope',
      function(const args: TArray<TValue>; const ReturnType: TRttiType): TValue
    var
      Event: TTraceEvent;
    begin
      Event.FEventType := TraceEnter;
      Event.FMetrics := args[1].AsType<TPerformanceMetrics>();
      Event.FScopeName := args[2].AsType<string>();
      FTraces.Push(Event);
      Result := True;
    end);
  FTracer.Setup.WillExecute('OnLeaveScope',
    function(const args: TArray<TValue>; const ReturnType: TRttiType): TValue
    var
      Event: TTraceEvent;
    begin
      Event.FEventType := TraceLeave;
      Event.FMetrics := args[1].AsType<TPerformanceMetrics>();
      FTraces.Push(Event);
    end);
end;

procedure TTraceTest.TearDown;
begin
  FTracer.Free;
  FTraces.Free;
end;

procedure TTraceTest.TestSetTrace;
begin
  TTrace.Tracer := nil;
  FTracer.Setup.Expect.Never('OnEnterScope');
  FTracer.Setup.Expect.Never('OnLeaveScope');
  begin
    TTrace.Create(''); // luckily, Delphi saves the returned trace in the nested scope stack
  end;
  Assert.AreEqual(0, FTraces.Count);
  FTracer.VerifyAll;
  Assert.IsNull(TTrace.Create('')); // in this case, the trace will be saved in the function stack
end;

procedure TTraceTest.TestTrace;
begin
  FTracer.Setup.Expect.Once('OnEnterScope');
  FTracer.Setup.Expect.Once('OnLeaveScope');
  begin
    TTrace.Create('abcdefghijklmnopqrstuvwxyz'); // count number of ticks spent in this block
  end;
  Assert.AreEqual(2, FTraces.Count);
  with FTraces.Pop do
    begin
      Assert.AreEqual(TraceLeave, FEventType);
      Assert.IsTrue(FMetrics.FRealClockTime < CMaximumTickCount);
    end;
  with FTraces.Pop do
    begin
      Assert.AreEqual('abcdefghijklmnopqrstuvwxyz', FScopeName);
      Assert.AreEqual(TraceEnter, FEventType);
    end;
  FTracer.VerifyAll;
  Assert.IsNotNull(TTrace.Create('')); // in this case, the trace will be saved in the function stack
end;

procedure TTraceTest.TestTraceWithWmi;
begin
  FTracer.Setup.Expect.Once('OnEnterScope');
  FTracer.Setup.Expect.Once('OnLeaveScope');
  TPerformanceCounter.EnableWmi := True;
  begin
    TTrace.Create(''); // count number of ticks spent in this block
  end;
  Assert.AreEqual(2, FTraces.Count);
  with FTraces.Pop do
    begin
      Assert.AreEqual(TraceLeave, FEventType);
      Assert.IsTrue(FMetrics.FRealClockTime < CMaximumTickCountWithWmi);
    end;
  with FTraces.Pop do
    begin
      Assert.AreEqual('', FScopeName);
      Assert.AreEqual(TraceEnter, FEventType);
    end;
  FTracer.VerifyAll;
end;

procedure TTraceTest.TestNestedTrace;
begin
  FTracer.Setup.Expect.Exactly('OnEnterScope', 2);
  FTracer.Setup.Expect.Exactly('OnLeaveScope', 2);
  begin
    TTrace.Create('Outer');
    begin
      TTrace.Create('Inner');
    end;
  end;
  Assert.AreEqual(4, FTraces.Count);
  with FTraces.Pop do
    begin
      Assert.AreEqual(TraceLeave, FEventType);
      Assert.IsTrue(FMetrics.FRealClockTime < CMaximumTickCount);
    end;
  with FTraces.Pop do
    begin
      Assert.AreEqual(TraceLeave, FEventType);
      Assert.IsTrue(FMetrics.FRealClockTime < CMaximumTickCount);
    end;
  with FTraces.Pop do
    begin
      Assert.AreEqual('Inner', FScopeName);
      Assert.AreEqual(TraceEnter, FEventType);
      Assert.IsTrue(FMetrics.FRealClockTime < CMaximumTickCount);
    end;
  with FTraces.Pop do
    begin
      Assert.AreEqual('Outer', FScopeName);
      Assert.AreEqual(TraceEnter, FEventType);
    end;
  FTracer.VerifyAll;
end;

initialization

TDUnitX.RegisterTestFixture(TTraceTest);

end.
