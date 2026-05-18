from rest_framework import serializers
from .models import Post, PostLike, Meetup, Question, Answer, Circle, CircleMembership


class PostSerializer(serializers.ModelSerializer):
    author_name  = serializers.SerializerMethodField()
    author_image = serializers.SerializerMethodField()
    is_liked     = serializers.SerializerMethodField()

    class Meta:
        model  = Post
        fields = [
            'id', 'author', 'author_name', 'author_image',
            'post_type', 'body', 'tags', 'city',
            'like_count', 'is_liked', 'created_at',
        ]
        read_only_fields = ['id', 'author', 'author_name', 'author_image',
                            'like_count', 'is_liked', 'created_at']

    def get_author_name(self, obj):
        return obj.author.first_name

    def get_author_image(self, obj):
        request = self.context.get('request')
        primary = obj.author.profile_images.filter(is_primary=True).first()
        if primary and primary.image and request:
            return request.build_absolute_uri(primary.image.url)
        return None

    def get_is_liked(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return PostLike.objects.filter(post=obj, user=request.user).exists()


class MeetupSerializer(serializers.ModelSerializer):
    organizer_name = serializers.SerializerMethodField()
    attendee_count = serializers.SerializerMethodField()
    is_attending   = serializers.SerializerMethodField()

    class Meta:
        model  = Meetup
        fields = [
            'id', 'title', 'city', 'location', 'date', 'time',
            'organizer', 'organizer_name', 'attendee_count', 'is_attending', 'created_at',
        ]
        read_only_fields = ['id', 'organizer', 'organizer_name',
                            'attendee_count', 'is_attending', 'created_at']

    def get_organizer_name(self, obj):
        return obj.organizer.first_name

    def get_attendee_count(self, obj):
        return obj.attendee_count

    def get_is_attending(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return obj.attendees.filter(pk=request.user.pk).exists()


class AnswerSerializer(serializers.ModelSerializer):
    author_name  = serializers.SerializerMethodField()
    author_image = serializers.SerializerMethodField()

    class Meta:
        model  = Answer
        fields = ['id', 'question', 'author', 'author_name', 'author_image',
                  'body', 'vote_count', 'created_at']
        read_only_fields = ['id', 'question', 'author', 'author_name', 'author_image',
                            'vote_count', 'created_at']

    def get_author_name(self, obj):
        return obj.author.first_name

    def get_author_image(self, obj):
        request = self.context.get('request')
        primary = obj.author.profile_images.filter(is_primary=True).first()
        if primary and primary.image and request:
            return request.build_absolute_uri(primary.image.url)
        return None


class QuestionSerializer(serializers.ModelSerializer):
    author_name  = serializers.SerializerMethodField()
    answer_count = serializers.SerializerMethodField()
    answers      = AnswerSerializer(many=True, read_only=True)

    class Meta:
        model  = Question
        fields = [
            'id', 'author', 'author_name', 'body', 'city', 'tags',
            'is_solved', 'answer_count', 'answers', 'created_at',
        ]
        read_only_fields = ['id', 'author', 'author_name', 'is_solved',
                            'answer_count', 'created_at']

    def get_author_name(self, obj):
        return obj.author.first_name

    def get_answer_count(self, obj):
        return obj.answer_count


class CircleSerializer(serializers.ModelSerializer):
    is_subscribed = serializers.SerializerMethodField()

    class Meta:
        model  = Circle
        fields = ['id', 'name', 'description', 'nationality_code',
                  'language_code', 'member_count', 'is_subscribed', 'created_at']
        read_only_fields = ['id', 'member_count', 'is_subscribed', 'created_at']

    def get_is_subscribed(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return CircleMembership.objects.filter(
            user=request.user, circle=obj, subscribed=True
        ).exists()
