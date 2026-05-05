from rest_framework import generics, permissions, filters
from rest_framework_simplejwt.views import TokenObtainPairView
from .models import User, Specialty
from .serializers import RegisterSerializer, UserProfileSerializer, PublicHelperSerializer, SpecialtySerializer


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]


class LoginView(TokenObtainPairView):
    permission_classes = [permissions.AllowAny]


class MeView(generics.RetrieveUpdateAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class HelperListView(generics.ListAPIView):
    serializer_class = PublicHelperSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['city', 'country', 'bio', 'specialties__name']
    ordering = ['-rating_avg']

    def get_queryset(self):
        qs = User.objects.filter(role=User.Role.HELPER, is_active=True)
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