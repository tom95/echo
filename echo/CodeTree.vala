
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
		ERRORDOMAIN  = 1 << 12,
		CONSTANT  = 1 << 13,
		DELEGATE = 1 << 14;

		public string to_string () {
			switch(this) {
				case FILE: 
					return "File";
				case NAMESPACE: 
					return "Namespace";
				case CLASS: 
					return "Class";
				case CONSTRUCTOR: 
					return "Constructor";
				case DESTRUCTOR: 
					return "Destructor";
				case INTERFACE: 
					return "Interface";
				case ENUM: 
					return "Enum";
				case METHOD: 
					return "Method";
				case STRUCT: 
					return "Struct";
				case PROPERTY: 
					return "Property";
				case FIELD: 
					return "Field";
				case SIGNAL: 
					return "Signal";
				case CONSTANT: 
					return "Constant";
				case ERRORDOMAIN: 
					return "ErrorDomain";
				case DELEGATE: 
					return "Delegate";
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
			this.file_full_path = file_full_path;
			this.line = line;
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

		// TODO
		public Gee.List<DataType>? generic_types { get ; set ; }

	}

	public class Symbol
	{
		public SymbolType symbol_type { get ; set ; }
		public AccessType access_type { get ; set ; }
		public string verbose_name { get ; set ; }
		public string name { get ; set ; }
		public Symbol? parent { get ; set ; }
		public Gee.List<Symbol> children { get ; set ; default = new Gee.ArrayList<Symbol> () ; }
		public string source_file_name { get ; set ; }
		public int source_line { get ; set ; }
		public int source_column { get ; set ; }
		public int source_last_line { get ; set ; }
		public Gee.List<DataType>? parameters { get ; set ; }
		
		// public Gee.List<Symbol>? symbols;

		public string fully_qualified_name {
			owned get {
				return parent == null || parent.parent == null ?
					name :
					"%s.%s".printf (parent.fully_qualified_name, name);
			}
		}

		private SourceReference _declaration = null;

		public SourceReference declaration {
			owned get {
				var file_name = source_file_name == null ? "unknown" : source_file_name;

				if( _declaration == null)
					_declaration = new SourceReference (file_name, source_line, source_column, source_last_line);
				return _declaration;
			}
		}

		public string to_string (bool hide_line=false) {
			if (hide_line)
				return "%s - %s".printf(fully_qualified_name, symbol_type.to_string ());
			else
				return "%s - %s - %d:%d".printf(fully_qualified_name, symbol_type.to_string (), source_line, source_column);
		}
	}

	public class CodeTree
	{
		Vala.CodeContext context;

		HashTable<string, Symbol> trees =
				new HashTable<string, Symbol> (str_hash, str_equal);
		HashTable<string, Gee.List<Symbol>> lists =
				new HashTable<string, Gee.List<Symbol>> (str_hash, str_equal);

		public CodeTree (Vala.CodeContext context)
		{
			this.context = context;
		}

		public void update_code_tree (Vala.SourceFile src)
		{
			//message ("update_code_tree (%s)", src.filename);
			var symbols = new Gee.ArrayList<Symbol> ();
			var root = new Symbol ();
			root.symbol_type = SymbolType.FILE;
			root.verbose_name = root.name = src.filename;
			// root.symbols = symbols;
			//symbols.add (root);

			//current_symbol_list = new Gee.ArrayList<Symbol> ();

			//current_file = src;
			//current = root;
			var visitor = new Visitor (root, src);
			var reporter = (Reporter) context.report;
			reporter.clear_errors (src.filename);

			//context.accept (this);
			context.accept (visitor);
			// FIXME : sort the symbol tree also
			sort_symbols (root.children);
			sort_symbols (visitor.current_symbol_list, true);
			trees[src.filename] = root;
			lists[src.filename] = visitor.current_symbol_list;
		}

		private void sort_symbols (Gee.List<Symbol> symbols, bool flat = false) {
			symbols.sort((a,b) => {
			    return a.source_line - b.source_line;
			});
			if (!flat)
				foreach (var sym in symbols)
					sort_symbols (sym.children, flat);
		} 

		public Symbol? get_code_tree (Vala.SourceFile src)
		{
			var tree = trees[src.filename];
			if (tree == null)
				update_code_tree (src);

			return trees[src.filename];
		}

		public Symbol? find_root_symbol (Vala.SourceFile src) {
			var result = get_code_tree (src);
			if (result == null)
				message ("find_root_symbol: NULL for '%s'", src.filename);

			return result;
		}

		public Gee.List<Symbol>? find_symbols (Vala.SourceFile src) {
			var list = lists[src.filename];
			if (list == null)
				update_code_tree (src);

			return lists[src.filename];
		}

		
	}
}

