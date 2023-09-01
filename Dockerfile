FROM python:3.11-bookworm
COPY . /app/
WORKDIR /app/docs/
RUN pip install -e "../psycopg[docs]" -e ../psycopg_pool
CMD ["make", "serve"]
