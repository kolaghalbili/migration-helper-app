from django.test import TestCase
from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth import get_user_model
from .models import Post, Meetup, Question, Answer, Circle, CircleMembership

User = get_user_model()


class PostModelTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='a@test.com', password='pass', first_name='Ali', last_name='T', role='newcomer'
        )

    def test_post_str(self):
        p = Post.objects.create(author=self.user, body='I need help', city='Berlin')
        self.assertIn('need', str(p))

    def test_like_count_default_zero(self):
        p = Post.objects.create(author=self.user, body='test', city='Berlin')
        self.assertEqual(p.like_count, 0)


class PostAPITests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='u@test.com', password='pass', first_name='U', last_name='T', role='newcomer'
        )
        self.client.force_authenticate(user=self.user)

    def test_create_post(self):
        r = self.client.post('/api/community/posts/', {
            'post_type': 'need', 'body': 'Need banking help', 'city': 'Berlin', 'tags': []
        }, format='json')
        self.assertEqual(r.status_code, status.HTTP_201_CREATED)
        self.assertEqual(r.data['author'], self.user.id)

    def test_list_posts(self):
        Post.objects.create(author=self.user, body='test', city='Berlin')
        r = self.client.get('/api/community/posts/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(r.data), 1)

    def test_list_posts_filtered_by_city(self):
        Post.objects.create(author=self.user, body='Berlin post', city='Berlin')
        Post.objects.create(author=self.user, body='Toronto post', city='Toronto')
        r = self.client.get('/api/community/posts/?city=Berlin')
        self.assertEqual(len(r.data), 1)

    def test_like_toggle(self):
        p = Post.objects.create(author=self.user, body='test', city='Berlin')
        r1 = self.client.post(f'/api/community/posts/{p.pk}/like/')
        self.assertTrue(r1.data['liked'])
        self.assertEqual(r1.data['like_count'], 1)
        r2 = self.client.post(f'/api/community/posts/{p.pk}/like/')
        self.assertFalse(r2.data['liked'])
        self.assertEqual(r2.data['like_count'], 0)

    def test_unauthenticated_cannot_create_post(self):
        self.client.force_authenticate(user=None)
        r = self.client.post('/api/community/posts/', {'body': 'test'})
        self.assertEqual(r.status_code, status.HTTP_401_UNAUTHORIZED)


class MeetupAPITests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='m@test.com', password='pass', first_name='M', last_name='T', role='newcomer'
        )
        self.client.force_authenticate(user=self.user)

    def test_create_meetup(self):
        r = self.client.post('/api/community/meetups/', {
            'title': 'Coffee Chat', 'city': 'Berlin',
            'location': 'Café Noir', 'date': '2026-12-01', 'time': '10:00:00',
        }, format='json')
        self.assertEqual(r.status_code, status.HTTP_201_CREATED)
        self.assertEqual(r.data['organizer'], self.user.id)

    def test_rsvp_toggle(self):
        m = Meetup.objects.create(
            title='Test', city='Berlin', location='X',
            date='2026-12-01', time='10:00', organizer=self.user
        )
        r1 = self.client.post(f'/api/community/meetups/{m.pk}/rsvp/')
        self.assertTrue(r1.data['attending'])
        self.assertEqual(r1.data['count'], 1)
        r2 = self.client.post(f'/api/community/meetups/{m.pk}/rsvp/')
        self.assertFalse(r2.data['attending'])
        self.assertEqual(r2.data['count'], 0)


class QuestionAnswerAPITests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='q@test.com', password='pass', first_name='Q', last_name='T', role='newcomer'
        )
        self.other = User.objects.create_user(
            email='o@test.com', password='pass', first_name='O', last_name='T', role='helper'
        )
        self.client.force_authenticate(user=self.user)

    def test_create_question(self):
        r = self.client.post('/api/community/questions/', {
            'body': 'How long does SCHUFA take?', 'city': 'Berlin', 'tags': ['banking']
        }, format='json')
        self.assertEqual(r.status_code, status.HTTP_201_CREATED)

    def test_list_unanswered(self):
        q1 = Question.objects.create(author=self.user, body='Q1', city='Berlin')
        q2 = Question.objects.create(author=self.user, body='Q2', city='Berlin')
        Answer.objects.create(author=self.other, question=q1, body='ans')
        r = self.client.get('/api/community/questions/?tab=unanswered')
        ids = [item['id'] for item in r.data]
        self.assertIn(q2.id, ids)
        self.assertNotIn(q1.id, ids)

    def test_post_answer(self):
        q = Question.objects.create(author=self.user, body='test?', city='Berlin')
        self.client.force_authenticate(user=self.other)
        r = self.client.post(f'/api/community/questions/{q.pk}/answers/', {
            'body': 'Here is the answer.'
        }, format='json')
        self.assertEqual(r.status_code, status.HTTP_201_CREATED)

    def test_only_author_can_mark_solved(self):
        q = Question.objects.create(author=self.user, body='test?', city='Berlin')
        self.client.force_authenticate(user=self.other)
        r = self.client.patch(f'/api/community/questions/{q.pk}/solve/')
        self.assertEqual(r.status_code, status.HTTP_404_NOT_FOUND)

    def test_vote_answer(self):
        q   = Question.objects.create(author=self.user, body='test?', city='Berlin')
        ans = Answer.objects.create(author=self.other, question=q, body='ans')
        r   = self.client.post(f'/api/community/answers/{ans.pk}/vote/')
        self.assertEqual(r.data['vote_count'], 1)


class CircleAPITests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='c@test.com', password='pass', first_name='C', last_name='T', role='newcomer'
        )
        self.client.force_authenticate(user=self.user)

    def test_list_circles(self):
        Circle.objects.create(name='Iranians in Berlin', nationality_code='IR')
        r = self.client.get('/api/community/circles/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(r.data), 1)

    def test_subscribe_toggle_updates_member_count(self):
        circle = Circle.objects.create(name='Test Circle', nationality_code='IR')
        self.assertEqual(circle.member_count, 0)
        r1 = self.client.patch(f'/api/community/circles/{circle.pk}/subscribe/')
        self.assertTrue(r1.data['subscribed'])
        self.assertEqual(r1.data['member_count'], 1)
        r2 = self.client.patch(f'/api/community/circles/{circle.pk}/subscribe/')
        self.assertFalse(r2.data['subscribed'])
        self.assertEqual(r2.data['member_count'], 0)
