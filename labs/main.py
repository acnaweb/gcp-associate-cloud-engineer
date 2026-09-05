import base64

def hello_pubsub(event, context):
    data = event.get('data')
    msg = base64.b64decode(data).decode('utf-8') if data else 'sem mensagem'
    print(f'ACE recebeu: {msg}')
