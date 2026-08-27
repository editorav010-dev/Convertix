# Mirrors the deployed Space (pandeypratham/libreoffice-converter).
# Python 3.10 matches what that Space's image was built on.
FROM python:3.10-slim

# Install LibreOffice (headless document conversion engine)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libreoffice-writer \
    libreoffice-calc \
    libreoffice-impress \
    libreoffice-common \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install from requirements.txt so this file is never a second source of
# version truth. Pin changes belong in requirements.txt only.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Create a non-root user (HF Spaces requirement)
RUN useradd -m -u 1000 user
USER user

EXPOSE 7860

CMD ["python", "app.py"]
