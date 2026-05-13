from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth.forms import UserCreationForm, UserChangeForm
from .models import User

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