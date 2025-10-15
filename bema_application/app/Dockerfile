# Use official Python image
FROM python:3.10-slim

# Set working directory inside container
WORKDIR /app

# Install system dependencies (needed for mysqlclient etc.)
RUN apt-get update && apt-get install -y \
    gcc \
    pkg-config \
    default-libmysqlclient-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y libgl1 libglib2.0-0


# Copy requirements file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all source code
COPY . .

# Expose FastAPI port
EXPOSE 9005

# Disable Python buffering to see logs in real-time
ENV PYTHONUNBUFFERED=1

# Start FastAPI (main.py inside "app" folder, app object inside it)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "9005"]

