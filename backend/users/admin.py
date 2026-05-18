from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth.forms import UserCreationForm, UserChangeForm
from .models import User, Specialty, HelperBadge, Review, HelpRequest

# ۱. ساخت فرم اختصاصی برای اضافه کردن کاربر با ایمیل
class CustomUserCreationForm(UserCreationForm):
    class Meta:
        model = User
        fields = ('email',)

# ۲. ساخت فرم اختصاصی برای ویرایش کاربر
class CustomUserChangeForm(UserChangeForm):
    class Meta:
        model = User
        fields = ('email',)

# ۳. معرفی فرم‌های جدید به پنل ادمین
class CustomUserAdmin(UserAdmin):
    add_form = CustomUserCreationForm
    form = CustomUserChangeForm
    model = User
    
    list_display = ('email', 'is_staff', 'is_active')
    ordering = ('email',)
    
    # تنظیمات صفحه ویرایش
    fieldsets = (
        (None, {'fields': ('first_name','email', 'password', 'role')}),
        ('Permissions', {'fields': ('is_staff', 'is_active', 'is_superuser')}),
    )
    
    # تنظیمات صفحه اضافه کردن (اینجا فیلدهای تکرار رمز رو بهش دادیم)
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'password1', 'password2'), 
        }),
    )

admin.site.register(User, CustomUserAdmin)


@admin.register(HelperBadge)
class HelperBadgeAdmin(admin.ModelAdmin):
    list_display  = ['helper', 'badge_type', 'awarded_by', 'awarded_at']
    list_filter   = ['badge_type']
    search_fields = ['helper__email', 'helper__first_name', 'helper__last_name']
    raw_id_fields = ['helper', 'awarded_by']


@admin.register(Specialty)
class SpecialtyAdmin(admin.ModelAdmin):
    list_display = ['name', 'icon', 'is_active']


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ['reviewer', 'reviewee', 'rating', 'created_at']
    list_filter  = ['rating']


@admin.register(HelpRequest)
class HelpRequestAdmin(admin.ModelAdmin):
    list_display = ['id', 'newcomer', 'helper', 'category', 'status', 'created_at']
    list_filter  = ['status', 'category']