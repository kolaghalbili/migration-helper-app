from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, Specialty

@admin.register(Specialty)
class SpecialtyAdmin(admin.ModelAdmin):
    list_display = ['name', 'icon', 'is_active']
    search_fields = ['name']

@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['email', 'first_name', 'last_name', 'role', 'city', 'is_verified', 'date_joined']
    list_filter = ['role', 'is_verified', 'is_active']
    search_fields = ['email', 'first_name', 'last_name']
    ordering = ['-date_joined']
    filter_horizontal = ['specialties', 'groups', 'user_permissions']
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Personal Info', {'fields': ('first_name', 'last_name', 'avatar', 'bio', 'phone')}),
        ('Role & Location', {'fields': ('role', 'country', 'city', 'origin_country', 'languages')}),
        ('Helper Settings', {'fields': ('specialties', 'hourly_rate', 'is_available')}),
        ('Verification', {'fields': ('is_verified', 'id_verified')}),
        ('Stats', {'fields': ('rating_avg', 'total_reviews', 'total_sessions')}),)