#!/usr/local/bin/python
import optparse
from proton import Message
from proton.handlers import MessagingHandler
from proton.reactor import Container

class Send(MessagingHandler):
    def __init__(self, url, address, count, username, password, QoS):
        super(Send, self).__init__()
        self.url = url
        self.address = address
        self.expected = count
        self.username = username 
        self.password = password 
        self.message_durability = True if QoS==2 else False
        self.received = 0
        self.confirmed = 0
        self.sent = 0

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
            event.container.create_sender(conn, target=self.address)

    def on_sendable(self, event):
        while event.sender.credit and self.sent < self.expected:
            msg = Message(id=(self.sent+1), 
                          body='sequence'+str(self.sent+1), 
                          durable=self.message_durability)

            event.sender.send(msg)
            self.sent += 1

    def on_accepted(self, event):
        self.confirmed += 1
        if self.confirmed == self.expected:
            print("all sent messages confirmed")
            #event.connection.close()

    def on_rejected(self, event):
        self.confirmed += 1
        print("Broker", self.url, "Reject message:", event.delivery.tag)
        if self.confirmed == self.expected:
            print("all sent messages confirmed")
            #event.connection.close()

    def on_message(self, event):
        if event.message.id and event.message.id < self.received:
            # ignore duplicate message
            return
        if self.expected == 0 or self.received < self.expected:
            print("Received: ", event.message.body)
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
parser.add_option("-q", "--qos", default="non-persistent",
                  help="Selects the message QoS for published messages. Valid values are [persistent or 2] for persistent messages. Valid values are [non-persistent or 1] for non-persistent messages. default %default)")
opts, args = parser.parse_args()

# determine Quality of Service for sending messages
if str(opts.qos) == "non-persistent" or  opts.qos==1:
    QoS=1 # non-persistent
elif str(opts.qos) == "persistent" or  opts.qos==2:
    QoS=2 # persistent
else:
    # TODO add QOS for direct (0)
    # default to non-persistent
    QoS=1

try:
    Container(Send(opts.url, opts.address, opts.messages, opts.username, opts.password, QoS)).run()
except KeyboardInterrupt: pass
