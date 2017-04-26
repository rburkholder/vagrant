from ryu.base import app_manager
from ryu.controller import ofp_event
from ryu.controller.handler import MAIN_DISPATCHER, CONFIG_DISPATCHER, DEAD_DISPATCHER, HANDSHAKE_DISPATCHER
from ryu.controller.handler import set_ev_cls
from ryu.lib.packet import packet
from ryu.lib.packet import ethernet
from ryu.ofproto import ofproto_v1_4
#from ryu.ofproto import ofproto_v1_3
from ryu import utils
from ryu.controller.controller import Datapath

from ryu.topology import event
from ryu.controller import dpset

from ryu.topology import event, switches
from ryu.topology.api import get_switch, get_link


# init with:
#   mkdir /var/log/ryu

# started with:
#   ryu-manager --observe-links --use-stderr --install-lldp-flow --verbose /vagrant/test1.py

# todo:
#   network discovery using the sample code
#   start analyzing events and building flows

class test1(app_manager.RyuApp):
#  OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]
  OFP_VERSIONS = [ofproto_v1_4.OFP_VERSION]

  def __init__(self, *args, **kwargs):
    super(test1, self).__init__(*args, **kwargs)

    self.datapath = {} # keyed by datapath_id
    self.mac_to_port = {} # keyed by mac
    self.topology_api_app = self
    self.nodes = {}
    self.links = {}
    self.no_of_nodes = 0
    self.no_of_links = 0
    self.i=0

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

  @set_ev_cls(ofp_event.EventOFPStateChange, [MAIN_DISPATCHER, DEAD_DISPATCHER])
  def state_change_handler(self,ev):
    datapath = ev.datapath
    if ev.state == MAIN_DISPATCHER:
      self.logger.info('OFPStateChange MAIN received: '
                       'datapath_id=%016x', datapath.id
                       )
    elif ev.state == DEAD_DISPATCHER:
      self.logger.info('**OFPStateChange DEAD received ' )

  @set_ev_cls(dpset.EventPortModify, MAIN_DISPATCHER)
  def port_modify_handler(self, ev):
    self.logger.info('**EventPortModify')

  @set_ev_cls(event.EventSwitchEnter)
  def get_topology_data(self, ev):
    switch_list = get_switch(self.topology_api_app, None)
    switches=[switch.dp.id for switch in switch_list]
    #self.net.add_nodes_from(switches)

    print "**********List of switches"
    for switch in switch_list:
      #self.ls(switch)
      print switch
      self.nodes[self.no_of_nodes] = switch
      self.no_of_nodes += 1

    links_list = get_link(self.topology_api_app, None)
    print links_list

    links=[(link.src.dpid,link.dst.dpid,{'port':link.src.port_no}) for link in links_list]
    print links

    #self.net.add_edges_from(links)
    links=[(link.dst.dpid,link.src.dpid,{'port':link.dst.port_no}) for link in links_list]
    print links

    #self.net.add_edges_from(links)
    print "**********List of links"
    #print self.net.edges()
    for link in links_list:
      print link.dst
      print link.src
      #print "Novo link"
	  #self.no_of_links += 1


  @set_ev_cls(event.EventSwitchLeave, [MAIN_DISPATCHER, CONFIG_DISPATCHER, DEAD_DISPATCHER])
  def handler_switch_leave(self, ev):
    self.logger.info("**Not tracking Switch, switch left.")

  @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)
  def packet_in_handler(self, ev):

    # self.logger.info('**packet_in')

    msg      = ev.msg
    datapath = msg.datapath
    ofproto  = datapath.ofproto
    parser   = datapath.ofproto_parser

    #if ofproto_v1_4.OFP_NO_BUFFER == msg.buffer_id:
    #  self.logger.info('**not buffered in switch')

    #actions = [ofp_parser.OFPActionOutput(ofproto.OFPP_FLOOD)]
    #out = ofp_parser.OFPPacketOut(
    #  datapath=dp,
    #  buffer_id=msg.buffer_id,
    #  in_port=msg.msg.match['in_port'],
    #  actions=actions)
    #dp.send_msg(out)

#   version 1.4
    if msg.reason == ofproto.OFPR_TABLE_MISS:
#   version 1.3
#    if msg.reason == ofproto.OFPR_NO_MATCH:
        reason = 'TABLE MISS'
    elif msg.reason == ofproto.OFPR_APPLY_ACTION:
        reason = 'APPLY ACTION'
    elif msg.reason == ofproto.OFPR_INVALID_TTL:
        reason = 'INVALID TTL'
    elif msg.reason == ofproto.OFPR_ACTION_SET:
        reason = 'ACTION SET'
    elif msg.reason == ofproto.OFPR_GROUP:
        reason = 'GROUP'
    elif msg.reason == ofproto.OFPR_PACKET_OUT:
        reason = 'PACKET OUT'
    else:
        reason = 'unknown'

    if True:
      self.logger.info('**OFPPacketIn: '
                      'datapath_id=%016x '
                      'buffer_id=%x total_len=%d reason=%s '
                      'table_id=%d cookie=%d match=%s',
                      datapath.id,
                      msg.buffer_id, msg.total_len, reason,
                      msg.table_id, msg.cookie, msg.match
                      )
    else:
      self.logger.info('**OFPPacketIn: '
                      'datapath_id=%016x '
                      'buffer_id=%x total_len=%d reason=%s '
                      'table_id=%d cookie=%d match=%s data=%s',
                      datapath.id,
                      msg.buffer_id, msg.total_len, reason,
                      msg.table_id, msg.cookie, msg.match,
                      utils.hex_array(msg.data)
                      )

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

    self.logger.info('**OFPPortStatus received: reason=%s desc=%s',
                      reason, msg.desc)

  @set_ev_cls(ofp_event.EventOFPPortStateChange, MAIN_DISPATCHER)
  def port_state_change(self,ev):
    dp = ev.datapath
    reason = ev.reason
    port = ev.port_no
    self.logger.info('**OFPPortStateChange recieved: '
                     'datapath.id=%016x reason=%s port_no=%d',
                     dp.id, reason, port
                     )

  @set_ev_cls(ofp_event.EventOFPDescStatsReply, MAIN_DISPATCHER)
  def desc_stats_reply_handler(self, ev):
    body = ev.msg.body
    self.logger.info('**DescStats: mfr_desc=%s hw_desc=%s sw_desc=%s '
                      'serial_num=%s dp_desc=%s',
                      body.mfr_desc, body.hw_desc, body.sw_desc,
                      body.serial_num, body.dp_desc)

  @set_ev_cls(ofp_event.EventOFPFlowStatsReply, MAIN_DISPATCHER)
  def flow_stats_reply_handler(self, ev):
    flows = []
    for stat in ev.msg.body:
        flows.append('table_id=%s '
                     'duration_sec=%d duration_nsec=%d '
                     'priority=%d '
                     'idle_timeout=%d hard_timeout=%d flags=0x%04x '
                     'importance=%d cookie=%d packet_count=%d '
                     'byte_count=%d match=%s instructions=%s' %
                     (stat.table_id,
                      stat.duration_sec, stat.duration_nsec,
                      stat.priority,
                      stat.idle_timeout, stat.hard_timeout,
                      stat.flags, stat.importance,
                      stat.cookie, stat.packet_count, stat.byte_count,
                      stat.match, stat.instructions))
    self.logger.info('**FlowStats: %s', flows)

  @set_ev_cls(ofp_event.EventOFPAggregateStatsReply, MAIN_DISPATCHER)
  def aggregate_stats_reply_handler(self, ev):
    body = ev.msg.body

    self.logger.info('**AggregateStats: packet_count=%d byte_count=%d '
                      'flow_count=%d',
                      body.packet_count, body.byte_count,
                      body.flow_count)

  @set_ev_cls(ofp_event.EventOFPTableStatsReply, MAIN_DISPATCHER)
  def table_stats_reply_handler(self, ev):
    tables = []
    for stat in ev.msg.body:
        tables.append('table_id=%d active_count=%d lookup_count=%d '
                      ' matched_count=%d' %
                      (stat.table_id, stat.active_count,
                       stat.lookup_count, stat.matched_count))
    self.logger.info('**TableStats: %s', tables)

  @set_ev_cls(ofp_event.EventOFPTableDescStatsReply, MAIN_DISPATCHER)
  def table_desc_stats_reply_handler(self, ev):
    tables = []
    for p in ev.msg.body:
        tables.append('table_id=%d config=0x%08x properties=%s' %
                     (p.table_id, p.config, repr(p.properties)))
    self.logger.info('**OFPTableDescStatsReply received: %s', tables)

  @set_ev_cls(ofp_event.EventOFPFlowRemoved, MAIN_DISPATCHER)
  def flow_removed_handler(self, ev):
    msg = ev.msg
    dp = msg.datapath
    ofp = dp.ofproto

    if msg.reason == ofp.OFPRR_IDLE_TIMEOUT:
        reason = 'IDLE TIMEOUT'
    elif msg.reason == ofp.OFPRR_HARD_TIMEOUT:
        reason = 'HARD TIMEOUT'
    elif msg.reason == ofp.OFPRR_DELETE:
        reason = 'DELETE'
    elif msg.reason == ofp.OFPRR_GROUP_DELETE:
        reason = 'GROUP DELETE'
    else:
        reason = 'unknown'

    self.logger.info('**OFPFlowRemoved received: '
                      'cookie=%d priority=%d reason=%s table_id=%d '
                      'duration_sec=%d duration_nsec=%d '
                      'idle_timeout=%d hard_timeout=%d '
                      'packet_count=%d byte_count=%d match.fields=%s',
                      msg.cookie, msg.priority, reason, msg.table_id,
                      msg.duration_sec, msg.duration_nsec,
                      msg.idle_timeout, msg.hard_timeout,
                      msg.packet_count, msg.byte_count, msg.match)


  @set_ev_cls(ofp_event.EventOFPTableStatus, MAIN_DISPATCHER)
  def table(self, ev):
    msg = ev.msg
    dp = msg.datapath
    ofp = dp.ofproto

    if msg.reason == ofp.OFPTR_VACANCY_DOWN:
        reason = 'VACANCY_DOWN'
    elif msg.reason == ofp.OFPTR_VACANCY_UP:
        reason = 'VACANCY_UP'
    else:
        reason = 'unknown'

    self.logger.info('**OFPTableStatus received: reason=%s '
                      'table_id=%d config=0x%08x properties=%s',
                      reason, msg.table.table_id, msg.table.config,
                      repr(msg.table.properties))

  @set_ev_cls(ofp_event.EventOFPErrorMsg,
            [HANDSHAKE_DISPATCHER, CONFIG_DISPATCHER, MAIN_DISPATCHER])
  def error_msg_handler(self, ev):
    msg = ev.msg

    self.logger.info('**OFPErrorMsg received: type=0x%02x code=0x%02x '
                      'message=%s',
                      msg.type, msg.code, utils.hex_array(msg.data))
