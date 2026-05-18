from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import User, Specialty, UserImage, Review, HelpRequest, HelperBadge


class SpecialtySerializer(serializers.ModelSerializer):
    class Meta:
        model = Specialty
        fields = ['id', 'name', 'icon', 'description']


class UserImageSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = UserImage
        fields = ['id', 'image', 'image_url', 'order', 'is_primary', 'uploaded_at']
        read_only_fields = ['id', 'uploaded_at', 'image_url']

    def get_image_url(self, obj):
        request = self.context.get('request')
        if obj.image and request:
            return request.build_absolute_uri(obj.image.url)
        return None


class RegisterSerializer(serializers.ModelSerializer):
    password  = serializers.CharField(write_only=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = [
            'email', 'password', 'password2', 'first_name', 'last_name', 'role',
            'nationality', 'country', 'city', 'languages', 'bio', 'helper_scope',
        ]

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({'password': 'Passwords do not match.'})
        return attrs

    def create(self, validated_data):
        validated_data.pop('password2')
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    specialties   = SpecialtySerializer(many=True, read_only=True)
    specialty_ids = serializers.PrimaryKeyRelatedField(
        queryset=Specialty.objects.all(),
        many=True,
        write_only=True,
        required=False,
    )
    profile_images = UserImageSerializer(many=True, read_only=True)
    badges         = HelperBadgeSerializer(many=True, read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'last_name', 'role', 'avatar', 'bio',
            'phone', 'country', 'city', 'nationality', 'origin_country', 'languages',
            'latitude', 'longitude', 'location_tracking_enabled', 'location_updated_at',
            'specialties', 'specialty_ids', 'hourly_rate', 'is_available', 'is_verified',
            'rating_avg', 'total_reviews', 'total_sessions', 'profile_images',
            'helper_scope', 'badges',
        ]
        read_only_fields = [
            'id', 'email', 'role', 'is_verified', 'rating_avg', 'total_reviews', 'total_sessions',
        ]

    def update(self, instance, validated_data):
        specialty_ids = validated_data.pop('specialty_ids', None)
        instance = super().update(instance, validated_data)
        if specialty_ids is not None:
            instance.specialties.set(specialty_ids)
        return instance


class HelperBadgeSerializer(serializers.ModelSerializer):
    label = serializers.SerializerMethodField()

    class Meta:
        model = HelperBadge
        fields = ['id', 'badge_type', 'label', 'awarded_at']

    def get_label(self, obj):
        return obj.get_badge_type_display()


class PublicHelperSerializer(serializers.ModelSerializer):
    specialties    = SpecialtySerializer(many=True, read_only=True)
    profile_images = UserImageSerializer(many=True, read_only=True)
    badges         = HelperBadgeSerializer(many=True, read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'first_name', 'last_name', 'avatar', 'bio', 'city', 'country',
            'nationality', 'origin_country', 'languages', 'specialties', 'hourly_rate',
            'is_available', 'rating_avg', 'total_reviews', 'total_sessions', 'is_verified',
            'latitude', 'longitude', 'profile_images', 'badges',
        ]


class PublicUserSerializer(serializers.ModelSerializer):
    profile_images = UserImageSerializer(many=True, read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'first_name', 'last_name', 'avatar', 'bio', 'city', 'country',
            'nationality', 'origin_country', 'languages', 'role', 'profile_images',
        ]


class LocationUpdateSerializer(serializers.Serializer):
    latitude  = serializers.DecimalField(max_digits=9, decimal_places=6, required=False, allow_null=True)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6, required=False, allow_null=True)
    city      = serializers.CharField(max_length=100, required=False, allow_blank=True)
    country   = serializers.CharField(max_length=100, required=False, allow_blank=True)
    location_tracking_enabled = serializers.BooleanField(required=False)


class ReviewSerializer(serializers.ModelSerializer):
    reviewer_name  = serializers.SerializerMethodField()
    reviewer_image = serializers.SerializerMethodField()

    class Meta:
        model = Review
        fields = ['id', 'reviewer', 'reviewer_name', 'reviewer_image',
                  'rating', 'tags', 'note', 'created_at']
        read_only_fields = ['id', 'reviewer', 'reviewer_name', 'reviewer_image', 'created_at']

    def get_reviewer_name(self, obj):
        return obj.reviewer.first_name

    def get_reviewer_image(self, obj):
        request = self.context.get('request')
        primary = obj.reviewer.profile_images.filter(is_primary=True).first()
        if primary and primary.image and request:
            return request.build_absolute_uri(primary.image.url)
        return None


class HelpRequestSerializer(serializers.ModelSerializer):
    newcomer_name = serializers.SerializerMethodField()
    helper_name   = serializers.SerializerMethodField()

    class Meta:
        model = HelpRequest
        fields = [
            'id', 'newcomer', 'newcomer_name', 'helper', 'helper_name',
            'category', 'sub_topics', 'description', 'package', 'status',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'newcomer', 'newcomer_name', 'helper_name', 'status',
            'created_at', 'updated_at',
        ]

    def get_newcomer_name(self, obj):
        return obj.newcomer.first_name

    def get_helper_name(self, obj):
        return obj.helper.first_name if obj.helper else None
