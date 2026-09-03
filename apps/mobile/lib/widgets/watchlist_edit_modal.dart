import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../models/media_item.dart';
import '../models/watchlist_item.dart';
import '../providers/anilist_provider.dart';
import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';
import '../views/auth/login_screen.dart';

/// Modalul unificat pentru Adăugare / Editare Serie în Watchlist
/// Gestionează starea seriei (Vizionare, Finalizat, etc.), progresul episoadelor,
/// nota 1-10, datele de început/sfârșit și sincronizarea automată cu AniList.
Future<void> showWatchlistEditModal(
  BuildContext context,
  WidgetRef ref, {
  required MediaItem item,
  WatchlistItemRecord? existingRecord,
}) async {
  final isLoggedIn = ref.read(isLoggedInProvider);
  if (!isLoggedIn) {
    LoginScreen.show(context);
    return;
  }

  final resolvedRecord = existingRecord ??
      ref.read(watchlistProvider).maybeWhen(
            data: (list) => list.where((w) => w.mediaId == item.id).firstOrNull,
            orElse: () => null,
          );

  String selectedStatus = resolvedRecord?.status ?? 'WATCHING';
  int episodes = resolvedRecord?.progressEpisodes ?? 0;
  final totalEpisodes = item.episodes;
  String? startedAt = resolvedRecord?.startedAt;
  String? completedAt = resolvedRecord?.completedAt;

  // Scorul inițial al utilizatorului (rotunjit 1..10, sau 0 pentru Fără Notă)
  int userScore = (resolvedRecord?.score != null && resolvedRecord!.score! > 0)
      ? resolvedRecord.score!.round().clamp(1, 10)
      : 0;

  // Scorul implicit calculat din media seriei dacă utilizatorul apasă + de la 0
  final animeAvg = (item.scores.weightedScore > 0 ? item.scores.weightedScore : item.scores.averageScore);
  final defaultSmartScore = animeAvg > 0
      ? (animeAvg > 10 ? (animeAvg / 10).round() : animeAvg.round()).clamp(1, 10)
      : 8;

  String formatDateShort(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '--';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    const months = AppStrings.shortMonths;
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> pickDate({
    required BuildContext ctx,
    required String? currentDateStr,
    required Function(String?) onSelected,
  }) async {
    final now = DateTime.now();
    final initial = (currentDateStr != null ? DateTime.tryParse(currentDateStr) : null) ?? now;
    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year + 5),
      builder: (datePickerCtx, child) {
        return Theme(
          data: Theme.of(datePickerCtx).copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.accentPrimary,
              onPrimary: context.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              surface: context.bgSurface,
              onSurface: context.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelected(picked.toIso8601String().split('T').first);
    }
  }

  final statuses = [
    {'key': 'WATCHING', 'label': AppStrings.statusWatching, 'color': context.statusWatching},
    {'key': 'COMPLETED', 'label': AppStrings.statusCompleted, 'color': context.statusCompleted},
    {'key': 'PLAN_TO_WATCH', 'label': AppStrings.statusPlanToWatch, 'color': context.statusPlanToWatch},
    {'key': 'ON_HOLD', 'label': AppStrings.statusOnHold, 'color': context.statusOnHold},
    {'key': 'DROPPED', 'label': AppStrings.statusDropped, 'color': context.statusDropped},
  ];

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      bool autoCompletedEpisodes = false;
      bool episodesIncreasing = true;
      bool scoreIncreasing = true;

      return StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + MediaQuery.paddingOf(modalCtx).bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.borderSubtle,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    resolvedRecord != null ? AppStrings.editSeries : AppStrings.addToWatchlist,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status chips (Dot semantic discret pentru neselectat, fundal plin pentru selectat)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: statuses.map((st) {
                      final isSel = selectedStatus == st['key'];
                      final color = st['color'] as Color;
                      final bool isLightColor = color.computeLuminance() > 0.4;
                      final Color isSelTextColor = isLightColor ? const Color(0xFF141414) : Colors.white;

                      return GestureDetector(
                        onTap: () => setModalState(() {
                          selectedStatus = st['key'] as String;
                          final todayStr = DateTime.now().toIso8601String().split('T').first;
                          if (selectedStatus == 'WATCHING') {
                            startedAt ??= todayStr;
                          } else if (selectedStatus == 'COMPLETED') {
                            startedAt ??= todayStr;
                            completedAt ??= todayStr;
                            int targetEp = episodes;
                            if (totalEpisodes != null && totalEpisodes > 0) {
                              targetEp = totalEpisodes;
                            } else if (item.format?.toUpperCase() == 'MOVIE' || item.type.toUpperCase() == 'MOVIE') {
                              targetEp = 1;
                            }
                            if (targetEp != episodes) {
                              episodesIncreasing = targetEp >= episodes;
                              episodes = targetEp;
                              autoCompletedEpisodes = true;
                              HapticFeedback.mediumImpact();
                              Future.delayed(const Duration(milliseconds: 750), () {
                                if (modalCtx.mounted) {
                                  setModalState(() => autoCompletedEpisodes = false);
                                }
                              });
                            }
                          } else if (selectedStatus == 'PLAN_TO_WATCH' && totalEpisodes != null && episodes == totalEpisodes) {
                            episodesIncreasing = false;
                            episodes = 0;
                          }
                        }),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? color : context.bgSurfaceHover,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: isSel ? color : context.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSel)
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Icon(
                                    PhosphorIcons.check(PhosphorIconsStyle.bold),
                                    size: 13,
                                    color: isSelTextColor,
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Container(
                                    width: 6.5,
                                    height: 6.5,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              Text(
                                st['label'] as String,
                                style: TextStyle(
                                  color: isSel ? isSelTextColor : context.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // 1. Header & Stepper: Episode Progress
                  Text(
                    AppStrings.episodeProgress,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: autoCompletedEpisodes
                          ? const Color(0xFF60A5FA).withValues(alpha: 0.16)
                          : context.bgSurfaceHover,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: autoCompletedEpisodes
                            ? const Color(0xFF60A5FA).withValues(alpha: 0.65)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Minus button (Left)
                        GestureDetector(
                          onTap: () {
                            if (episodes > 0) {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                episodesIncreasing = false;
                                episodes--;
                                if (selectedStatus == 'COMPLETED' &&
                                    totalEpisodes != null &&
                                    totalEpisodes > 0 &&
                                    episodes < totalEpisodes) {
                                  selectedStatus = 'WATCHING';
                                }
                              });
                            }
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: context.bgPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                PhosphorIcons.minus(PhosphorIconsStyle.bold),
                                size: 16,
                                color: episodes > 0 ? context.textPrimary : context.textMuted,
                              ),
                            ),
                          ),
                        ),

                        // Center Value: Progres cifre tabulare
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (autoCompletedEpisodes) ...[
                              Icon(
                                PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                                size: 14,
                                color: const Color(0xFF60A5FA),
                              ),
                              const SizedBox(width: 4),
                            ],
                            SizedBox(
                              height: 36,
                              child: Center(
                                child: ClipRect(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    transitionBuilder: (child, animation) {
                                      final key = child.key;
                                      final bool isIncoming = key is ValueKey<int> && key.value == episodes;
                                      final double beginY = episodesIncreasing
                                          ? (isIncoming ? 1.0 : -1.0)
                                          : (isIncoming ? -1.0 : 1.0);
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: Offset(0, beginY),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          )),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      '$episodes',
                                      key: ValueKey<int>(episodes),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: autoCompletedEpisodes ? const Color(0xFF60A5FA) : context.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              ' / ${totalEpisodes != null && totalEpisodes > 0 ? totalEpisodes : "?"}',
                              style: TextStyle(
                                color: autoCompletedEpisodes ? const Color(0xFF60A5FA) : context.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),

                        // Plus button (Right)
                        GestureDetector(
                          onTap: () {
                            if (totalEpisodes == null || totalEpisodes == 0 || episodes < totalEpisodes) {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                episodesIncreasing = true;
                                episodes++;
                                if (totalEpisodes != null && totalEpisodes > 0 && episodes >= totalEpisodes) {
                                  selectedStatus = 'COMPLETED';
                                }
                              });
                            }
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: context.bgPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                PhosphorIcons.plus(PhosphorIconsStyle.bold),
                                size: 16,
                                color: (totalEpisodes == null || totalEpisodes == 0 || episodes < totalEpisodes)
                                    ? context.textPrimary
                                    : context.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. Header & Stepper: Nota Ta (1 - 10)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        userScore > 0 ? PhosphorIconsFill.star : PhosphorIcons.star(PhosphorIconsStyle.bold),
                        size: 14,
                        color: userScore > 0 ? context.scoreGold : context.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.yourScore,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: context.bgSurfaceHover,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Minus button (Left)
                        GestureDetector(
                          onTap: () {
                            if (userScore > 0) {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                scoreIncreasing = false;
                                userScore--;
                              });
                            }
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: context.bgPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                PhosphorIcons.minus(PhosphorIconsStyle.bold),
                                size: 16,
                                color: userScore > 0 ? context.textPrimary : context.textMuted,
                              ),
                            ),
                          ),
                        ),

                        // Center Value: Notă utilizator
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (userScore > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: Icon(
                                  PhosphorIcons.star(PhosphorIconsStyle.fill),
                                  size: 14,
                                  color: context.scoreGold,
                                ),
                              ),
                            SizedBox(
                              height: 36,
                              child: Center(
                                child: ClipRect(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    transitionBuilder: (child, animation) {
                                      final key = child.key;
                                      final bool isIncoming = key is ValueKey<int> && key.value == userScore;
                                      final double beginY = scoreIncreasing
                                          ? (isIncoming ? 1.0 : -1.0)
                                          : (isIncoming ? -1.0 : 1.0);
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: Offset(0, beginY),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          )),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      userScore > 0 ? '$userScore' : AppStrings.noScore,
                                      key: ValueKey<int>(userScore),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: userScore > 0 ? context.textPrimary : context.textMuted,
                                        fontSize: userScore > 0 ? 15 : 14.5,
                                        fontWeight: userScore > 0 ? FontWeight.w700 : FontWeight.w600,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (userScore > 0)
                              Text(
                                ' / 10',
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                          ],
                        ),

                        // Plus button (Right)
                        GestureDetector(
                          onTap: () {
                            if (userScore < 10) {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                scoreIncreasing = true;
                                if (userScore == 0) {
                                  userScore = defaultSmartScore;
                                } else {
                                  userScore++;
                                }
                              });
                            }
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: context.bgPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                PhosphorIcons.plus(PhosphorIconsStyle.bold),
                                size: 16,
                                color: userScore < 10 ? context.textPrimary : context.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3. Headers & Buttons: Data Început & Data Sfârșit
                  Row(
                    children: [
                      // Data Început Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIcons.calendarBlank(PhosphorIconsStyle.bold),
                                  size: 14,
                                  color: startedAt != null ? context.signalLive : context.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppStrings.startDate,
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.selectionClick();
                                await pickDate(
                                  ctx: modalCtx,
                                  currentDateStr: startedAt,
                                  onSelected: (date) => setModalState(() => startedAt = date),
                                );
                              },
                              child: Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: context.bgSurfaceHover,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        formatDateShort(startedAt),
                                        style: TextStyle(
                                          color: startedAt != null ? context.textPrimary : context.textMuted,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (startedAt != null)
                                      GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setModalState(() => startedAt = null);
                                        },
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: context.bgPrimary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              PhosphorIcons.x(PhosphorIconsStyle.bold),
                                              size: 13,
                                              color: context.textMuted,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Icon(
                                        PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                                        size: 14,
                                        color: context.textMuted,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Data Sfârșit Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIcons.flagCheckered(PhosphorIconsStyle.bold),
                                  size: 14,
                                  color: completedAt != null ? context.scoreGold : context.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppStrings.endDate,
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.selectionClick();
                                await pickDate(
                                  ctx: modalCtx,
                                  currentDateStr: completedAt,
                                  onSelected: (date) => setModalState(() => completedAt = date),
                                );
                              },
                              child: Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: context.bgSurfaceHover,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        formatDateShort(completedAt),
                                        style: TextStyle(
                                          color: completedAt != null ? context.textPrimary : context.textMuted,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (completedAt != null)
                                      GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setModalState(() => completedAt = null);
                                        },
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: context.bgPrimary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              PhosphorIcons.x(PhosphorIconsStyle.bold),
                                              size: 13,
                                              color: context.textMuted,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Icon(
                                        PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                                        size: 14,
                                        color: context.textMuted,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Actions: Save & optional Remove
                  Row(
                    children: [
                      if (resolvedRecord != null) ...[
                        InkWell(
                          borderRadius: BorderRadius.circular(9999),
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            HapticFeedback.mediumImpact();
                            await ref.read(watchlistProvider.notifier).removeItem(item.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(AppStrings.removedFromWatchlistToast),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: context.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Center(
                              child: Icon(
                                PhosphorIcons.trash(PhosphorIconsStyle.bold),
                                size: 18,
                                color: context.error,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(9999),
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            HapticFeedback.mediumImpact();

                            final double finalScoreToSave = userScore > 0 ? userScore.toDouble() : 0.0;
                            await ref.read(watchlistProvider.notifier).updateItem(
                                  mediaId: item.id,
                                  status: selectedStatus,
                                  progressEpisodes: episodes,
                                  score: finalScoreToSave,
                                  startedAt: startedAt,
                                  completedAt: completedAt,
                                );

                            // Sincronizare automată AniList dacă este conectat
                            final anilistState = ref.read(anilistProvider);
                            if (anilistState.isConnected) {
                              final anilistId = item.anilistId ?? int.tryParse(item.id.replaceAll('anilist-', ''));
                              if (anilistId != null) {
                                await ref.read(anilistProvider.notifier).syncMedia(
                                      anilistMediaId: anilistId,
                                      status: selectedStatus,
                                      score: userScore > 0 ? userScore.toDouble() : null,
                                      progress: episodes,
                                      startedAt: startedAt,
                                      completedAt: completedAt,
                                    );
                              }
                            }

                            if (!context.mounted) return;
                            final String syncSuffix = anilistState.isConnected ? ' & synced with AniList' : '';
                            final String msg = userScore > 0
                                ? '${AppStrings.savedToWatchlistToast} (Score $userScore/10)$syncSuffix!'
                                : '${AppStrings.savedToWatchlistToast}$syncSuffix!';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: context.accentPrimary,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              AppStrings.saveToList,
                              style: TextStyle(
                                color: context.onPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
