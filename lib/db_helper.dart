import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fast_food_test.db');
    return _database!;
  }

  Future<void> deleteDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fast_food_test.db');

    await databaseFactoryFfi.deleteDatabase(path);

    print('Database deleted at: $path');    

    _database = null;
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;

    try {
      return await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
    } on Exception catch (e) {
      print('Error deleting product: $e');
      return 0; // Return 0 if there was an error
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await databaseFactoryFfi.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: _createDB,
        ));
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      price INTEGER,
      count INTEGER
    )
    ''');

    // // Insert some initial data
    await db.insert('products', {'name': 'Lavash', 'price': 22000, 'count': 1});
    await db
        .insert('products', {'name': 'Shaurma', 'price': 20000, 'count': 1});
    // await db.insert('products', {'name': 'Burger', 'price': 18000, 'count': 1});
    // await db
    //     .insert('products', {'name': 'Hot Dog', 'price': 15000, 'count': 1});
    // await db.insert('products', {'name': 'Pizza', 'price': 45000, 'count': 1});
    // await db.insert('products', {'name': 'Donar', 'price': 25000, 'count': 1});
    // await db.insert(
    //     'products', {'name': 'Fried Chicken', 'price': 30000, 'count': 1});
    // await db.insert(
    //     'products', {'name': 'Kartoshka Free', 'price': 12000, 'count': 1});
    // await db.insert('products', {'name': 'Sushi', 'price': 35000, 'count': 1});
    // await db.insert('products', {'name': 'Samsa', 'price': 10000, 'count': 1});
    // await db
    //     .insert('products', {'name': 'Cheburek', 'price': 14000, 'count': 1});
    // await db.insert(
    //     'products', {'name': 'Qovurilgan Baliq', 'price': 32000, 'count': 1});
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;

    print(db.query("products").then((value) => print(value)));
    return db.query('products');
  }

  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await instance.database;
    try {
      await db.insert('products', product);
    } on Exception catch (e) {
      print('Error inserting product: $e');
    }
    return 1;
  }
}
