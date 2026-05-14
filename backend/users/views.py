import math
from rest_framework import generics, permissions, filters, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from django.utils import timezone
from .models import User, Specialty, UserImage
from .serializers import (
    RegisterSerializer, UserProfileSerializer, PublicHelperSerializer,
    SpecialtySerializer, UserImageSerializer, PublicUserSerializer,
    LocationUpdateSerializer,
)


def _haversine_km(lat1, lon1, lat2, lon2):
    R = 6371.0
    lat1, lon1, lat2, lon2 = map(math.radians, [float(lat1), float(lon1), float(lat2), float(lon2)])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    return R * 2 * math.asin(math.sqrt(a))


# ── Auth ──────────────────────────────────────────────────────────────────────

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]


class LoginView(TokenObtainPairView):
    permission_classes = [permissions.AllowAny]


# ── Current user ──────────────────────────────────────────────────────────────

class MeView(generics.RetrieveUpdateAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


# ── Profile images ────────────────────────────────────────────────────────────

class UserImageView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        images = request.user.profile_images.all()
        serializer = UserImageSerializer(images, many=True, context={'request': request})
        return Response(serializer.data)

    def post(self, request):
        if request.user.profile_images.count() >= 3:
            return Response(
                {'error': 'Maximum 3 profile images allowed.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        image_file = request.FILES.get('image')
        if not image_file:
            return Response({'error': 'No image provided.'}, status=status.HTTP_400_BAD_REQUEST)

        is_primary = request.user.profile_images.count() == 0
        order = request.user.profile_images.count()

        img = UserImage.objects.create(
            user=request.user,
            image=image_file,
            order=order,
            is_primary=is_primary,
        )
        return Response(
            UserImageSerializer(img, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )


class UserImageDeleteView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, pk):
        try:
            img = UserImage.objects.get(pk=pk, user=request.user)
        except UserImage.DoesNotExist:
            return Response({'error': 'Image not found.'}, status=status.HTTP_404_NOT_FOUND)

        was_primary = img.is_primary
        img.image.delete(save=False)
        img.delete()

        remaining = list(request.user.profile_images.order_by('order'))
        if was_primary and remaining:
            remaining[0].is_primary = True
            remaining[0].save(update_fields=['is_primary'])
        for i, image in enumerate(remaining):
            image.order = i
            image.save(update_fields=['order'])

        return Response(status=status.HTTP_204_NO_CONTENT)


class UserImageSetPrimaryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, pk):
        try:
            img = UserImage.objects.get(pk=pk, user=request.user)
        except UserImage.DoesNotExist:
            return Response({'error': 'Image not found.'}, status=status.HTTP_404_NOT_FOUND)

        request.user.profile_images.update(is_primary=False)
        img.is_primary = True
        img.save(update_fields=['is_primary'])
        return Response({'status': 'primary image updated'})


# ── Location ──────────────────────────────────────────────────────────────────

class LocationUpdateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request):
        serializer = LocationUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        user = request.user
        for field in ('latitude', 'longitude', 'city', 'country', 'location_tracking_enabled'):
            if field in data:
                setattr(user, field, data[field])

        if data.get('latitude') is not None:
            user.location_updated_at = timezone.now()

        user.save()
        return Response(UserProfileSerializer(user, context={'request': request}).data)


class NearbyUsersView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        try:
            lat    = float(request.query_params.get('lat', 0))
            lng    = float(request.query_params.get('lng', 0))
            radius = float(request.query_params.get('radius', 50))
        except (TypeError, ValueError):
            return Response({'error': 'Invalid coordinates.'}, status=status.HTTP_400_BAD_REQUEST)

        role_filter = request.query_params.get('role')
        qs = User.objects.filter(
            is_active=True,
            latitude__isnull=False,
            longitude__isnull=False,
        ).exclude(id=request.user.id)

        if role_filter:
            qs = qs.filter(role=role_filter)

        nearby = sorted(
            [(_haversine_km(lat, lng, u.latitude, u.longitude), u) for u in qs],
            key=lambda x: x[0],
        )
        users = [u for dist, u in nearby if dist <= radius]

        serializer = PublicHelperSerializer(users, many=True, context={'request': request})
        return Response(serializer.data)


# ── Public profiles ───────────────────────────────────────────────────────────

class PublicUserDetailView(generics.RetrieveAPIView):
    serializer_class = PublicUserSerializer
    permission_classes = [permissions.AllowAny]
    queryset = User.objects.filter(is_active=True)


class HelperListView(generics.ListAPIView):
    serializer_class = PublicHelperSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['city', 'country', 'bio', 'specialties__name']
    ordering = ['-rating_avg']

    def get_queryset(self):
        qs = User.objects.filter(role=User.Role.HELPER, is_active=True)
        if self.request.user.is_authenticated:
            qs = qs.exclude(id=self.request.user.id)
        city = self.request.query_params.get('city')
        if city:
            qs = qs.filter(city__icontains=city)
        return qs


class HelperDetailView(generics.RetrieveAPIView):
    serializer_class = PublicHelperSerializer
    permission_classes = [permissions.AllowAny]
    queryset = User.objects.filter(role=User.Role.HELPER, is_active=True)


class SpecialtyListView(generics.ListAPIView):
    serializer_class = SpecialtySerializer
    permission_classes = [permissions.AllowAny]
    queryset = Specialty.objects.filter(is_active=True)
