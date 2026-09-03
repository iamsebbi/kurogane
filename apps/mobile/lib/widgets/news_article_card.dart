import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../models/news_article.dart';
import 'tactile_scale_button.dart';

/// Card interactiv reutilizabil pentru articole de știri și noutăți anime.
///
/// Afișează thumbnail-ul decupat GPU 10px, titlul pe 2 rânduri, sursa
/// și data relativă, având suport nativ de deschidere în browser la atingere.
class NewsArticleCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback? onTap;

  const NewsArticleCard({
    super.key,
    required this.article,
    this.onTap,
  });

  Future<void> _handleTap(BuildContext context) async {
    if (onTap != null) {
      onTap!();
      return;
    }

    final articleUrl = article.url;
    if (articleUrl != null && articleUrl.isNotEmpty) {
      final uri = Uri.tryParse(articleUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TactileScaleButton(
        onTap: () => _handleTap(context),
        scaleDown: 0.98,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderSubtle),
          ),
          child: Row(
            children: [
              if (article.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: article.imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 70,
                      height: 70,
                      color: context.bgPrimary,
                      child: Icon(
                        PhosphorIcons.newspaper(PhosphorIconsStyle.bold),
                        color: context.textMuted,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        color: context.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          article.source,
                          style: TextStyle(
                            color: context.accentPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (article.date.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '•  ${article.date}',
                            style: TextStyle(
                              color: context.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
