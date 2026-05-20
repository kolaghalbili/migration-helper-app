from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.db.models import Avg, Count
from django.utils import timezone


class Specialty(models.Model):
    name = models.CharField(max_length=100, unique=True)
    icon = models.CharField(max_length=50, blank=True)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name_plural = 'Specialties'

    def __str__(self):
        return self.name


class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Email is required')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', 'admin')
        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    class Role(models.TextChoices):
        NEWCOMER = 'newcomer', 'Newcomer'
        HELPER   = 'helper',   'Local Helper'
        ADMIN    = 'admin',    'Admin'

    email          = models.EmailField(unique=True)
    first_name     = models.CharField(max_length=100)
    last_name      = models.CharField(max_length=100)
    role           = models.CharField(max_length=20, choices=Role.choices, default=Role.NEWCOMER)
    avatar         = models.ImageField(upload_to='avatars/', blank=True, null=True)
    bio            = models.TextField(blank=True)
    phone          = models.CharField(max_length=20, blank=True)

    # Location fields
    country        = models.CharField(max_length=100, blank=True)
    city           = models.CharField(max_length=100, blank=True)
    latitude       = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude      = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    location_tracking_enabled = models.BooleanField(default=False)
    location_updated_at = models.DateTimeField(null=True, blank=True)

    # Identity fields
    nationality    = models.CharField(max_length=100, blank=True)
    origin_country = models.CharField(max_length=100, blank=True)  # kept for backwards compat
    languages      = models.JSONField(default=list)

    class HelperScope(models.TextChoices):
        ANY              = 'any',              'Open to all'
        SAME_NATIONALITY = 'same_nationality', 'Same nationality only'
        LANGUAGE_MATCH   = 'language_match',   'Language match'

    helper_scope = models.CharField(
        max_length=20,
        choices=HelperScope.choices,
        default=HelperScope.ANY,
    )

    specialties    = models.ManyToManyField(Specialty, blank=True, related_name='helpers')
    hourly_rate    = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    is_available   = models.BooleanField(default=True)
    is_verified    = models.BooleanField(default=False)
    id_verified    = models.BooleanField(default=False)
    rating_avg     = models.DecimalField(max_digits=3, decimal_places=2, default=0.00)
    total_reviews  = models.IntegerField(default=0)
    total_sessions = models.IntegerField(default=0)
    intro_video_url = models.URLField(blank=True)
    is_active      = models.BooleanField(default=True)
    is_staff       = models.BooleanField(default=False)
    date_joined    = models.DateTimeField(default=timezone.now)
    last_seen      = models.DateTimeField(null=True, blank=True)

    objects = UserManager()

    USERNAME_FIELD  = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    def __str__(self):
        return f'{self.first_name} {self.last_name} ({self.role})'

    @property
    def is_helper(self):
        return self.role == self.Role.HELPER


class UserImage(models.Model):
    user        = models.ForeignKey(User, on_delete=models.CASCADE, related_name='profile_images')
    image       = models.ImageField(upload_to='profile_images/')
    order       = models.PositiveSmallIntegerField(default=0)
    is_primary  = models.BooleanField(default=False)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['order']

    def save(self, *args, **kwargs):
        if self.is_primary:
            UserImage.objects.filter(user=self.user, is_primary=True).exclude(pk=self.pk).update(is_primary=False)
        super().save(*args, **kwargs)

    def __str__(self):
        return f'{self.user.email} - image #{self.order}'


class HelperBadge(models.Model):
    class BadgeType(models.TextChoices):
        BANKING   = 'banking',    '🏦 Banking Pro'
        HOUSING   = 'housing',    '🏠 Housing Wiz'
        SIM_CARD  = 'sim_card',   '📱 SIM Card Expert'
        LEGAL     = 'legal',      '📄 Legal Guide'
        LANGUAGE  = 'language',   '💬 Language Coach'
        JOB       = 'job_search', '💼 Job Search Pro'
        COMMUNITY = 'community',  '🌍 Community Builder'

    helper     = models.ForeignKey(User, on_delete=models.CASCADE, related_name='badges')
    badge_type = models.CharField(max_length=30, choices=BadgeType.choices)
    awarded_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True, related_name='badges_awarded'
    )
    awarded_at = models.DateTimeField(auto_now_add=True)
    note       = models.TextField(blank=True)

    class Meta:
        unique_together = ('helper', 'badge_type')
        ordering = ['badge_type']

    def __str__(self):
        return f'{self.helper} — {self.get_badge_type_display()}'


class Notification(models.Model):
    class Type(models.TextChoices):
        NEW_REQUEST    = 'new_request',    'New Help Request'
        STATUS_CHANGED = 'status_changed', 'Request Status Changed'
        NEW_MESSAGE    = 'new_message',    'New Message'

    recipient       = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    notif_type      = models.CharField(max_length=30, choices=Type.choices)
    title           = models.CharField(max_length=200)
    body            = models.CharField(max_length=500, blank=True)
    is_read         = models.BooleanField(default=False)
    related_request = models.ForeignKey(
        'HelpRequest', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='notifications'
    )
    created_at      = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'[{self.notif_type}] → {self.recipient}: {self.title}'


class Review(models.Model):
    reviewer   = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviews_given')
    reviewee   = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviews_received')
    rating     = models.PositiveSmallIntegerField()
    tags       = models.JSONField(default=list)
    note       = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('reviewer', 'reviewee')
        ordering = ['-created_at']

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        agg = Review.objects.filter(reviewee=self.reviewee).aggregate(
            avg=Avg('rating'), cnt=Count('id')
        )
        self.reviewee.rating_avg  = round(agg['avg'] or 0, 2)
        self.reviewee.total_reviews = agg['cnt'] or 0
        self.reviewee.save(update_fields=['rating_avg', 'total_reviews'])

    def __str__(self):
        return f'{self.reviewer} → {self.reviewee}: {self.rating}★'


class HelpRequest(models.Model):
    class Status(models.TextChoices):
        PENDING   = 'pending',   'Pending'
        ACCEPTED  = 'accepted',  'Accepted'
        DECLINED  = 'declined',  'Declined'
        DONE      = 'done',      'Done'
        CANCELLED = 'cancelled', 'Cancelled'

    class Package(models.TextChoices):
        STARTER    = 'starter',    '2hr Starter'
        HALF_DAY   = 'half_day',   'Half Day'
        FIRST_WEEK = 'first_week', 'First Week'
        CUSTOM     = 'custom',     'Custom'

    newcomer    = models.ForeignKey(User, on_delete=models.CASCADE, related_name='help_requests')
    helper      = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True, related_name='received_requests'
    )
    category    = models.CharField(max_length=100)
    sub_topics  = models.JSONField(default=list)
    description = models.TextField(blank=True)
    package     = models.CharField(max_length=20, choices=Package.choices, blank=True)
    status      = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'Request #{self.id} by {self.newcomer} [{self.status}]'
