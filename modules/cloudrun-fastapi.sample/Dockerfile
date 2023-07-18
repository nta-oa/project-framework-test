FROM python:3.10-slim-buster

ARG PYTHON_LIB_INDEX_URL

# Print logs immediately instead of buffering
ENV PYTHONUNBUFFERED=True \
    # Application
    APP_PATH=/app \
    APP_USER=uvicorn \
    APP_RUN=app \
    # Server
    PORT=8080 \
    MAIN=main

COPY src/ requirements.txt  $APP_PATH/

RUN echo "" \
    && mkdir /creds \
    && useradd --system --shell /bin/true --home $APP_PATH $APP_USER \
    && chown $APP_USER:$APP_USER /creds \
    && python -m pip install --no-cache-dir --extra-index-url $PYTHON_LIB_INDEX_URL \
        -r $APP_PATH/requirements.txt \
    && rm -f $APP_PATH/requirements.txt

EXPOSE $PORT
USER $APP_USER
WORKDIR $APP_PATH

CMD exec uvicorn $MAIN:$APP_RUN --host 0.0.0.0 --port $PORT $DEBUG_FLAG
