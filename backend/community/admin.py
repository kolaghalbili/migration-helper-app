from django.contrib import admin
from .models import Post, PostLike, Meetup, Question, Answer, Circle, CircleMembership


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display  = ('id', 'author', 'post_type', 'city', 'like_count', 'created_at')
    list_filter   = ('post_type', 'city')
    search_fields = ('body', 'author__email')


@admin.register(Meetup)
class MeetupAdmin(admin.ModelAdmin):
    list_display  = ('id', 'title', 'city', 'date', 'time', 'organizer')
    list_filter   = ('city', 'date')
    search_fields = ('title', 'organizer__email')


@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
    list_display  = ('id', 'author', 'city', 'is_solved', 'created_at')
    list_filter   = ('is_solved', 'city')
    search_fields = ('body', 'author__email')


@admin.register(Answer)
class AnswerAdmin(admin.ModelAdmin):
    list_display  = ('id', 'author', 'question', 'vote_count', 'created_at')
    search_fields = ('body', 'author__email')


@admin.register(Circle)
class CircleAdmin(admin.ModelAdmin):
    list_display  = ('id', 'name', 'nationality_code', 'language_code', 'member_count')
    search_fields = ('name',)


admin.site.register(PostLike)
admin.site.register(CircleMembership)
