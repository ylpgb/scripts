#!/usr/bin/env python

import json

from klein import Klein


class ItemStore(object):
    app = Klein()

    def __init__(self):
        self._items = {}

    @app.route('/')
    def items(self, request):
        request.setHeader('Content-Type', 'application/json')
        return json.dumps(self._items)

    @app.route('/<string:name>', methods=['PUT'])
    @app.route('/<string:name>', methods=['POST'])
    def save_item(self, request, name):
        request.setHeader('Content-Type', 'application/plain')
        body = request.content.read()
	#print("name ", name, "body ", body)
        self._items[name] = body
        return json.dumps({'success': True})

    @app.route('/<string:name>', methods=['GET'])
    def get_item(self, request, name):
        request.setHeader('Content-Type', 'application/json')
        return json.dumps(self._items.get(name))


if __name__ == '__main__':
    store = ItemStore()
    store.app.run('', 8007)
