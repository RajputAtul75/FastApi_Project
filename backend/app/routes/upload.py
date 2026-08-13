"""Upload and AI analysis routes."""
from fastapi import APIRouter, HTTPException, UploadFile, File
from app.schemas.models import AnalyzeRequest, AnalyzeResponse, AIClassification
from app.services.ai_service import analyze_grievance
from app.services.upload_service import upload_image

router = APIRouter(prefix="/api", tags=["upload", "ai"])

ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_SIZE_BYTES = 5 * 1024 * 1024  # 5 MB


@router.post("/upload/image")
async def upload_image_endpoint(file: UploadFile = File(...)):
    """Upload an image to Cloudinary."""
    # Validate MIME type
    if file.content_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type: {file.content_type}. Allowed: JPG, PNG, WEBP."
        )

    # Read and validate size
    contents = await file.read()
    if len(contents) > MAX_SIZE_BYTES:
        raise HTTPException(
            status_code=400,
            detail=f"File too large ({len(contents) / 1024 / 1024:.1f} MB). Maximum is 5 MB."
        )

    try:
        result = upload_image(contents, file.filename or "grievance_image")
        return result
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))


@router.post("/ai/analyze", response_model=AnalyzeResponse)
def analyze_text(payload: AnalyzeRequest):
    """Standalone AI analysis endpoint."""
    result, status = analyze_grievance(payload.text)
    return AnalyzeResponse(
        classification=AIClassification(**result),
        ai_status=status,
    )
