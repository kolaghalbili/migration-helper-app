from django.db import models
from django.conf import settings


class Transaction(models.Model):
    class Type(models.TextChoices):
        BOOKING = 'booking', 'Booking Payment'
        TIP     = 'tip',     'Tip'
        POOL    = 'pool',    'Community Pool Donation'

    class Status(models.TextChoices):
        HELD     = 'held',     'Held in Escrow'
        RELEASED = 'released', 'Released to Helper'
        PAID     = 'paid',     'Paid Out'
        FAILED   = 'failed',   'Failed'
        REFUNDED = 'refunded', 'Refunded'

    payer           = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='transactions_paid'
    )
    payee           = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='transactions_received'
    )
    amount          = models.DecimalField(max_digits=10, decimal_places=2)
    platform_fee    = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    net_amount      = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    type            = models.CharField(max_length=20, choices=Type.choices)
    status          = models.CharField(max_length=20, choices=Status.choices, default=Status.HELD)
    help_request    = models.ForeignKey(
        'users.HelpRequest', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='transactions'
    )
    stripe_payment_intent_id = models.CharField(max_length=200, blank=True)
    note            = models.TextField(blank=True)
    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def save(self, *args, **kwargs):
        # platform fee = 15%, helper gets 85%
        self.platform_fee = round(self.amount * 0.15, 2)
        self.net_amount   = round(self.amount - self.platform_fee, 2)
        super().save(*args, **kwargs)

    def __str__(self):
        return f'#{self.id} {self.type} ${self.amount} [{self.status}]'


class HelpRequestEarnings(models.Model):
    """Aggregated earnings per helper per month — updated on release."""
    helper      = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='earnings'
    )
    year        = models.PositiveSmallIntegerField()
    month       = models.PositiveSmallIntegerField()   # 1-12
    total_gross = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total_fees  = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total_net   = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total_tips  = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    session_count = models.PositiveIntegerField(default=0)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('helper', 'year', 'month')
        ordering = ['-year', '-month']

    def __str__(self):
        return f'{self.helper} — {self.year}/{self.month:02d} net=${self.total_net}'


class CommunityPool(models.Model):
    """Single-row table — the global community fund balance."""
    balance     = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_donated = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Community Pool'

    def __str__(self):
        return f'Pool balance: ${self.balance}'