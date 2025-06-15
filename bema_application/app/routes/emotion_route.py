import io
from fastapi import APIRouter, HTTPException, UploadFile, File
from PIL import Image
from app.services.emotion_service import EmotionService

router = APIRouter()

emotion_service = EmotionService("app/resources/yolo11n.pt", "app/resources/best.pt", "app/resources/images")

ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png"}
MAX_FILE_SIZE = 2 * 1024 * 1024 

@router.post("/detect_emotion/")
async def detect_emotion(file: UploadFile = File(...)):
    # Check file extension
    file_extension = file.filename.split(".")[-1].lower()
    if file_extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(status_code=400, detail="Invalid file type. Allowed types are jpg, jpeg, and png.")

    # Check file size
    contents = await file.read()
    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(status_code=400, detail="File size exceeds the maximum limit of 2 MB.")

    try:
        result = emotion_service.detect_emotion(contents, file_extension)
        return {"result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error processing the image.")