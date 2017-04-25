
In kernel 4.10.0, the function "nf_defrag_ipv6_enable" need
parameters "struct net *", so we need call it for each namespace init
to load netfilter fragment kmod.

Reported-by: Raymond Burkholder <ray@oneunified.net>
Reported-at: https://mail.openvswitch.org/pipermail/ovs-dev/2017-April/331411.html
Signed-off-by: Guoshuai Li <ligs@dtdream.com>
---
 datapath/linux/compat/ip_fragment.c        | 14 ++++++++++++++
 datapath/linux/compat/nf_conntrack_reasm.c | 14 ++++++++++++++
 2 files changed, 28 insertions(+)

diff --git a/datapath/linux/compat/ip_fragment.c b/datapath/linux/compat/ip_fragment.c
index b0f5d0e..efa86fc 100644
--- a/datapath/linux/compat/ip_fragment.c
+++ b/datapath/linux/compat/ip_fragment.c
@@ -729,18 +729,32 @@ int rpl_ip_defrag(struct net *net, struct sk_buff *skb, u32 user)
 	return -ENOMEM;
 }
 
+#if LINUX_VERSION_CODE >= KERNEL_VERSION(4,10,0)
+static int __net_init ipv4_frags_init_net(struct net *net)
+{
+	nf_defrag_ipv4_enable(net);
+
+	return 0;
+}
+#endif
+
 static void __net_exit ipv4_frags_exit_net(struct net *net)
 {
 	inet_frags_exit_net(&net->ipv4.frags, &ip4_frags);
 }
 
 static struct pernet_operations ip4_frags_ops = {
+#if LINUX_VERSION_CODE >= KERNEL_VERSION(4,10,0)
+	.init = ipv4_frags_init_net,
+#endif
 	.exit = ipv4_frags_exit_net,
 };
 
 int __init rpl_ipfrag_init(void)
 {
+#if LINUX_VERSION_CODE < KERNEL_VERSION(4,10,0)
 	nf_defrag_ipv4_enable();
+#endif
 	register_pernet_subsys(&ip4_frags_ops);
 	ip4_frags.hashfn = ip4_hashfn;
 	ip4_frags.constructor = ip4_frag_init;
diff --git a/datapath/linux/compat/nf_conntrack_reasm.c b/datapath/linux/compat/nf_conntrack_reasm.c
index 0bc4d9e..cb6da6c 100644
--- a/datapath/linux/compat/nf_conntrack_reasm.c
+++ b/datapath/linux/compat/nf_conntrack_reasm.c
@@ -558,12 +558,24 @@ out_unlock:
 	return ret;
 }
 
+#if LINUX_VERSION_CODE >= KERNEL_VERSION(4,10,0)
+static int nf_ct_net_init(struct net *net)
+{
+	nf_defrag_ipv6_enable(net);
+
+	return 0;
+}
+#endif
+
 static void nf_ct_net_exit(struct net *net)
 {
 	inet_frags_exit_net(&net->nf_frag.frags, &nf_frags);
 }
 
 static struct pernet_operations nf_ct_net_ops = {
+#if LINUX_VERSION_CODE >= KERNEL_VERSION(4,10,0)
+	.init = nf_ct_net_init,
+#endif
 	.exit = nf_ct_net_exit,
 };
 
@@ -571,7 +583,9 @@ int rpl_nf_ct_frag6_init(void)
 {
 	int ret = 0;
 
+#if LINUX_VERSION_CODE < KERNEL_VERSION(4,10,0)
 	nf_defrag_ipv6_enable();
+#endif
 	nf_frags.hashfn = nf_hashfn;
 	nf_frags.constructor = ip6_frag_init;
 	nf_frags.destructor = NULL;
-- 
2.10.1.windows.1

_______________________________________________
dev mailing list
dev@openvswitch.org
https://mail.openvswitch.org/mailman/listinfo/ovs-dev

-- 
This message has been scanned for viruses and
dangerous content by MailScanner, and is
believed to be clean.

