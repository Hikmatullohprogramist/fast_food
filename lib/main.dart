import 'package:fast_food/insert_product.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'db_helper.dart';
import 'package:intl/intl.dart';

bool isProduction = false;

void main() {
  runApp(MyApp());

  isProduction = true;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fast Food App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FastFoodPage(),
    );
  }
}

class FastFoodPage extends StatefulWidget {
  @override
  _FastFoodPageState createState() => _FastFoodPageState();
}

class _FastFoodPageState extends State<FastFoodPage> {
  List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _selectedProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await DatabaseHelper.instance.getProducts();
    setState(() {
      _products = products;
    });
  }

  void _addProduct(Map<String, dynamic> product) {
    setState(() {
      // Check if the product already exists in the list
      int index =
          _selectedProducts.indexWhere((p) => p['name'] == product['name']);

      if (index != -1) {
        // If it exists, increment the count
        _selectedProducts[index]['count']++;
      } else {
        // If it doesn't exist, add the product with count 1
        _selectedProducts.add({...product, 'count': 1});
      }
    });
  }

  void _removeProduct(Map<String, dynamic> product) {
    setState(() {
      _selectedProducts.removeWhere((p) => p['id'] == product['id']);
    });
  }

  Future<void> _printSelectedProducts(
      String address, String clientPhone, String fastFoodNumber) async {
    final pdf = pw.Document();

    // Jami summani hisoblash
    int totalAmount = _selectedProducts
        .map((p) => p['count'] * p['price'])
        .reduce((a, b) => a + b);

    // Current date
    String currentDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(58 * 2.835, double.infinity),
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(4.0), // Overall padding
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Cafe Title
                pw.Text(
                  'Food Cafe',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),

                pw.Text(
                  '+998 90 778 6655',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Manzil: O\'ram choyxonasi ro\'parasida',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.start,
                ),
                pw.SizedBox(height: 2),

                // Card Number
                pw.Text(
                  'Karta: 5614-6818-1840-7672\nSattorov A',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.start,
                ),
                pw.SizedBox(height: 2),

                // Current Date and Time
                pw.Text(
                  'Sana: $currentDate',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 10),
                pw.Divider(), // Separator line
                pw.ListView.builder(
                  itemCount: _selectedProducts.length,
                  itemBuilder: (context, index) {
                    final product = _selectedProducts[index];
                    final subtotal = product['price'] * product['count'];
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 2.0), // Reduced vertical padding
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '${product['name']}',
                              style: const pw.TextStyle(fontSize: 10),
                              maxLines: 1, // Prevents overflow
                            ),
                          ),
                          pw.Text(
                            '${product['count']} x ${product['price']} = $subtotal',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                pw.Divider(), // Another separator line
                pw.SizedBox(height: 5),

                // Jami summa
                pw.Text(
                  'Jami Summa: $totalAmount UZS',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
                pw.SizedBox(height: 8),

                pw.Text(
                  'Tel: $clientPhone',
                  style: pw.TextStyle(
                    fontSize: 10,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  'Manzil: $address',
                  style: pw.TextStyle(
                    fontSize: 10,
                  ),
                  textAlign: pw.TextAlign.center,
                ),

                pw.Text(
                  'Haridiging uchun rahmat :)',
                  style: pw.TextStyle(
                    fontSize: 10,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );

    // Clear selected products after printing
    setState(() {
      _selectedProducts.clear();
    });
  }

  Future<void> _navigateToInsertProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InsertProductScreen()),
    );

    if (result == true) {
      _loadProducts();
    }
  }

  TextEditingController clientNameController = TextEditingController();
  TextEditingController clientPhoneController = TextEditingController();
  TextEditingController fastFoodNumberController = TextEditingController();

  final FocusNode _clientNameFocusNode = FocusNode();
  final FocusNode _clientPhoneFocusNode = FocusNode();
  final FocusNode _fastFoodNumberFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = "";
  @override
  void dispose() {
    _clientNameFocusNode.dispose();
    _clientPhoneFocusNode.dispose();
    _fastFoodNumberFocusNode.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    fastFoodNumberController.text = "+998907786655";
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Fast Food'),
        actions: [
          IconButton(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
          ),
          isProduction
              ? Container()
              : IconButton(
                  onPressed: () async {
                    await DatabaseHelper.instance.deleteDB();
                  },
                  icon: const Icon(Icons.delete_forever),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToInsertProduct,
        child: const Text('+'),
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 6),
                // Search Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    focusNode: _searchFocusNode,
                    onTap: () {
                      _searchFocusNode.requestFocus();
                    },
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value; // Update search query
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Mahsulotlarni qidirish',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Filter products based on the search query
                Expanded(
                  child: ListView.builder(
                    itemCount: _products.where((product) {
                      // Filtering logic: check if product name contains the search query
                      return product['name']
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                    }).length,
                    itemBuilder: (context, index) {
                      final product = _products.where((product) {
                        return product['name']
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                      }).toList()[index]; // Get the filtered product

                      return Card(
                        child: ListTile(
                          title: Text(product['name']),
                          subtitle: Text('${product['price']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _addProduct(product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever),
                                onPressed: () async {
                                  int productIdToDelete = product['id'];
                                  int result = await DatabaseHelper.instance
                                      .deleteProduct(productIdToDelete);

                                  if (result > 0) {
                                    print('Product deleted successfully.');
                                    _loadProducts();
                                  } else {
                                    print('Failed to delete product.');
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      // Address Field
                      TextField(
                        controller: clientNameController,
                        focusNode: _clientNameFocusNode,
                        onTap: () {
                          _clientNameFocusNode.requestFocus();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Manzil',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Phone Number Field
                      TextField(
                        controller: clientPhoneController,
                        focusNode: _clientPhoneFocusNode,
                        onTap: () {
                          _clientPhoneFocusNode.requestFocus();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Telefon Raqami',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Fast Food Number Field
                      TextField(
                        controller: fastFoodNumberController,
                        focusNode: _fastFoodNumberFocusNode,
                        onTap: () {
                          _fastFoodNumberFocusNode.requestFocus();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Fast Food Raqami',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Button for printing selected products
                ElevatedButton(
                  onPressed: () {
                    _printSelectedProducts(
                        clientNameController.text,
                        clientPhoneController.text,
                        fastFoodNumberController.text);
                  },
                  child: const Text('Sotish 🖨️'),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _selectedProducts.length,
                    itemBuilder: (context, index) {
                      final product = _selectedProducts[index];
                      product['count'] ??= 0;

                      return Card(
                        child: ListTile(
                          title: Text(product['name']),
                          subtitle: Text('${product['price']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  product['count']++;
                                  setState(() {});
                                },
                              ),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  '${product['count']}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (product['count'] > 0) {
                                    product['count']--;
                                  }

                                  setState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeProduct(product),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 50,
        color: Colors.grey[200],
        padding: const EdgeInsets.all(8.0),
        child: const Center(
          child: Text(
            '© 2024 SOLVEX. Barcha huquqlar himoyalangan.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}
