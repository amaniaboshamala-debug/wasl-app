# وَصْل | WASL

تطبيق Flutter بيربط المؤسسات والفرق المجتمعية بأهل غزة والمتطوعين.

## التشغيل لأول مرة

```bash
cd D:\flutter_projects\wasl_app

# 1) إنشاء ملفات أندرويد و iOS (ما بيمسح ملفات lib)
flutter create . --org com.amani --project-name wasl --platforms android,ios

# 2) تنزيل الحزم
flutter pub add flutter_bloc equatable go_router get_it supabase_flutter hive_flutter connectivity_plus cached_network_image flutter_image_compress google_fonts intl

# 3) المفاتيح: انسخي env.example.json لـ env.json وحطي مفاتيح Supabase
# 4) قاعدة البيانات: الصقي supabase/schema.sql في Supabase → SQL Editor

# 5) التشغيل
flutter run --dart-define-from-file=env.json
```

## الهيكلية (Feature-Based Clean Architecture)

```
lib/
├── main.dart                 نقطة البداية
├── app.dart                  MaterialApp + RTL + Theme
├── core/                     أشياء مشتركة بين كل الـ features
│   ├── config/               المفاتيح (env)
│   ├── di/                   get_it: تسجيل الكلاسات
│   ├── errors/               Failure: رسائل خطأ مفهومة
│   ├── network/              حالة الإنترنت
│   ├── router/               go_router + المسارات
│   ├── storage/              Hive: الكاش والمفضلة
│   ├── theme/                الألوان والخطوط (من نظام التصميم)
│   ├── utils/                Result
│   └── widgets/              ويدجتس مشتركة (شريط التنقل، شريط عدم الاتصال)
└── features/
    ├── auth/                 ✅ مكتمل كمثال
    │   ├── data/             datasources · models · repositories(impl)
    │   ├── domain/           entities · repositories(abstract)
    │   └── presentation/     cubit · screens
    ├── home/                 الرئيسية
    ├── explore/              استكشف (تبويبات)
    ├── initiatives/          المبادرات
    ├── services/             الخدمات
    ├── needs/                الاحتياجات
    ├── opportunities/        فرص التطوع
    ├── applications/         طلبات التطوع (طلباتي)
    ├── organization/         لوحة المؤسسة
    ├── profile/              حسابي
    ├── notifications/        الإشعارات
    └── favorites/            المفضلة
```

### كيف تبني أي feature جديدة؟ (انسخي نفس طريقة auth)
1. **domain/entities**: الكلاس الأساسي (موجود لـ initiatives, services, needs, opportunities, applications)
2. **domain/repositories**: abstract class فيه شو بتعمل
3. **data/datasources**: الكلام مع Supabase
4. **data/models**: تحويل JSON ← Entity
5. **data/repositories**: الـ impl، وفيه الكاش بـ LocalCache لما ما في نت
6. **presentation/cubit**: الحالة (loading / loaded / error)
7. **presentation/screens**: الشاشة
8. سجّلي الكلاسات في `core/di/injection.dart`

## ترتيب البناء المقترح
1. ✅ الدخول واختيار الدور
2. الرئيسية + استكشف (مبادرات · خدمات · احتياجات) + التفاصيل
3. الفرص + التقديم + طلباتي
4. لوحة المؤسسة: نشر · قبول/رفض
5. الإشعارات (FCM) + المفضلة + العمل بدون نت
