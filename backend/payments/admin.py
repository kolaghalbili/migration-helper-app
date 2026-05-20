from django.contrib import admin
from .models import Transaction, HelpRequestEarnings, CommunityPool


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display  = ['id', 'type', 'status', 'payer', 'payee', 'amount', 'net_amount', 'created_at']
    list_filter   = ['type', 'status']
    search_fields = ['payer__email', 'payee__email', 'stripe_payment_intent_id']
    readonly_fields = ['platform_fee', 'net_amount', 'created_at', 'updated_at']


@admin.register(HelpRequestEarnings)
class EarningsAdmin(admin.ModelAdmin):
    list_display = ['helper', 'year', 'month', 'total_net', 'total_tips', 'session_count']
    list_filter  = ['year', 'month']


@admin.register(CommunityPool)
class CommunityPoolAdmin(admin.ModelAdmin):
    list_display = ['balance', 'total_donated', 'updated_at']
