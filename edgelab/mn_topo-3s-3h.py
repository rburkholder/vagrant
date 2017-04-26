""" Custom topology

Three directly connected switches, plus a host for each switch

On the command line:
  --topo=T3s3h
"""

# http://mininet.org/walkthrough/#custom-topologies

from mininet.topo import Topo

# https://inside-openflow.com/2016/06/29/custom-mininet-topologies-and-introducing-atom/
from mininet.cli import CLI
from mininet.log import setLogLevel
from mininet.net import Mininet
from mininet.node import RemoteController, OVSKernelSwitch, OVSSwitch

class Topo3s3h( Topo ):
  " topo: three switches, three hosts"

  def __init__( self ):
    "topo creation"
    Topo.__init__( self )

    protocols = [ 'OpenFlow14' ]

    # Add hosts and switches
    topHost = self.addHost( 'h1' )
    topSwitch = self.addSwitch( 's1', protocols = protocols )
    self.addLink( topHost, topSwitch )

    leftHost = self.addHost( 'h2' )
    leftSwitch = self.addSwitch( 's2', protocols = protocols )
    self.addLink( leftHost, leftSwitch )

    rightHost = self.addHost( 'h3' )
    rightSwitch = self.addSwitch( 's3', protocols = protocols )
    self.addLink( rightHost, rightSwitch )

    # Add Additional Links
    self.addLink( topSwitch, leftSwitch )
    self.addLink( topSwitch, rightSwitch )
    self.addLink( leftSwitch, rightSwitch )

def RunWithTopo():
  
  # create instance of topology
  topo = Topo3s3h()

  # create a network with the topology, OVS, with Ryu
  net = Mininet(
    topo=topo,
    controller=lambda name: RemoteController(name, ip='127.0.0.1' ),
    switch=OVSKernelSwitch,
    autoSetMacs=True
    )
  
  # start the network
  net.start()

  # run command line interface
  CLI( net )

  # on exit from cli, clean up and quite
  net.stop()

if __name__ == '__main__':
  setLogLevel( 'info' )
  RunWithTopo()

# file can be imported using 'mn --custom <filename> --topo t3s3h'
topos = { 't3s3h': ( lambda: Topo3s3h() ) }
    
