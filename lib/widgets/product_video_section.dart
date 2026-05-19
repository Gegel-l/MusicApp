import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

/// Секция видеоплеера
class ProductVideoSection extends StatefulWidget {
  final String videoUrl;

  const ProductVideoSection({super.key, required this.videoUrl});

  @override
  State<ProductVideoSection> createState() => _ProductVideoSectionState();
}

class _ProductVideoSectionState extends State<ProductVideoSection> {
  static const _linkOpenerChannel = MethodChannel('app.link_opener');

  VideoPlayerController? _controller;
  bool _linkOnlyVideo = false;
  bool _mp4Mode = false;
  String? _linkPreviewImageUrl;
  bool _loading = true;
  bool _initialized = false;
  bool _ended = false;
  String? _error;

  List<String> _candidateUrls(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return const [];

    if (trimmed.contains('drive.google.com') && trimmed.contains('/file/d/')) {
      final parts = trimmed.split('/file/d/');
      if (parts.length >= 2) {
        final id = parts[1].split('/')[0];
        return [
          'https://drive.google.com/uc?export=download&id=$id',
          'https://drive.google.com/uc?export=view&id=$id',
          'https://drive.google.com/uc?id=$id&export=download',
          trimmed,
        ];
      }
    }
    return [trimmed];
  }

  bool _isValidNetworkUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  bool _isLikelyMp4Url(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    return path.endsWith('.mp4') || path.contains('.mp4?');
  }

  bool _isYandexDiskUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.host.toLowerCase().contains('disk.yandex.ru');
  }

  Future<String?> _loadLinkPreviewImage(String url) async {
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode < 200 || resp.statusCode >= 300) return null;
      final body = resp.body;
      final match = RegExp(
        "<meta[^>]+property=[\"']og:image[\"'][^>]+content=[\"']([^\"']+)[\"']",
        caseSensitive: false,
      ).firstMatch(body);
      final image = match?.group(1);
      if (image == null || image.isEmpty) return null;
      return image;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveYandexDiskDirectUrl(String publicUrl) async {
    try {
      final variants = <String>{publicUrl};
      if (publicUrl.contains('disk.yandex.ru/i/')) {
        variants.add(
          publicUrl.replaceFirst(
            'disk.yandex.ru/i/',
            'disk.yandex.ru/d/',
          ),
        );
      }

      for (final variant in variants) {
        final apiUrl = Uri.parse(
          'https://cloud-api.yandex.net/v1/disk/public/resources/download'
          '?public_key=${Uri.encodeComponent(variant)}',
        );
        final resp = await http.get(apiUrl);
        if (resp.statusCode != 200) continue;
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final href = data['href'] as String?;
        if (href != null && href.isNotEmpty) {
          return href;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openExternalVideo() async {
    try {
      final raw = widget.videoUrl.trim();
      final normalized =
          raw.startsWith('http://') || raw.startsWith('https://')
              ? raw
              : 'https://$raw';
      final uri = Uri.tryParse(normalized);
      if (uri == null) return;

      var launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
      if (!launched) {
        final encoded = Uri.tryParse(Uri.encodeFull(uri.toString()));
        if (encoded != null) {
          launched = await launchUrl(
            encoded,
            mode: LaunchMode.inAppBrowserView,
          );
          if (!launched) {
            launched = await launchUrl(
              encoded,
              mode: LaunchMode.platformDefault,
            );
          }
        }
      }

      if (!launched && mounted) {
        await _showOpenFallbackDialog(uri.toString());
      }
    } catch (e) {
      debugPrint('Open video error: $e');
      if (!mounted) return;
      final raw = widget.videoUrl.trim();
      final fallback =
          raw.startsWith('http://') || raw.startsWith('https://')
              ? raw
              : 'https://$raw';
      await _showOpenFallbackDialog(fallback);
    }
  }

  Future<void> _showOpenFallbackDialog(String url) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Не удалось открыть автоматически'),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () async {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                try {
                  await _linkOpenerChannel.invokeMethod(
                    'openChooser',
                    {'url': uri.toString()},
                  );
                } catch (_) {}
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Выбрать приложение'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ссылка скопирована')),
              );
            },
            child: const Text('Копировать'),
          ),
          FilledButton(
            onPressed: () async {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.platformDefault);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Открыть'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final raw = widget.videoUrl.trim();
    if (!_isLikelyMp4Url(raw)) {
      final normalized =
          raw.startsWith('http://') || raw.startsWith('https://')
              ? raw
              : 'https://$raw';
      final preview = await _loadLinkPreviewImage(normalized);
      if (!mounted) return;
      setState(() {
        _linkOnlyVideo = true;
        _linkPreviewImageUrl = preview;
        _initialized = true;
        _loading = false;
        _error = null;
      });
      return;
    }

    final rawUrl = widget.videoUrl.trim();
    final candidates =
        _candidateUrls(rawUrl).where(_isValidNetworkUrl).toList();

    if (_isYandexDiskUrl(rawUrl)) {
      final direct = await _resolveYandexDiskDirectUrl(rawUrl);
      if (direct != null && _isValidNetworkUrl(direct)) {
        candidates.insert(0, direct);
      }
    }
    if (candidates.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Некорректная ссылка на видео';
      });
      return;
    }

    for (final url in candidates) {
      final allowByYandexDirect = _isYandexDiskUrl(rawUrl) && url != rawUrl;
      if (!_isLikelyMp4Url(url) && !allowByYandexDirect) {
        continue;
      }
      try {
        final controller = VideoPlayerController.networkUrl(Uri.parse(url));
        await controller.initialize();
        controller.addListener(() {
          final value = controller.value;
          final duration = value.duration;
          final position = value.position;
          final isEnded = duration > Duration.zero &&
              position >= duration - const Duration(milliseconds: 300);
          if (mounted && _ended != isEnded) {
            setState(() => _ended = isEnded);
          }
        });
        if (!mounted) {
          controller.dispose();
          return;
        }
        setState(() {
          _controller = controller;
          _mp4Mode = true;
          _initialized = true;
          _loading = false;
          _error = null;
        });
        return;
      } catch (_) {
        // Try next URL variant
      }
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = 'Поддерживается прямая ссылка на mp4. Пример: https://site/video.mp4';
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Видеообзор инструмента',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: _error != null
              ? Text(_error!, style: const TextStyle(color: Colors.red))
              : _loading
                  ? const SizedBox(
                      height: 170,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _initialized && _linkOnlyVideo
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: _openExternalVideo,
                                child: Container(
                                  color: Colors.black,
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (_linkPreviewImageUrl != null)
                                          Image.network(
                                            _linkPreviewImageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              color: Colors.black87,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.ondemand_video,
                                                color: Colors.white70,
                                                size: 48,
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            color: Colors.black87,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.ondemand_video,
                                              color: Colors.white70,
                                              size: 48,
                                            ),
                                          ),
                                        Center(
                                          child: Container(
                                            width: 62,
                                            height: 62,
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white54,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _openExternalVideo,
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('Смотреть в приложении'),
                              ),
                            ),
                          ],
                        )
                      : _initialized && _controller != null
                          ? Column(
                              children: [
                                if (_mp4Mode)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: scheme.primary
                                                .withValues(alpha: 0.14),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'MP4',
                                            style: TextStyle(
                                              color: scheme.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'Прямое воспроизведение файла',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                AspectRatio(
                                  aspectRatio:
                                      _controller!.value.aspectRatio == 0
                                          ? 16 / 9
                                          : _controller!.value.aspectRatio,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: VideoPlayer(_controller!),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () async {
                                        if (_controller!.value.isPlaying) {
                                          await _controller!.pause();
                                        } else {
                                          if (_ended) {
                                            await _controller!
                                                .seekTo(Duration.zero);
                                            setState(() => _ended = false);
                                          }
                                          await _controller!.play();
                                        }
                                      },
                                      icon: Icon(
                                        _controller!.value.isPlaying
                                            ? Icons.pause_circle_filled
                                            : (_ended
                                                ? Icons.replay_circle_filled
                                                : Icons.play_circle_filled),
                                        size: 42,
                                        color: scheme.primary,
                                      ),
                                    ),
                                    Expanded(
                                      child: VideoProgressIndicator(
                                        _controller!,
                                        allowScrubbing: true,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
