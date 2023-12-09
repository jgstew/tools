from transformers import TrOCRProcessor, VisionEncoderDecoderModel
import requests
from PIL import Image

# "microsoft/trocr-base-handwritten", "microsoft/trocr-base-printed"
model_id = "microsoft/trocr-base-printed"

processor = TrOCRProcessor.from_pretrained(model_id)
model = VisionEncoderDecoderModel.from_pretrained(model_id)

image = Image.open("text.jpg").convert("RGB")

pixel_values = processor(image, return_tensors="pt").pixel_values
generated_ids = model.generate(pixel_values)

generated_text = processor.batch_decode(generated_ids, skip_special_tokens=True)

print(generated_text)
