# Imagen base con vulnerabilidades conocidas para demostrar escaneo
FROM python:3.9-slim

LABEL maintainer="devops-course"
LABEL version="2.0"
LABEL description="Demo app for vulnerability scanning - v2"

WORKDIR /app

# Aplicacion simple - version 2
RUN echo 'print("Hello from demo-app v2")' > app.py

# Usuario non-root (best practice, se profundiza en S09)
RUN useradd --create-home appuser
USER appuser

CMD ["python", "app.py"]