""" Custom topology

Three directly connected switches, plus a host for each switch

On the command line:
  --topo=T3s3h
"""

# http://mininet.org/walkthrough/#custom-topologies

from mininet.topo import Topo

class T3s3h( Topo ):
  " topo: three switches, three hosts"

  def __init__( self ):
    "topo creation"
    Topo.__init__( self )

    # Add hosts and switches
    topHost = self.addHost( 'h1' )
    topSwitch = self.addSwitch( 's1' )
    self.addLink( topHost, topSwitch )

    leftHost = self.addHost( 'h2' )
    leftSwitch = self.addSwitch( 's2' )
    self.addLink( leftHost, leftSwitch )

    rightHost = self.addHost( 'h3' )
    rightSwitch = self.addSwitch( 's3' )
    self.addLink( rightHost, rightSwitch )

    # Add Additional Links
    self.addLink( topSwitch, leftSwitch )
    self.addLink( topSwitch, rightSwitch )
    self.addLink( leftSwitch, rightSwitch )

topos = { 't3s3h': ( lambda: T3s3h() ) }
    
