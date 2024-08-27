import 'package:fast_food/insert_product.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'db_helper.dart';

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
  List<Map<String, dynamic>> _selectedProducts = [];

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

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(58 * 2.835, double.infinity),
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(4.0), // Overall padding
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Manzil, telefon raqami va fast food raqami
                pw.Text('Manzil: $address',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('Telefon Raqami: $clientPhone',
                    style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Fast Food Raqami: $fastFoodNumber',
                    style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 10),

                // Mahsulotlar ro‘yxati
                pw.Text('Tanlangan Mahsulotlar:',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Divider(), // Separator line
                pw.ListView.builder(
                  itemCount: _selectedProducts.length,
                  itemBuilder: (context, index) {
                    final product = _selectedProducts[index];
                    final subtotal = product['price'] * product['count'];
                    // totalAmount += subtotal; // Jami summaga qo'shish
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
                pw.SizedBox(height: 10),
                pw.Divider(), // Another separator line
                pw.SizedBox(height: 5),

                // Jami summa
                pw.Text(
                  'Jami Summa: $totalAmount',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
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
  String _searchQuery = "";
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
                  icon: const Icon(Icons.delete_forever))
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
                TextField(
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
                      TextField(
                        controller: clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Manzil',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: clientPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefon Raqami',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: fastFoodNumberController,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Fast Food Raqami'),
                      ),
                    ],
                  ),
                ),
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
