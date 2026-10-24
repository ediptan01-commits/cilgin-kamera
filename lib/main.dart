import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'effects.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const CrazyCameraApp());
}

class CrazyCameraApp extends StatelessWidget {
  const CrazyCameraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Çılgın Kamera',
    theme: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFCCFF66),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF141322),
    ),
    home: const CameraPage(),
  );
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _camera;
  List<CameraDescription> _cameras = [];
  int _index = 0, _generation = 0;
  bool _loading = true, _busy = false, _mirror = false, _active = true;
  String? _error;
  PhotoEffect _effect = PhotoEffect.original;
  Future<void> _disposal = Future.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _open();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      _open();
    } else {
      _generation++;
      final old = _camera;
      _camera = null;
      if (old != null) _disposal = old.dispose();
      if (mounted) setState(() => _loading = true);
    }
  }

  Future<void> _open() async {
    final token = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    final old = _camera;
    _camera = null;
    if (old != null) _disposal = old.dispose();
    CameraController? next;
    try {
      await _disposal;
      if (!mounted || !_active || token != _generation) return;
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw StateError('Bu cihazda kamera bulunamadı.');
      _index %= _cameras.length;
      next = CameraController(
        _cameras[_index],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await next.initialize();
      await next.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (!mounted || !_active || token != _generation) {
        await next.dispose();
        return;
      }
      _camera = next;
    } catch (e) {
      await next?.dispose();
      if (!mounted || token != _generation) return;
      _error = e is CameraException && e.code.startsWith('CameraAccess')
          ? 'Kamera izni gerekli. Ayarlar’dan kamera erişimini açıp tekrar dene.'
          : 'Kamera açılamadı. Başka bir uygulama kullanıyor olabilir. Tekrar dene.';
      if (_cameras.isEmpty && e is StateError) {
        _error = 'Bu cihazda kamera bulunamadı.';
      }
    }
    if (mounted && token == _generation) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (_busy || camera == null || !camera.value.isInitialized) return;
    final effect = _effect, mirror = _mirror;
    setState(() => _busy = true);
    File? raw;
    File? result;
    try {
      final shot = await camera.takePicture();
      raw = File(shot.path);
      final bytes = await compute(renderPhoto, (
        await raw.readAsBytes(),
        effect,
        mirror,
      ));
      final dir = await getTemporaryDirectory();
      result = File(
        '${dir.path}/cilgin_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await result.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => PhotoPage(file: result!)));
    } catch (_) {
      _message('Fotoğraf hazırlanamadı. Lütfen tekrar dene.');
    } finally {
      // Keep the shared output in cache: receiving apps may read it later.
      try {
        await raw?.delete();
      } catch (_) {
        /* OS may already remove it. */
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 16, 22, 12),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFFCCFF66)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Çılgın Kamera',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Biraz renk. Bolca sen.',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator()
                      : _error != null
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt_outlined, size: 48),
                              const SizedBox(height: 16),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _open,
                                child: const Text('Tekrar dene'),
                              ),
                              TextButton(
                                onPressed: openAppSettings,
                                child: const Text('Uygulama ayarları'),
                              ),
                            ],
                          ),
                        )
                      : camera == null
                      ? const Text('Kamera hazırlanıyor…')
                      : AspectRatio(
                          aspectRatio: 1 / camera.value.aspectRatio,
                          child: ColorFiltered(
                            colorFilter: ColorFilter.matrix(_effect.matrix),
                            // CameraPreview mirrors front cameras by default. Cancel that
                            // baseline so the explicit mirror switch matches saved pixels.
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(
                                (_mirror !=
                                        (camera.description.lensDirection ==
                                            CameraLensDirection.front))
                                    ? math.pi
                                    : 0,
                              ),
                              child: CameraPreview(camera),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'RENK KAT',
                style: TextStyle(
                  letterSpacing: 3,
                  fontSize: 11,
                  color: Colors.white60,
                ),
              ),
            ),
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final effect in PhotoEffect.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(effect.label),
                        selected: _effect == effect,
                        onSelected: _busy
                            ? null
                            : (_) => setState(() => _effect = effect),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton.filledTonal(
                    tooltip: _mirror ? 'Aynayı kapat' : 'Ayna efekti',
                    isSelected: _mirror,
                    onPressed: _busy
                        ? null
                        : () => setState(() => _mirror = !_mirror),
                    icon: const Icon(Icons.flip),
                  ),
                  Semantics(
                    label: 'Fotoğraf çek',
                    button: true,
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: _busy || _loading || camera == null
                            ? null
                            : _capture,
                        child: _busy
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.camera_alt, size: 34),
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Kamerayı değiştir',
                    onPressed: _busy || _loading || _cameras.length < 2
                        ? null
                        : () {
                            _index = (_index + 1) % _cameras.length;
                            _open();
                          },
                    icon: const Icon(Icons.cameraswitch),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Filtren fotoğrafına da işlenir ✨',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoPage extends StatefulWidget {
  const PhotoPage({super.key, required this.file});
  final File file;
  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  bool _busy = false, _saved = false;
  Future<void> _action(bool save) async {
    setState(() => _busy = true);
    String? message;
    try {
      if (save) {
        if (!await Gal.hasAccess()) await Gal.requestAccess();
        if (!await Gal.hasAccess()) {
          throw StateError(
            'Galeri izni verilmedi. Uygulama ayarlarından izin verebilirsin.',
          );
        }
        await Gal.putImage(widget.file.path);
        _saved = true;
        message = 'Harika! Fotoğraf galeriye kaydedildi.';
      } else {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(widget.file.path)], title: 'Çılgın Kamera'),
        );
      }
    } on StateError catch (e) {
      message = e.message.toString();
    } catch (_) {
      message = save
          ? 'Kaydedilemedi. Galeri iznini ve boş alanı kontrol et.'
          : 'Paylaşım açılamadı. Tekrar dene.';
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('İşte senin karen!')),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(widget.file, fit: BoxFit.contain),
              ),
            ),
          ),
          const Text(
            'Gördüğün fotoğraf kaydedilir ve paylaşılır.',
            style: TextStyle(color: Colors.white60),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy || _saved ? null : () => _action(true),
                    icon: const Icon(Icons.download),
                    label: Text(_saved ? 'Kaydedildi ✓' : 'Kaydet'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _action(false),
                    icon: const Icon(Icons.share),
                    label: const Text('Paylaş'),
                  ),
                ),
              ],
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    ),
  );
}
