/// حالات وأنواع طلبات الرحلات
///
/// يحتوي على الـ Enums الأساسية لحالة الرحلة ونوعها
library;

/// حالات طلب الرحلة
enum TripStatus {
  pending,          // في انتظار سائق
  accepted,         // تم قبول الطلب
  arrivedAtPickup,  // السائق وصل لموقع الاستلام
  pickedUp,         // الراكب ركب في السيارة
  cancelled,        // تم إلغاء الطلب (من الراكب)
  cancelledByDriver,// تم إلغاء الطلب من قبل السائق
  completed,        // تم إكمال الرحلة
}

/// نوع الرحلة
enum TripType {
  ride,     // تكسي (حجز تكسي عادي)
  delivery, // توصيل طلب
}
