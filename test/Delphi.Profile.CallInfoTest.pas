unit Delphi.Profile.CallInfoTest;

interface

uses
  DUnitX.TestFramework,
  Delphi.Profile.CallInfo;

type

  [TestFixture]
  TCallInfoTest = class
    private
      FCallInfo: TCallInfo;

    public
      [Setup]
      procedure Setup;
      [TearDown]
      procedure TearDown;

      [Test]
      procedure TestGetCommaHeader;
  end;

implementation

{ TCallInfoTest }

procedure TCallInfoTest.Setup;
begin
  FCallInfo := TCallInfo.Create('abc');
end;

procedure TCallInfoTest.TearDown;
begin
  FCallInfo.Free;
end;

procedure TCallInfoTest.TestGetCommaHeader;
begin
  Assert.AreEqual('"Function","Total Calls","Total Time (us)","Average Time (us)"', TCallInfo.CommaHeader);
end;

initialization

TDUnitX.RegisterTestFixture(TCallInfoTest);

end.
