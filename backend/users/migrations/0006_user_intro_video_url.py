from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0005_helper_badge'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='intro_video_url',
            field=models.URLField(blank=True),
        ),
    ]
