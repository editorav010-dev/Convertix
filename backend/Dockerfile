FROM python:3.10-slim

# Install LibreOffice
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libreoffice-writer \
    libreoffice-calc \
    libreoffice-impress \
    libreoffice-common \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Install Python deps with exact pinned versions
# jinja2 and starlette pinned to avoid template cache crash
RUN pip install --no-cache-dir \
    jinja2==3.1.4 \
    starlette==0.37.2 \
    gradio==4.36.0 \
    gradio_client==1.0.1 \
    huggingface_hub==0.23.5 \
    pymupdf==1.24.11 \
    fastapi==0.111.0 \
    pydantic==2.7.4

# Copy app
COPY app.py .

# Create a non-root user (HF requirement)
RUN useradd -m -u 1000 user
USER user

EXPOSE 7860

CMD ["python", "app.py"]
