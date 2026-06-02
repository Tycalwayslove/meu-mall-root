FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DATABASE_PATH=/app/data/meumall-config.sqlite

WORKDIR /app

COPY server-meumall/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY server-meumall/app ./app
RUN mkdir -p /app/data

EXPOSE 4100

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "4100"]
