# Celery doesn't support 3.7 yet :(
FROM python:3.6-alpine

ADD requirements.txt /root/
RUN apk add --no-cache postgresql-libs libstdc++ && \
  apk add --no-cache --virtual .build-deps build-base musl-dev libffi-dev openssl-dev postgresql-dev && \
  pip install --no-cache-dir -r /root/requirements.txt && \
  apk --purge del .build-deps

COPY . /app
WORKDIR /app
ENTRYPOINT ["python"]
CMD ["app.py"]