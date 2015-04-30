using Echo;

namespace Echo.Tests {
    public class ExtraSymbolsTestCase: EchoTestCase {
   
    public ExtraSymbolsTestCase () {
      base ("ExtraSymbolsTestCase");
      // add test methods

      add_file_test ("test_error_domain", "(main_error_domain.vala)", test_error_domain);
      add_file_test ("test_constant", "(main_constant.vala)", test_constant);
     }

     public override void set_up () {
       // setup your test
     }

    public void test_error_domain () {
      assert_symbol_type (get_root_symbols ("./tests/files/main_error_domain.vala"), SymbolType.ERRORDOMAIN);
     }

    public void test_constant () {
      assert_symbol_type (get_root_symbols ("./tests/files/main_constant.vala"), SymbolType.CONSTANT);
     }

     public override void tear_down () {
     }
  }
}