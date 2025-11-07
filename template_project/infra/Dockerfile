FROM python:3.11-slim
WORKDIR /app
COPY app-src/requirements.txt .
RUN pip install -r requirements.txt
COPY app-src/ .
CMD ["gunicorn", "-b", ":8080", "main:app"]
