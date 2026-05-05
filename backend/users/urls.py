from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    path('auth/register/', views.RegisterView.as_view(), name='register'),
    path('auth/login/',    views.LoginView.as_view(),    name='login'),
    path('auth/refresh/',  TokenRefreshView.as_view(),   name='token_refresh'),
    path('users/me/',      views.MeView.as_view(),       name='me'),
    path('helpers/',       views.HelperListView.as_view(),   name='helper-list'),
    path('helpers/<int:pk>/', views.HelperDetailView.as_view(), name='helper-detail'),
    path('specialties/',   views.SpecialtyListView.as_view(), name='specialty-list'),
]