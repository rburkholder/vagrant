
import consul

def listener():

  c = consul.Consul(host='10.0.2.15')

  c.kv.put('key1', 'value1' )
  c.kv.put('key2', 'value2' )
  c.kv.put('switch', 'step1' )

  # poll a key for updates
  index = None
  while True:
    index, data = c.kv.get( 'switch', index=index )
    print index, data

if __name__ == '__main__':
  listener()
