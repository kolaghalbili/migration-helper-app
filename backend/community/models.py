from django.conf import settings
from django.db import models


class Post(models.Model):
    class PostType(models.TextChoices):
        NEED  = 'need',  'Need Help'
        OFFER = 'offer', 'Offering Help'
        STORY = 'story', 'Story'

    author     = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='community_posts'
    )
    post_type  = models.CharField(max_length=10, choices=PostType.choices, default=PostType.NEED)
    body       = models.TextField()
    tags       = models.JSONField(default=list)
    city       = models.CharField(max_length=100, blank=True)
    like_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'[{self.post_type}] {self.author} — {self.body[:40]}'


class PostLike(models.Model):
    post     = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='likes')
    user     = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    liked_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('post', 'user')


class Meetup(models.Model):
    title     = models.CharField(max_length=200)
    city      = models.CharField(max_length=100)
    location  = models.CharField(max_length=300, blank=True)
    date      = models.DateField()
    time      = models.TimeField()
    organizer = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='organized_meetups'
    )
    attendees  = models.ManyToManyField(
        settings.AUTH_USER_MODEL, blank=True, related_name='attending_meetups'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['date', 'time']

    def __str__(self):
        return f'{self.title} — {self.city} {self.date}'

    @property
    def attendee_count(self):
        return self.attendees.count()


class Question(models.Model):
    author     = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='questions'
    )
    body       = models.TextField()
    city       = models.CharField(max_length=100, blank=True)
    tags       = models.JSONField(default=list)
    is_solved  = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'Q by {self.author}: {self.body[:60]}'

    @property
    def answer_count(self):
        return self.answers.count()


class Answer(models.Model):
    question   = models.ForeignKey(Question, on_delete=models.CASCADE, related_name='answers')
    author     = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='answers'
    )
    body       = models.TextField()
    vote_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-vote_count', 'created_at']

    def __str__(self):
        return f'Answer by {self.author} to Q#{self.question_id}'


class Circle(models.Model):
    name             = models.CharField(max_length=100, unique=True)
    description      = models.TextField(blank=True)
    nationality_code = models.CharField(max_length=5, blank=True)
    language_code    = models.CharField(max_length=10, blank=True)
    member_count     = models.PositiveIntegerField(default=0)
    created_at       = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-member_count']

    def __str__(self):
        return self.name


class CircleMembership(models.Model):
    user       = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='circle_memberships'
    )
    circle     = models.ForeignKey(Circle, on_delete=models.CASCADE, related_name='memberships')
    subscribed = models.BooleanField(default=True)
    joined_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'circle')

    def save(self, *args, **kwargs):
        try:
            old = CircleMembership.objects.get(pk=self.pk)
            was_subscribed = old.subscribed
        except CircleMembership.DoesNotExist:
            was_subscribed = None

        super().save(*args, **kwargs)

        if was_subscribed is None and self.subscribed:
            Circle.objects.filter(pk=self.circle_id).update(
                member_count=models.F('member_count') + 1
            )
        elif was_subscribed is True and not self.subscribed:
            Circle.objects.filter(pk=self.circle_id).update(
                member_count=models.F('member_count') - 1
            )
        elif was_subscribed is False and self.subscribed:
            Circle.objects.filter(pk=self.circle_id).update(
                member_count=models.F('member_count') + 1
            )

    def delete(self, *args, **kwargs):
        if self.subscribed:
            Circle.objects.filter(pk=self.circle_id).update(
                member_count=models.F('member_count') - 1
            )
        super().delete(*args, **kwargs)
