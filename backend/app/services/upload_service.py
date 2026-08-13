import os
import cloudinary
import cloudinary.uploader

CLOUDINARY_CLOUD_NAME = os.getenv("CLOUDINARY_CLOUD_NAME")
CLOUDINARY_API_KEY = os.getenv("CLOUDINARY_API_KEY")
CLOUDINARY_API_SECRET = os.getenv("CLOUDINARY_API_SECRET")

if CLOUDINARY_CLOUD_NAME and CLOUDINARY_API_KEY and CLOUDINARY_API_SECRET:
    cloudinary.config(
        cloud_name=CLOUDINARY_CLOUD_NAME,
        api_key=CLOUDINARY_API_KEY,
        api_secret=CLOUDINARY_API_SECRET
    )

def upload_to_cloudinary(file_bytes: bytes, filename: str) -> dict:
    if not (CLOUDINARY_CLOUD_NAME and CLOUDINARY_API_KEY and CLOUDINARY_API_SECRET):
        # Fallback if unconfigured
        return {"error": "Cloudinary is not configured on the server."}
        
    try:
        result = cloudinary.uploader.upload(
            file_bytes,
            resource_type="image",
            folder="nyayaai_evidence"
        )
        return {
            "url": result.get("secure_url"),
            "public_id": result.get("public_id")
        }
    except Exception as e:
        print(f"Cloudinary Upload Failed: {e}")
        return {"error": str(e)}
