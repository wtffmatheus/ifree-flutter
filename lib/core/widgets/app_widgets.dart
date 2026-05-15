import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

// ── StatusBadge ───────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'aprovado':  return AppColors.aprovado;
      case 'concluido': return AppColors.concluido;
      default:          return AppColors.analise;
    }
  }

  String get _label {
    switch (status) {
      case 'aprovado':  return '✓ Aprovado';
      case 'concluido': return '🏁 Concluído';
      default:          return '⏳ Em Análise';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'Sora',
        ),
      ),
    );
  }
}

// ── IFreeAvatar ────────────────────────────────────────────────────────────────
class IFreeAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final String? photoUrl;

  const IFreeAvatar({
    super.key,
    required this.name,
    this.size = 56,
    this.color,
    this.photoUrl,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final primary = color ?? Theme.of(context).colorScheme.primary;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(primary),
        ),
      );
    }
    return _fallback(primary);
  }

  Widget _fallback(Color primary) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [primary, primary.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            fontFamily: 'Sora',
          ),
        ),
      ),
    );
  }
}

// ── ShimmerCard ─────────────────────────────────────────────────────────────────
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF1C1C26) : const Color(0xFFE8E8EE),
        highlightColor: isDark ? const Color(0xFF2A2A38) : const Color(0xFFF5F5FA),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C26) : const Color(0xFFE8E8EE),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

// ── InfoChip ───────────────────────────────────────────────────────────────────
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(0.2), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Sora')),
        ],
      ),
    );
  }
}

// ── StarRating ─────────────────────────────────────────────────────────────────
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  const StarRating({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star_rounded, size: size, color: AppColors.gold);
        } else if (i < rating) {
          return Icon(Icons.star_half_rounded, size: size, color: AppColors.gold);
        }
        return Icon(Icons.star_outline_rounded, size: size, color: AppColors.gold.withOpacity(0.3));
      }),
    );
  }
}

// ── SectionHeader ─────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

// ── EmptyState ─────────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
