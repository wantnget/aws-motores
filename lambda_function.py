import json
import boto3
import base64
import os

s3 = boto3.client('s3')
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'nombre-de-tu-bucket')


def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}')) if isinstance(event.get('body'), str) else event

        action = body.get('action')
        key = body.get('key')

        if not action or not key:
            return response(400, {'error': 'Faltan parámetros: action y key son requeridos'})

        if action == 'upload':
            content = body.get('content')
            if not content:
                return response(400, {'error': 'Falta content para upload'})

            data = base64.b64decode(content) if body.get('is_base64') else content.encode('utf-8')
            s3.put_object(Bucket=BUCKET_NAME, Key=key, Body=data)
            return response(200, {'message': f'Archivo {key} subido correctamente'})

        elif action == 'download':
            obj = s3.get_object(Bucket=BUCKET_NAME, Key=key)
            content = obj['Body'].read().decode('utf-8')
            return response(200, {'key': key, 'content': content})

        else:
            return response(400, {'error': 'action debe ser "upload" o "download"'})

    except s3.exceptions.NoSuchKey:
        return response(404, {'error': 'Archivo no encontrado'})
    except Exception as e:
        return response(500, {'error': str(e)})


def response(status_code, body_dict):
    return {
        'statusCode': status_code,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps(body_dict)
    }
