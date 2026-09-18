FROM public.ecr.aws/lambda/python:3.12

RUN dnf install -y zip && dnf clean all

WORKDIR /build

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt -t /opt/python