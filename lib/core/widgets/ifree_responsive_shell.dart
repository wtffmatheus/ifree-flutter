import 'package:flutter/material.dart';

class IFreeNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const IFreeNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class IFreeResponsiveShell extends StatelessWidget {
  final int selectedIndex;
  final Widget child;
  final List<IFreeNavItem> destinations;
  final ValueChanged<int> onDestinationSelected;
  final String sectionLabel;
  final String sectionSubtitle;

  const IFreeResponsiveShell({
    super.key,
    required this.selectedIndex,
    required this.child,
    required this.destinations,
    required this.onDestinationSelected,
    required this.sectionLabel,
    required this.sectionSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (!isDesktop) {
          return Scaffold(
            body: child,
            bottomNavigationBar: _MobileNavigation(
              selectedIndex: selectedIndex,
              destinations: destinations,
              onDestinationSelected: onDestinationSelected,
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              _DesktopNavigation(
                width: constraints.maxWidth,
                selectedIndex: selectedIndex,
                destinations: destinations,
                onDestinationSelected: onDestinationSelected,
                sectionLabel: sectionLabel,
                sectionSubtitle: sectionSubtitle,
              ),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  final int selectedIndex;
  final List<IFreeNavItem> destinations;
  final ValueChanged<int> onDestinationSelected;

  const _MobileNavigation({
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations
              .map(
                (item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  final double width;
  final int selectedIndex;
  final List<IFreeNavItem> destinations;
  final ValueChanged<int> onDestinationSelected;
  final String sectionLabel;
  final String sectionSubtitle;

  const _DesktopNavigation({
    required this.width,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.sectionLabel,
    required this.sectionSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final extended = width >= 1180;

    return SafeArea(
      right: false,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            right: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
        ),
        child: NavigationRail(
          extended: extended,
          minWidth: 88,
          minExtendedWidth: 232,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          groupAlignment: -0.86,
          labelType: extended
              ? NavigationRailLabelType.none
              : NavigationRailLabelType.selected,
          leading: Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 28),
            child: _BrandHeader(
              extended: extended,
              sectionLabel: sectionLabel,
              sectionSubtitle: sectionSubtitle,
            ),
          ),
          destinations: destinations
              .map(
                (item) => NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final bool extended;
  final String sectionLabel;
  final String sectionSubtitle;

  const _BrandHeader({
    required this.extended,
    required this.sectionLabel,
    required this.sectionSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final mark = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'iF',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
      ),
    );

    if (!extended) {
      return Tooltip(message: sectionLabel, child: mark);
    }

    return SizedBox(
      width: 190,
      child: Row(
        children: [
          mark,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'iFree',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sectionSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
