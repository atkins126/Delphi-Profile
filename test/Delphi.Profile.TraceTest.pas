unit Delphi.Profile.TraceTest;

interface

uses
  DUnitX.TestFramework,
  Delphi.Mocks,
  Delphi.Profile,
  System.Generics.Collections;

type

  [TestFixture]
  TTraceTest = class
    private
      FTracer: TMock<ITracer>;
      FTraces: TStack<TTraceInfo>;

    public
      [Setup]
      procedure Setup;
      [TearDown]
      procedure TearDown;

      [Test]
      [TestCase('Empty scope name', '')]
      [TestCase('Non-empty scope name', 'abcdefghijklmnopqrstuvwxyz')]
      procedure TestTrace(const AScopeName: string);
  end;

implementation

uses
  System.Rtti;

procedure TTraceTest.Setup;
begin
  FTracer := TMock<ITracer>.Create;
  FTraces := TStack<TTraceInfo>.Create;
  FTracer.Setup.WillExecute('Log',
      function(const args: TArray<TValue>; const ReturnType: TRttiType): TValue
    begin
      FTraces.Push(args[1].AsType<TTraceInfo>());
    end);
  SetTracer(FTracer);
end;

procedure TTraceTest.TearDown;
begin
  FTracer.Free;
  FTraces.Free;
end;

procedure TTraceTest.TestTrace(const AScopeName: string);
begin
  FTracer.Setup.Expect.Exactly('Log', 2);
  begin
    Trace(AScopeName); // count number of ticks spent in this block
  end;
  Assert.AreEqual(2, FTraces.Count);
  with FTraces.Pop do
    begin
      Assert.AreEqual(AScopeName, FScopeName);
      Assert.AreEqual(TraceLeave, FEventType);
      Assert.IsTrue(FElapsedTicks < 3);
    end;
  with FTraces.Pop do
    begin
      Assert.AreEqual(AScopeName, FScopeName);
      Assert.AreEqual(TraceEnter, FEventType);
      Assert.IsTrue(FElapsedTicks > 0);
    end;
end;

initialization

TDUnitX.RegisterTestFixture(TTraceTest);

end.
