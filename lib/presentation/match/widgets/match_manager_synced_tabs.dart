import 'package:flutter/material.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/common/widgets/synced_tab_bar_page_view.dart';

/// Tres pestañas con deslizamiento; mismas cáscara en vivo y en detalle.
class MatchManagerSyncedTabs extends StatelessWidget {
  const MatchManagerSyncedTabs({
    super.key,
    required this.pageScrollPad,
    required this.tabListPad,
    required this.l10n,
    required this.colorScheme,
    required this.onRefresh,
    required this.principalSections,
    required this.statsSections,
    required this.eventsSections,
  });

  final EdgeInsets pageScrollPad;
  final EdgeInsets tabListPad;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final Future<void> Function() onRefresh;
  final List<Widget> principalSections;
  final List<Widget> statsSections;
  final List<Widget> eventsSections;

  @override
  Widget build(BuildContext context) {
    Widget tabPage(List<Widget> children) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: pageScrollPad,
          physics: const AlwaysScrollableScrollPhysics(),
          children: children,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tabListPad.left,
        tabListPad.top,
        tabListPad.right,
        0,
      ),
      child: SyncedTabBarPageView(
        surfaceColor: colorScheme.surface,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: l10n.matchStatsTabMain),
          Tab(text: l10n.matchStatsTabStats),
          Tab(text: l10n.matchStatsTabEvents),
        ],
        children: [
          tabPage(principalSections),
          tabPage(statsSections),
          tabPage(eventsSections),
        ],
      ),
    );
  }
}
