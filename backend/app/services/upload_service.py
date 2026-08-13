"""Image upload service using Cloudinary."""
import os
import cloudinary
import cloudinary.uploader


def _configure_cloudinary() -> bool:
    """Configure Cloudinary from environment variables. Returns False if not configured."""
    cloud_name = os.getenv("CLOUDINARY_CLOUD_NAME", "").strip()
    api_key = os.getenv("CLOUDINARY_API_KEY", "").strip()
    api_secret = os.getenv("CLOUDINARY_API_SECRET", "").strip()

    if not all([cloud_name, api_key, api_secret]):
        return False

    cloudinary.config(
        cloud_name=cloud_name,
        api_key=api_key,
        api_secret=api_secret,
        secure=True,
    )
    return True


def upload_image(file_bytes: bytes, filename: str) -> dict:
    """
    Upload image bytes to Cloudinary.
    Returns {"url": "...", "public_id": "..."} on success.
    Raises RuntimeError if Cloudinary is not configured or upload fails.
    """
    if not _configure_cloudinary():
        raise RuntimeError("Image upload is temporarily unavailable. Cloudinary credentials are not configured.")

    try:
        result = cloudinary.uploader.upload(
            file_bytes,
            folder="nyayaai/grievances",
            public_id=filename.rsplit(".", 1)[0] if "." in filename else filename,
            resource_type="image",
        )
        return {
            "url": result["secure_url"],
            "public_id": result["public_id"],
        }
    except Exception as e:
        raise RuntimeError(f"Image upload failed: {str(e)}")
