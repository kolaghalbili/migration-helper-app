from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
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

    specialties    = models.ManyToManyField(Specialty, blank=True, related_name='helpers')
    hourly_rate    = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    is_available   = models.BooleanField(default=True)
    is_verified    = models.BooleanField(default=False)
    id_verified    = models.BooleanField(default=False)
    rating_avg     = models.DecimalField(max_digits=3, decimal_places=2, default=0.00)
    total_reviews  = models.IntegerField(default=0)
    total_sessions = models.IntegerField(default=0)
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
