// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';
// ignore: depend_on_referenced_packages

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MediaJournalApp());
}

class MediaJournalApp extends StatelessWidget {
  const MediaJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediaJournal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

enum PageMode { notes, camera, video }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PageMode _mode = PageMode.notes;

  // --------------------
  // NOTES (File I/O)
  // --------------------
  final TextEditingController _notesController = TextEditingController();
  String _loadedText = '';

  List<String> get _lines => _loadedText.isEmpty
      ? const []
      : _loadedText.split('\n').where((e) => e.trim().isNotEmpty).toList();

  Future<File> _notesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'notes.txt'));
  }

  Future<void> _saveNotes() async {
    final file = await _notesFile();
    try {
      await file.writeAsString(_notesController.text);
      // update loaded text too so UI stays consistent
      setState(() => _loadedText = _notesController.text);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tersimpan ke notes.txt')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  Future<void> _loadNotes() async {
    try {
      final file = await _notesFile();
      if (await file.exists()) {
        final text = await file.readAsString();
        setState(() {
          _loadedText = text;
          _notesController.text = text;
        });
      } else {
        setState(() {
          _loadedText = '';
          _notesController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat: $e')));
    }
  }

  Future<void> _clearAllNotes() async {
    final file = await _notesFile();
    try {
      if (await file.exists()) await file.writeAsString('');
      setState(() {
        _loadedText = '';
        _notesController.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua catatan dihapus')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  Future<void> _deleteLineAt(int index) async {
    final list = _lines.toList();
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    final newText = list.join('\n');
    final file = await _notesFile();
    try {
      await file.writeAsString(newText);
      setState(() {
        _loadedText = newText;
        _notesController.text = newText;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Baris dihapus')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus baris: $e')));
    }
  }

  // --------------------
  // CAMERA (Image Picker + save to app dir + AnimatedSwitcher)
  // --------------------
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage; // points to file inside app directory (copied)

  // copy picked file to app documents with unique name
  Future<File> _savePickedFileToAppDir(XFile xfile) async {
    final docDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = p.extension(xfile.path);
    final fileName = 'img_$timestamp$ext';
    final target = File(p.join(docDir.path, fileName));
    final saved = await File(xfile.path).copy(target.path);
    return saved;
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? x = await _picker.pickImage(source: ImageSource.gallery);
      if (x != null) {
        final saved = await _savePickedFileToAppDir(x);
        setState(() => _pickedImage = saved);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gambar disimpan ke folder app')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? x = await _picker.pickImage(source: ImageSource.camera);
      if (x != null) {
        final saved = await _savePickedFileToAppDir(x);
        setState(() => _pickedImage = saved);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto tersimpan ke folder app')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
    }
  }

  Future<void> _deletePickedImage() async {
    if (_pickedImage == null) return;
    try {
      if (await _pickedImage!.exists()) {
        await _pickedImage!.delete();
      }
    } catch (e) {
      // ignore if can't delete
    } finally {
      setState(() => _pickedImage = null);
    }
  }

  // --------------------
  // VIDEO (video_player)
  // --------------------
  late final VideoPlayerController _videoController;
  Future<void>? _videoInit;

  @override
  void initState() {
    super.initState();
    // load notes at start
    _loadNotes();

    // initialize video controller
    _videoController = VideoPlayerController.network(
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    );
    _videoInit = _videoController
        .initialize()
        .then((_) {
          setState(() {});
        })
        .catchError((error) {
          // handle init error
          debugPrint('Video init error: $error');
        });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  // --------------------
  // UI
  // --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForMode(_mode)),
        actions: [
          PopupMenuButton<PageMode>(
            onSelected: (m) => setState(() => _mode = m),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: PageMode.notes, child: Text('Catatan')),
              PopupMenuItem(value: PageMode.camera, child: Text('Kamera')),
              PopupMenuItem(value: PageMode.video, child: Text('Video')),
            ],
          ),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(16.0), child: _buildBody()),
    );
  }

  String _titleForMode(PageMode mode) {
    switch (mode) {
      case PageMode.notes:
        return 'Catatan & File I/O';
      case PageMode.camera:
        return 'Kamera (Picker) & AnimatedSwitcher';
      case PageMode.video:
        return 'Media Player (Video)';
    }
  }

  Widget _buildBody() {
    switch (_mode) {
      case PageMode.notes:
        return _notesView();
      case PageMode.camera:
        return _cameraView();
      case PageMode.video:
        return _videoView();
    }
  }

  // ----- Notes View -----
  Widget _notesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Tulis catatan',
            border: OutlineInputBorder(),
            hintText:
                'Tulis beberapa baris, tekan Simpan untuk menyimpan ke file',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _saveNotes,
              icon: const Icon(Icons.save),
              label: const Text('Simpan'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _loadNotes,
              icon: const Icon(Icons.download),
              label: const Text('Muat'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _clearAllNotes,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Bersihkan'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Daftar Catatan (geser ke kiri/kanan untuk hapus):',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _lines.isEmpty
              ? const Center(child: Text('Belum ada catatan tersimpan.'))
              : ListView.builder(
                  itemCount: _lines.length,
                  itemBuilder: (ctx, i) {
                    final line = _lines[i];
                    return Dismissible(
                      key: ValueKey(line + i.toString()),
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteLineAt(i),
                      child: ListTile(
                        leading: const Icon(Icons.note),
                        title: Text(line),
                        subtitle: null,
                        onLongPress: () => _confirmDeleteLine(i),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDeleteLine(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus baris'),
        content: const Text('Yakin ingin menghapus baris ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteLineAt(index);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ----- Camera View -----
  Widget _cameraView() {
    final savedName = _pickedImage != null
        ? p.basename(_pickedImage!.path)
        : null;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: _pickedImage == null
                  ? const Text(
                      'Belum ada gambar.\nAmbil dari kamera / pilih dari galeri.',
                      key: ValueKey('empty'),
                      textAlign: TextAlign.center,
                    )
                  : Column(
                      key: ValueKey('image_${_pickedImage!.path}'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 320,
                            maxHeight: 320,
                          ),
                          child: Image.file(_pickedImage!, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          savedName ?? '-',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _pickFromCamera,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Kamera'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Galeri'),
            ),
            const SizedBox(width: 12),
            if (_pickedImage != null)
              IconButton(
                onPressed: () => _confirmDeleteImage(),
                icon: const Icon(Icons.delete_forever),
                tooltip: 'Hapus gambar',
              ),
          ],
        ),
      ],
    );
  }

  void _confirmDeleteImage() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus gambar'),
        content: const Text('Hapus gambar yang tersimpan di folder aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deletePickedImage();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ----- Video View -----
  Widget _videoView() {
    return Column(
      children: [
        FutureBuilder(
          future: _videoInit,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!_videoController.value.isInitialized) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: Text('Gagal menginisialisasi video')),
              );
            }

            return AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: VideoPlayer(_videoController),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                if (_videoController.value.isPlaying) {
                  _videoController.pause();
                } else {
                  _videoController.play();
                }
                setState(() {});
              },
              icon: Icon(
                _videoController.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              label: Text(_videoController.value.isPlaying ? 'Pause' : 'Play'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                // jump to start
                _videoController.seekTo(Duration.zero);
                setState(() {});
              },
              icon: const Icon(Icons.replay),
              label: const Text('Restart'),
            ),
          ],
        ),
      ],
    );
  }
}
