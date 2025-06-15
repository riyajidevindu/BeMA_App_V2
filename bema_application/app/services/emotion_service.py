import io
from ultralytics import YOLO
from PIL import Image
import os
import uuid

# class EmotionService:
#     def __init__(self, person_model_path, emotion_model_path, output_folder):
#         self.person_model = YOLO(person_model_path)
#         self.emotion_model = YOLO(emotion_model_path)
#         self.output_folder = output_folder
#         os.makedirs(output_folder, exist_ok=True)

#     def detect_emotion(self, image: Image.Image):
#         # Generate a unique image name
#         image_name = f"image_{uuid.uuid4()}.jpg"
        
#         # Detect person using YOLOv8n
#         person_results = self.person_model(image)
        
#         if person_results and len(person_results) > 0 and len(person_results[0].boxes) > 0:
#             # Get the bounding box of the first detected person
#             box = person_results[0].boxes[0].xyxy[0].cpu().numpy()
            
#             # Crop the image to the person's bounding box
#             cropped_image = image.crop((box[0], box[1], box[2], box[3]))
            
#             # Save the cropped person image
#             person_image_path = os.path.join(self.output_folder, f"{image_name}_person.png")
#             cropped_image.save(person_image_path)
            
#             # Predict emotion on the cropped image
#             emotion_results = self.emotion_model(cropped_image)
#             print(emotion_results)
            
#             if emotion_results and len(emotion_results) > 0 and len(emotion_results[0].boxes) > 0:
#                 emotion = emotion_results[0].boxes.cls[0].item()
#                 emotion_labels = ['Anger', 'Contempt', 'Disgust', 'Fear', 'Happy', 'Neutral', 'Sad', 'Surprise']
#                 emotion_label = emotion_labels[int(emotion)]
                
#                 # Save the annotated emotion image
#                 emotion_image_path = os.path.join(self.output_folder, f"{image_name}_emotion.png")
#                 emotion_results[0].save(emotion_image_path)
                
#                 return emotion_label
#             else:
#                 return "No emotion detected"
#         else:
#             return "No person detected"
        
class EmotionService:
    def __init__(self, person_model_path, emotion_model_path, output_folder):
        self.person_model = YOLO(person_model_path)
        self.emotion_model = YOLO(emotion_model_path)
        self.output_folder = output_folder
        os.makedirs(output_folder, exist_ok=True)
        self.allowed_extensions = {"jpg", "jpeg", "png"}

    def detect_emotion(self, file_content: bytes, file_extension: str):
        if file_extension.lower() not in self.allowed_extensions:
            return "Invalid file type. Allowed types are jpg, jpeg, and png."

        try:
            image = Image.open(io.BytesIO(file_content))
        except Exception:
            return "Invalid image file."

        # Generate a unique image name
        image_name = f"image_{uuid.uuid4()}.{file_extension}"
        
        # Detect person using YOLOv8n
        person_results = self.person_model(image)
        
        if person_results and len(person_results) > 0 and len(person_results[0].boxes) > 0:
            # Get the bounding box of the first detected person
            box = person_results[0].boxes[0].xyxy[0].cpu().numpy()
            
            # Crop the image to the person's bounding box
            cropped_image = image.crop((box[0], box[1], box[2], box[3]))
            
            # Save the cropped person image
            person_image_path = os.path.join(self.output_folder, f"{image_name}_person.png")
            cropped_image.save(person_image_path)
            
            # Predict emotion on the cropped image
            emotion_results = self.emotion_model(cropped_image)
            
            if emotion_results and len(emotion_results) > 0 and len(emotion_results[0].boxes) > 0:
                emotion = emotion_results[0].boxes.cls[0].item()
                emotion_labels = ['Anger', 'Contempt', 'Disgust', 'Fear', 'Happy', 'Neutral', 'Sad', 'Surprise']
                emotion_label = emotion_labels[int(emotion)]
                
                # Save the annotated emotion image
                emotion_image_path = os.path.join(self.output_folder, f"{image_name}_emotion.png")
                emotion_results[0].save(emotion_image_path)
                
                return emotion_label
            else:
                return "No emotion detected"
        else:
            return "No person detected"