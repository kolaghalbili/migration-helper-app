from django.urls import path
from . import views

urlpatterns = [
    path('payments/checkout/',            views.checkout,       name='payments-checkout'),
    path('payments/release/<int:request_id>/', views.release,   name='payments-release'),
    path('payments/tip/',                 views.add_tip,        name='payments-tip'),
    path('payments/pool/contribute/',     views.pool_contribute, name='payments-pool-contribute'),
    path('payments/earnings/',            views.earnings,       name='payments-earnings'),
    path('payments/pool/',                views.pool_info,      name='payments-pool'),
]