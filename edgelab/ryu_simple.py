from ryu.base import app_manager
from ryu.controller import ofp_event
from ryu.controller.handler import MAIN_DISPATCHER, CONFIG_DISPATCHER, DEAD_DISPATCHER, HANDSHAKE_DISPATCHER
from ryu.controller.handler import set_ev_cls
#from ryu.lib.packet import packet
#from ryu.lib.packet import ethernet
from ryu.ofproto import ofproto_v1_4
#from ryu.ofproto import ofproto_v1_3
#from ryu import utils
from ryu.controller.controller import Datapath
from ryu.controller import dpset

class test1(app_manager.RyuApp):
  OFP_VERSIONS = [ofproto_v1_0.OFP_VERSION, ofproto_v1_2.OFP_VERSION,
                    ofproto_v1_3.OFP_VERSION, ofproto_v1_4.OFP_VERSION]
  def __init__(self, *args, **kwargs):
    super(test1, self).__init__(*args, **kwargs)

    self.datapath = {} # keyed by datapath_id


  @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
  def switch_features_handler(self, ev):
    msg = ev.msg
    datapath = msg.datapath
    ofproto = datapath.ofproto
    parser = datapath.ofproto_parser

    # install the table-miss flow entry.
    match = parser.OFPMatch()
    actions = [parser.OFPActionOutput(ofproto.OFPP_CONTROLLER,
                                      ofproto.OFPCML_NO_BUFFER
                                      )]
    # set to 0 based upon:
    # https://github.com/osrg/ryu/blob/master/ryu/app/simple_switch_snort.py
    self.add_flow(datapath, 0, match, actions )

    #id = '0x{0:016x}'.format(datapath.id)
    sId = str(datapath.id)


    self.logger.info('**OFPSwitchFeatures received: '
                      'datapath_id=0x%016x n_buffers=%d '
                      'n_tables=%d auxiliary_id=%d '
                      'capabilities=0x%08x',
                      msg.datapath_id, msg.n_buffers, msg.n_tables,
                      msg.auxiliary_id, msg.capabilities)

  def add_flow(self, datapath, priority, match, actions):
    ofproto = datapath.ofproto
    parser = datapath.ofproto_parser

    # construct flow_mod message and send it.
    inst = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS, actions)]
    mod = parser.OFPFlowMod(datapath=datapath, priority=priority,
                            match=match, instructions=inst,
                            cookie=1024
                            )
    datapath.send_msg(mod)

  def DecodePort(self, OFPPort):  # OFPPort
    item = OFPPort
    port = {}
    port['id'] = item.port_no
    port['mac'] = item.hw_addr
    port['length'] = item.length # dunno what this is
    port['name'] = item.name
    port['state'] = item.state
    for desc in item.properties:
      if 0 == desc.type:
        port['speed'] = desc.curr_speed
    #self.logger.info(port)
    return port

  # for definitions: http://ryu.readthedocs.io/en/latest/ofproto_v1_4_ref.html
  @set_ev_cls(dpset.EventDP)
  def HandleEventDP(self, event):
    # EventOFPStateChange has subset of this info, so use this state instead for info gathering?
    # the switch has a mac, maybe use it sometime?
    # ^^^^ EventDP: 1 86:44:9f:d1:c6:4c s1 0 4294967294
    self.logger.info( "^^^^^ EventDP: dpid %d, enter %d", event.dp.id, event.enter) # true for switch connected, false for swtich disconnected
    #print("^^^^^", event.ports)
    ports = {}
    for item in event.ports:
      #print( '&&&:', type(item))
      #print( '&&&&:', item )
      # id 4294967294 is the switch name
      port = self.DecodePort( item )
      #self.logger.info( port )
      ports[port['id']] = port
      self.logger.info( '^^^^ EventDP: %d %s %s %d %d', port['state'], port['mac'], port['name'], port['speed'], port['id'] )
    #print ports


  @set_ev_cls(dpset.EventPortAdd)
  def HandleEventPortAdd(self, event):
    dp = event.dp # datapath
    port = self.DecodePort( event.port )
    self.UpdateConsulDatapathPort( dp.id, 'HandleEventPortAdd', port )

  # not called as part of startup or shutdown
  @set_ev_cls(dpset.EventPortDelete)
  def HandleEventPortDelete(self, event):
    dp = event.dp
    port = self.DecodePort( event.port )
    self.UpdateConsulDatapathPort( dp.id, 'HandleEventPortDelete', port )

  @set_ev_cls(dpset.EventPortModify)
  def HandleEventPortModify(self, event):
    dp = event.dp
    port = self.DecodePort( event.port )
    self.UpdateConsulDatapathPort( dp.id, 'HandleEventPortModify', port )

  # don't really need this as we monitor the original Add, Delete, Modify events
  #  isn't being called during port setup
  @set_ev_cls(ofp_event.EventOFPPortStatus, MAIN_DISPATCHER)
  def port_status_handler(self, ev):
    msg = ev.msg
    dp = msg.datapath
    ofp = dp.ofproto

    if msg.reason == ofp.OFPPR_ADD:
        reason = 'ADD'
    elif msg.reason == ofp.OFPPR_DELETE:
        reason = 'DELETE'
    elif msg.reason == ofp.OFPPR_MODIFY:
        reason = 'MODIFY'
    else:
        reason = 'unknown'

    self.logger.info('!!!!! ++ OFPPortStatus received: reason=%s desc=%s',
                      reason, msg.desc)

  @set_ev_cls(ofp_event.EventOFPPortStateChange, MAIN_DISPATCHER)
  def port_state_change(self,ev):
    dp = ev.datapath
    reason = ev.reason
    port = ev.port_no
    self.logger.info('!!!! -- OFPPortStateChange recieved: '
                     'datapath.id=%016x reason=%s port_no=%d',
                     dp.id, reason, port
                     )

