import whisper

model = whisper.load_model("small.en")
result = model.transcribe("podcast_episode.mp3")

print(result["text"])
