import math
from rest_framework import generics, permissions, filters, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import User, Specialty, UserImage, Review, HelpRequest, Notification
from .serializers import (
    RegisterSerializer, UserProfileSerializer, PublicHelperSerializer,
    SpecialtySerializer, UserImageSerializer, PublicUserSerializer,
    LocationUpdateSerializer, ReviewSerializer, HelpRequestSerializer,
    NotificationSerializer,
)


def _push_notification(recipient, notif_type, title, body='', related_request=None):
    Notification.objects.create(
        recipient=recipient,
        notif_type=notif_type,
        title=title,
        body=body,
        related_request=related_request,
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


class CheckEmailView(APIView):
    """POST /auth/check-email/  — returns {available: bool}. No auth required."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        if not email:
            return Response({'error': 'Email is required.'}, status=status.HTTP_400_BAD_REQUEST)
        taken = User.objects.filter(email__iexact=email).exists()
        return Response({'available': not taken})


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


# ── Reviews ───────────────────────────────────────────────────────────────────

class UserReviewsView(generics.ListAPIView):
    serializer_class = ReviewSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return Review.objects.filter(
            reviewee_id=self.kwargs['pk']
        ).select_related('reviewer')


class SubmitReviewView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        reviewee = get_object_or_404(User, pk=pk, is_active=True)
        if reviewee == request.user:
            return Response(
                {'error': 'You cannot review yourself.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if Review.objects.filter(reviewer=request.user, reviewee=reviewee).exists():
            return Response(
                {'error': 'You have already reviewed this user.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = ReviewSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        review = serializer.save(reviewer=request.user, reviewee=reviewee)
        return Response(
            ReviewSerializer(review, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )

    def get(self, request, pk):
        """Check whether the current user has already reviewed user pk."""
        already = Review.objects.filter(
            reviewer=request.user, reviewee_id=pk
        ).exists()
        return Response({'has_reviewed': already})


# ── Help Requests ─────────────────────────────────────────────────────────────

class HelpRequestView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role == User.Role.HELPER:
            qs = HelpRequest.objects.filter(helper=user)
        else:
            qs = HelpRequest.objects.filter(newcomer=user)
        return Response(
            HelpRequestSerializer(qs, many=True, context={'request': request}).data
        )

    def post(self, request):
        serializer = HelpRequestSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        hr = serializer.save(newcomer=request.user)

        if hr.helper:
            newcomer_name = f'{request.user.first_name} {request.user.last_name}'.strip()
            _push_notification(
                recipient=hr.helper,
                notif_type='new_request',
                title='New Help Request',
                body=f'{newcomer_name} needs help with {hr.category}',
                related_request=hr,
            )

        return Response(
            HelpRequestSerializer(hr, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )


class HelpRequestStatusView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, pk):
        hr = get_object_or_404(HelpRequest, pk=pk)
        new_status = request.data.get('status')
        valid = [c[0] for c in HelpRequest.Status.choices]

        if not new_status or new_status not in valid:
            return Response({'error': 'Invalid status.'}, status=status.HTTP_400_BAD_REQUEST)

        user = request.user
        if new_status in ('accepted', 'declined') and hr.helper != user:
            return Response(
                {'error': 'Only the assigned helper can accept or decline.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        if new_status == 'cancelled' and hr.newcomer != user:
            return Response(
                {'error': 'Only the newcomer can cancel.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        hr.status = new_status
        hr.save(update_fields=['status', 'updated_at'])

        helper_name   = f'{hr.helper.first_name} {hr.helper.last_name}'.strip() if hr.helper else 'Your helper'
        newcomer_name = f'{hr.newcomer.first_name} {hr.newcomer.last_name}'.strip()

        if new_status == 'accepted':
            _push_notification(
                recipient=hr.newcomer,
                notif_type='status_changed',
                title='Request Accepted!',
                body=f'{helper_name} accepted your {hr.category} request.',
                related_request=hr,
            )
        elif new_status == 'declined':
            _push_notification(
                recipient=hr.newcomer,
                notif_type='status_changed',
                title='Request Declined',
                body=f'{helper_name} is unable to take your {hr.category} request right now.',
                related_request=hr,
            )
        elif new_status == 'done':
            _push_notification(
                recipient=hr.newcomer,
                notif_type='status_changed',
                title='Session Complete',
                body=f'Your session with {helper_name} has been marked as done.',
                related_request=hr,
            )
        elif new_status == 'cancelled' and hr.helper:
            _push_notification(
                recipient=hr.helper,
                notif_type='status_changed',
                title='Request Cancelled',
                body=f'{newcomer_name} cancelled their {hr.category} request.',
                related_request=hr,
            )

        return Response(HelpRequestSerializer(hr, context={'request': request}).data)



class VerificationStatusView(APIView):
    """
    GET /users/me/verification-status/
    Returns completion status for the 5 helper verification steps.
    """
    permission_classes = [permissions.IsAuthenticated]
 
    def get(self, request):
        user = request.user
 
        # ── Step 1: Verify ID ────────────────────────────────────────────────
        step_id = {
            'key':       'verify_id',
            'title':     'Verify Your ID',
            'desc':      'Submit a government-issued photo ID',
            'icon':      'badge',
            'completed': user.id_verified,
            'route':     'verify_id',
        }
 
        # ── Step 2: Photo + Bio ──────────────────────────────────────────────
        has_photo = user.profile_images.filter(is_primary=True).exists()
        has_bio   = bool(user.bio and len(user.bio.strip()) >= 20)
        step_photo = {
            'key':       'photo_bio',
            'title':     'Add Photo & Bio',
            'desc':      'Upload a profile photo and write a short bio (20+ chars)',
            'icon':      'person',
            'completed': has_photo and has_bio,
            'sub': {
                'photo': has_photo,
                'bio':   has_bio,
            },
            'route': 'edit_profile',
        }
 
        # ── Step 3: Specialties ───────────────────────────────────────────────
        specialty_count = user.specialties.count()
        step_specialties = {
            'key':       'specialties',
            'title':     'Choose Your Specialties',
            'desc':      'Pick at least 1 area you can help newcomers with',
            'icon':      'star',
            'completed': specialty_count >= 1,
            'count':     specialty_count,
            'route':     'edit_profile',
        }
 
        # ── Step 4: Intro Video ───────────────────────────────────────────────
        # Stored as a URL in bio or a dedicated field — extend User model
        # if you add an intro_video field later. For now we check a placeholder.
        has_video = getattr(user, 'intro_video_url', None) not in (None, '')
        step_video = {
            'key':       'intro_video',
            'title':     'Record Intro Video',
            'desc':      'A short 30-60 second video helps newcomers trust you',
            'icon':      'videocam',
            'completed': has_video,
            'route':     'intro_video',
        }
 
        # ── Step 5: Set Your Rate ─────────────────────────────────────────────
        step_rate = {
            'key':       'set_rate',
            'title':     'Set Your Rate',
            'desc':      'Choose hourly rate or offer a free/package price',
            'icon':      'payments',
            'completed': user.hourly_rate is not None,
            'current_rate': str(user.hourly_rate) if user.hourly_rate else None,
            'route':     'set_price',
        }
 
        steps = [step_id, step_photo, step_specialties, step_video, step_rate]
        completed_count = sum(1 for s in steps if s['completed'])
 
        return Response({
            'steps':           steps,
            'completed_count': completed_count,
            'total':           len(steps),
            'is_verified':     user.is_verified,
            'ready_to_submit': completed_count == len(steps) and not user.is_verified,
        })


# ── Notifications ──────────────────────────────────────────────────────────────

class NotificationListView(generics.ListAPIView):
    serializer_class   = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(recipient=self.request.user)


class NotificationUnreadCountView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        count = Notification.objects.filter(
            recipient=request.user, is_read=False
        ).count()
        return Response({'count': count})


class NotificationMarkReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, pk):
        notif = get_object_or_404(Notification, pk=pk, recipient=request.user)
        notif.is_read = True
        notif.save(update_fields=['is_read'])
        return Response({'status': 'ok'})


class NotificationMarkAllReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        Notification.objects.filter(
            recipient=request.user, is_read=False
        ).update(is_read=True)
        return Response({'status': 'ok'})