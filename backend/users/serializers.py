from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import User, Specialty


class SpecialtySerializer(serializers.ModelSerializer):
    class Meta:
        model = Specialty
        fields = ['id', 'name', 'icon', 'description']


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['email', 'password', 'password2', 'first_name', 'last_name', 'role', 'country', 'city', 'origin_country', 'languages']

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
    specialties = SpecialtySerializer(many=True, read_only=True)

    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'role', 'avatar', 'bio', 'phone', 'country', 'city', 'origin_country', 'languages', 'specialties', 'hourly_rate', 'is_available', 'is_verified', 'rating_avg', 'total_reviews', 'total_sessions']
        read_only_fields = ['id', 'email', 'role', 'is_verified', 'rating_avg', 'total_reviews', 'total_sessions']


class PublicHelperSerializer(serializers.ModelSerializer):
    specialties = SpecialtySerializer(many=True, read_only=True)

    class Meta:
        model = User
        fields = ['id', 'first_name', 'last_name', 'avatar', 'bio', 'city', 'country', 'origin_country', 'languages', 'specialties', 'hourly_rate', 'is_available', 'rating_avg', 'total_reviews', 'is_verified']