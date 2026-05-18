from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import Post, PostLike, Meetup, Question, Answer, Circle, CircleMembership
from .serializers import (
    PostSerializer, MeetupSerializer,
    QuestionSerializer, AnswerSerializer, CircleSerializer,
)


# ── Posts ─────────────────────────────────────────────────────────────────────

class PostListCreateView(generics.ListCreateAPIView):
    serializer_class   = PostSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        qs    = Post.objects.select_related('author').prefetch_related('author__profile_images')
        city  = self.request.query_params.get('city')
        ptype = self.request.query_params.get('type')
        if city:
            qs = qs.filter(city__icontains=city)
        if ptype:
            qs = qs.filter(post_type=ptype)
        return qs

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)


class PostLikeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        post = get_object_or_404(Post, pk=pk)
        like, created = PostLike.objects.get_or_create(post=post, user=request.user)
        if created:
            Post.objects.filter(pk=pk).update(like_count=post.like_count + 1)
            post.refresh_from_db(fields=['like_count'])
            return Response({'liked': True, 'like_count': post.like_count})
        else:
            like.delete()
            Post.objects.filter(pk=pk).update(like_count=max(post.like_count - 1, 0))
            post.refresh_from_db(fields=['like_count'])
            return Response({'liked': False, 'like_count': post.like_count})


# ── Meetups ───────────────────────────────────────────────────────────────────

class MeetupListCreateView(generics.ListCreateAPIView):
    serializer_class   = MeetupSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        qs   = Meetup.objects.select_related('organizer').prefetch_related('attendees')
        city = self.request.query_params.get('city')
        if city:
            qs = qs.filter(city__icontains=city)
        return qs

    def perform_create(self, serializer):
        serializer.save(organizer=self.request.user)


class MeetupRSVPView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        meetup = get_object_or_404(Meetup, pk=pk)
        if meetup.attendees.filter(pk=request.user.pk).exists():
            meetup.attendees.remove(request.user)
            return Response({'attending': False, 'count': meetup.attendee_count})
        meetup.attendees.add(request.user)
        return Response({'attending': True, 'count': meetup.attendee_count})


# ── Questions & Answers ───────────────────────────────────────────────────────

class QuestionListCreateView(generics.ListCreateAPIView):
    serializer_class   = QuestionSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        qs   = Question.objects.select_related('author').prefetch_related('answers__author')
        city = self.request.query_params.get('city')
        tab  = self.request.query_params.get('tab')
        if city:
            qs = qs.filter(city__icontains=city)
        if tab == 'unanswered':
            qs = qs.filter(answers__isnull=True)
        elif tab == 'mine' and self.request.user.is_authenticated:
            qs = qs.filter(author=self.request.user)
        elif tab == 'hot':
            qs = qs.order_by('-answers__count', '-created_at')
        return qs

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)


class QuestionMarkSolvedView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, pk):
        question = get_object_or_404(Question, pk=pk, author=request.user)
        question.is_solved = True
        question.save(update_fields=['is_solved'])
        return Response({'is_solved': True})


class AnswerListCreateView(generics.ListCreateAPIView):
    serializer_class   = AnswerSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        return Answer.objects.filter(
            question_id=self.kwargs['question_pk']
        ).select_related('author').prefetch_related('author__profile_images')

    def perform_create(self, serializer):
        question = get_object_or_404(Question, pk=self.kwargs['question_pk'])
        serializer.save(author=self.request.user, question=question)


class AnswerVoteView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        answer = get_object_or_404(Answer, pk=pk)
        Answer.objects.filter(pk=pk).update(vote_count=answer.vote_count + 1)
        answer.refresh_from_db(fields=['vote_count'])
        return Response({'vote_count': answer.vote_count})


# ── Circles ───────────────────────────────────────────────────────────────────

class CircleListView(generics.ListAPIView):
    serializer_class   = CircleSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    queryset           = Circle.objects.all()


class CircleSubscribeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, pk):
        circle = get_object_or_404(Circle, pk=pk)
        membership, created = CircleMembership.objects.get_or_create(
            user=request.user, circle=circle,
            defaults={'subscribed': True},
        )
        if not created:
            membership.subscribed = not membership.subscribed
            membership.save(update_fields=['subscribed'])
        return Response({
            'subscribed':   membership.subscribed,
            'member_count': Circle.objects.get(pk=pk).member_count,
        })


class MyCirclesFeedView(generics.ListAPIView):
    serializer_class   = PostSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        subscribed_codes = CircleMembership.objects.filter(
            user=self.request.user, subscribed=True
        ).values_list('circle__nationality_code', 'circle__language_code')

        nat_codes  = [c[0] for c in subscribed_codes if c[0]]
        lang_codes = [c[1] for c in subscribed_codes if c[1]]

        from django.db.models import Q

        # Filter by nationality (string field) or language overlap (JSONField list).
        # For the language overlap we use __contains per element since PostgreSQL
        # JSONField overlap (__overlap) requires an ArrayField, not JSONField.
        lang_q = Q()
        for lang in lang_codes:
            lang_q |= Q(author__languages__contains=[lang])

        nat_q = Q(author__nationality__in=nat_codes) if nat_codes else Q()
        combined = nat_q | lang_q if (nat_codes or lang_codes) else Q(pk__in=[])

        qs = Post.objects.filter(combined).select_related(
            'author'
        ).prefetch_related('author__profile_images').distinct()

        city = self.request.query_params.get('city')
        if city:
            qs = qs.filter(city__icontains=city)
        return qs
