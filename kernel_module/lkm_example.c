#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/slab.h>
#include <asm-generic/io.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Leipo Yan");
MODULE_DESCRIPTION("Simple Linux kernel module.");
MODULE_VERSION("0.01");

static void *buf;
phys_addr_t paddr;
static int buf_size = 4096;

static int __init lkm_example_init(void) {
	buf = kzalloc(buf_size, GFP_KERNEL);
	if (buf == NULL) {
		printk(KERN_ERR "Memory allocation failed\n");
		return -ENOMEM;
	}

	paddr = virt_to_phys(buf);

	printk(KERN_INFO "Virtual Address: %p, Physical Address: %pa\n",
	       buf, &paddr);

	return 0;
}
static void __exit lkm_example_exit(void) {
	if (buf)
		kfree(buf);
}

module_param(buf_size, int, 0600);
MODULE_PARM_DESC(buf_size, "Buffer size in bytes");

module_init(lkm_example_init);
module_exit(lkm_example_exit);
