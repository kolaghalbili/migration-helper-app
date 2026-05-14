from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import User, Specialty, UserImage


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
            'nationality', 'country', 'city', 'languages', 'bio',
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
    specialties    = SpecialtySerializer(many=True, read_only=True)
    profile_images = UserImageSerializer(many=True, read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'last_name', 'role', 'avatar', 'bio',
            'phone', 'country', 'city', 'nationality', 'origin_country', 'languages',
            'latitude', 'longitude', 'location_tracking_enabled', 'location_updated_at',
            'specialties', 'hourly_rate', 'is_available', 'is_verified',
            'rating_avg', 'total_reviews', 'total_sessions', 'profile_images',
        ]
        read_only_fields = [
            'id', 'email', 'role', 'is_verified', 'rating_avg', 'total_reviews', 'total_sessions',
        ]


class PublicHelperSerializer(serializers.ModelSerializer):
    specialties    = SpecialtySerializer(many=True, read_only=True)
    profile_images = UserImageSerializer(many=True, read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'first_name', 'last_name', 'avatar', 'bio', 'city', 'country',
            'nationality', 'origin_country', 'languages', 'specialties', 'hourly_rate',
            'is_available', 'rating_avg', 'total_reviews', 'is_verified',
            'latitude', 'longitude', 'profile_images',
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
