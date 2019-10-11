#!/usr/local/bin/python
import optparse
from proton.handlers import MessagingHandler
from proton.reactor import Container

class Recv(MessagingHandler):
    def __init__(self, url, address, count, username, password):
        super(Recv, self).__init__()
        self.url = url
        self.address = address
        self.expected = count
        self.username = username 
        self.password = password 
        self.received = 0

    def on_start(self, event):
        if self.username:
            conn = event.container.connect(url=self.url,
                                           user=self.username,
                                           password=self.password,
                                           allow_insecure_mechs=True)
        else:
            conn = event.container.connect(url=self.url)
            
        if conn:
            print("Connection created")
            event.container.create_receiver(conn, source=self.address)

    def on_message(self, event):
        if event.message.id and event.message.id < self.received:
            # ignore duplicate message
            return
        if self.expected == 0 or self.received < self.expected:
            print(event.message.body)
            self.received += 1
            if self.received == self.expected:
                event.receiver.close()
                event.connection.close()

    def on_transport_error(self, event):
        print("Transport error:", event.transport.condition)
        MessagingHandler.on_transport_error(self, event)

    def on_disconnected(self, event):
        print("Disconnected")

parser = optparse.OptionParser(usage="usage: %prog [options]")
parser.add_option("-u", "--url", default="amqp://localhost:5672",
                  help="address from which messages are received (default %default)")
parser.add_option("-a", "--address", default="examples",
                  help="node address from which messages are received (default %default)")
parser.add_option("-m", "--messages", type="int", default=100,
                  help="number of messages to receive; 0 receives indefinitely (default %default)")
parser.add_option("-o", "--username", type="string", default="admin",
                  help="username for authentication (default %default)")
parser.add_option("-p", "--password", type="string", default="solace1",
                  help="password for authentication (default %default)")
opts, args = parser.parse_args()

try:
    Container(Recv(opts.url, opts.address, opts.messages, opts.username, opts.password)).run()
except KeyboardInterrupt: pass
