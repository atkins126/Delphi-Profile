unit Delphi.Profile.ScopeInfoTest;

interface

uses
  DUnitX.TestFramework,
  Delphi.Profile.ScopeInfo;

type

  [TestFixture]
  TScopeInfoTest = class
    private
      FScopeInfo: TScopeInfo;

    public
      [Setup]
      procedure Setup;
      [TearDown]
      procedure TearDown;

      [Test]
      procedure TestGetCommaHeader;
  end;

implementation

uses
  System.SysUtils;

{ TScopeInfoTest }

procedure TScopeInfoTest.Setup;
begin
  FScopeInfo := TScopeInfo.Create('abc');
end;

procedure TScopeInfoTest.TearDown;
begin
  FScopeInfo.Free;
end;

procedure TScopeInfoTest.TestGetCommaHeader;
begin
  Assert.AreEqual('"Scope Name","Total Hits","Total Time (us)","Average Time (us)"', TScopeInfo.CommaHeader);
end;

initialization

TDUnitX.RegisterTestFixture(TScopeInfoTest);

end.
