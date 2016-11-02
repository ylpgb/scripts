#!/usr/bin/env python

from klein import Klein
import copy
import json

bufferSize=(1024*64)

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
        if( len(self._items.get(name, "")) < bufferSize) :
              self._items[name] = self._items.get(name, "") + body
	else :
              self._items[name] = body
        return ("success")

    @app.route('/<string:name>', methods=['GET'])
    def get_item(self, request, name):
        request.setHeader('Content-Type', 'application/plain')
	self.dup = copy.deepcopy(self._items.get(name))
	self._items[name] = ""
        return (self.dup)


if __name__ == '__main__':
    store = ItemStore()
    store.app.run('', 8007)
