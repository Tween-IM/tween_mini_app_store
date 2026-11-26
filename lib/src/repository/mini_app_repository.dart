import '../models/mini_app.dart';

/// Implement this interface with Firebase, REST, Supabase, or your own backend.
abstract class MiniAppRepository {
  Future<List<MiniApp>> fetchApps();
  Future<void> submitApp(MiniApp app);
}

class DemoMiniAppRepository implements MiniAppRepository {
  final List<MiniApp> _apps = [
    const MiniApp(
      id: 'canva', name: 'Canva',
      description: 'Create designs, presentations, posters and social content with Canva.',
      shortDescription: 'Design anything with Canva',
      launchUrl: 'https://www.canva.com/', canonicalUrl: 'https://www.canva.com/',
      category: 'Design & Creativity', developer: 'Canva', featured: true,
      keywords: 'graphic design templates presentations posters',
      iconUrl: 'https://www.canva.com/favicon.ico',
      coverImageUrl: 'https://images.unsplash.com/photo-1545235617-9465d2a55698?w=1200&fit=crop',
    ),
    const MiniApp(
      id: 'lucifer-donghua', name: 'Lucifer Donghua',
      description: 'Browse the Lucifer Donghua website for Chinese animation and donghua.',
      shortDescription: 'Donghua and Chinese animation',
      launchUrl: 'https://luciferdonghua.in/', canonicalUrl: 'https://luciferdonghua.in/',
      category: 'Anime & Entertainment', developer: 'Website shortcut',
      keywords: 'donghua anime Chinese animation',
      iconUrl: 'https://luciferdonghua.in/favicon.ico',
      coverImageUrl: 'https://images.unsplash.com/photo-1578632767115-351be0dcb3?w=1200&fit=crop',
    ),
    const MiniApp(
      id: 'mister-donghua', name: 'Mister Donghua',
      description: 'Open Mister Donghua to browse its donghua and animation catalogue.',
      shortDescription: 'Explore donghua online',
      launchUrl: 'https://misterdonghua.com/', canonicalUrl: 'https://misterdonghua.com/',
      category: 'Anime & Entertainment', developer: 'Website shortcut',
      keywords: 'donghua anime Chinese animation',
      iconUrl: 'https://misterdonghua.com/favicon.ico',
      coverImageUrl: 'https://images.unsplash.com/photo-1578632767115-351be0dcb3?w=1200&fit=crop',
    ),
    const MiniApp(
      id: 'anime-heaven', name: 'AnimeHeaven',
      description: 'Open AnimeHeaven to browse anime titles and episodes.',
      shortDescription: 'Anime catalogue and episodes',
      launchUrl: 'https://animeheaven.me/', canonicalUrl: 'https://animeheaven.me/',
      category: 'Anime & Entertainment', developer: 'Website shortcut',
      keywords: 'anime animation episodes',
      iconUrl: 'https://animeheaven.me/favicon.ico',
      coverImageUrl: 'https://images.unsplash.com/photo-1578632767115-351be0dcb3?w=1200&fit=crop',
    ),
    const MiniApp(id: 'shop', name: 'Tween Shop', description: 'Discover products and shop online.', launchUrl: 'https://flutter.dev', category: 'Shopping', developer: 'Tween', featured: true, iconUrl: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=320&h=320&fit=crop', coverImageUrl: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=1200&fit=crop'),
    const MiniApp(id: 'learn', name: 'Learn Hub', description: 'Learning resources in one place.', launchUrl: 'https://dart.dev', category: 'Education', developer: 'Tween Labs', featured: true, iconUrl: 'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=320&h=320&fit=crop', coverImageUrl: 'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=1200&fit=crop'),
    const MiniApp(id: 'music', name: 'Music Lounge', description: 'Explore music and entertainment.', launchUrl: 'https://www.wikipedia.org', category: 'Entertainment', developer: 'Indie Studio', iconUrl: 'https://images.unsplash.com/photo-1516280440614-37939bbacic?auto=format&fit=crop&w=320&h=320&q=80', coverImageUrl: 'https://images.unsplash.com/photo-1516280440614-37939bbacic?auto=format&fit=crop&w=1200&q=80'),
    const MiniApp(id: 'tools', name: 'Quick Tools', description: 'Useful tools for everyday tasks.', launchUrl: 'https://www.google.com', category: 'Utilities', developer: 'Developer One', iconUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=320&h=320&fit=crop', coverImageUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=1200&fit=crop'),
    const MiniApp(id: 'jobs', name: 'Job Finder', description: 'Find opportunities, browse vacancies and prepare your next application.', shortDescription: 'Explore jobs and career opportunities', launchUrl: 'https://www.indeed.com', category: 'Business', developer: 'Tween Labs', iconUrl: 'https://images.unsplash.com/photo-1521737711867-e3b97375f902?w=320&h=320&fit=crop', coverImageUrl: 'https://images.unsplash.com/photo-1521737711867-e3b97375f902?w=1200&fit=crop'),
    const MiniApp(id: 'news', name: 'Daily News', description: 'Browse headlines and stories from around the world.', shortDescription: 'News and current affairs', launchUrl: 'https://www.bbc.com/news', category: 'News', developer: 'Tween Media', iconUrl: 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=320&h=320&fit=crop', coverImageUrl: 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=1200&fit=crop'),
    const MiniApp(id: 'wellness', name: 'Wellness Guide', description: 'Explore wellness articles and everyday healthy habits.', shortDescription: 'Wellness tips and guides', launchUrl: 'https://www.nhs.uk', category: 'Health & Fitness', developer: 'Wellbeing Lab', iconUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=320&h=320&fit=crop', coverImageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=1200&fit=crop'),
  ];

  @override
  Future<List<MiniApp>> fetchApps() async => List.unmodifiable(_apps);

  @override
  Future<void> submitApp(MiniApp app) async {
    _apps.insert(0, app);
  }
}
