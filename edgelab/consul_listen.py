
import consul

def listener():

  c = consul.Consul(host='10.0.2.15')

  c.kv.put('switch', 'placeholder' )
  c.kv.put('mn_ryu/', '' )

  # poll a key for updates
  index = None
  while True:
#    index, data = c.kv.get( 'mn_ryu', index=index )
    index, data = c.kv.get( 'mn_ryu', keys=True, index=index )
    print index, data
    for key in data:
      data = c.kv.get( key )
      print "- ", key, data

if __name__ == '__main__':
  listener()
