import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// Секция аудиоплеера
class ProductAudioSection extends StatefulWidget {
  final String audioUrl;

  const ProductAudioSection({super.key, required this.audioUrl});

  @override
  State<ProductAudioSection> createState() => _ProductAudioSectionState();
}

class _ProductAudioSectionState extends State<ProductAudioSection> {
  final _player = AudioPlayer();
  bool _loading = true;
  bool _playing = false;
  bool _completed = false;
  bool _seeking = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _sourcePrepared = false;
  String? _activeSourceUrl;
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
          trimmed,
        ];
      }
    }

    return [trimmed];
  }

  bool _isValidNetworkAudioUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;
    return uri.scheme == 'https' || uri.scheme == 'http';
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted && !_seeking) setState(() => _position = p);
    });
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = s == PlayerState.playing);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _completed = true;
          _playing = false;
          _position = _duration;
        });
      }
    });
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _startPlayback() async {
    final candidates =
        _candidateUrls(widget.audioUrl).where(_isValidNetworkAudioUrl).toList();
    if (candidates.isEmpty) {
      if (mounted) {
        setState(() {
          _error = 'Некорректная ссылка на аудио';
          _loading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    Object? lastError;
    for (final url in candidates) {
      try {
        await _player.play(UrlSource(url));
        if (mounted) {
          setState(() {
            _activeSourceUrl = url;
            _sourcePrepared = true;
            _completed = false;
            _position = Duration.zero;
            _loading = false;
            _error = null;
          });
        }
        return;
      } catch (e) {
        lastError = e;
      }
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _sourcePrepared = false;
        _error =
            'Не удалось воспроизвести аудио. Проверьте прямую ссылку на файл (mp3/wav).';
      });
    }
    debugPrint('Audio playback failed: $lastError');
  }

  bool get _isAtTrackEnd {
    if (_duration == Duration.zero) return false;
    return _position >= _duration - const Duration(milliseconds: 250);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showReplayOnMainButton =
        !_playing && (_completed || _isAtTrackEnd);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Прослушать звучание',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
          ),
          child: _error != null
              ? Text(_error!, style: const TextStyle(color: Colors.red))
              : _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () async {
                                if (_playing) {
                                  await _player.pause();
                                } else {
                                  if (_sourcePrepared) {
                                    if (_completed || _isAtTrackEnd) {
                                      if (_activeSourceUrl != null) {
                                        await _player.play(
                                          UrlSource(_activeSourceUrl!),
                                        );
                                        if (mounted) {
                                          setState(() {
                                            _position = Duration.zero;
                                            _completed = false;
                                          });
                                        }
                                      } else {
                                        await _startPlayback();
                                      }
                                    } else {
                                      await _player.resume();
                                    }
                                  } else {
                                    await _startPlayback();
                                  }
                                }
                              },
                              icon: Icon(
                                _playing
                                    ? Icons.pause_circle_filled
                                    : (showReplayOnMainButton
                                        ? Icons.replay_circle_filled
                                        : Icons.play_circle_filled),
                                size: 44,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3,
                                      thumbShape:
                                          const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                        overlayRadius: 12,
                                      ),
                                    ),
                                    child: Slider(
                                      value: _duration.inMilliseconds > 0
                                          ? _position.inMilliseconds
                                              .clamp(
                                                0,
                                                _duration.inMilliseconds,
                                              )
                                              .toDouble()
                                          : 0,
                                      max: _duration.inMilliseconds > 0
                                          ? _duration.inMilliseconds.toDouble()
                                          : 1,
                                      activeColor: scheme.primary,
                                      onChangeStart: (_) {
                                        setState(() => _seeking = true);
                                      },
                                      onChanged: (v) {
                                        setState(() {
                                          _position = Duration(
                                            milliseconds: v.toInt(),
                                          );
                                          if (_completed) _completed = false;
                                        });
                                      },
                                      onChangeEnd: (v) async {
                                        final target = Duration(
                                          milliseconds: v.toInt(),
                                        );
                                        await _player.seek(target);
                                        if (_playing) {
                                          await _player.resume();
                                        }
                                        if (mounted) {
                                          setState(() {
                                            _position = target;
                                            _seeking = false;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _fmt(_position),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          _fmt(_duration),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}
