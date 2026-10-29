"""Call the user's configured PixelLab MCP without copying authentication into the project.

Requests and responses belong in .godot/, which Git ignores. No credentials are printed.
Usage: python tools/pixellab_mcp.py request.json response.json
"""
import json
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path


def main():
    config = json.loads((Path.home() / '.claude.json').read_text(encoding='utf-8'))
    server = config['mcpServers']['pixellab']
    headers = {'Content-Type': 'application/json', 'Accept': 'application/json, text/event-stream'}
    headers.update(server.get('headers', {}))

    def call(method, params, request_id):
        payload = json.dumps({'jsonrpc': '2.0', 'id': request_id, 'method': method, 'params': params}).encode()
        request = urllib.request.Request(server['url'], payload, headers, method='POST')
        with urllib.request.urlopen(request, timeout=45) as response:
            session = response.headers.get('Mcp-Session-Id')
            if session:
                headers['Mcp-Session-Id'] = session
            if 'text/event-stream' in response.headers.get('Content-Type', ''):
                for raw in response:
                    line = raw.decode().strip()
                    if line.startswith('data:'):
                        value = json.loads(line[5:])
                        if value.get('id') == request_id:
                            return value
                raise ValueError('MCP stream closed without a response')
            return json.loads(response.read())

    call('initialize', {'protocolVersion': '2025-03-26', 'capabilities': {},
                       'clientInfo': {'name': 'ceniza-neon-assets', 'version': '1.0'}}, 1)
    requests = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8-sig'))
    results = []
    destination = Path(sys.argv[2])
    destination.parent.mkdir(parents=True, exist_ok=True)
    for index, request in enumerate(requests):
        response = call(request.get('method', 'tools/call'), request.get('params',
                        {'name': request.get('name', ''), 'arguments': request.get('arguments', {})}), index + 2)
        results.append({'request': request, 'response': response})
        destination.write_text(json.dumps(results), encoding='utf-8')
        print(request.get('name', request.get('method', 'request')), flush=True)
        for block in response.get('result', {}).get('content', []):
            if block.get('type') == 'text':
                print(block['text'][:1800], flush=True)
        if response.get('error'):
            print('MCP returned an error', flush=True)
        if request.get('wait_for_image'):
            summary = '\n'.join(b.get('text', '') for b in response.get('result', {}).get('content', []))
            job = re.search(r'job_id: ([a-f0-9-]+)', summary)
            if not job:
                raise ValueError('Generation was not queued')
            for attempt in range(90):
                time.sleep(3)
                response = call('tools/call', {'name': 'get_image', 'arguments': {'job_id': job[1]}}, 1000 + index * 100 + attempt)
                summary = '\n'.join(b.get('text', '') for b in response.get('result', {}).get('content', []))
                if 'status: completed' in summary:
                    results[-1]['completed'] = response
                    destination.write_text(json.dumps(results), encoding='utf-8')
                    url = re.search(r'download: (https://\S+)', summary)
                    if request.get('destination') and url:
                        output = Path(request['destination'])
                        output.parent.mkdir(parents=True, exist_ok=True)
                        with urllib.request.urlopen(url[1], timeout=45) as image:
                            output.write_bytes(image.read())
                        print('Saved ' + str(output), flush=True)
                    break
                if 'status: failed' in summary:
                    raise ValueError('PixelLab generation failed')
            else:
                raise TimeoutError('PixelLab generation did not finish')


if __name__ == '__main__':
    try:
        main()
    except urllib.error.HTTPError as error:
        print('PixelLab HTTP status:', error.code, file=sys.stderr)
        sys.exit(1)
    except Exception as error:
        print('PixelLab request failed:', type(error).__name__, file=sys.stderr)
        sys.exit(1)
