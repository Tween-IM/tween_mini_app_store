import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mini_app.dart';
import '../models/app_suggestion.dart';
import '../repository/mini_app_repository.dart';
import '../repository/app_suggestion_repository.dart';
import 'mini_app_runtime.dart';
import 'submit_mini_app_screen.dart';
import 'suggest_app_screen.dart';
import 'community_suggestions_screen.dart';
import 'upload_mini_app_package_screen.dart';

/// A reusable mini-app marketplace inspired by Google Play's discovery layout.
/// The host app supplies its own [MiniAppRepository].
class MiniAppStore extends StatefulWidget {
  const MiniAppStore({
    super.key,
    required this.repository,
    this.title = 'Mini Apps',
    this.onAppOpened,
  });

  final MiniAppRepository repository;
  final String title;
  final ValueChanged<MiniApp>? onAppOpened;

  @override
  State<MiniAppStore> createState() => _MiniAppStoreState();
}

class _MiniAppStoreState extends State<MiniAppStore>
    with SingleTickerProviderStateMixin {
  late Future<List<MiniApp>> _future;
  late final TabController _tabs;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _libraryIds = <String>{};
  String _search = '';
  String _category = 'All';
  int _destination = 0; // Explore, Categories, Search, My Apps

  @override
  void initState() {
    super.initState();
    _future = widget.repository.fetchApps();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<MiniApp>> _refresh() async {
    final result = widget.repository.fetchApps();
    setState(() => _future = result);
    return result;
  }

  Future<void> _showSubmissionOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Add to Tween', style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Choose how you want to contribute.', style: Theme.of(sheetContext).textTheme.bodyMedium),
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.link_rounded)),
              title: const Text('Publish a website / PWA'),
              subtitle: const Text('Add a live website as a mini app'),
              onTap: () => Navigator.pop(sheetContext, 'website'),
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.code_rounded)),
              title: const Text('Upload a mini app package'),
              subtitle: const Text('Install a ZIP with HTML, CSS and JavaScript'),
              onTap: () => Navigator.pop(sheetContext, 'package'),
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.code_rounded)),
              title: const Text('Suggest a GitHub project'),
              subtitle: const Text('Recommend a public developer repository'),
              onTap: () => Navigator.pop(sheetContext, 'github'),
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.people_alt_outlined)),
              title: const Text('Browse community suggestions'),
              subtitle: const Text('Vote for ideas and see review status'),
              onTap: () => Navigator.pop(sheetContext, 'community'),
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.lightbulb_outline_rounded)),
              title: const Text('Suggest an app or idea'),
              subtitle: const Text('Let the community recommend what to build'),
              onTap: () => Navigator.pop(sheetContext, 'idea'),
            ),
          ]),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'package') {
      final submitted = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => UploadMiniAppPackageScreen(repository: widget.repository),
      ));
      if (submitted == true && mounted) {
        await _refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mini app package added to your store.')),
        );
      }
      return;
    }
    if (choice == 'community') {
      await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => CommunitySuggestionsScreen(
          repository: DemoAppSuggestionRepository.instance,
        ),
      ));
      return;
    }
    if (choice == 'website') {
      await _submit();
      return;
    }
    final source = choice == 'github'
        ? SuggestionSource.github
        : SuggestionSource.appIdea;
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SuggestAppScreen(
          repository: DemoAppSuggestionRepository.instance,
          initialSource: source,
        ),
      ),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks! Your app suggestion was submitted for review.')),
      );
    }
  }

  Future<void> _submit() async {
    final before = await widget.repository.fetchApps();
    final beforeIds = before.map((app) => app.id).toSet();
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SubmitMiniAppScreen(repository: widget.repository),
      ),
    );
    if (submitted == true && mounted) {
      final after = await _refresh();
      final added = after.where((app) => !beforeIds.contains(app.id));
      setState(() {
        // Apps submitted by this developer are immediately discoverable and
        // also appear in the personal developer/library view.
        _libraryIds.addAll(added.map((app) => app.id));
        _destination = 0;
        _category = 'All';
        _search = '';
        _searchController.clear();
        _tabs.animateTo(0);
      });
      if (added.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mini app added to the store')),
        );
      }
    } else {
      await _refresh();
    }
  }

  void _openDetails(MiniApp app) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MiniAppDetailsPage(
          app: app,
          onOpen: () {
            setState(() => _libraryIds.add(app.id));
            widget.onAppOpened?.call(app);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MiniAppRuntime(app: app)),
            );
          },
        ),
      ),
    );
  }

  void _setDestination(int index) {
    setState(() {
      _destination = index;
      if (index == 2) _tabs.animateTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF16845B),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.apps_rounded, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _destination == 1 ? 'Categories'
                    : _destination == 2 ? 'Search'
                    : _destination == 3 ? 'My apps' : widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Publish a mini app',
            onPressed: _showSubmissionOptions,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<List<MiniApp>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to load mini apps: ${snapshot.error}',
                    textAlign: TextAlign.center),
              ),
            );
          }

          final apps = snapshot.data ?? const <MiniApp>[];
          final categories = <String>{
            'All',
            ...apps.map((app) => app.category.trim()).where((c) => c.isNotEmpty),
          }.toList()..sort((a, b) => a == 'All' ? -1 : b == 'All' ? 1 : a.compareTo(b));

          final query = _search.toLowerCase();
          final matched = apps.where((app) {
            final searchable = [
              app.name, app.description, app.shortDescription ?? '',
              app.developer, app.category, app.keywords ?? '',
              app.launchUrl, app.canonicalUrl ?? '',
            ].join(' ').toLowerCase();
            return (query.isEmpty || searchable.contains(query)) &&
                (_category == 'All' || app.category == _category);
          }).toList();
          final ranked = [...matched]
            ..sort((a, b) => b.rating.compareTo(a.rating));
          final library = apps.where((app) => _libraryIds.contains(app.id)).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onTap: () {
                    if (_destination != 2) _setDestination(2);
                  },
                  onChanged: (value) => setState(() => _search = value.trim()),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search apps & games',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.isEmpty
                        ? IconButton(
                            tooltip: 'Add mini app',
                            icon: const Icon(Icons.add_link_rounded),
                            onPressed: _submit,
                          )
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          ),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest.withOpacity(.62),
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_destination == 0)
                Material(
                  color: scheme.surface,
                  child: TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: scheme.primary,
                    unselectedLabelColor: scheme.onSurfaceVariant,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'For you'),
                      Tab(text: 'Top charts'),
                      Tab(text: 'Categories'),
                    ],
                  ),
                ),
              Expanded(
                child: switch (_destination) {
                  1 => _CategoryBrowser(
                      categories: categories.where((c) => c != 'All').toList(),
                      apps: matched,
                      selected: _category,
                      onSelect: (value) => setState(() => _category = value),
                      onAppTap: _openDetails,
                    ),
                  2 => _SearchResults(
                      query: _search,
                      apps: matched,
                      onAppTap: _openDetails,
                      onCategory: (value) => setState(() => _category = value),
                      categories: categories,
                      selected: _category,
                    ),
                  3 => _MyAppsPage(
                      apps: library,
                      onAppTap: _openDetails,
                      onBrowse: () => _setDestination(0),
                    ),
                  _ => TabBarView(
                      controller: _tabs,
                      children: [
                        _ForYouTab(
                          apps: matched,
                          categories: categories.where((c) => c != 'All').toList(),
                          onAppTap: _openDetails,
                          onSeeAll: () {
                            setState(() { _destination = 1; _category = 'All'; });
                          },
                          onCategoryTap: (category) {
                            setState(() {
                              _category = category;
                              _destination = 1;
                            });
                          },
                        ),
                        _TopChartsTab(apps: ranked, onAppTap: _openDetails),
                        _CategoriesTab(
                          categories: categories.where((c) => c != 'All').toList(),
                          selected: _category,
                          onSelect: (value) {
                            setState(() {
                              _category = value;
                              _destination = 1;
                            });
                          },
                          apps: matched,
                          onAppTap: _openDetails,
                        ),
                      ],
                    ),
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _destination,
        onDestinationSelected: _setDestination,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category_rounded),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: 'My apps',
          ),
        ],
      ),
    );
  }
}

class _CategoryBrowser extends StatelessWidget {
  const _CategoryBrowser({
    required this.categories, required this.apps, required this.selected,
    required this.onSelect, required this.onAppTap,
  });
  final List<String> categories;
  final List<MiniApp> apps;
  final String selected;
  final ValueChanged<String> onSelect;
  final ValueChanged<MiniApp> onAppTap;

  @override
  Widget build(BuildContext context) {
    final visible = selected == 'All'
        ? apps
        : apps.where((app) => app.category == selected).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        Text('Explore categories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All apps'),
              selected: selected == 'All',
              onSelected: (_) => onSelect('All'),
            ),
            ...categories.map((category) => ChoiceChip(
              avatar: Icon(_categoryIcon(category), size: 17),
              label: Text(category),
              selected: selected == category,
              onSelected: (_) => onSelect(category),
            )),
          ],
        ),
        const SizedBox(height: 18),
        Text(selected == 'All' ? 'All mini apps' : selected,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        if (visible.isEmpty)
          const _EmptyStoreMessage(
            icon: Icons.category_outlined,
            title: 'No apps in this category yet',
            message: 'New mini apps in this category will appear here.',
          )
        else
          ...visible.map((app) => _MiniAppRow(
                app: app, onTap: () => onAppTap(app))),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query, required this.apps, required this.onAppTap,
    required this.onCategory, required this.categories, required this.selected,
  });
  final String query;
  final List<MiniApp> apps;
  final ValueChanged<MiniApp> onAppTap;
  final ValueChanged<String> onCategory;
  final List<String> categories;
  final String selected;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (categories.length > 1)
            SizedBox(
              height: 46,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: categories.map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selected == category,
                    onSelected: (_) => onCategory(category),
                  ),
                )).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: Text(query.isEmpty ? 'Discover mini apps' : 'Results for “$query”',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (apps.isEmpty)
            const _EmptyStoreMessage(
              icon: Icons.search_off_rounded,
              title: 'No matching mini apps',
              message: 'Try another name, keyword, developer or category.',
            )
          else
            ...apps.map((app) => _MiniAppRow(
                  app: app, onTap: () => onAppTap(app))),
        ],
      );
}

class _MyAppsPage extends StatelessWidget {
  const _MyAppsPage({
    required this.apps, required this.onAppTap, required this.onBrowse,
  });
  final List<MiniApp> apps;
  final ValueChanged<MiniApp> onAppTap;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) => apps.isEmpty
      ? Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.library_add_outlined,
                    size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 14),
                Text('Your mini app library is empty',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Apps you publish or open will be collected here for quick access.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton(onPressed: onBrowse, child: const Text('Explore apps')),
              ],
            ),
          ),
        )
      : ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Text('Recently added and opened',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            ...apps.map((app) => _MiniAppRow(
                  app: app, onTap: () => onAppTap(app))),
          ],
        );
}

class _EmptyStoreMessage extends StatelessWidget {
  const _EmptyStoreMessage({
    required this.icon, required this.title, required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 44),
        child: Column(
          children: [
            Icon(icon, size: 52, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}

class _ForYouTab extends StatelessWidget {
  const _ForYouTab({
    required this.apps,
    required this.categories,
    required this.onAppTap,
    required this.onCategoryTap,
    required this.onSeeAll,
  });
  final List<MiniApp> apps;
  final List<String> categories;
  final ValueChanged<MiniApp> onAppTap;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final featured = apps.where((app) => app.featured).toList();
    final recommended = featured.isEmpty ? apps : featured;
    final updated = apps.where((app) => !app.featured).toList();
    final heroApp = recommended.isEmpty ? null : recommended.first;
    return ListView(
      padding: const EdgeInsets.only(bottom: 22),
      children: [
        // Editorial Play Store-style feature panel; content is based on the
        // actual store listing and never claims external approvals/ratings.
        if (heroApp != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: _DiscoveryHero(
              app: heroApp,
              onTap: () => onAppTap(heroApp),
            ),
          ),
        ],
        _SectionHeading(
          title: 'Browse by category',
          action: 'See all',
          onAction: () => onCategoryTap('All'),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ActionChip(
                avatar: Icon(_categoryIcon(category), size: 17),
                label: Text(category),
                onPressed: () => onCategoryTap(category),
              );
            },
          ),
        ),
        _SectionHeading(
          title: 'Recommended for you',
          action: 'See all',
          onAction: onSeeAll,
        ),
        SizedBox(
          height: 216,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: recommended.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) => _RecommendationCard(
              app: recommended[index],
              onTap: () => onAppTap(recommended[index]),
            ),
          ),
        ),
        _SectionHeading(
          title: 'New & updated mini apps',
          action: 'See all',
          onAction: onSeeAll,
        ),
        SizedBox(
          height: 216,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: (updated.isEmpty ? apps : updated).length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final list = updated.isEmpty ? apps : updated;
              return _CompactAppCard(
                app: list[index],
                onTap: () => onAppTap(list[index]),
              );
            },
          ),
        ),
        _SectionHeading(
          title: 'Popular mini apps',
          action: 'Explore',
          onAction: onSeeAll,
        ),
        ...apps.take(8).map(
          (app) => _MiniAppRow(app: app, onTap: () => onAppTap(app)),
        ),
      ],
    );
  }
}

class _DiscoveryHero extends StatelessWidget {
  const _DiscoveryHero({required this.app, required this.onTap});
  final MiniApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 218,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (app.coverImageUrl != null && app.coverImageUrl!.isNotEmpty)
                Image.network(
                  app.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              if (app.coverImageUrl == null || app.coverImageUrl!.isEmpty)
                Positioned(
                  right: -12,
                  top: -30,
                  child: Icon(
                    _categoryIcon(app.category),
                    size: 190,
                    color: scheme.onPrimaryContainer.withOpacity(.10),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      scheme.primaryContainer.withOpacity(.98),
                      scheme.primaryContainer.withOpacity(.82),
                      scheme.primaryContainer.withOpacity(.12),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Discover mini apps',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onPrimaryContainer,
                                  )),
                          const SizedBox(height: 8),
                          Text(
                            'Find useful tools for learning, shopping and entertainment.',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: onTap,
                            child: const Text('Open featured app'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _AppArtwork(app: app, size: 68),
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

class _TopChartsTab extends StatelessWidget {
  const _TopChartsTab({required this.apps, required this.onAppTap});
  final List<MiniApp> apps;
  final ValueChanged<MiniApp> onAppTap;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Top rated mini apps',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Icon(Icons.tune_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
          ...apps.asMap().entries.map(
                (entry) => _RankedAppRow(
                  rank: entry.key + 1,
                  app: entry.value,
                  onTap: () => onAppTap(entry.value),
                ),
              ),
        ],
      );
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.apps,
    required this.onAppTap,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;
  final List<MiniApp> apps;
  final ValueChanged<MiniApp> onAppTap;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          Text('Explore by category',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: categories
                .map((category) => ChoiceChip(
                      avatar: Icon(_categoryIcon(category), size: 18),
                      label: Text(category),
                      selected: selected == category,
                      onSelected: (_) => onSelect(category),
                    ))
                .toList(),
          ),
          const SizedBox(height: 22),
          ...apps.map((app) => _MiniAppRow(
                app: app,
                onTap: () => onAppTap(app),
              )),
        ],
      );
}

class MiniAppDetailsPage extends StatefulWidget {
  const MiniAppDetailsPage({super.key, required this.app, required this.onOpen});
  final MiniApp app;
  final VoidCallback onOpen;

  @override
  State<MiniAppDetailsPage> createState() => _MiniAppDetailsPageState();
}

class _MiniAppDetailsPageState extends State<MiniAppDetailsPage> {
  bool _expandedDescription = false;

  Future<void> _openExternal(String? value) async {
    if (value == null || value.trim().isEmpty) return;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final scheme = Theme.of(context).colorScheme;
    final screenshots = <String>[
      ...app.screenshotUrls,
      if (app.coverImageUrl != null &&
          app.coverImageUrl!.isNotEmpty &&
          !app.screenshotUrls.contains(app.coverImageUrl))
        app.coverImageUrl!,
    ];
    final description = app.description.trim().isEmpty
        ? 'The developer has not added a full description yet.'
        : app.description.trim();
    final isLong = description.length > 240;
    final visibleDescription = !_expandedDescription && isLong
        ? '${description.substring(0, 240).trimRight()}…'
        : description;

    return Scaffold(
      appBar: AppBar(
        title: Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Open website',
            icon: const Icon(Icons.open_in_browser_rounded),
            onPressed: () => _openExternal(app.canonicalUrl ?? app.launchUrl),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AppArtwork(app: app, size: 82),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              )),
                      const SizedBox(height: 5),
                      Text(app.developer,
                          style: TextStyle(color: scheme.primary, fontSize: 13)),
                      const SizedBox(height: 5),
                      Text(
                        app.shortDescription?.trim().isNotEmpty == true
                            ? app.shortDescription!
                            : '${app.category} · Mini app',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _Metric(
                    value: app.rating.toStringAsFixed(1),
                    label: 'Listing rating',
                    icon: Icons.star_rounded,
                  ),
                ),
                const _MetricDivider(),
                const Expanded(child: _Metric(value: 'Web', label: 'App type')),
                const _MetricDivider(),
                Expanded(child: _Metric(value: app.category, label: 'Category')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: FilledButton(
              onPressed: widget.onOpen,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Open mini app'),
            ),
          ),
          if (screenshots.isNotEmpty) ...[
            SizedBox(
              height: 218,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: screenshots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: Image.network(
                      screenshots[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 122,
                        color: scheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, size: 30),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          _SectionHeading(
            title: 'About this mini app',
            action: '',
            onAction: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(visibleDescription,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (isLong)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(
                    () => _expandedDescription = !_expandedDescription),
                child: Text(_expandedDescription ? 'Show less' : 'Read more'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(label: Text(app.category)),
                const Chip(label: Text('Mini app')),
                if (app.language != null && app.language!.isNotEmpty)
                  Chip(label: Text(app.language!.toUpperCase())),
              ],
            ),
          ),
          if (app.keywords?.trim().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text('Keywords: ${app.keywords}',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          const _SectionHeading(
            title: 'App information',
            action: '',
            onAction: null,
          ),
          _InfoRow(label: 'Developer', value: app.developer),
          _InfoRow(label: 'Category', value: app.category),
          _InfoRow(label: 'App type', value: 'Website mini app'),
          if (app.canonicalUrl?.isNotEmpty == true)
            _InfoRow(label: 'Website', value: app.canonicalUrl!),
          if (app.privacyPolicyUrl?.isNotEmpty == true)
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy policy'),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () => _openExternal(app.privacyPolicyUrl),
            ),
          if (app.supportUrl?.isNotEmpty == true)
            ListTile(
              leading: const Icon(Icons.support_agent_rounded),
              title: const Text('Developer support'),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () => _openExternal(app.supportUrl),
            ),
          const _SectionHeading(
            title: 'Ratings & reviews',
            action: '',
            onAction: null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(app.rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(width: 12),
                const Icon(Icons.star_rounded, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Store listing rating. Review totals and rating breakdown '
                    'will appear when real review data is connected.',
                    style: Theme.of(context).textTheme.bodySmall,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 94,
              child: Text(label,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(
              child: Text(value,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.action,
    required this.onAction,
  });
  final String title;
  final String action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
            ),
            if (action.isNotEmpty)
              TextButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      );
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.app, required this.onTap});
  final MiniApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AppArtwork(app: app, size: 142),
              const SizedBox(height: 8),
              Text(app.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13)),
              Text(app.developer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 3),
              _RatingText(rating: app.rating),
            ],
          ),
        ),
      );
}

class _CompactAppCard extends StatelessWidget {
  const _CompactAppCard({required this.app, required this.onTap});
  final MiniApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 116,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AppArtwork(app: app, size: 126),
              const SizedBox(height: 8),
              Text(app.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13)),
              Text(app.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 3),
              _RatingText(rating: app.rating),
            ],
          ),
        ),
      );
}

class _MiniAppRow extends StatelessWidget {
  const _MiniAppRow({required this.app, required this.onTap});
  final MiniApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: _AppArtwork(app: app, size: 54),
        title: Text(app.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text('${app.developer} • ${app.rating.toStringAsFixed(1)} ★',
            maxLines: 2,
            style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right_rounded),
      );
}

class _RankedAppRow extends StatelessWidget {
  const _RankedAppRow(
      {required this.rank, required this.app, required this.onTap});
  final int rank;
  final MiniApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        leading: SizedBox(
          width: 24,
          child: Center(
            child: Text('$rank',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
        title: Row(
          children: [
            _AppArtwork(app: app, size: 54),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(app.developer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 3),
                  _RatingText(rating: app.rating),
                ],
              ),
            ),
          ],
        ),
      );
}

class _AppArtwork extends StatelessWidget {
  const _AppArtwork({required this.app, this.size = 58});
  final MiniApp app;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .22),
      child: SizedBox(
        width: size,
        height: size,
        child: app.iconUrl == null || app.iconUrl!.isEmpty
            ? DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primaryContainer,
                      scheme.tertiaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(_categoryIcon(app.category),
                    color: scheme.onPrimaryContainer, size: size * .48),
              )
            : Image.network(
                app.iconUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: scheme.primaryContainer,
                  child: Icon(_categoryIcon(app.category),
                      color: scheme.onPrimaryContainer, size: size * .48),
                ),
              ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, this.icon});
  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 15),
              if (icon != null) const SizedBox(width: 3),
              Flexible(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();
  @override
  Widget build(BuildContext context) => Container(
        height: 32,
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: Theme.of(context).colorScheme.outlineVariant,
      );
}

class _RatingText extends StatelessWidget {
  const _RatingText({required this.rating});
  final double rating;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(rating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 3),
          const Icon(Icons.star_rounded, size: 13),
        ],
      );
}

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'shopping':
      return Icons.shopping_bag_rounded;
    case 'education':
      return Icons.school_rounded;
    case 'entertainment':
      return Icons.play_circle_fill_rounded;
    case 'finance':
      return Icons.account_balance_wallet_rounded;
    case 'lifestyle':
      return Icons.favorite_rounded;
    case 'productivity':
      return Icons.check_circle_rounded;
    case 'social':
      return Icons.people_rounded;
    case 'utilities':
      return Icons.build_rounded;
    default:
      return Icons.apps_rounded;
  }
}
