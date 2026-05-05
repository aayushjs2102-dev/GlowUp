"""
GlowUp – FastAPI application entry-point.

Provides JWT-based /register and /login endpoints backed by a SQLite
database via SQLAlchemy, plus an AI-powered /analyze-selfie endpoint.

Run with:
    uvicorn main:app --reload
"""

import base64
import json
import os
import time
from datetime import datetime, timedelta, timezone
from typing import Generator
from urllib.parse import quote_plus
import urllib.request
import urllib.parse
import bcrypt
from fastapi import Depends, FastAPI, File, HTTPException, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from openai import OpenAI
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy.orm import Session

from models import Base, SessionLocal, User, engine

# ──────────────────────────────────────────────
# App configuration
# ──────────────────────────────────────────────
SECRET_KEY = os.getenv(
    "JWT_SECRET_KEY",
    "CHANGE-ME-to-a-real-secret-in-production",
)  # ⚠️  set JWT_SECRET_KEY env var before deploying
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 30  # 30 days

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434/v1")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llava:7b")

app = FastAPI(
    title="GlowUp API",
    description="Backend API for the GlowUp cosmetic wellness application.",
    version="0.1.0",
)

# CORS – allow web and mobile clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create tables on startup
Base.metadata.create_all(bind=engine)

# ──────────────────────────────────────────────
# Security utilities
# ──────────────────────────────────────────────
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Check a plain-text password against a bcrypt hash."""
    return bcrypt.checkpw(
        plain_password.encode("utf-8"),
        hashed_password.encode("utf-8"),
    )


def hash_password(password: str) -> str:
    """Hash a plain-text password with bcrypt."""
    return bcrypt.hashpw(
        password.encode("utf-8"),
        bcrypt.gensalt(),
    ).decode("utf-8")


def create_access_token(data: dict, expires_delta: timedelta | None = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


# ──────────────────────────────────────────────
# Database dependency
# ──────────────────────────────────────────────
def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ──────────────────────────────────────────────
# Pydantic schemas
# ──────────────────────────────────────────────
class UserRegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, description="Minimum 8 characters")
    age: int | None = Field(None, ge=1, le=150)
    height_cm: float | None = Field(None, gt=0)
    weight_kg: float | None = Field(None, gt=0)
    preferred_language: str = Field("en", max_length=10)


class UserUpdate(BaseModel):
    age: int | None = Field(None, ge=1, le=150)
    height_cm: float | None = Field(None, gt=0)
    weight_kg: float | None = Field(None, gt=0)
    preferred_language: str | None = Field(None, max_length=10)


class UserResponse(BaseModel):
    id: int
    email: str
    age: int | None
    height_cm: float | None
    weight_kg: float | None
    preferred_language: str

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class ProductLinks(BaseModel):
    amazon_in: str
    flipkart: str


class ProductRecommendation(BaseModel):
    product: str
    links: ProductLinks


class SelfieAnalysisResponse(BaseModel):
    analysis_summary: str
    lifestyle_advice: str
    otc_product_recommendations: list[ProductRecommendation]


# ──────────────────────────────────────────────
# Auth helper – get current user from JWT
# ──────────────────────────────────────────────
def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_email: str | None = payload.get("sub")
        if user_email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(User).filter(User.email == user_email).first()
    if user is None:
        raise credentials_exception
    return user


# ──────────────────────────────────────────────
# Localization API
# ──────────────────────────────────────────────

_cached_languages = None

@app.get("/languages")
def get_languages():
    """Return all supported languages from Google Translate."""
    global _cached_languages
    if _cached_languages is None:
        try:
            url = 'https://translate.googleapis.com/translate_a/l?client=gtx'
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            resp = urllib.request.urlopen(req, timeout=5)
            data = json.loads(resp.read().decode('utf-8'))
            langs = data.get('tl', {})
            _cached_languages = {v: k for k, v in langs.items()}
        except Exception as e:
            print(f"Error fetching languages: {e}")
            _cached_languages = {"English": "en", "Hindi": "hi", "Malayalam": "ml", "Tamil": "ta"}
    
    return list(_cached_languages.keys())

def _get_lang_code(target_lang: str) -> str:
    global _cached_languages
    if _cached_languages is None:
        get_languages()
    target_lower = target_lang.lower()
    for name, code in _cached_languages.items():
        if name.lower() == target_lower:
            return code
    return "en"

class TranslateUIRequest(BaseModel):
    target_language: str
    strings: dict[str, str]

@app.post("/translate_ui")
def translate_ui(req: TranslateUIRequest):
    """Translate UI dictionary dynamically."""
    code = _get_lang_code(req.target_language)
    if code == "en":
        return req.strings
        
    result = {}
    for key, text in req.strings.items():
        result[key] = _translate_text_by_code(text, code)
    return result

def _translate_text_by_code(text: str, tl: str) -> str:
    if not text or tl == "en":
        return text
    try:
        url = f"https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl={tl}&dt=t&q={urllib.parse.quote(text)}"
        req_obj = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        resp = urllib.request.urlopen(req_obj, timeout=5)
        data = json.loads(resp.read().decode('utf-8'))
        translated_text = "".join(item[0] for item in data[0] if item[0])
        return translated_text
    except Exception as e:
        print(f"Translation failed: {e}")
        return text

# ──────────────────────────────────────────────
# Endpoints
# ──────────────────────────────────────────────
@app.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
)
def register(payload: UserRegisterRequest, db: Session = Depends(get_db)):
    """Create a new GlowUp account. Returns the created user (without password)."""
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A user with this email already exists.",
        )

    new_user = User(
        email=payload.email,
        hashed_password=hash_password(payload.password),
        age=payload.age,
        height_cm=payload.height_cm,
        weight_kg=payload.weight_kg,
        preferred_language=payload.preferred_language,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@app.post(
    "/login",
    response_model=TokenResponse,
    summary="Authenticate and receive a JWT",
)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    """
    Accepts `username` (email) and `password` as form fields
    (OAuth2-compatible). Returns a Bearer JWT on success.
    """
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = create_access_token(
        data={"sub": user.email},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    return TokenResponse(access_token=access_token)


@app.get(
    "/me",
    response_model=UserResponse,
    summary="Get current authenticated user",
)
def read_current_user(current_user: User = Depends(get_current_user)):
    """Returns the profile of the currently authenticated user."""
    return current_user


@app.patch(
    "/me",
    response_model=UserResponse,
    summary="Update current authenticated user",
)
def update_current_user(
    payload: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Updates the profile of the currently authenticated user."""
    if payload.age is not None:
        current_user.age = payload.age
    if payload.height_cm is not None:
        current_user.height_cm = payload.height_cm
    if payload.weight_kg is not None:
        current_user.weight_kg = payload.weight_kg
    if payload.preferred_language is not None:
        current_user.preferred_language = payload.preferred_language

    db.commit()
    db.refresh(current_user)
    return current_user


# ──────────────────────────────────────────────
# Shopping link utility
# ──────────────────────────────────────────────
def generate_shopping_links(product_name: str) -> ProductLinks:
    """Generate Amazon India and Flipkart search URLs for a product name."""
    encoded = quote_plus(product_name)
    return ProductLinks(
        amazon_in=f"https://www.amazon.in/s?k={encoded}",
        flipkart=f"https://www.flipkart.com/search?q={encoded}",
    )


def enrich_recommendations(
    product_names: list[str],
) -> list[ProductRecommendation]:
    """Attach shopping links to each generic product recommendation."""
    return [
        ProductRecommendation(
            product=name,
            links=generate_shopping_links(name),
        )
        for name in product_names
    ]


# ──────────────────────────────────────────────
# Selfie analysis endpoint
# ──────────────────────────────────────────────
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
MAX_IMAGE_SIZE_MB = 10


@app.post(
    "/analyze-selfie",
    response_model=SelfieAnalysisResponse,
    summary="AI-powered cosmetic selfie analysis",
)
async def analyze_selfie(
    file: UploadFile = File(..., description="Selfie image (JPEG, PNG, WebP, or GIF)"),
    current_user: User = Depends(get_current_user),
):
    """
    Upload a selfie to receive a cosmetic wellness analysis powered by
    a local LLaVA vision model via Ollama. The analysis factors in the
    authenticated user's age, height, weight, and preferred language.
    """
    # ── Validate image ──
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported image type '{file.content_type}'. "
            f"Accepted: {', '.join(sorted(ALLOWED_IMAGE_TYPES))}.",
        )

    image_bytes = await file.read()
    if len(image_bytes) > MAX_IMAGE_SIZE_MB * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"Image exceeds the {MAX_IMAGE_SIZE_MB} MB size limit.",
        )

    # ── Build user metrics ──
    age = current_user.age or "unknown"
    height = current_user.height_cm or "unknown"
    weight = current_user.weight_kg or "unknown"
    language = current_user.preferred_language or "en"

    system_prompt = (
        "You are an expert cosmetic dermatologist. "
        "Analyze the provided selfie for cosmetic wellness "
        "(skin hydration, texture, under-eyes). "
        "Do NOT diagnose medical conditions. "
        "Do NOT prescribe medication. "
        "Based STRICTLY on the visual evidence in this specific image, "
        "suggest over-the-counter (OTC) cosmetic products. "
        "These recommendations MUST be highly specific and tailored to the unique "
        "skin conditions observed. Do NOT give generic recommendations. "
        f"The user is {age} years old, {height} cm tall, "
        f"and weighs {weight} kg. "
        "Factor these metrics into your general wellness advice. "
        "Format the response in clear JSON containing three keys: "
        "analysis_summary (string), lifestyle_advice (string), and "
        "otc_product_recommendations (a JSON array of product name strings "
        "like [\"The Ordinary Niacinamide 10%\", \"CeraVe Hydrating Cleanser\"]). "
        "Return ONLY the JSON object, no markdown fences, no extra text."
    )

    # ── Encode image as base64 data-url ──
    mime = file.content_type or "image/jpeg"
    b64_image = base64.b64encode(image_bytes).decode("utf-8")
    data_url = f"data:{mime};base64,{b64_image}"

    # ── Call local Ollama (LLaVA) ──
    try:
        raw_content = _call_ollama(system_prompt, data_url)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Local AI model error: {exc}. "
            "Make sure Ollama is running: ollama serve",
        )

    # ── Parse AI response ──
    try:
        parsed = json.loads(raw_content)
    except json.JSONDecodeError:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="AI returned a malformed response. Please try again.",
        )

    # ── Translate content if needed ──
    if language.lower() not in ("en", "english"):
        parsed["analysis_summary"] = _translate_text(parsed.get("analysis_summary", ""), language)
        parsed["lifestyle_advice"] = _translate_text(parsed.get("lifestyle_advice", ""), language)
        translated_products = []
        for p in parsed.get("otc_product_recommendations", []):
            translated_products.append(_translate_text(p, language))
        parsed["otc_product_recommendations"] = translated_products

    raw_products = parsed.get("otc_product_recommendations", [])

    return SelfieAnalysisResponse(
        analysis_summary=parsed.get("analysis_summary", ""),
        lifestyle_advice=parsed.get("lifestyle_advice", ""),
        otc_product_recommendations=enrich_recommendations(raw_products),
    )


# ──────────────────────────────────────────────
# Local AI helper (Ollama + LLaVA)
# ──────────────────────────────────────────────


def _call_ollama(system_prompt: str, data_url: str) -> str:
    """Call a local Ollama vision model via its OpenAI-compatible API."""
    client = OpenAI(
        base_url=OLLAMA_BASE_URL,
        api_key="ollama",  # Ollama doesn't need a real key
    )
    response = client.chat.completions.create(
        model=OLLAMA_MODEL,
        messages=[
            {"role": "system", "content": system_prompt},
            {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {"url": data_url},
                    },
                    {
                        "type": "text",
                        "text": "Please analyze this selfie.",
                    },
                ],
            },
        ],
        temperature=0.4,
    )
    text = response.choices[0].message.content or "{}"
    return _strip_markdown_fences(text)


def _strip_markdown_fences(text: str) -> str:
    """Remove ```json ... ``` wrappers from AI output."""
    text = text.strip()
    if text.startswith("```"):
        lines = text.split("\n")
        lines = [l for l in lines[1:] if not l.strip().startswith("```")]
        text = "\n".join(lines)
    return text

def _translate_text(text: str, target_lang: str) -> str:
    """Translate text using the free Google Translate API."""
    if not text or target_lang.lower() in ("english", "en"):
        return text
        
    tl = _get_lang_code(target_lang)
    return _translate_text_by_code(text, tl)
