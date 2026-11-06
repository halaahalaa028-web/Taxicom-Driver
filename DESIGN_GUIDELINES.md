# 👑 Taxicom Driver Brand Design System (نظام تصميم تاكسيكوم - السائق)

> [!IMPORTANT]
> **تعليمات إلزامية لوكيل الذكاء الاصطناعي (AI Agent Mandatory Directive):**
> يجب على أي وكيل ذكاء اصطناعي (AI Agent / Antigravity Assistant) يبدأ العمل في واجهات تطبيق السائق **Taxicom Driver App** الالتزام التام بنظام الألوان والهوية البصرية الرسمية المستخرجة والمعتمدة من الأيقونة الرسمية للتطبيق.

---

<div dir="rtl">

## 1. الفلسفة العامة للتصميم (Design Philosophy)

يعتمد تطبيق **Taxicom Driver App** على هوية بصرية فاخرة وعصرية تجمع بين **الأزرق الملكي العميق (Royal Sapphire Blue)** و**الأصفر التاكسي والذهبي المعدني (Taxi Yellow & Metallic Gold)** و**الكروم الفضي (Platinum & Chrome)**.

### المبادئ الأساسية:
1. **التناغم مع الشعار والأيقونة:** يعكس التطبيق روح الأيقونة الرسمية والفخامة التي تمثلها.
2. **التباين العالي وسهولة القراءة أثناء القيادة:** استخدام خلفيات بيضاء ورمادية فائقة النقاء (`#FFFFFF` و `#F8FAFC`) مع نصوص كحلية داكنة (`#0F172A`) لراحة العين وسرعة القراءة والتفاعل أثناء القيادة.
3. **وضوح نقاط التفاعل وقبول الطلبات:** تمييز أزرار قبول الرحلات، بدء الرحلة، إنهاء الرحلة، ومؤشرات الأرباح بالأصفر التاكسي والذهبي المشرق (`#FFC700` / `#E5B842`).
4. **دعماً كاملاً للغة العربية و RTL:** اتجاه يمين-إلى-يسار مع خط `Cairo` المتناسق.

---

## 2. لوحة الألوان الرسمية (Brand Palette)

### أ) لوحة الألوان الأساسية:

| اسم اللون | القيمة (HEX) | الاستخدام |
| :--- | :--- | :--- |
| **Royal Blue Primary** | `#0B4EA2` | الأزرار الرئيسية، الهيدر، البطاقات البارزة |
| **Royal Blue Light** | `#1A73E8` | التدرجات اللونية، إضاءة الأزرار، الحالات النشطة |
| **Deep Royal Dark** | `#062152` | عمق التدرجات، شريط الحالة، البطاقات العميقة |
| **Taxi Yellow (Accent)** | `#FFC700` | أزرار قبول الطلبات، مسار الرحلة، مؤشرات الأرباح، التقييمات |
| **Metallic Gold** | `#E5B842` | الإطارات الذهبية، شارات السائق المميز VIP، بطاقات الاشتراك |
| **Pure White** | `#FFFFFF` | خلفية البطاقات، النصوص فوق الأزرق الملكي |
| **Clean Background** | `#F8FAFC` | خلفية الشاشات الرئيسية |
| **Surface Variant** | `#F1F5F9` | حقول الإدخال، خلفيات القوائم الفرعية |
| **Charcoal Slate Text** | `#0F172A` | النصوص والعناوين الرئيسية (عالية التباين) |
| **Muted Slate Text** | `#64748B` | النصوص والتسميات الثانوية |
| **Border Gray** | `#E2E8F0` | حدود البطاقات والفواصل |

---

## 3. الخطوط وتنسيق النصوص (Typography)

- **نوع الخط الأساسي:** `Cairo`
- **اتجاه الكتابة:** RTL (من اليمين لليسار)

---

## 4. تطبيق الهوية في كود فلاتر (Flutter Code Reference)

يتم استيراد واستخدام فئة `AppColors` الموحدة في `lib/core/constants/app_colors.dart`:

```dart
// الألوان الأساسية
AppColors.primary       // 0xFF0B4EA2 (Royal Blue)
AppColors.primaryLight  // 0xFF1A73E8
AppColors.primaryDark   // 0xFF062152

// الألوان الثانوية والتمييز
AppColors.secondary     // 0xFFFFC700 (Taxi Yellow)
AppColors.goldAccent    // 0xFFE5B842 (Metallic Gold)

// الخلفيات والأسطح
AppColors.background    // 0xFFF8FAFC
AppColors.surface       // 0xFFFFFFFF
AppColors.textPrimary   // 0xFF0F172A
AppColors.textSecondary // 0xFF64748B
```

</div>
</div>
