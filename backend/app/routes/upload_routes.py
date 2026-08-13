from fastapi import APIRouter, UploadFile, File, HTTPException
from app.services.upload_service import upload_to_cloudinary

router = APIRouter(prefix="/upload", tags=["upload"])

@router.post("/image")
async def upload_image(file: UploadFile = File(...)):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File provided is not an image.")
    
    # 5MB limit
    content = await file.read()
    if len(content) > 5 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Image size exceeds 5MB limit.")
        
    result = upload_to_cloudinary(content, file.filename)
    
    if "error" in result:
        # According to constraints, do NOT crash, but return a clear error so the app can proceed with image=null.
        # Wait, the prompt says: "Return a clear error from /api/upload/image (e.g. "Image upload is temporarily unavailable. You can still submit your grievance without an image.") and let the app proceed with image=null."
        # The frontend API client expects a successful JSON or throws an exception. Let's return 400 or 503 so frontend catches it? Or return 200 with error? Let's check `api_client.dart`:
        # `if (response.statusCode >= 200 && response.statusCode < 300)`
        # If I return 503, the frontend throws `ApiException(statusCode, message)`.
        raise HTTPException(status_code=503, detail="Image upload is temporarily unavailable. You can still submit your grievance without an image.")
        
    return result

