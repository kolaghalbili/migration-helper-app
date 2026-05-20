import anthropic
import os

# کلاینت رو می‌سازیم. بهتره کلید رو تو متغیر محیطی ANTHROPIC_API_KEY بذاری
client = anthropic.Anthropic(
    api_key="", # یا os.environ.get("ANTHROPIC_API_KEY")
)

message = client.messages.create(
    model="claude-3-5-sonnet-20240620",
    max_tokens=1000,
    messages=[
        {"role": "user", "content": "سلام! تو کی هستی؟"}
    ]
)

print(message.content[0].text)