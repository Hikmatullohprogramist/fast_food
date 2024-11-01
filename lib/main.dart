import 'package:fast_food/insert_product.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'db_helper.dart';
import 'package:intl/intl.dart';

bool isProduction = false;

void main() {
  sqfliteFfiInit();
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
  Printer? _cachedPrinter;

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

  Future<void> _selectPrinter(BuildContext context) async {
    _cachedPrinter = await Printing.pickPrinter(context: context);
  }

  Future<void> _printSelectedProducts(
    String address,
    String clientPhone,
    String fastFoodNumber,
  ) async {
    if (_cachedPrinter == null) {
      await _selectPrinter(context);
    }

    if (_cachedPrinter != null) {
      final pdf = pw.Document();

      // Calculate total amount
      int totalAmount = _selectedProducts
          .map((p) => p['count'] * p['price'])
          .reduce((a, b) => a + b);

      // Current date
      String currentDate =
          DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

      // Add the receipt content to the PDF
      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(58 * 2.835, double.infinity),
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(4.0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
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
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Karta: 5614-6818-1840-7672\nSattorov A',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Sana: $currentDate',
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  pw.ListView.builder(
                    itemCount: _selectedProducts.length,
                    itemBuilder: (context, index) {
                      final product = _selectedProducts[index];
                      final subtotal = product['price'] * product['count'];
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                '${product['name']}',
                                style: const pw.TextStyle(fontSize: 10),
                                maxLines: 1,
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
                  pw.Divider(),
                  pw.SizedBox(height: 5),
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
                    style: const pw.TextStyle(
                      fontSize: 10,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'Manzil: $address',
                    style: const pw.TextStyle(
                      fontSize: 10,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'Haridingiz uchun rahmat :)',
                    style: const pw.TextStyle(
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

      // Directly print the document using the selected printer
      try {
        await Printing.directPrintPdf(
          printer: _cachedPrinter!,
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: "fast_food_chek.pdf",
        );
      } catch (e) {
        print('Error printing: $e');
      }

      clearTextFieldTexts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No printer selected!'),
        ),
      );
    }
  }

  clearTextFieldTexts() {
    setState(() {
      _selectedProducts.clear();
      clientNameController.clear();
      clientPhoneController.clear();
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
          IconButton(
              onPressed: () {
                _selectPrinter(context);
              },
              icon: const Icon(Icons.print)),
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
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
                  // Filter products based on the search query and display in a grid
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 3 / 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: _products.where((product) {
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

                        return InkWell(
                          onTap: () {
                            _addProduct(product);
                          },
                          child: Card(
                            child: Stack(
                              children: [
                                // Product Info
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        product['name'],
                                        style: const TextStyle(fontSize: 16.0),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        '${product['price']}',
                                        style: const TextStyle(fontSize: 14.0),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                // Delete Button Positioned at the bottom-right
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete_forever,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      // Show confirmation dialog
                                      bool? confirmDelete =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                              'Mahsulotni o\'chirish'),
                                          content: const Text(
                                              'Siz chindan ham ushbu mahsulotni o\'chirmoqchimisiz?'),
                                          actions: [
                                            TextButton(
                                              child: const Text('Bekor qilish'),
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(false);
                                              },
                                            ),
                                            TextButton(
                                              child: const Text('O\'chirish'),
                                              onPressed: () {
                                                Navigator.of(context).pop(true);
                                              },
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmDelete == true) {
                                        // Perform delete operation if confirmed
                                        int productIdToDelete = product['id'];
                                        int result = await DatabaseHelper
                                            .instance
                                            .deleteProduct(productIdToDelete);

                                        if (result > 0) {
                                          print(
                                              'Product deleted successfully.');
                                          _loadProducts();
                                        } else {
                                          print('Failed to delete product.');
                                        }
                                      }
                                    },
                                  ),
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
                      const SizedBox(height: 12),
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
