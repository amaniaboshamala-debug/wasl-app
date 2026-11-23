/// كل مسارات التطبيق بمكان واحد.
class Routes {
  // الدخول
  static const welcome = '/welcome';
  static const login = '/login';
  static const signUp = '/sign-up';
  static const role = '/role';
  static const checkEmail = '/check-email';
  static const forgotPassword = '/forgot-password';
  static const newPassword = '/new-password';

  // المستخدم والمتطوع
  static const home = '/home';
  static const explore = '/explore';
  static const opportunities = '/opportunities';
  static const myRequests = '/my-requests';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const favorites = '/favorites';
  static const editProfile = '/edit-profile';

  /// استكشف على تبويب معيّن: 0 مبادرات · 1 خدمات · 2 احتياجات
  static String exploreTab(int tab) => '$explore?tab=$tab';

  // التفاصيل
  static const initiativeDetailsPattern = '/initiative/:id';
  static const serviceDetailsPattern = '/service/:id';
  static String initiativeDetails(String id) => '/initiative/$id';
  static String serviceDetails(String id) => '/service/$id';
  static const opportunityDetailsPattern = '/opportunity/:id';
  static const applyPattern = '/opportunity/:id/apply';
  static String opportunityDetails(String id) => '/opportunity/$id';
  static String applyTo(String id) => '/opportunity/$id/apply';

  // المؤسسة
  static const orgHome = '/org';
  static const orgOpportunities = '/org/opportunities';
  static const orgRequests = '/org/requests';
  static const orgProfile = '/org/profile';
  static const orgNewOpportunity = '/org/new-opportunity';
  static const orgEdit = '/org/edit';
  static const orgInitiatives = '/org/initiatives';
  static const orgNewInitiative = '/org/new-initiative';
  static const orgNewService = '/org/new-service';
  static const orgInitiativePattern = '/org/initiative/:id';
  static String orgInitiative(String id) => '/org/initiative/$id';

  static const orgScan = '/org/scan';

  // سجل التطوع والشهادات
  static const myRecord = '/my-record';

  // ركن التوعية
  static const awareness = '/awareness';

  // الإدارة
  static const admin = '/admin';

  /// صفحات التفاصيل (مبادرة · خدمة · فرصة) مسموحة لكل الأدوار
  static bool isDetails(String location) =>
      location.startsWith('/initiative/') || location.startsWith('/service/') || location.startsWith('/opportunity/');

  static bool isOrgArea(String location) => location == orgHome || location.startsWith('$orgHome/');
}
