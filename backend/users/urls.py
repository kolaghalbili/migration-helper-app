from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    # Auth
    path('auth/register/', views.RegisterView.as_view(),  name='register'),
    path('auth/login/',    views.LoginView.as_view(),     name='login'),
    path('auth/refresh/',  TokenRefreshView.as_view(),    name='token_refresh'),

    # Current user
    path('users/me/',          views.MeView.as_view(),             name='me'),
    path('users/me/location/', views.LocationUpdateView.as_view(), name='location-update'),

    # Profile images
    path('users/me/images/',                      views.UserImageView.as_view(),           name='user-images'),
    path('users/me/images/<int:pk>/',             views.UserImageDeleteView.as_view(),     name='user-image-delete'),
    path('users/me/images/<int:pk>/set-primary/', views.UserImageSetPrimaryView.as_view(), name='image-set-primary'),

    # Discovery
    path('users/nearby/', views.NearbyUsersView.as_view(), name='nearby-users'),

    # Public profile (any user)
    path('users/<int:pk>/',         views.PublicUserDetailView.as_view(), name='user-detail'),
    path('users/<int:pk>/reviews/', views.UserReviewsView.as_view(),     name='user-reviews'),
    path('users/<int:pk>/review/',  views.SubmitReviewView.as_view(),    name='submit-review'),

    # Helpers
    path('helpers/',          views.HelperListView.as_view(),   name='helper-list'),
    path('helpers/<int:pk>/', views.HelperDetailView.as_view(), name='helper-detail'),

    # Specialties
    path('specialties/', views.SpecialtyListView.as_view(), name='specialty-list'),

    # Help requests
    path('requests/',                  views.HelpRequestView.as_view(),       name='help-requests'),
    path('requests/<int:pk>/status/',  views.HelpRequestStatusView.as_view(), name='request-status'),
]
