from rest_framework import serializers
from .models import Transaction, HelpRequestEarnings, CommunityPool


class TransactionSerializer(serializers.ModelSerializer):
    payer_name = serializers.SerializerMethodField()
    payee_name = serializers.SerializerMethodField()

    class Meta:
        model  = Transaction
        fields = [
            'id', 'payer', 'payer_name', 'payee', 'payee_name',
            'amount', 'platform_fee', 'net_amount',
            'type', 'status', 'help_request',
            'stripe_payment_intent_id', 'note',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['platform_fee', 'net_amount', 'status', 'created_at', 'updated_at']

    def get_payer_name(self, obj):
        return f'{obj.payer.first_name} {obj.payer.last_name}'

    def get_payee_name(self, obj):
        if obj.payee:
            return f'{obj.payee.first_name} {obj.payee.last_name}'
        return None


class CheckoutSerializer(serializers.Serializer):
    help_request_id = serializers.IntegerField()
    amount          = serializers.DecimalField(max_digits=10, decimal_places=2)
    note            = serializers.CharField(required=False, allow_blank=True)


class TipSerializer(serializers.Serializer):
    help_request_id = serializers.IntegerField()
    amount          = serializers.DecimalField(max_digits=10, decimal_places=2)


class PoolContributeSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    note   = serializers.CharField(required=False, allow_blank=True)


class EarningsSerializer(serializers.ModelSerializer):
    class Meta:
        model  = HelpRequestEarnings
        fields = '__all__'


class CommunityPoolSerializer(serializers.ModelSerializer):
    class Meta:
        model  = CommunityPool
        fields = '__all__'