
namespace Echo
{
	public enum SymbolType
	{
		FILE = 1,
		NAMESPACE  = 1 << 1,
		CLASS = 1 << 2,
		CONSTRUCTOR = 1 << 3,
		DESTRUCTOR = 1 << 4,
		ENUM = 1 << 5,
		INTERFACE = 1 << 6,
		METHOD = 1 << 7,
		STRUCT = 1 << 8,
		PROPERTY = 1 << 9,
		FIELD = 1 << 10,
		SIGNAL  = 1 << 11,
    FUNCTION  = 1 << 12 ;

		public string to_string () {
			switch(this) {
				case FILE: 
					return "File" ; 
				case NAMESPACE: 
					return "Namespace" ; 
				case CLASS: 
					return "Class" ; 
				case CONSTRUCTOR: 
					return "Constructor" ; 
				case DESTRUCTOR: 
					return "Destructor" ; 
				case INTERFACE: 
					return "Interface" ; 
				case METHOD: 
					return "Method" ; 
				case STRUCT: 
					return "Struct" ; 
				case PROPERTY: 
					return "Property" ; 
				case FIELD: 
					return "Field" ; 
				case SIGNAL: 
					return "Signal" ; 
				case FUNCTION: 
					return "Function" ; 					
        default:
          assert_not_reached ();
			}
		}

	}

  [Flags]
	public enum AccessType
	{
		PRIVATE = 1,
		INTERNAL = 1 << 1,
		PROTECTED = 1 << 2,
		PUBLIC = 1 << 3
//	useful?	ANY = SymbolAccessibility.PRIVATE | SymbolAccessibility.INTERNAL | SymbolAccessibility.PROTECTED | SymbolAccessibility.PUBLIC

	}

	public class SourceReference {
		public string file_full_path { get ; set ; } 
		public int line { get ; set ; }
		public int column { get ; set ; }
		public int last_line { get ; set ; }
		
		public SourceReference (string file_full_path, int line, int column, int last_line) {
			this.file_full_path = file_full_path ; 
			this.line = line ; 
			this.column = column;
			this.last_line=last_line;
		}
	}

	public class DataType
	{
		/**
		 * Symbol this DataType belongs to
		 */
		public unowned Symbol? symbol  { get ; set ; }

		public string name  { get ; set ; }
		public string type_name  { get ; set ; }

		public bool is_array  { get ; set ; }
		public bool is_pointer  { get ; set ; }
		public bool is_generic  { get ; set ; }
		public bool is_nullable { get ; set ; }
		public bool is_out  { get ; set ; }
		public bool is_ref  { get ; set ; }
	}

	public class Symbol
	{
		public SymbolType symbol_type { get ; set ; }
		public AccessType access_type { get ; set ; }
		public string verbose_name { get ; set ; }
		public string name { get ; set ; }
		public Symbol? parent { get ; set ; }
		public Vala.List<Symbol> children { get ; set ; default = new Vala.ArrayList<Symbol> () ; }
		public string source_file_name { get ; set ; }
		public int source_line { get ; set ; }
		public int source_column { get ; set ; }
		public int source_last_line { get ; set ; }
		public Vala.List<DataType>? parameters { get ; set ; }

		public string fully_qualified_name {
			owned get {
				return parent == null || parent.parent == null ?
					name :
					"%s.%s".printf (parent.fully_qualified_name, name);
			}
		}

		private SourceReference _declaration = null ; 

		public SourceReference declaration {
			owned get {
				if( _declaration == null)
					_declaration = new SourceReference (source_file_name, source_line, source_column, source_last_line);
				return _declaration;
			}
		}

		public string to_string () {
			return "%s: %s".printf(fully_qualified_name, symbol_type.to_string ());
		}
	}

	public class CodeTree : Vala.CodeVisitor
	{
		Symbol current;

		HashTable<string,Symbol> trees = new HashTable<string,Symbol> (str_hash, str_equal);

		public void update_code_tree (Vala.SourceFile src)
		{
			var root = new Symbol ();
			root.symbol_type = SymbolType.FILE;
			root.verbose_name = root.name = src.filename;

			current = root;
			src.accept_children (this);

			trees[src.filename] = root;
		}

		public Symbol? get_code_tree (Vala.SourceFile src)
		{
			var tree = trees[src.filename];
			if (tree == null)
				update_code_tree (src);

			return trees[src.filename];
		}

		void check_location (Vala.Symbol symbol, SymbolType symbol_type)
		{
			if (symbol.hides)
				return;

			var s = new Symbol ();
			s.symbol_type = symbol_type;
			s.access_type = (AccessType) symbol.access;
			s.source_file_name = symbol.source_reference.file.filename;
			s.source_line = symbol.source_reference.begin.line;
			s.source_last_line = symbol.source_reference.end.line;
			s.source_column = symbol.source_reference.begin.column;
			s.verbose_name = Utils.symbol_to_string (symbol);
			s.name = Utils.symbol_to_name (symbol);
			s.parent = current;
			s.parameters = Utils.extract_parameters (symbol);

			var prev = current;
			current = s;

			// prev.children.prepend (s);
			prev.children.insert (0, s);
			symbol.accept_children (this);
			// s.children.reverse ();
			s.children = Utils.reverse (s.children);

			current = prev;
		}

		public override void visit_namespace (Vala.Namespace symbol)
		{
			check_location (symbol, SymbolType.NAMESPACE);
		}
		public override void visit_class (Vala.Class symbol)
		{
			check_location (symbol, SymbolType.CLASS);
		}
		public override void visit_block (Vala.Block symbol)
		{
			symbol.accept_children (this);
		}
		public override void visit_constructor (Vala.Constructor symbol)
		{
			check_location (symbol, SymbolType.CONSTRUCTOR);
		}
		public override void visit_creation_method (Vala.CreationMethod symbol)
		{
			check_location (symbol, SymbolType.CONSTRUCTOR);
		}
		public override void visit_destructor (Vala.Destructor symbol)
		{
			check_location (symbol, SymbolType.DESTRUCTOR);
		}
		public override void visit_enum (Vala.Enum symbol)
		{
			check_location (symbol, SymbolType.ENUM);
		}
		public override void visit_interface (Vala.Interface symbol)
		{
			check_location (symbol, SymbolType.INTERFACE);
		}
		public override void visit_method (Vala.Method symbol)
		{
			check_location (symbol, SymbolType.METHOD);
		}
		public override void visit_struct (Vala.Struct symbol)
		{
			check_location (symbol, SymbolType.STRUCT);
		}
		public override void visit_property (Vala.Property symbol)
		{
			check_location (symbol, SymbolType.PROPERTY);
		}
		public override void visit_field (Vala.Field symbol)
		{
			check_location (symbol, SymbolType.FIELD);
		}
		public override void visit_signal (Vala.Signal symbol)
		{
			check_location (symbol, SymbolType.SIGNAL);
		}
	}
}

