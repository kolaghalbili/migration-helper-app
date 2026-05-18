from django.urls import path
from . import views

urlpatterns = [
    # Posts
    path('community/posts/',                views.PostListCreateView.as_view(),    name='post-list'),
    path('community/posts/<int:pk>/like/',  views.PostLikeView.as_view(),          name='post-like'),

    # Meetups
    path('community/meetups/',               views.MeetupListCreateView.as_view(), name='meetup-list'),
    path('community/meetups/<int:pk>/rsvp/', views.MeetupRSVPView.as_view(),       name='meetup-rsvp'),

    # Questions
    path('community/questions/',                            views.QuestionListCreateView.as_view(), name='question-list'),
    path('community/questions/<int:pk>/solve/',             views.QuestionMarkSolvedView.as_view(), name='question-solve'),
    path('community/questions/<int:question_pk>/answers/', views.AnswerListCreateView.as_view(),   name='answer-list'),
    path('community/answers/<int:pk>/vote/',                views.AnswerVoteView.as_view(),         name='answer-vote'),

    # Circles
    path('community/circles/',                    views.CircleListView.as_view(),      name='circle-list'),
    path('community/circles/<int:pk>/subscribe/', views.CircleSubscribeView.as_view(), name='circle-subscribe'),

    # Blended feed for subscribed circles
    path('community/feed/', views.MyCirclesFeedView.as_view(), name='circle-feed'),
]
