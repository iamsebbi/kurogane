import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../models/media_item.dart';
import '../models/watchlist_item.dart';
import '../providers/anilist_provider.dart';
import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';
import '../views/auth/login_screen.dart';

class MediaRatingSheet extends ConsumerStatefulWidget {
  final MediaItem media;
  final WatchlistItemRecord? currentWatchlistRecord;

  const MediaRatingSheet({
    super.key,
    required this.media,
    this.currentWatchlistRecord,
  });

  static Future<void> show(
    BuildContext context, {
    required MediaItem media,
    WatchlistItemRecord? currentWatchlistRecord,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => MediaRatingSheet(
        media: media,
        currentWatchlistRecord: currentWatchlistRecord,
      ),
    );
  }

  @override
  ConsumerState<MediaRatingSheet> createState() => _MediaRatingSheetState();
}

class _MediaRatingSheetState extends ConsumerState<MediaRatingSheet> {
  late String _status;
  late double _score;
  late int _progress;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.currentWatchlistRecord?.status ?? 'WATCHING';
    _score = widget.currentWatchlistRecord?.score ?? 0.0;
    _progress = widget.currentWatchlistRecord?.progressEpisodes ?? 0;
  }

  String _getScoreLabel(double score) {
    if (score <= 0) return AppStrings.noScore;
    if (score >= 9.5) return 'Masterpiece';
    if (score >= 8.5) return 'Great';
    if (score >= 7.5) return 'Very Good';
    if (score >= 6.5) return 'Good';
    if (score >= 5.5) return 'Decent';
    if (score >= 4.0) return 'Mediocre';
    return 'Poor';
  }

  Color _getScoreColor(double score) {
    if (score <= 0) return Colors.grey;
    if (score >= 8.5) return const Color(0xFFFBBF24); // Gold
    if (score >= 7.0) return const Color(0xFF10B981); // Emerald
    if (score >= 5.0) return const Color(0xFF3B82F6); // Blue
    return const Color(0xFFEF4444); // Red
  }

  Future<void> _handleSave() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      Navigator.of(context).pop();
      LoginScreen.show(context);
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      // 1. Save to Kurogane Watchlist
      await ref.read(watchlistProvider.notifier).updateItem(
        mediaId: widget.media.id,
        status: _status,
        score: _score > 0 ? _score : null,
        progressEpisodes: _progress,
      );

      // 2. Synchronize with AniList if connected
      final anilistState = ref.read(anilistProvider);
      if (anilistState.isConnected) {
        final anilistId = widget.media.anilistId ??
            int.tryParse(widget.media.id.replaceAll('anilist-', ''));
        if (anilistId != null) {
          await ref.read(anilistProvider.notifier).syncMedia(
            anilistMediaId: anilistId,
            status: _status,
            score: _score > 0 ? _score : null,
            progress: _progress,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              anilistState.isConnected
                  ? 'Saved to Kurogane & synced with AniList!'
                  : 'Progress and score saved!',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorPrefix}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final anilistState = ref.watch(anilistProvider);
    final totalEpisodes = widget.media.episodes;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header cu Imagine și Titlu
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: widget.media.coverImage.large,
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 50,
                      height: 70,
                      color: context.bgPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.media.title.userPreferred,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Zalando Sans Expanded',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Update score and progress',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold), size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 1. Selector Status
            Text(
              AppStrings.watchStatus,
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildStatusPill(AppStrings.statusWatching, 'WATCHING', PhosphorIcons.play(PhosphorIconsStyle.bold)),
                  const SizedBox(width: 8),
                  _buildStatusPill(AppStrings.statusCompleted, 'COMPLETED', PhosphorIcons.check(PhosphorIconsStyle.bold)),
                  const SizedBox(width: 8),
                  _buildStatusPill(AppStrings.statusPlanToWatch, 'PLAN_TO_WATCH', PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.bold)),
                  const SizedBox(width: 8),
                  _buildStatusPill(AppStrings.statusOnHold, 'ON_HOLD', PhosphorIcons.pause(PhosphorIconsStyle.bold)),
                  const SizedBox(width: 8),
                  _buildStatusPill(AppStrings.statusDropped, 'DROPPED', PhosphorIcons.x(PhosphorIconsStyle.bold)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Selector Notă (1 – 10) cu Stele Interactive
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.yourScore,
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(_score).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.star(PhosphorIconsStyle.fill),
                        size: 13,
                        color: _getScoreColor(_score),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _score > 0 ? '${_score.toStringAsFixed(1)} • ${_getScoreLabel(_score)}' : AppStrings.noScore,
                        style: TextStyle(
                          color: _getScoreColor(_score),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Slider Rating 0 – 10 cu trepte de 0.5
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _getScoreColor(_score),
                inactiveTrackColor: context.borderSubtle,
                thumbColor: _getScoreColor(_score),
                overlayColor: _getScoreColor(_score).withValues(alpha: 0.15),
                trackHeight: 6,
              ),
              child: Slider(
                value: _score,
                min: 0.0,
                max: 10.0,
                divisions: 20, // Pas de 0.5
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _score = val);
                },
              ),
            ),

            const SizedBox(height: 20),

            // 3. Stepper Progres Episoade
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.episodeProgress,
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  totalEpisodes != null ? 'of $totalEpisodes ep' : 'Total unknown',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: context.bgSurfaceHover,
                borderRadius: BorderRadius.circular(9999), // FULL ROUNDED
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Buton Scădere
                  IconButton(
                    icon: Icon(PhosphorIcons.minus(PhosphorIconsStyle.bold)),
                    onPressed: _progress > 0
                        ? () {
                            HapticFeedback.lightImpact();
                            setState(() => _progress--);
                          }
                        : null,
                  ),

                  // Display Episod Curent (Tap to type)
                  GestureDetector(
                    onTap: () => _showDirectEpisodeDialog(context, totalEpisodes),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.bgSurfaceHover,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_progress ${totalEpisodes != null ? "/ $totalEpisodes" : ""}',
                            style: TextStyle(
                              fontFamily: 'Zalando Sans Expanded',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(PhosphorIcons.pencilSimple(PhosphorIconsStyle.bold), size: 12, color: context.textSecondary),
                        ],
                      ),
                    ),
                  ),

                  // Butoane Creștere & Max
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
                        onPressed: (totalEpisodes == null || _progress < totalEpisodes)
                            ? () {
                                HapticFeedback.lightImpact();
                                setState(() => _progress++);
                              }
                            : null,
                      ),
                      if (totalEpisodes != null && _progress < totalEpisodes)
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _progress = totalEpisodes;
                              _status = 'COMPLETED';
                            });
                          },
                          child: Text(
                            'MAX',
                            style: TextStyle(
                              color: context.accentPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Indicator Sincronizare AniList
            if (anilistState.isConnected)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIcons.cloudCheck(PhosphorIconsStyle.fill),
                      size: 16,
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active sync with @${anilistState.user!.name}',
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.accentPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                          color: context.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String label, String value, IconData icon) {
    final isSelected = _status == value;
    final totalEpisodes = widget.media.episodes;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _status = value;
          if (value == 'COMPLETED') {
            if (totalEpisodes != null && totalEpisodes > 0) {
              _progress = totalEpisodes;
            } else if (widget.media.format?.toUpperCase() == 'MOVIE' || widget.media.type.toUpperCase() == 'MOVIE') {
              _progress = 1;
            } else if (_progress == 0) {
              _progress = 1;
            }
          } else if (value == 'PLAN_TO_WATCH' && _progress == totalEpisodes) {
            _progress = 0;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.accentPrimary : context.bgSurfaceHover,
          borderRadius: BorderRadius.circular(9999), // FULL ROUNDED
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? context.onPrimary : context.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? context.onPrimary : context.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDirectEpisodeDialog(BuildContext context, int? totalEpisodes) {
    final controller = TextEditingController(text: '$_progress');
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Episode Number',
          style: TextStyle(
            fontFamily: 'Zalando Sans Expanded',
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Enter episode watched...',
            hintStyle: TextStyle(color: context.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: Text(AppStrings.cancel, style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed >= 0) {
                setState(() {
                  _progress = (totalEpisodes != null && totalEpisodes > 0 && parsed > totalEpisodes)
                      ? totalEpisodes
                      : parsed;
                  if (totalEpisodes != null && totalEpisodes > 0 && _progress >= totalEpisodes) {
                    _status = 'COMPLETED';
                  }
                });
              }
              Navigator.of(dlgCtx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.accentPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Set', style: TextStyle(color: context.onPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
