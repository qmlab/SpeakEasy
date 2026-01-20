import os
import cloudinary
import cloudinary.uploader
import cloudinary.api
from typing import Optional


class CloudinaryService:
    _instance = None
    _configured = False
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def configure(self, cloud_name: str, api_key: str, api_secret: str):
        cloudinary.config(
            cloud_name=cloud_name,
            api_key=api_key,
            api_secret=api_secret,
            secure=True
        )
        self._configured = True
    
    def configure_from_env(self):
        creds = os.environ.get('CLOUDINARY_CREDENTIALS', '')
        cloud_name = os.environ.get('CLOUDINARY_CLOUD_NAME', '')
        
        if ':' in creds:
            api_key, api_secret = creds.split(':', 1)
        else:
            api_key = os.environ.get('CLOUDINARY_API_KEY', '')
            api_secret = os.environ.get('CLOUDINARY_API_SECRET', creds)
        
        if cloud_name and api_key and api_secret:
            self.configure(cloud_name, api_key, api_secret)
            return True
        return False
    
    @property
    def is_configured(self) -> bool:
        return self._configured
    
    def upload_image(
        self,
        file_data: bytes,
        folder: str = "speakeasy",
        public_id: Optional[str] = None,
        resource_type: str = "image",
        transformation: Optional[dict] = None
    ) -> dict:
        if not self._configured:
            raise RuntimeError("Cloudinary is not configured")
        
        upload_options = {
            "folder": folder,
            "resource_type": resource_type,
        }
        
        if public_id:
            upload_options["public_id"] = public_id
        
        if transformation:
            upload_options["transformation"] = transformation
        
        result = cloudinary.uploader.upload(file_data, **upload_options)
        
        return {
            "public_id": result.get("public_id"),
            "url": result.get("secure_url"),
            "width": result.get("width"),
            "height": result.get("height"),
            "format": result.get("format"),
            "bytes": result.get("bytes"),
        }
    
    def delete_image(self, public_id: str) -> bool:
        if not self._configured:
            raise RuntimeError("Cloudinary is not configured")
        
        result = cloudinary.uploader.destroy(public_id)
        return result.get("result") == "ok"
    
    def get_optimized_url(
        self,
        public_id: str,
        width: Optional[int] = None,
        height: Optional[int] = None,
        crop: str = "fill",
        quality: str = "auto",
        fetch_format: str = "auto"
    ) -> str:
        if not self._configured:
            raise RuntimeError("Cloudinary is not configured")
        
        transformations = {
            "quality": quality,
            "fetch_format": fetch_format,
        }
        
        if width:
            transformations["width"] = width
        if height:
            transformations["height"] = height
        if width or height:
            transformations["crop"] = crop
        
        url, _ = cloudinary.utils.cloudinary_url(
            public_id,
            **transformations
        )
        return url


cloudinary_service = CloudinaryService()
