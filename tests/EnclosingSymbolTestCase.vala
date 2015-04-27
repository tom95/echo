using Echo ; 

class EnclosingSymbolTestCase : Gee.TestCase {
 
  public EnclosingSymbolTestCase () {
    base ("EnclosingSymbolTestCase");
    // add test methods

    add_file_test ("test_simple_method", "(main.vala)", test_simple_method);
    //add_file_test ("test_main_namespace", "(main_namespace.vala)", test_main_namespace);
    //add_file_test ("test_main_function", "(main_function.vala)", test_main_function);
   }

   public override void set_up () {
     // setup your test
   }
 
   public void test_simple_method () {
     assert_symbol_type_and_name (get_all_symbols_for_file ("./files/main.vala"), "HelloClass.main", SymbolType.CLASS);
   }
 
  /*public void test_main_namespace () {
    assert_symbol_type (get_root_symbols ("./files/main_namespace.vala"), SymbolType.NAMESPACE);
   }

  public void test_main_function () {
    assert_symbol_type (get_root_symbols ("./files/main_function.vala"), SymbolType.FUNCTION);
   }*/

   public override void tear_down () {
   }
}