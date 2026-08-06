import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

String formatRupiah(int amount) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(amount);
}

Future<Uint8List> buildReceiptPdf(TransactionRecord transaction) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return [
          pw.Center(
            child: pw.Text(
              'BAKSO URAT MAD GEMBUL',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.orange900,
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'No Pesanan : ${transaction.id}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Nama pelanggan : ${transaction.customerName}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Nomor meja : ${transaction.tableNumber}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Tanggal : ${DateFormat('dd-MM-yyyy HH:mm').format(transaction.date)}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Divider(height: 24),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: transaction.items.map((item) {
              final itemTotal =
                  (item['harga'] as int) * (item['jumlah'] as int);
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '${item['nama']} x${item['jumlah']}',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    ),
                    pw.Text(
                      formatRupiah(itemTotal),
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          pw.Divider(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                formatRupiah(transaction.total),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Pembayaran : ${transaction.pembayaran}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(
              'Terima kasih',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ];
      },
    ),
  );

  return pdf.save();
}

class TransactionRecord {
  final String id;
  final DateTime date;
  final String pembayaran;
  final int total;
  final String customerName;
  final String tableNumber;
  final List<Map<String, dynamic>> items;

  TransactionRecord({
    required this.id,
    required this.date,
    required this.pembayaran,
    required this.total,
    required this.customerName,
    required this.tableNumber,
    required this.items,
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      pembayaran: json['pembayaran'] as String,
      total: json['total'] as int,
      customerName: json['customerName'] as String? ?? '-',
      tableNumber: json['tableNumber'] as String? ?? '-',
      items: (json['items'] as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'pembayaran': pembayaran,
      'total': total,
      'customerName': customerName,
      'tableNumber': tableNumber,
      'items': items,
    };
  }
}

void main() {
  runApp(const BaksoApp());
}

class IndustrialPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final bool leftPipe;
  final bool rightPipe;

  const IndustrialPanel({
    super.key,
    required this.child,
    this.margin,
    this.leftPipe = false,
    this.rightPipe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Panel background
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade900.withOpacity(0.95),
                  Colors.grey.shade800.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black87, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  offset: const Offset(4, 6),
                  blurRadius: 12,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.02),
                  offset: const Offset(-2, -2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: child,
          ),

          // Rivets (corners)
          Positioned(top: -6, left: -6, child: _rivet()),
          Positioned(top: -6, right: -6, child: _rivet()),
          Positioned(bottom: -6, left: -6, child: _rivet()),
          Positioned(bottom: -6, right: -6, child: _rivet()),

          // Pipes (optional)
          if (leftPipe)
            Positioned(
              left: -36,
              top: 12,
              child: _pipeSegment(height: 24, rotate: -12),
            ),
          if (rightPipe)
            Positioned(
              right: -36,
              bottom: 12,
              child: _pipeSegment(height: 28, rotate: 12),
            ),
        ],
      ),
    );
  }

  Widget _rivet() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.grey.shade300, Colors.grey.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            offset: const Offset(1, 2),
            blurRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.black87, width: 1),
      ),
    );
  }

  Widget _pipeSegment({double height = 24, double rotate = 0}) {
    return Transform.rotate(
      angle: rotate * (math.pi / 180),
      child: Container(
        width: 60,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade700,
              Colors.grey.shade600,
              Colors.grey.shade800,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              offset: const Offset(2, 3),
              blurRadius: 6,
            ),
          ],
          border: Border.all(color: Colors.black87, width: 2),
        ),
      ),
    );
  }
}

class BaksoApp extends StatelessWidget {
  const BaksoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bakso Urat Mad Gembul',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.grey.shade900,
        cardColor: Colors.grey.shade850,
        textTheme: ThemeData.dark().textTheme.apply(bodyColor: Colors.white70),
      ),
      home: const MenuBakso(),
    );
  }
}

class MenuBakso extends StatefulWidget {
  const MenuBakso({super.key});

  @override
  State<MenuBakso> createState() => _MenuBaksoState();
}

class _MenuBaksoState extends State<MenuBakso> {
  final List<Map<String, dynamic>> menu = [
    {"nama": "Bakso Urat Original", "harga": 15000},
    {"nama": "Bakso Urat Jumbo", "harga": 25000},
    {"nama": "Bakso Telur", "harga": 20000},
    {"nama": "Es Teh", "harga": 5000},
    {"nama": "Es Jeruk", "harga": 7000},
  ];

  final List<Map<String, dynamic>> keranjang = [];
  final List<TransactionRecord> riwayatTransaksi = [];

  @override
  void initState() {
    super.initState();
    _loadRiwayatTransaksi();
  }

  // keys for connector overlay
  final GlobalKey _heroKey = GlobalKey();
  final List<GlobalKey> _serviceKeys = List.generate(5, (_) => GlobalKey());

  Future<void> _loadRiwayatTransaksi() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('transaction_history') ?? [];
    setState(() {
      riwayatTransaksi.clear();
      riwayatTransaksi.addAll(
        stored
            .map(
              (jsonText) => TransactionRecord.fromJson(
                jsonDecode(jsonText) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
    });
  }

  Future<void> _saveRiwayatTransaksi() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = riwayatTransaksi
        .map((record) => jsonEncode(record.toJson()))
        .toList();
    await prefs.setStringList('transaction_history', stored);
  }

  String _nextInvoiceId() {
    final invoiceNumbers = riwayatTransaksi
        .map((record) => record.id)
        .where((id) => id.startsWith('INV-'))
        .map((id) {
          final match = RegExp(r'INV-(\d{4})').firstMatch(id);
          return match != null ? int.parse(match.group(1)!) : 0;
        })
        .where((value) => value > 0)
        .toList();

    final nextNumber = invoiceNumbers.isEmpty
        ? 1
        : invoiceNumbers.reduce((a, b) => a > b ? a : b) + 1;
    return 'INV-${nextNumber.toString().padLeft(4, '0')}';
  }

  Future<void> _tambahRiwayat(TransactionRecord record) async {
    setState(() {
      riwayatTransaksi.insert(0, record);
    });
    await _saveRiwayatTransaksi();
  }

  void tambah(Map<String, dynamic> item) {
    setState(() {
      final index = keranjang.indexWhere((e) => e["nama"] == item["nama"]);

      if (index >= 0) {
        keranjang[index]["jumlah"]++;
      } else {
        keranjang.add({
          "nama": item["nama"],
          "harga": item["harga"],
          "jumlah": 1,
        });
      }
    });
  }

  void hapusKeranjang() {
    setState(() {
      keranjang.clear();
    });
  }

  bool _isDuplicateMenuName(String name, [int? ignoreIndex]) {
    final normalized = name.toLowerCase().trim();
    return menu.asMap().entries.any((entry) {
      if (ignoreIndex != null && entry.key == ignoreIndex) {
        return false;
      }
      return (entry.value['nama'] as String).toLowerCase().trim() == normalized;
    });
  }

  Future<void> _editMenuItem(int index) async {
    final nameController = TextEditingController(
      text: menu[index]["nama"] as String,
    );
    final priceController = TextEditingController(
      text: (menu[index]["harga"] as int).toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Menu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama menu'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final newName = nameController.text.trim();
      final newPrice =
          int.tryParse(priceController.text.replaceAll('.', '')) ?? 0;
      if (newName.isEmpty || newPrice <= 0) {
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Data tidak valid'),
              content: const Text('Nama dan harga harus diisi dengan benar.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }
      if (_isDuplicateMenuName(newName, index)) {
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Duplikasi menu'),
              content: const Text('Nama menu sudah ada. Gunakan nama lain.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }
      setState(() {
        menu[index] = {'nama': newName, 'harga': newPrice};
      });
    }
  }

  Future<void> _addMenuItem() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Menu Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama menu'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final name = nameController.text.trim();
      final price = int.tryParse(priceController.text.replaceAll('.', '')) ?? 0;
      if (name.isEmpty || price <= 0) {
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Data tidak valid'),
              content: const Text('Nama dan harga harus diisi dengan benar.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }
      if (_isDuplicateMenuName(name)) {
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Duplikasi menu'),
              content: const Text('Nama menu sudah ada. Gunakan nama lain.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }
      setState(() {
        menu.add({'nama': name, 'harga': price});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: IndustrialHeader(),
      ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Menu',
            onPressed: _addMenuItem,
          ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Dashboard Pemilik',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DashboardPage(riwayat: riwayatTransaksi),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Transaksi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RiwayatTransaksiPage(riwayat: riwayatTransaksi),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Hapus Keranjang',
            onPressed: keranjang.isEmpty
                ? null
                : () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Kosongkan Keranjang'),
                          content: const Text(
                            'Apakah Anda yakin ingin menghapus semua item di keranjang?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Hapus'),
                            ),
                          ],
                        );
                      },
                    );

                    if (result == true) {
                      hapusKeranjang();
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutPage(
                    pesanan: keranjang,
                    orderId: _nextInvoiceId(),
                    onCheckout: _tambahRiwayat,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: IndustrialBackground()),
          ListView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            children: [
              const SizedBox(height: 8),
              HeroPanel(key: _heroKey),
              const SizedBox(height: 12),
              ServiceGrid(keys: _serviceKeys),
              const SizedBox(height: 12),
              // connector overlay will draw on top of panels
              ConnectorOverlay(heroKey: _heroKey, serviceKeys: _serviceKeys),
              ...menu.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return IndustrialPanel(
                  leftPipe: index % 2 == 0,
                  rightPipe: index % 2 != 0,
                  child: ListTile(
                    title: Text(item["nama"]),
                    subtitle: Text(formatRupiah(item["harga"] as int)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit Harga',
                          onPressed: () => _editMenuItem(index),
                        ),
                        ElevatedButton(
                          onPressed: () => tambah(item),
                          child: const Text("Tambah"),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 40),
            ],
          ),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> pesanan;
  final String orderId;
  final Future<void> Function(TransactionRecord) onCheckout;

  const CheckoutPage({
    super.key,
    required this.pesanan,
    required this.orderId,
    required this.onCheckout,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _tableController = TextEditingController();

  int get total {
    int jumlah = 0;
    for (var item in widget.pesanan) {
      jumlah += (item["harga"] as int) * (item["jumlah"] as int);
    }
    return jumlah;
  }

  @override
  void dispose() {
    _customerController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  Future<void> prosesPembayaran(String metode) async {
    final receiptPesanan = widget.pesanan
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final transaction = TransactionRecord(
      id: widget.orderId,
      date: DateTime.now(),
      pembayaran: metode,
      total: total,
      customerName: _customerController.text.trim().isEmpty
          ? '-'
          : _customerController.text.trim(),
      tableNumber: _tableController.text.trim().isEmpty
          ? '-'
          : _tableController.text.trim(),
      items: receiptPesanan,
    );

    widget.pesanan.clear();

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            StrukPage(transaction: transaction, onFinish: widget.onCheckout),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keranjang")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nama pelanggan:'),
                TextField(
                  controller: _customerController,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan nama pelanggan',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Nomor meja:'),
                TextField(
                  controller: _tableController,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan nomor meja',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Pesanan : ${widget.orderId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: widget.pesanan.isEmpty
                ? const Center(child: Text('Keranjang kosong.'))
                : ListView.builder(
                    itemCount: widget.pesanan.length,
                    itemBuilder: (context, index) {
                      final item = widget.pesanan[index];

                      return IndustrialPanel(
                        leftPipe: true,
                        child: ListTile(
                          title: Text(item["nama"]),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formatRupiah(item["harga"] as int)),

                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      setState(() {
                                        if (item["jumlah"] > 1) {
                                          item["jumlah"]--;
                                        }
                                      });
                                    },
                                  ),

                                  Text(
                                    "${item["jumlah"]}",
                                    style: const TextStyle(fontSize: 18),
                                  ),

                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      setState(() {
                                        item["jumlah"]++;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),

                          trailing: IconButton(
                            icon: const Icon(Icons.delete),

                            onPressed: () {
                              setState(() {
                                widget.pesanan.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Text(
            "Total : ${formatRupiah(total)}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.pesanan.isEmpty
                      ? null
                      : () => prosesPembayaran("Tunai"),
                  child: const Text("Tunai"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.pesanan.isEmpty
                      ? null
                      : () => prosesPembayaran("QRIS"),
                  child: const Text("QRIS"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StrukPage extends StatelessWidget {
  final TransactionRecord transaction;
  final Future<void> Function(TransactionRecord)? onFinish;

  const StrukPage({super.key, required this.transaction, this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Struk Pembayaran"),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Cetak Struk',
            onPressed: () {
              Printing.layoutPdf(
                onLayout: (format) => buildReceiptPdf(transaction),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "BAKSO URAT MAD GEMBUL",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No Pesanan : ${transaction.id}",
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Nama pelanggan : ${transaction.customerName}",
              style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
            ),
            Text(
              "Nomor meja : ${transaction.tableNumber}",
              style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
            ),
            Text(
              "Tanggal : ${DateFormat('dd-MM-yyyy HH:mm').format(transaction.date)}",
              style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
            ),
            const Divider(height: 32, thickness: 1.2),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transaction.items.length,
              itemBuilder: (context, index) {
                final item = transaction.items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${item['nama']} x${item['jumlah']}",
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        formatRupiah(
                          (item['harga'] as int) * (item['jumlah'] as int),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(height: 32, thickness: 1.2),
            Text(
              "Total : ${formatRupiah(transaction.total)}",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Pembayaran : ${transaction.pembayaran}",
              style: const TextStyle(fontFamily: 'Courier', fontSize: 16),
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                "Terima kasih",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text("Selesai"),
                onPressed: () async {
                  if (onFinish != null) {
                    await onFinish!(transaction);
                  }
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaksi tersimpan'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RiwayatTransaksiPage extends StatelessWidget {
  final List<TransactionRecord> riwayat;

  const RiwayatTransaksiPage({super.key, required this.riwayat});

  @override
  Widget build(BuildContext context) {
    if (riwayat.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Riwayat Transaksi')),
        body: const Center(child: Text('Belum ada transaksi.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: ListView.builder(
        itemCount: riwayat.length,
        itemBuilder: (context, index) {
          final record = riwayat[index];
          return IndustrialPanel(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leftPipe: true,
            child: InkWell(
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(record.id),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal : ${DateFormat('dd-MM-yyyy HH:mm').format(record.date)}',
                            ),
                            const SizedBox(height: 8),
                            Text('Nama pelanggan : ${record.customerName}'),
                            Text('Nomor meja : ${record.tableNumber}'),
                            Text('Pembayaran : ${record.pembayaran}'),
                            const SizedBox(height: 12),
                            const Text(
                              'Item :',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...record.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item['nama']} x${item['jumlah']}',
                                      ),
                                    ),
                                    Text(
                                      formatRupiah(
                                        (item['harga'] as int) *
                                            (item['jumlah'] as int),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(),
                            Text(
                              'Total : ${formatRupiah(record.total)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Tutup'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tanggal : ${DateFormat('dd-MM-yyyy').format(record.date)}',
                    ),
                    Text('Total   : ${formatRupiah(record.total)}'),
                    Text('Bayar   : ${record.pembayaran}'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final List<TransactionRecord> riwayat;

  const DashboardPage({super.key, required this.riwayat});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class IndustrialBackground extends StatelessWidget {
  const IndustrialBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _IndustrialBackgroundPainter(),
    );
  }
}

class _IndustrialBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.shade900;
    canvas.drawRect(Offset.zero & size, paint);

    // subtle grid
    final gridPaint = Paint()
      ..color = Colors.grey.shade800.withOpacity(0.25)
      ..strokeWidth = 1;

    const gap = 32.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // diagonal plate seams
    final seamPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.black.withOpacity(0.6), Colors.white.withOpacity(0.02)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2;

    for (double i = -size.height; i < size.width; i += 220) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), seamPaint);
    }

    // faint vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class IndustrialHeader extends StatelessWidget {
  const IndustrialHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.black87, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo block
          Container(
            width: 220,
            height: 86,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black87, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.ac_unit, color: Colors.cyanAccent, size: 34),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('DAUNG', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Art', style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('PROJECT', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _navItem('Beranda'),
                _navItem('Tentang'),
                _navItem('Layanan'),
                _navItem('Harga'),
                _navItem('Galeri'),
              ],
            ),
          ),
          // Contact button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), offset: const Offset(2, 2), blurRadius: 6)],
            ),
            child: Row(
              children: const [
                Icon(Icons.whatsapp, color: Colors.white),
                SizedBox(width: 8),
                Text('Hubungi WhatsApp', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(label, style: const TextStyle(color: Colors.white70)),
    );
  }
}

class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return IndustrialPanel(
      leftPipe: true,
      rightPipe: true,
      child: SizedBox(
        height: 240,
        child: Row(
          children: [
            // Left text block
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WELCOME TO', style: TextStyle(color: Colors.cyanAccent, fontSize: 14)),
                    const SizedBox(height: 8),
                    const Text('DAUNG Art', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('PROJECT', style: TextStyle(color: Colors.white70, fontSize: 18)),
                    const SizedBox(height: 12),
                    const Text('Music arrangement, recording studio, live entertainment', style: TextStyle(color: Colors.white60)),
                    const Spacer(),
                    Row(
                      children: [
                        ElevatedButton(onPressed: () {}, child: const Text('Hubungi WhatsApp')),
                        const SizedBox(width: 12),
                        OutlinedButton(onPressed: () {}, child: const Text('Lihat Portfolio')),
                      ],
                    )
                  ],
                ),
              ),
            ),

            // Right image / console mock
            Expanded(
              flex: 6,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blueGrey.shade900, width: 2),
                ),
                child: Stack(
                  children: [
                    Center(child: Icon(Icons.equalizer, size: 96, color: Colors.blueGrey.shade700)),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade900,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(child: Text('MASTER OUTPUT', style: TextStyle(color: Colors.cyan.shade100))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceGrid extends StatelessWidget {
  final List<GlobalKey>? keys;
  const ServiceGrid({super.key, this.keys});

  @override
  Widget build(BuildContext context) {
    final services = [
      {'icon': Icons.music_note, 'label': 'Music Arrangement'},
      {'icon': Icons.mic, 'label': 'Recording'},
      {'icon': Icons.settings, 'label': 'Mixing & Mastering'},
      {'icon': Icons.library_music, 'label': 'Cover Lagu'},
      {'icon': Icons.event, 'label': 'Live Entertainment'},
    ];

    return Row(
      children: services.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: IndustrialPanel(
              key: keys != null && keys!.length > i ? keys![i] : null,
              child: SizedBox(
                height: 110,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(s['icon'] as IconData, size: 34, color: Colors.cyanAccent),
                    const SizedBox(height: 8),
                    Text(s['label'] as String, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ConnectorOverlay extends StatefulWidget {
  final GlobalKey heroKey;
  final List<GlobalKey> serviceKeys;

  const ConnectorOverlay({super.key, required this.heroKey, required this.serviceKeys});

  @override
  State<ConnectorOverlay> createState() => _ConnectorOverlayState();
}

class _ConnectorOverlayState extends State<ConnectorOverlay> {
  List<Offset?> _points = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    final heroBox = widget.heroKey.currentContext?.findRenderObject() as RenderBox?;
    final heroCenter = heroBox != null
        ? overlayBox.globalToLocal(heroBox.localToGlobal(heroBox.size.center(Offset.zero)))
        : null;

    final serviceCenters = widget.serviceKeys.map((k) {
      final b = k.currentContext?.findRenderObject() as RenderBox?;
      return b != null ? overlayBox.globalToLocal(b.localToGlobal(b.size.center(Offset.zero))) : null;
    }).toList();

    setState(() {
      _points = [heroCenter, ...serviceCenters];
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConnectorPainter(points: _points),
        size: Size.infinite,
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final List<Offset?> points;
  _ConnectorPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || points[0] == null) return;
    final origin = points[0]!;

    final glow = Paint()
      ..color = Colors.cyan.withOpacity(0.14)
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pipe = Paint()
      ..color = Colors.grey.shade900
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i < points.length; i++) {
      final p = points[i];
      if (p == null) continue;
      final path = Path();
      path.moveTo(origin.dx, origin.dy);
      final mid = Offset((origin.dx + p.dx) / 2, (origin.dy + p.dy) / 2 - 20);
      path.quadraticBezierTo(mid.dx, mid.dy, p.dx, p.dy);

      canvas.drawPath(glow, path);
      canvas.drawPath(pipe, path);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) => oldDelegate.points != points;
}

class IndustrialConnectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pipePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glow = Paint()
      ..color = Colors.cyan.withOpacity(0.12)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // simple sample pipe path across top
    final path = Path();
    path.moveTo(16, 96);
    path.cubicTo(size.width * 0.25, 40, size.width * 0.5, 40, size.width - 16, 96);

    canvas.drawPath(glow, path);
    canvas.drawPath(pipePaint, path);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedFilter = 0; // 0: Hari ini, 1: Minggu ini, 2: Bulan ini

  List<TransactionRecord> get _filtered {
    final now = DateTime.now();
    if (_selectedFilter == 0) {
      return widget.riwayat
          .where(
            (r) =>
                r.date.year == now.year &&
                r.date.month == now.month &&
                r.date.day == now.day,
          )
          .toList();
    } else if (_selectedFilter == 1) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return widget.riwayat
          .where(
            (r) => r.date.isAfter(
              startOfWeek.subtract(const Duration(seconds: 1)),
            ),
          )
          .toList();
    } else {
      // month
      return widget.riwayat
          .where((r) => r.date.year == now.year && r.date.month == now.month)
          .toList();
    }
  }

  int get totalOmzet => _filtered.fold(0, (sum, r) => sum + r.total);
  int get totalTransaksi => _filtered.length;
  int get rataRata =>
      totalTransaksi == 0 ? 0 : (totalOmzet / totalTransaksi).round();

  Map<String, int> get _menuCounts {
    final counts = <String, int>{};
    for (final r in _filtered) {
      for (final item in r.items) {
        final name = item['nama'] as String;
        final jumlah = item['jumlah'] as int;
        counts[name] = (counts[name] ?? 0) + jumlah;
      }
    }
    return counts;
  }

  List<int> get _last7DaysTotals {
    final now = DateTime.now();
    final days = List.generate(
      7,
      (i) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i)),
    );
    return days.map((d) {
      return widget.riwayat
          .where(
            (r) =>
                r.date.year == d.year &&
                r.date.month == d.month &&
                r.date.day == d.day,
          )
          .fold(0, (s, r) => s + r.total);
    }).toList();
  }

  Future<void> _exportCsv() async {
    final rows = <List<String>>[];
    rows.add(['id', 'date', 'customer', 'table', 'payment', 'total', 'items']);
    for (final r in _filtered) {
      final items = r.items
          .map((i) => '${i['nama']} x${i['jumlah']}')
          .join('; ');
      rows.add([
        r.id,
        DateFormat('dd-MM-yyyy HH:mm').format(r.date),
        r.customerName,
        r.tableNumber,
        r.pembayaran,
        r.total.toString(),
        items,
      ]);
    }
    final csv = rows
        .map((r) => r.map((c) => '"${c.replaceAll('"', '""')}"').join(','))
        .join('\n');
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan CSV disalin ke clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuCounts = _menuCounts;
    final topMenu = menuCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final last7 = _last7DaysTotals;
    final maxVal = last7.isEmpty ? 1 : last7.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Pemilik')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Pemilik',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ToggleButtons(
              isSelected: [
                _selectedFilter == 0,
                _selectedFilter == 1,
                _selectedFilter == 2,
              ],
              onPressed: (i) {
                setState(() => _selectedFilter = i);
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Hari ini'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Minggu ini'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Bulan ini'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: IndustrialPanel(
                    leftPipe: true,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Omzet'),
                          const SizedBox(height: 8),
                          Text(
                            formatRupiah(totalOmzet),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: IndustrialPanel(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Transaksi'),
                          const SizedBox(height: 8),
                          Text(
                            totalTransaksi.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: IndustrialPanel(
                    rightPipe: true,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rata-rata Transaksi'),
                          const SizedBox(height: 8),
                          Text(
                            formatRupiah(rataRata),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text(
              'Penjualan 7 Hari Terakhir',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final val = last7[i];
                  final double barHeight = maxVal == 0
                      ? 0.0
                      : (val / maxVal) * 100.0;
                  final dateLabel = DateFormat(
                    'dd',
                  ).format(DateTime.now().subtract(Duration(days: 6 - i)));
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: barHeight,
                          width: 12,
                          color: Colors.orange.shade300,
                        ),
                        const SizedBox(height: 6),
                        Text(dateLabel, style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              'Menu Terlaris',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            IndustrialPanel(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: topMenu
                      .take(5)
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('${e.key} — ${e.value}'),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),

            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) =>
                              RiwayatTransaksiPage(riwayat: widget.riwayat),
                        ),
                      );
                    },
                    child: const Text('Lihat Semua Transaksi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _exportCsv,
                    child: const Text('Export Laporan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
