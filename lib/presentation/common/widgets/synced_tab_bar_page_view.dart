import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// [TabBar] + [PageView] con el mismo [TabController], sincronizados.
///
/// Sustituye a [DefaultTabController] + [TabBarView] cuando hace falta
/// deslizar entre pestañas **sin** el bug en web "Build scheduled during
/// frame" (el [TabBarView] interno puede marcar [setState] durante el layout).
class SyncedTabBarPageView extends StatefulWidget {
  const SyncedTabBarPageView({
    super.key,
    required this.tabs,
    required this.children,
    this.surfaceColor,
    this.isScrollable = false,
    this.tabAlignment = TabAlignment.start,
  });

  final List<Widget> tabs;
  final List<Widget> children;
  final Color? surfaceColor;
  /// En web, `true` puede disparar "Build scheduled during frame" (scroll del [TabBar]).
  final bool isScrollable;
  final TabAlignment tabAlignment;

  @override
  State<SyncedTabBarPageView> createState() => _SyncedTabBarPageViewState();
}

class _SyncedTabBarPageViewState extends State<SyncedTabBarPageView>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final n = widget.tabs.length;
    assert(
      n == widget.children.length,
      'SyncedTabBarPageView: ${widget.tabs.length} tabs y '
      '${widget.children.length} children',
    );
    _tabController = TabController(length: n, vsync: this);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface =
        widget.surfaceColor ?? Theme.of(context).colorScheme.surface;
    // [TabAlignment.start] / [end] solo son válidos con [isScrollable: true] (API Material 3).
    final bool scrollable = widget.isScrollable;
    final TabAlignment effectiveTabAlignment = scrollable
        ? widget.tabAlignment
        : TabAlignment.fill;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: scrollable,
            tabAlignment: effectiveTabAlignment,
            onTap: (int i) {
              _pageController.animateToPage(
                i,
                duration: kTabScrollDuration,
                curve: Curves.easeInOut,
              );
              // Evita notificar al [TabController] durante el layout del [PageView] (p. ej. web).
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (_tabController.index != i) {
                  _tabController.animateTo(i);
                }
              });
            },
            tabs: widget.tabs,
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const ClampingScrollPhysics(
              parent: PageScrollPhysics(),
            ),
            onPageChanged: (int i) {
              // Doble aplazamiento: el primero deja pasar [applyContentDimensions] del [PageView].
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  if (_tabController.index != i) {
                    _tabController.animateTo(i);
                  }
                });
              });
            },
            children: widget.children,
          ),
        ),
      ],
    );
  }
}
