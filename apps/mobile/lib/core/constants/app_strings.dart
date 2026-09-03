/// Centralized UI String Constants for Kurogane Mobile App.
/// Guarantees Zero Hardcoding, consistent English terminology, and clean localization readiness.
abstract class AppStrings {
  // --- COMMON ACTIONS & LABELS ---
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String remove = 'Remove';
  static const String retry = 'Retry';
  static const String refresh = 'Refresh';
  static const String error = 'Error';
  static const String errorPrefix = 'Error';
  static const String loading = 'Loading...';
  static const String close = 'Close';
  static const String apply = 'Apply';
  static const String reset = 'Reset';
  static const String seeAll = 'See all';
  static const String showLess = 'Show less';
  static const String viewMore = 'View more';
  static const String done = 'Done';
  static const String ok = 'OK';
  static const String search = 'Search';
  static const String back = 'Back';
  static const String all = 'All';
  static const String none = 'None';
  static const String na = 'N/A';

  // --- RELATIVE TIME & DATES ---
  static const String justNow = 'Just now';
  static const String yesterday = 'Yesterday';
  static const String recent = 'Recent';
  static const List<String> shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static String minutesAgo(int minutes) => '${minutes}m ago';
  static String hoursAgo(int hours) => '${hours}h ago';
  static String daysAgo(int days) => '${days}d ago';

  // --- BOTTOM NAVIGATION & QUICK SEARCH ---
  static const String navHome = 'Home';
  static const String navExplore = 'Explore';
  static const String navWatchlist = 'Watchlist';
  static const String navProfile = 'Profile';

  static const String quickSearchPlaceholder = 'Search title or acronym (e.g. aot, jjk)...';
  static const String quickSearchEmptyTitle = 'Instant Anime Search';
  static const String quickSearchEmptySubtitle = 'Type a title, genre, or acronym for instant results.';
  static const String quickSearchNoResults = 'No results for';
  static const String quickSearchTryAgain = 'Check spelling or try searching for another keyword.';
  static const String doubleBackToExit = 'Press back again to exit';

  // --- HOME SCREEN ---
  static const String homeNewEpisodes = 'New Episodes';
  static const String homeTrendingSeason = 'Trending This Season';
  static const String homeAllTimeMasterpieces = 'All-Time Masterpieces';
  static const String homeRecentNews = 'Recent News & Articles';
  static const String homeRecommendedForYou = 'Recommended For You';
  static const String homeUpcomingSeason = 'Coming Soon';
  static const String homeUnableToLoad = 'Unable to load data';
  static const String homeCheckConnection = 'Check your connection to Kurogane server.';

  // --- SEASONS ---
  static const String seasonWinter = 'Winter';
  static const String seasonSpring = 'Spring';
  static const String seasonSummer = 'Summer';
  static const String seasonFall = 'Fall';
  static String seasonTitle(String season, int year) => '$season $year Season';
  static String trendingSeasonTitle(String season, int year) => 'Trending • $season $year';

  // --- EXPLORE SCREEN & FILTERS ---
  static const String exploreTitle = 'Explore';
  static const String exploreSearchHint = 'Search anime, characters, genres...';
  static const String exploreFilters = 'Filters';
  static const String exploreActiveFilters = 'Active Filters';
  static const String exploreResetFilters = 'Reset Filters';
  static const String exploreNoResultsTitle = 'No matching anime found';
  static const String exploreNoResultsSubtitle = 'Try adjusting your filters or search for something else.';
  static const String exploreLoadError = 'Error loading catalog';

  // Sort By options
  static const String sortScore = 'Score';
  static const String sortPopularity = 'Popularity';
  static const String sortYear = 'Year';
  static const String sortTitleAz = 'Title (A-Z)';
  static const String sortRelevance = 'Relevance';
  static const String viewGrid = 'Grid';
  static const String viewList = 'List';

  // Filter Sheet
  static const String filterMediaType = 'Media Type';
  static const String filterFormat = 'Format';
  static const String filterSortBy = 'Sort By';
  static const String filterGenres = 'Genres';
  static const String filterTagsThemes = 'Tags / Themes';
  static const String filterApply = 'Apply Filters';
  static String filterSeeAllTags(int count) => '+ See all tags ($count more)';
  static const String filterShowFewerTags = 'Show fewer tags';

  // --- WATCHLIST & SERIES STATUS ---
  static const String statusAll = 'All';
  static const String statusWatching = 'Watching';
  static const String statusPlanToWatch = 'Plan to Watch';
  static const String statusCompleted = 'Completed';
  static const String statusOnHold = 'On Hold';
  static const String statusDropped = 'Dropped';
  static const String watchStatus = 'Watch Status';

  static const String watchlistTitle = 'Watchlist';
  static const String watchlistLoadError = 'Error loading watchlist';
  static String watchlistEmptyTab(String tabLabel) => 'No anime in $tabLabel';
  static const String watchlistEmptySubtitle = 'Explore the catalog and add titles to track your progress!';
  static const String watchlistExploreCatalog = 'Explore Catalog';

  // Watchlist Modal & Card Actions
  static const String editSeries = 'Edit Series';
  static const String addToWatchlist = 'Add to Watchlist';
  static const String episodeProgress = 'Episode Progress';
  static const String yourScore = 'Your Score';
  static const String noScore = 'No score';
  static const String startDate = 'Start Date';
  static const String endDate = 'End Date';
  static const String notSet = 'Not set';
  static const String personalNotes = 'Personal Notes';
  static const String notesPlaceholder = 'Add private thoughts, pacing notes...';
  static const String saveToList = 'Save to List';
  static const String removeFromWatchlist = 'Remove from Watchlist';
  static const String confirmRemoveTitle = 'Remove from Watchlist?';
  static const String confirmRemoveMessage = 'Are you sure you want to remove this series from your list? Your progress will be erased.';
  static const String savedToWatchlistToast = 'Saved to Watchlist';
  static const String removedFromWatchlistToast = 'Removed from Watchlist';
  static const String syncWithAnilist = 'Sync with AniList';

  // Activity semantic badges
  static const String activityWatchedEpisode = 'Watched episode';
  static const String activityCompletedSeries = 'Completed series';
  static const String activityDroppedSeries = 'Dropped series';
  static const String activityPausedSeries = 'Paused series';
  static const String activityPlanToWatch = 'Plan to watch';

  // Episode label helpers
  static String episodeN(int n) => 'Episode $n';
  static String episodeProgressDisplay(int current, int? total) =>
      total != null && total > 0 ? '$current / $total eps' : '$current eps';

  // --- GUEST & AUTHENTICATION PROMPTS ---
  static const String authRequiredTitle = 'Sign In Required';
  static const String authRequiredSubtitle = 'Sign in to save your anime, customize watchlists, and sync progress across all your devices.';
  static const String errorLoadingWatchlist = 'Error loading watchlist';
  static const String watchlistAuthRequired = 'Sign In Required';
  static const String watchlistAuthSubtitle = 'Sign in to save your anime and keep your progress up to date.';
  static const String watchlistFeatureSync = 'Multi-Device Sync';
  static const String watchlistFeatureProgress = 'Episode & Progress Tracking';
  static const String watchlistFeatureCategories = 'Category Organization';
  static const String watchlistSignIn = 'Sign In to Account';
  static const String watchlistCreateAccount = 'Create a New Account';
  static const String profileFeatureWatchlist = 'Live Synced Watchlist';
  static const String profileFeatureStats = 'Stats & Episodes Watched';
  static const String profileFeatureNotifications = 'New Episode Notifications';
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String logOut = 'Log Out';
  static const String createAccount = 'Create an account';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String featureMultiDevice = 'Multi-Device Sync';
  static const String featureAlerts = 'New Episode Alerts';
  static const String featureTasteProfile = 'Taste Profile & Analytics';
  static const String logOutConfirmTitle = 'Log Out?';
  static const String logOutConfirmMessage = 'Are you sure you want to log out of your Kurogane account?';

  // Auth form fields
  static const String email = 'Email';
  static const String emailOrUsername = 'Email Address or Username';
  static const String emailOrUsernameHint = 'username or email@example.com';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot password?';
  static const String continueWithGoogle = 'Continue with Google';
  static const String fillAllFields = 'Please fill in all fields.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String passwordTooShort = 'Password must be at least 6 characters.';
  static const String passwordsDoNotMatch = 'Passwords do not match.';
  static const String signInSuccess = 'Sign in successful! Welcome back.';
  static const String googleSignInSuccess = 'Google sign-in successful! Welcome back.';
  static const String welcomeBackSubtitle = 'Welcome back to Kurogane.';
  static const String createAccountSubtitle = 'Join the Kurogane anime community.';
  static const String registerSuccess = 'Account created successfully! Welcome to Kurogane.';

  // --- USER PROFILE ---
  static const String profileTitle = 'Profile';
  static const String recentActivity = 'Recent Activity';
  static const String connectedAccounts = 'Connected Accounts';
  static const String kuroganeMember = 'Kurogane Member';
  static String titlesCount(int count) => count == 1 ? '1 title' : '$count titles';
  static const String emptyProfileWatchlistTitle = 'No anime in your list yet';
  static const String emptyProfileWatchlistSubtitle = 'Add anime to your Watchlist from Explore or Home to track your progress here.';
  static const String editProfile = 'Edit Profile';
  static const String profileStatsWatching = 'Watching';
  static const String profileStatsEpisodes = 'Episodes';
  static const String profileStatsAvgScore = 'Mean Score';
  static const String profileAddBio = 'Add a bio…';
  static const String settings = 'Settings';
  static const String username = 'Username';
  static const String bio = 'Bio';
  static const String bioPlaceholder = 'Tell the community about your anime taste...';
  static const String pronouns = 'Pronouns';
  static const String saveChanges = 'Save Changes';
  static const String changesSaved = 'Profile updated successfully.';
  static const List<String> fullMonths = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  // --- MEDIA DETAIL SCREEN ---
  static const String synopsis = 'Synopsis';
  static const String readMore = 'Read more';
  static const String readLess = 'Read less';
  static const String characters = 'Characters';
  static const String staff = 'Staff & Production';
  static const String relations = 'Relations & Franchise';
  static const String watchOrder = 'Watch Order';
  static const String themeSongs = 'Theme Songs';
  static const String communityAndScores = 'Community & Scores';
  static const String similarAnime = 'Similar Recommendations';
  static const String statusReleasing = 'Releasing';
  static const String statusFinished = 'Finished';
  static const String statusNotYetAired = 'Not Yet Aired';
  static const String statusCancelled = 'Cancelled';
  static const String share = 'Share';

  // --- SETTINGS SCREEN ---
  static const String settingsDisplayContent = 'DISPLAY & CONTENT';
  static const String settingsDarkTheme = 'Dark Theme (OLED Dark)';
  static const String settingsLightTheme = 'Light Theme (Light Mode)';
  static const String settingsAnimeTitles = 'Anime Titles';
  static const String settingsIntegrations = 'INTEGRATIONS & ACCOUNTS';
  static const String settingsSystemPreferences = 'SYSTEM PREFERENCES';
  static const String settingsAbout = 'ABOUT APP';
  static const String settingsVersion = 'Version';
  static const String settingsHapticFeedback = 'Haptic Feedback';
}
