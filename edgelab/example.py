# https://groups.google.com/a/openflowhub.org/forum/#!msg/floodlight-dev/Em_17o2YTS4/YvHTEsKMFAAJ

from mininet.net import Mininet
from mininet.node import Controller, OVSSwitch,RemoteController
from mininet.cli import CLI
from mininet.log import setLogLevel

def multiControllerNet():
    "Create a network from semi-scratch with multiple controllers."

    net = Mininet( controller=Controller, switch=OVSSwitch )

    print "*** Creating (reference) controllers"
    c1= net.addController( 'c1', controller=RemoteController, ip='192.168.56.1', port=6653)
    c2= net.addController( 'c2', controller=RemoteController, ip='192.168.56.1', port=6652)
    

    print "*** Creating switches"
    s1 = net.addSwitch( 's1',protocols=["OpenFlow14"])
    s2 = net.addSwitch( 's2',protocols=["OpenFlow14"])
    #s1 = net.addSwitch( 's1')
    #s2 = net.addSwitch( 's2')

    h1=net.addHost('h1')
    h2=net.addHost('h2')
    h3=net.addHost('h3')
    h4=net.addHost('h4')

    net.addLink(h1, s1, )
    net.addLink(h2, s1, ) 
    net.addLink(h3, s2, ) 
    net.addLink(h4, s2, ) 
    net.addLink( s1, s2 )

    print "*** Starting network"
    net.build()
    
    s1.start( [ c2,c1 ] )
    s2.start( [ c1,c2 ] )
    
    print "*** Testing network"
    net.pingAll()

    print "*** Running CLI"
    CLI( net )

    print "*** Stopping network"
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )  # for CLI output
    multiControllerNet()

