import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// Root Project
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Tugas Flutter",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

/// --------------------
/// Halaman Utama (Menu)
/// --------------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Tugas Widget")),
      body: ListView(
        children: [
          menuButton(context, "Hello World", const HelloWorldPage()),
          menuButton(context, "Widget Column", const ColumnPage()),
          menuButton(context, "Widget Row", const RowPage()),
          menuButton(context, "Stateless vs Stateful", const CounterPage()),
          menuButton(context, "Form Input", const FormPage()),
          menuButton(context, "Pisah Fungsi Widget", const FunctionWidgetPage()),
        ],
      ),
    );
  }

  Widget menuButton(BuildContext context, String title, Widget page) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }
}

/// --------------------
/// 1. Hello World
/// --------------------
class HelloWorldPage extends StatelessWidget {
  const HelloWorldPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hello World")),
      body: const Center(
        child: Text(
          "Hello World!",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// --------------------
/// 2. Column Widget
/// --------------------
class ColumnPage extends StatelessWidget {
  const ColumnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Widget Column")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text("Baris 1"),
            Text("Baris 2"),
            Text("Baris 3"),
          ],
        ),
      ),
    );
  }
}

/// --------------------
/// 3. Row Widget
/// --------------------
class RowPage extends StatelessWidget {
  const RowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Widget Row")),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text("Kolom 1   "),
            Text("Kolom 2   "),
            Text("Kolom 3"),
          ],
        ),
      ),
    );
  }
}

/// --------------------
/// 4. Stateless vs Stateful
/// --------------------
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _counter = 0;

  void _tambah() {
    setState(() {
      _counter++;
    });
  }

  void _reset() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stateful vs Stateless")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Contoh StatefulWidget (Counter)"),
            Text(
              "$_counter",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _tambah, child: const Text("+ Tambah")),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _reset, child: const Text("Reset")),
              ],
            )
          ],
        ),
      ),
    );
  }
}

/// --------------------
/// 5. Form Input
/// --------------------
class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Form Input")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: "Nama",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Nama tidak boleh kosong" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) return "Email tidak boleh kosong";
                  if (!value.contains("@")) return "Email tidak valid";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Nama: ${_namaController.text}, Email: ${_emailController.text}",
                        ),
                      ),
                    );
                  }
                },
                child: const Text("Submit"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// --------------------
/// 6. Pisah Fungsi Widget
/// --------------------
class FunctionWidgetPage extends StatelessWidget {
  const FunctionWidgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pisah Fungsi Widget")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildButton("Tombol 1"),
            buildButton("Tombol 2"),
            buildButton("Tombol 3"),
          ],
        ),
      ),
    );
  }
}

/// Fungsi terpisah
Widget buildButton(String text) {
  return ElevatedButton(
    onPressed: () {
      debugPrint("$text ditekan");
    },
    child: Text(text),
  );
}
