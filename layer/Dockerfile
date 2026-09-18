FROM public.ecr.aws/lambda/python:3.12

# Instalar utilidades del sistema necesarias para empaquetar
RUN dnf install -y zip && dnf clean all

# Directorio de trabajo
WORKDIR /build

# Copiar archivo de requerimientos
COPY requirements.txt .

# Instalar paquetes en la ruta /opt/python (estructura requerida por AWS Lambda)
RUN pip install --no-cache-dir -r requirements.txt -t /opt/python

# Sobrescribir el ENTRYPOINT por defecto de la imagen de Lambda (que busca un handler)
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["cd /opt && zip -r9 /output/layer.zip python"]
