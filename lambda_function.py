import json
import boto3
import base64
import os
import requests  # Importado desde la Lambda Layer
from flask import Flask, request
import awsgi

app = Flask(__name__)

s3 = boto3.client('s3')
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'nombre-de-tu-bucket')


@app.route('/validate', methods=['GET'])
def validate():
    return {'status': 'ok', 'message': 'Ruta /validate funcionando'}


@app.route('/motor-data', methods=['GET'])
def motor_data():
    return {'status': 'ok', 'message': 'Ruta /motor-data funcionando'}


@app.route('/', methods=['POST'])
def root():
    body = request.get_json(silent=True) or {}

    action = body.get('action')
    key = body.get('key')

    if action == 'ping':
        return {
            'status': 'ok',
            'message': 'Lambda y Layer operativas',
            'requests_version': requests.__version__
        }

    if not action or not key:
        return {'error': 'Faltan parametros: action y key son requeridos'}, 400

    if action == 'upload':
        content = body.get('content')
        if not content:
            return {'error': 'Falta content para upload'}, 400

        data = base64.b64decode(content) if body.get('is_base64') else content.encode('utf-8')
        s3.put_object(Bucket=BUCKET_NAME, Key=key, Body=data)
        return {'message': f'Archivo {key} subido correctamente'}

    elif action == 'download':
        try:
            obj = s3.get_object(Bucket=BUCKET_NAME, Key=key)
            content = obj['Body'].read().decode('utf-8')
            return {'key': key, 'content': content}
        except s3.exceptions.NoSuchKey:
            return {'error': 'Archivo no encontrado'}, 404

    else:
        return {'error': 'action debe ser "upload", "download" o "ping"'}, 400


def lambda_handler(event, context):
    return awsgi.response(app, event, context)