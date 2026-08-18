"""
Convertix Backend — Document Processing API
Deployed on Hugging Face Spaces (Docker)
"""

import asyncio
import io
import json
import os
import shutil
import subprocess
import zipfile
from uuid import uuid4

import fitz  # PyMuPDF
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import FileResponse, Response
from PIL import Image

app = FastAPI(
    title="Convertix Backend",
    description="Document processing API for Convertix mobile app",
    version="1.0.0",
)


# ─────────────────────────────────────────────
# FILE LIFECYCLE — cleanup temp files after response
# ─────────────────────────────────────────────

async def cleanup_after_delay(path: str, delay: int = 25):
    """Delete a directory after a delay. Called as a fire-and-forget task."""
    await asyncio.sleep(delay)
    shutil.rmtree(path, ignore_errors=True)


def create_job_dir() -> str:
    """Create a unique temporary directory for a processing job."""
    job_dir = f"/tmp/{uuid4()}"
    os.makedirs(job_dir, exist_ok=True)
    return job_dir


# ─────────────────────────────────────────────
# HEALTH CHECK
# ─────────────────────────────────────────────

@app.get("/health")
async def health():
    return {"status": "ok"}


# ─────────────────────────────────────────────
# 1. IMAGE TO PDF
# ─────────────────────────────────────────────

@app.post("/image-to-pdf")
async def image_to_pdf(files: list[UploadFile] = File(...)):
    """Convert one or more images to a single A4 PDF."""
    if not files:
        raise HTTPException(status_code=400, detail="No image files provided")

    job_dir = create_job_dir()

    try:
        # A4 dimensions in points (72 dpi)
        A4_WIDTH = 595.28
        A4_HEIGHT = 841.89
        MARGIN = 36  # 0.5 inch margin

        images_for_pdf: list[Image.Image] = []

        for upload_file in files:
            try:
                content = await upload_file.read()
                img = Image.open(io.BytesIO(content))

                # Convert to RGB if necessary (RGBA, P, etc.)
                if img.mode in ("RGBA", "P", "LA"):
                    background = Image.new("RGB", img.size, (255, 255, 255))
                    if img.mode == "P":
                        img = img.convert("RGBA")
                    background.paste(img, mask=img.split()[-1] if img.mode == "RGBA" else None)
                    img = background
                elif img.mode != "RGB":
                    img = img.convert("RGB")

                # Scale image to fit A4 page with margins
                max_w = A4_WIDTH - (2 * MARGIN)
                max_h = A4_HEIGHT - (2 * MARGIN)

                img_w, img_h = img.size
                scale = min(max_w / img_w, max_h / img_h, 1.0)
                new_w = int(img_w * scale)
                new_h = int(img_h * scale)

                if scale < 1.0:
                    img = img.resize((new_w, new_h), Image.LANCZOS)

                # Create A4 page with white background
                page = Image.new("RGB", (int(A4_WIDTH), int(A4_HEIGHT)), (255, 255, 255))

                # Center the image on the page
                x_offset = int((A4_WIDTH - new_w) / 2)
                y_offset = int((A4_HEIGHT - new_h) / 2)
                page.paste(img, (x_offset, y_offset))

                images_for_pdf.append(page)
            except Exception as e:
                raise HTTPException(
                    status_code=422,
                    detail=f"Failed to process image '{upload_file.filename}': {str(e)}"
                )

        if not images_for_pdf:
            raise HTTPException(status_code=400, detail="No valid images to convert")

        output_path = os.path.join(job_dir, "output.pdf")
        first_image = images_for_pdf[0]
        remaining = images_for_pdf[1:] if len(images_for_pdf) > 1 else []

        first_image.save(
            output_path,
            "PDF",
            save_all=True,
            append_images=remaining,
            resolution=72.0,
        )

        asyncio.create_task(cleanup_after_delay(job_dir))

        return FileResponse(
            output_path,
            media_type="application/pdf",
            filename="converted.pdf",
        )

    except HTTPException:
        raise
    except Exception as e:
        shutil.rmtree(job_dir, ignore_errors=True)
        raise HTTPException(status_code=500, detail=f"Image to PDF conversion failed: {str(e)}")


# ─────────────────────────────────────────────
# 2. DOCUMENT CONVERT
# ─────────────────────────────────────────────

@app.post("/document-convert")
async def document_convert(
    files: list[UploadFile] = File(...),
    target_format: str = Form(...),
):
    """Convert a document using LibreOffice headless."""
    if not files:
        raise HTTPException(status_code=400, detail="No file provided")

    upload_file = files[0]
    target_format = target_format.strip().lower()

    ALLOWED_FORMATS = {
        "docx", "xlsx", "pptx", "pdf", "odt", "ods", "odp", "rtf", "txt", "csv",
    }
    if target_format not in ALLOWED_FORMATS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported target format: '{target_format}'. Allowed: {', '.join(sorted(ALLOWED_FORMATS))}",
        )

    job_dir = create_job_dir()

    try:
        # Save uploaded file
        input_filename = upload_file.filename or "input"
        input_path = os.path.join(job_dir, input_filename)
        content = await upload_file.read()
        with open(input_path, "wb") as f:
            f.write(content)

        # Run LibreOffice headless conversion
        result = subprocess.run(
            [
                "soffice",
                "--headless",
                "--norestore",
                "--convert-to", target_format,
                "--outdir", job_dir,
                input_path,
            ],
            capture_output=True,
            text=True,
            timeout=120,
        )

        if result.returncode != 0:
            raise HTTPException(
                status_code=422,
                detail=f"LibreOffice conversion failed: {result.stderr.strip() or 'Unknown error'}",
            )

        # Find the output file (LibreOffice changes the extension)
        input_stem = os.path.splitext(input_filename)[0]
        output_filename = f"{input_stem}.{target_format}"
        output_path = os.path.join(job_dir, output_filename)

        if not os.path.exists(output_path):
            # Sometimes LibreOffice produces a slightly different name — find any new file
            for f in os.listdir(job_dir):
                if f != input_filename and f.endswith(f".{target_format}"):
                    output_path = os.path.join(job_dir, f)
                    output_filename = f
                    break

        if not os.path.exists(output_path):
            raise HTTPException(
                status_code=422,
                detail="Conversion produced no output file. The input format may not be supported.",
            )

        # Determine MIME type
        mime_types = {
            "pdf": "application/pdf",
            "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "odt": "application/vnd.oasis.opendocument.text",
            "ods": "application/vnd.oasis.opendocument.spreadsheet",
            "odp": "application/vnd.oasis.opendocument.presentation",
            "rtf": "application/rtf",
            "txt": "text/plain",
            "csv": "text/csv",
        }
        media_type = mime_types.get(target_format, "application/octet-stream")

        asyncio.create_task(cleanup_after_delay(job_dir))

        return FileResponse(
            output_path,
            media_type=media_type,
            filename=output_filename,
        )

    except HTTPException:
        raise
    except subprocess.TimeoutExpired:
        shutil.rmtree(job_dir, ignore_errors=True)
        raise HTTPException(status_code=422, detail="Conversion timed out (120s limit)")
    except Exception as e:
        shutil.rmtree(job_dir, ignore_errors=True)
        raise HTTPException(status_code=500, detail=f"Document conversion failed: {str(e)}")


# ─────────────────────────────────────────────
# 3. GREYSCALE PDF
# ─────────────────────────────────────────────

@app.post("/greyscale-pdf")
async def greyscale_pdf(files: list[UploadFile] = File(...)):
    """Convert a color PDF to grayscale."""
    if not files:
        raise HTTPException(status_code=400, detail="No PDF file provided")

    upload_file = files[0]
    job_dir = create_job_dir()

    try:
        content = await upload_file.read()
        input_path = os.path.join(job_dir, "input.pdf")
        with open(input_path, "wb") as f:
            f.write(content)

        # Open with PyMuPDF and rebuild each page in grayscale
        src_doc = fitz.open(input_path)
        out_doc = fitz.open()  # new empty PDF

        for page_num in range(len(src_doc)):
            src_page = src_doc[page_num]

            # Render page to grayscale pixmap
            pix = src_page.get_pixmap(
                matrix=fitz.Matrix(2, 2),  # 2x zoom for quality
                colorspace=fitz.csGRAY,
            )

            # Create new page with same dimensions
            rect = src_page.rect
            new_page = out_doc.new_page(width=rect.width, height=rect.height)

            # Insert the grayscale image
            new_page.insert_image(rect, pixmap=pix)

        output_path = os.path.join(job_dir, "greyscale.pdf")
        out_doc.save(output_path, garbage=4, deflate=True)
        out_doc.close()
        src_doc.close()

        asyncio.create_task(cleanup_after_delay(job_dir))

        return FileResponse(
            output_path,
            media_type="application/pdf",
            filename="greyscale.pdf",
        )

    except HTTPException:
        raise
    except Exception as e:
        shutil.rmtree(job_dir, ignore_errors=True)
        raise HTTPException(status_code=500, detail=f"Greyscale conversion failed: {str(e)}")


# ─────────────────────────────────────────────
# 4. MERGE PDF
# ─────────────────────────────────────────────

@app.post("/merge-pdf")
async def merge_pdf(files: list[UploadFile] = File(...)):
    """Merge multiple PDFs into one."""
    if not files or len(files) < 2:
        raise HTTPException(status_code=400, detail="At least 2 PDF files are required")

    job_dir = create_job_dir()

    try:
        merged_doc = fitz.open()

        for upload_file in files:
            try:
                content = await upload_file.read()
                pdf_doc = fitz.open(stream=content, filetype="pdf")
                merged_doc.insert_pdf(pdf_doc)
                pdf_doc.close()
            except Exception as e:
                raise HTTPException(
                    status_code=422,
                    detail=f"Failed to process '{upload_file.filename}': {str(e)}",
                )

        output_path = os.path.join(job_dir, "merged.pdf")
        merged_doc.save(output_path, garbage=4, deflate=True)
        merged_doc.close()

        asyncio.create_task(cleanup_after_delay(job_dir))

        return FileResponse(
            output_path,
            media_type="application/pdf",
            filename="merged.pdf",
        )

    except HTTPException:
        raise
    except Exception as e:
        shutil.rmtree(job_dir, ignore_errors=True)
        raise HTTPException(status_code=500, detail=f"PDF merge failed: {str(e)}")


# ─────────────────────────────────────────────
# 5. SPLIT PDF
# ─────────────────────────────────────────────

@app.post("/split-pdf")
async def split_pdf(
    files: list[UploadFile] = File(...),
    params: str = Form(...),
):
    """
    Split a PDF by page ranges or specific pages.
    
    params is a JSON string:
      - {"ranges": [[1,5], [6,10]]}  → split into segments
      - {"pages": [3, 7, 12]}         → extract specific pages
    
    Returns a single PDF if one output, or a ZIP if multiple.
    """
    if not files:
        raise HTTPException(status_code=400, detail="No PDF file provided")

    upload_file = files[0]
    job_dir = create_job_dir()

    try:
        # Parse params
        try:
            split_params = json.loads(params)
        except json.JSONDecodeError:
            raise HTTPException(status_code=400, detail="Invalid JSON in 'params' field")

        content = await upload_file.read()
        src_doc = fitz.open(stream=content, filetype="pdf")
        total_pages = len(src_doc)

        if total_pages == 0:
            raise HTTPException(status_code=422, detail="PDF has no pages")

        output_files: list[str] = []

        if "ranges" in split_params:
            ranges = split_params["ranges"]
            if not isinstance(ranges, list) or not ranges:
                raise HTTPException(status_code=400, detail="'ranges' must be a non-empty list of [start, end] pairs")

            for i, r in enumerate(ranges):
                if not isinstance(r, list) or len(r) != 2:
                    raise HTTPException(status_code=400, detail=f"Range {i+1} must be [start, end]")

                start, end = int(r[0]), int(r[1])

                # Validate (1-indexed from user, 0-indexed for PyMuPDF)
                if start < 1 or end < start or end > total_pages:
                    raise HTTPException(
                        status_code=400,
                        detail=f"Invalid range [{start}, {end}]. PDF has {total_pages} pages.",
                    )

                out_doc = fitz.open()
                out_doc.insert_pdf(src_doc, from_page=start - 1, to_page=end - 1)
                out_path = os.path.join(job_dir, f"pages_{start}-{end}.pdf")
                out_doc.save(out_path)
                out_doc.close()
                output_files.append(out_path)

        elif "pages" in split_params:
            pages = split_params["pages"]
            if not isinstance(pages, list) or not pages:
                raise HTTPException(status_code=400, detail="'pages' must be a non-empty list of page numbers")

            # Validate all pages
            for p in pages:
                p = int(p)
                if p < 1 or p > total_pages:
                    raise HTTPException(
                        status_code=400,
                        detail=f"Invalid page number {p}. PDF has {total_pages} pages.",
                    )

            # Extract pages into a single PDF
            out_doc = fitz.open()
            for p in pages:
                out_doc.insert_pdf(src_doc, from_page=int(p) - 1, to_page=int(p) - 1)
            out_path = os.path.join(job_dir, "extracted_pages.pdf")
            out_doc.save(out_path)
            out_doc.close()
            output_files.append(out_path)

        else:
            raise HTTPException(
                status_code=400,
                detail="params must contain 'ranges' or 'pages'",
            )

        src_doc.close()

        # Return single PDF or ZIP
        if len(output_files) == 1:
            asyncio.create_task(cleanup_after_delay(job_dir))
            return FileResponse(
                output_files[0],
                media_type="application/pdf",
                filename=os.path.basename(output_files[0]),
            )
        else:
            # Create ZIP archive
            zip_path = os.path.join(job_dir, "split_output.zip")
            with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
                for f in output_files:
                    zf.write(f, os.path.basename(f))

            asyncio.create_task(cleanup_after_delay(job_dir))
            return FileResponse(
                zip_path,
                media_type="application/zip",
                filename="split_output.zip",
            )

    except HTTPException:
        raise
    except Exception as e:
        shutil.rmtree(job_dir, ignore_errors=True)
        raise HTTPException(status_code=500, detail=f"PDF split failed: {str(e)}")
