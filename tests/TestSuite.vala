public static int main(string[] args) {
  Test.init (ref args);

  // add any of your test cases here
  TestSuite.get_root().add_suite(new SymbolListingTestCase().get_suite());
  
  return Test.run ();
}